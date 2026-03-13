// Must include Windows headers BEFORE C++ std headers to avoid
// std::byte vs Windows byte typedef collision (MinGW + C++17)
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <winhttp.h>

#include "plugin_interface.h"
#include <chrono>
#include <sstream>
#include <algorithm>

#pragma comment(lib, "winhttp.lib")

using namespace std;

namespace tablemax {

// ── TSV Parser ──────────────────────────────────────────────
static string unescape_tsv(const string& field) {
    string result;
    result.reserve(field.size());
    for (size_t i = 0; i < field.size(); ++i) {
        if (field[i] == '\\' && i + 1 < field.size()) {
            switch (field[i + 1]) {
                case '\\': result += '\\'; break;
                case 't':  result += '\t'; break;
                case 'n':  result += '\n'; break;
                case 'N':  result += "NULL"; --i; continue; // \N = null, handled separately
                default:   result += '\\'; result += field[i + 1]; break;
            }
            ++i;
        } else {
            result += field[i];
        }
    }
    return result;
}

static vector<string> split_tsv_line(const string& line) {
    vector<string> fields;
    string field;
    for (char c : line) {
        if (c == '\t') {
            fields.push_back(field);
            field.clear();
        } else {
            field += c;
        }
    }
    fields.push_back(field);
    return fields;
}

// ── Result Stream ───────────────────────────────────────────
class ClickHouseResultStream : public IResultStream {
    vector<ColumnInfo> cols_;
    vector<Row> rows_;
    QueryMeta meta_;
    size_t pos_ = 0;
public:
    ClickHouseResultStream(vector<ColumnInfo> c, vector<Row> r, QueryMeta m)
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

// ── Helper: is this a SELECT-like query? ────────────────────
static bool is_select_query(const string& sql) {
    string trimmed = sql;
    // trim leading whitespace
    size_t start = trimmed.find_first_not_of(" \t\n\r");
    if (start == string::npos) return false;
    string upper;
    for (size_t i = start; i < min(start + 10, trimmed.size()); ++i)
        upper += (char)toupper(trimmed[i]);
    return upper.substr(0, 6) == "SELECT" ||
           upper.substr(0, 4) == "SHOW" ||
           upper.substr(0, 8) == "DESCRIBE" ||
           upper.substr(0, 4) == "DESC" ||
           upper.substr(0, 7) == "EXPLAIN" ||
           upper.substr(0, 6) == "EXISTS" ||
           upper.substr(0, 4) == "WITH";
}

// ── Helper: trim trailing semicolons ────────────────────────
static string trim_query(const string& q) {
    string s = q;
    while (!s.empty() && (s.back() == ';' || s.back() == ' ' || s.back() == '\n' || s.back() == '\r'))
        s.pop_back();
    return s;
}

// ── Helper: widen string ────────────────────────────────────
static wstring to_wstring(const string& s) {
    if (s.empty()) return L"";
    int sz = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), nullptr, 0);
    wstring ws(sz, 0);
    MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), &ws[0], sz);
    return ws;
}

