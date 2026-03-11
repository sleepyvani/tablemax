#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#define byte win_byte_override
#include <winsock2.h>
#include <ws2tcpip.h>
#undef byte
#pragma comment(lib, "ws2_32.lib")
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#define SOCKET int
#define INVALID_SOCKET -1
#define SOCKET_ERROR -1
#define closesocket close
#endif

#include "plugin_interface.h"

#include <chrono>
#include <sstream>
#include <cstring>

using namespace std;

namespace tablemax {

class RedisResultStream : public IResultStream {
    vector<ColumnInfo> cols_;
    vector<Row> rows_;
    QueryMeta meta_;
    size_t pos_ = 0;
public:
    RedisResultStream(vector<ColumnInfo> c, vector<Row> r, QueryMeta m)
        : cols_(move(c)), rows_(move(r)), meta_(move(m)) {}
    vector<ColumnInfo> columns() const override { return cols_; }
    QueryMeta meta() const override { return meta_; }
    bool has_more() const override { return pos_ < rows_.size(); }
    void close() override { pos_ = rows_.size(); }
    vector<Row> next_chunk(int n) override {
        vector<Row> chunk;
        for (int i = 0; i < n && pos_ < rows_.size(); ++i, ++pos_)
            chunk.push_back(rows_[pos_]);
        return chunk;
    }
};

class RedisPlugin : public IDbPlugin {
    SOCKET sock_ = INVALID_SOCKET;
    string cs_, error_, host_;
    int port_ = 6379;
    string password_;
    bool connected_ = false;

    // Parse redis://[:password@]host:port
    void parse_url(const string& url) {
        host_ = "127.0.0.1"; port_ = 6379; password_ = "";
        string s = url;
        if (s.substr(0, 8) == "redis://") s = s.substr(8);
        // password
        auto at = s.find('@');
        if (at != string::npos) {
            password_ = s.substr(0, at);
            if (!password_.empty() && password_[0] == ':') password_ = password_.substr(1);
            s = s.substr(at + 1);
        }
        // host:port
        auto col = s.find(':');
        if (col != string::npos) {
            host_ = s.substr(0, col);
            port_ = atoi(s.substr(col + 1).c_str());
        } else if (!s.empty()) {
            host_ = s;
        }
        if (host_.empty()) host_ = "127.0.0.1";
        if (port_ <= 0) port_ = 6379;
    }

    string send_command(const vector<string>& args) {
        if (sock_ == INVALID_SOCKET) return "";
        // Build RESP
        ostringstream req;
        req << "*" << args.size() << "\r\n";
        for (auto& a : args) req << "$" << a.size() << "\r\n" << a << "\r\n";
        string data = req.str();
        ::send(sock_, data.c_str(), (int)data.size(), 0);

        // Read response
        char buf[8192];
        int n = ::recv(sock_, buf, sizeof(buf) - 1, 0);
        if (n <= 0) return "";
        buf[n] = '\0';
        return string(buf, n);
    }

    string parse_simple(const string& resp) {
        if (resp.empty()) return "";
        if (resp[0] == '+' || resp[0] == '-') {
            auto end = resp.find("\r\n");
            return end != string::npos ? resp.substr(1, end - 1) : resp.substr(1);
        }
        if (resp[0] == '$') {
            auto nl = resp.find("\r\n");
            int len = atoi(resp.substr(1, nl - 1).c_str());
            if (len < 0) return "(nil)";
            return resp.substr(nl + 2, len);
        }
        return resp;
    }

public:
    ~RedisPlugin() override { disconnect(); }

    string name() const override { return "Redis"; }
    string version() const override { return "0.2.0"; }
    string db_type() const override { return "redis"; }