// ── Helper: Base64 encode ───────────────────────────────────
static string base64_encode(const string& input) {
    static const char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    string encoded;
    int val = 0, bits = -6;
    for (unsigned char c : input) {
        val = (val << 8) + c;
        bits += 8;
        while (bits >= 0) {
            encoded.push_back(table[(val >> bits) & 0x3F]);
            bits -= 6;
        }
    }
    if (bits > -6) encoded.push_back(table[((val << 8) >> (bits + 8)) & 0x3F]);
    while (encoded.size() % 4) encoded.push_back('=');
    return encoded;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ClickHousePlugin
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ClickHousePlugin : public IDbPlugin {
    string error_;
    string host_, user_, pass_, database_;
    int port_ = 8123;
    bool connected_ = false;

    // Parse clickhouse://user:pass@host:port/db
    struct ConnParams { string host, user, pass, db; int port = 8123; };
    ConnParams parse_url(const string& url) {
        ConnParams p;
        string s = url;
        auto idx = s.find("://");
        if (idx != string::npos) s = s.substr(idx + 3);
        auto at = s.find('@');
        if (at != string::npos) {
            string auth = s.substr(0, at);
            s = s.substr(at + 1);
            auto col = auth.find(':');
            if (col != string::npos) {
                p.user = auth.substr(0, col);
                p.pass = auth.substr(col + 1);
            } else {
                p.user = auth;
            }
        }
        auto slash = s.find('/');
        if (slash != string::npos) {
            p.db = s.substr(slash + 1);
            s = s.substr(0, slash);
        }
        auto col = s.find(':');
        if (col != string::npos) {
            p.host = s.substr(0, col);
            p.port = atoi(s.substr(col + 1).c_str());
        } else {
            p.host = s;
        }
        if (p.host.empty()) p.host = "localhost";
        if (p.port <= 0) p.port = 8123;
        if (p.user.empty()) p.user = "default";
        return p;
    }

    // ── HTTP POST via WinHTTP ──
    bool http_post(const string& body, string& response, string& err) {
        HINTERNET hSession = WinHttpOpen(L"TableMax/1.0",
            WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, nullptr, nullptr, 0);
        if (!hSession) { err = "WinHttpOpen failed"; return false; }

        wstring whost = to_wstring(host_);
        HINTERNET hConnect = WinHttpConnect(hSession, whost.c_str(),
            (INTERNET_PORT)port_, 0);
        if (!hConnect) {
            WinHttpCloseHandle(hSession);
            err = "WinHttpConnect failed: " + host_ + ":" + to_string(port_);
            return false;
        }

        // Build path with database param
        wstring path = L"/?";
        if (!database_.empty()) {
            path += L"database=" + to_wstring(database_) + L"&";
        }
        path += L"send_progress_in_http_headers=1";

        HINTERNET hRequest = WinHttpOpenRequest(hConnect, L"POST",
            path.c_str(), nullptr, WINHTTP_NO_REFERER,
            WINHTTP_DEFAULT_ACCEPT_TYPES, 0);
        if (!hRequest) {
            WinHttpCloseHandle(hConnect);
            WinHttpCloseHandle(hSession);
            err = "WinHttpOpenRequest failed";
            return false;
        }

        // Set timeout (10s connect, 30s send/receive)
        WinHttpSetTimeouts(hRequest, 10000, 10000, 30000, 30000);

        // Add Basic Auth header
        string auth = "Basic " + base64_encode(user_ + ":" + pass_);
        wstring wauth = to_wstring("Authorization: " + auth);
        WinHttpAddRequestHeaders(hRequest, wauth.c_str(), (DWORD)-1,
            WINHTTP_ADDREQ_FLAG_ADD | WINHTTP_ADDREQ_FLAG_REPLACE);

        // Send request
        BOOL bSent = WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS,
            0, (LPVOID)body.c_str(), (DWORD)body.size(),
            (DWORD)body.size(), 0);
        if (!bSent) {
            WinHttpCloseHandle(hRequest);
            WinHttpCloseHandle(hConnect);
            WinHttpCloseHandle(hSession);
            err = "WinHttpSendRequest failed (is ClickHouse running?)";
            return false;
        }

        WinHttpReceiveResponse(hRequest, nullptr);

        // Check status code
        DWORD statusCode = 0;
        DWORD sz = sizeof(statusCode);
        WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
            nullptr, &statusCode, &sz, nullptr);

        // Read response body
        response.clear();
        DWORD bytesAvail = 0;
        while (WinHttpQueryDataAvailable(hRequest, &bytesAvail) && bytesAvail > 0) {
            vector<char> buf(bytesAvail);
            DWORD bytesRead = 0;
            WinHttpReadData(hRequest, buf.data(), bytesAvail, &bytesRead);
            response.append(buf.data(), bytesRead);
        }

        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);

        if (statusCode >= 400) {
            err = response.empty() ? ("HTTP " + to_string(statusCode)) : response;
            return false;
        }
        return true;
    }

public:
    ~ClickHousePlugin() override { disconnect(); }

    string name() const override { return "ClickHouse"; }
    string version() const override { return "0.1.0"; }
    string db_type() const override { return "clickhouse"; }

    bool connect(const string& cs) override {
        disconnect();
        auto p = parse_url(cs);
        host_ = p.host;
        port_ = p.port;
        user_ = p.user;
        pass_ = p.pass;
        database_ = p.db;

        // Test connection
        string resp, err;
        if (!http_post("SELECT 1", resp, err)) {
            error_ = err;
            return false;
        }
        connected_ = true;
        return true;
    }

    void disconnect() override { connected_ = false; }

    bool is_connected() const override { return connected_; }

    bool test_connection(int& ms) override {
        auto t0 = chrono::steady_clock::now();
        string resp, err;
        bool ok = http_post("SELECT 1", resp, err);
        auto t1 = chrono::steady_clock::now();
        ms = (int)chrono::duration_cast<chrono::milliseconds>(t1 - t0).count();
        if (!ok) error_ = err;
        return ok;
    }

    unique_ptr<IResultStream> execute(const string& query) override {
        if (!connected_) { error_ = "Not connected"; return nullptr; }

        auto t0 = chrono::steady_clock::now();
        string trimmed = trim_query(query);
        bool isSelect = is_select_query(trimmed);

        // For SELECT queries, append FORMAT to get structured output
        string body = isSelect
            ? (trimmed + " FORMAT TabSeparatedWithNamesAndTypes")
            : trimmed;

        string resp, err;
        if (!http_post(body, resp, err)) {
            error_ = err;
            return nullptr;
        }
        auto t1 = chrono::steady_clock::now();

        QueryMeta meta;
        meta.execution_time_ms = chrono::duration<double, milli>(t1 - t0).count();

        vector<ColumnInfo> cols;
        vector<Row> rows;

        if (isSelect && !resp.empty()) {
            // Parse TabSeparatedWithNamesAndTypes:
            // Line 1: column names (tab-separated)
            // Line 2: column types (tab-separated)
            // Line 3+: data rows
            istringstream ss(resp);
            string line;

            // Line 1: names
            vector<string> colNames;
            if (getline(ss, line)) {
                // Remove \r if present
                if (!line.empty() && line.back() == '\r') line.pop_back();
                colNames = split_tsv_line(line);
            }

            // Line 2: types
            vector<string> colTypes;
            if (getline(ss, line)) {
                if (!line.empty() && line.back() == '\r') line.pop_back();
                colTypes = split_tsv_line(line);
            }

            // Build column info
            for (size_t i = 0; i < colNames.size(); ++i) {
                ColumnInfo ci;
                ci.name = colNames[i];
                ci.type = (i < colTypes.size()) ? colTypes[i] : "String";
                ci.nullable = ci.type.find("Nullable") != string::npos;
                cols.push_back(ci);
            }

            // Data rows
            while (getline(ss, line)) {
                if (!line.empty() && line.back() == '\r') line.pop_back();
                if (line.empty()) continue;

                auto fields = split_tsv_line(line);
                Row r;
                for (size_t i = 0; i < fields.size() && i < colNames.size(); ++i) {
                    string val = (fields[i] == "\\N") ? "NULL" : unescape_tsv(fields[i]);
                    r.push_back({ colNames[i], val });
                }
                rows.push_back(move(r));
            }
            meta.total_rows = (int64_t)rows.size();
        } else {
            // Non-select: no rows returned
            meta.affected_rows = 0;
        }

        return make_unique<ClickHouseResultStream>(move(cols), move(rows), meta);
    }

    vector<string> list_databases() override {
        vector<string> dbs;
        if (!connected_) return dbs;
        auto result = execute("SHOW DATABASES");
        if (result) {
            while (result->has_more()) {
                auto chunk = result->next_chunk(1000);
                for (auto& row : chunk) {
                    if (!row.empty() && row[0].second != "NULL")
                        dbs.push_back(row[0].second);
                }
            }
        }
        return dbs;
    }

    vector<string> list_tables(const string& database) override {
        vector<string> tables;
        if (!connected_) return tables;

        // Temporarily switch database if needed
        string old_db = database_;
        if (!database.empty()) database_ = database;

        auto result = execute(
            "SELECT name FROM system.tables "
            "WHERE database = currentDatabase() AND name NOT LIKE '.%' "
            "ORDER BY name"
        );

        database_ = old_db;

        if (result) {
            while (result->has_more()) {
                auto chunk = result->next_chunk(1000);
                for (auto& row : chunk) {
                    if (!row.empty() && row[0].second != "NULL")
                        tables.push_back(row[0].second);
                }
            }
        }
        return tables;
    }

    vector<ColumnInfo> get_table_schema(const string& table) override {
        vector<ColumnInfo> cols;
        if (!connected_) return cols;

        string escaped = table;
        // Simple escaping for single quotes
        for (size_t pos = 0; (pos = escaped.find('\'', pos)) != string::npos; pos += 2)
            escaped.replace(pos, 1, "''");

        auto result = execute(
            "SELECT name, type, default_kind, default_expression, comment "
            "FROM system.columns "
            "WHERE database = currentDatabase() AND table = '" + escaped + "' "
            "ORDER BY position"
        );

        if (result) {
            while (result->has_more()) {
                auto chunk = result->next_chunk(1000);
                for (auto& row : chunk) {
                    if (row.size() < 2) continue;
                    ColumnInfo ci;
                    ci.name = row[0].second;
                    ci.type = row[1].second;
                    ci.nullable = ci.type.find("Nullable") != string::npos;
                    if (row.size() > 3 && row[3].second != "NULL" && !row[3].second.empty())
                        ci.default_value = row[3].second;
                    cols.push_back(ci);
                }
            }
        }

        // Detect primary key columns from sorting_key
        auto pkResult = execute(
            "SELECT primary_key, sorting_key FROM system.tables "
            "WHERE database = currentDatabase() AND name = '" + escaped + "'"
        );
        if (pkResult && pkResult->has_more()) {
            auto chunk = pkResult->next_chunk(1);
            if (!chunk.empty() && chunk[0].size() >= 2) {
                string key = chunk[0][0].second;
                if (key == "NULL" || key.empty()) key = chunk[0][1].second;
                // Parse comma-separated key columns
                istringstream ks(key);
                string col;
                while (getline(ks, col, ',')) {
                    // trim
                    size_t s = col.find_first_not_of(" ");
                    size_t e = col.find_last_not_of(" ");
                    if (s != string::npos) col = col.substr(s, e - s + 1);
                    for (auto& ci : cols) {
                        if (ci.name == col) ci.primary_key = true;
                    }
                }
            }
        }

        return cols;
    }

    string last_error() const override { return error_; }
};

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::ClickHousePlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