    bool connect(const string& cs) override {
        disconnect();
        cs_ = cs;
        parse_url(cs);

#ifdef _WIN32
        WSADATA wsa;
        WSAStartup(MAKEWORD(2, 2), &wsa);
#endif

        struct addrinfo hints{}, *result = nullptr;
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_STREAM;
        string port_str = to_string(port_);

        if (getaddrinfo(host_.c_str(), port_str.c_str(), &hints, &result) != 0) {
            error_ = "Cannot resolve host: " + host_;
            return false;
        }

        sock_ = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
        if (sock_ == INVALID_SOCKET) {
            error_ = "Failed to create socket";
            freeaddrinfo(result);
            return false;
        }

        // Set timeout
#ifdef _WIN32
        DWORD timeout = 5000;
        setsockopt(sock_, SOL_SOCKET, SO_RCVTIMEO, (const char*)&timeout, sizeof(timeout));
        setsockopt(sock_, SOL_SOCKET, SO_SNDTIMEO, (const char*)&timeout, sizeof(timeout));
#else
        struct timeval tv{5, 0};
        setsockopt(sock_, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
        setsockopt(sock_, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
#endif

        if (::connect(sock_, result->ai_addr, (int)result->ai_addrlen) == SOCKET_ERROR) {
            error_ = "Cannot connect to " + host_ + ":" + to_string(port_);
            closesocket(sock_);
            sock_ = INVALID_SOCKET;
            freeaddrinfo(result);
            return false;
        }
        freeaddrinfo(result);

        // AUTH if password set
        if (!password_.empty()) {
            string resp = send_command({"AUTH", password_});
            if (resp.empty() || resp[0] == '-') {
                error_ = "AUTH failed: " + parse_simple(resp);
                closesocket(sock_);
                sock_ = INVALID_SOCKET;
                return false;
            }
        }

        connected_ = true;
        return true;
    }

    void disconnect() override {
        if (sock_ != INVALID_SOCKET) {
            send_command({"QUIT"});
            closesocket(sock_);
            sock_ = INVALID_SOCKET;
        }
        connected_ = false;
    }

    bool is_connected() const override { return connected_ && sock_ != INVALID_SOCKET; }

    bool test_connection(int& ms) override {
        if (sock_ == INVALID_SOCKET) { error_ = "Not connected"; return false; }
        auto t0 = chrono::steady_clock::now();
        string resp = send_command({"PING"});
        auto t1 = chrono::steady_clock::now();
        ms = (int)chrono::duration_cast<chrono::milliseconds>(t1 - t0).count();
        string parsed = parse_simple(resp);
        if (parsed != "PONG") {
            error_ = "PING failed: " + parsed;
            return false;
        }
        return true;
    }

    unique_ptr<IResultStream> execute(const string& query) override {
        if (sock_ == INVALID_SOCKET) { error_ = "Not connected"; return nullptr; }

        // Parse command string into args
        vector<string> args;
        istringstream iss(query);
        string token;
        while (iss >> token) args.push_back(token);
        if (args.empty()) { error_ = "Empty command"; return nullptr; }

        auto t0 = chrono::steady_clock::now();
        string resp = send_command(args);
        auto t1 = chrono::steady_clock::now();

        if (resp.empty()) { error_ = "No response from server"; return nullptr; }
        if (resp[0] == '-') { error_ = parse_simple(resp); return nullptr; }

        vector<ColumnInfo> cols = {{ "result", "text", true, false, "" }};
        vector<Row> rows;
        rows.push_back({{"result", parse_simple(resp)}});

        QueryMeta meta;
        meta.total_rows = 1;
        meta.execution_time_ms = chrono::duration<double, milli>(t1 - t0).count();
        return make_unique<RedisResultStream>(move(cols), move(rows), meta);
    }

    vector<string> list_databases() override {
        vector<string> dbs;
        for (int i = 0; i < 16; ++i) dbs.push_back(to_string(i));
        return dbs;
    }

    vector<string> list_tables(const string&) override {
        // Redis doesn't have tables — list keys
        vector<string> keys;
        if (sock_ == INVALID_SOCKET) return keys;
        string resp = send_command({"DBSIZE"});
        keys.push_back("(keys: " + parse_simple(resp) + ")");
        return keys;
    }

    vector<ColumnInfo> get_table_schema(const string&) override { return {}; }
    string last_error() const override { return error_; }
};

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::RedisPlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
