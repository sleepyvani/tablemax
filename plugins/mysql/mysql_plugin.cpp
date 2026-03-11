#include "plugin_interface.h"
#include <mysql.h>
#include <chrono>

using namespace std;

namespace tablemax {

class MySQLResultStream : public IResultStream {
    vector<ColumnInfo> cols_;
    vector<Row> rows_;
    QueryMeta meta_;
    size_t pos_ = 0;
public:
    MySQLResultStream(vector<ColumnInfo> c, vector<Row> r, QueryMeta m)
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

class MySQLPlugin : public IDbPlugin {
    MYSQL* conn_ = nullptr;
    string cs_, error_;

    // Parse mysql://user:pass@host:port/db
    struct ConnParams { string host, user, pass, db; int port = 3306; };
    ConnParams parse_url(const string& url) {
        ConnParams p;
        string s = url;
        // Remove scheme
        auto idx = s.find("://");
        if (idx != string::npos) s = s.substr(idx + 3);
        // user:pass@
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
        // host:port/db
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
        if (p.port <= 0) p.port = 3306;
        return p;
    }

public:
    ~MySQLPlugin() override { disconnect(); }

    string name() const override { return "MySQL"; }
    string version() const override { return "0.2.0"; }
    string db_type() const override { return "mysql"; }

    bool connect(const string& cs) override {
        disconnect();
        cs_ = cs;
        auto p = parse_url(cs);

        conn_ = mysql_init(nullptr);
        if (!conn_) { error_ = "mysql_init failed"; return false; }

        // Timeout
        unsigned int timeout = 5;
        mysql_options(conn_, MYSQL_OPT_CONNECT_TIMEOUT, &timeout);

        if (!mysql_real_connect(conn_, p.host.c_str(),
                p.user.empty() ? nullptr : p.user.c_str(),
                p.pass.empty() ? nullptr : p.pass.c_str(),
                p.db.empty() ? nullptr : p.db.c_str(),
                p.port, nullptr, 0)) {
            error_ = mysql_error(conn_);
            mysql_close(conn_);
            conn_ = nullptr;
            return false;
        }
        return true;
    }

    void disconnect() override {
        if (conn_) { mysql_close(conn_); conn_ = nullptr; }
    }

    bool is_connected() const override { return conn_ != nullptr; }

    bool test_connection(int& ms) override {
        if (!conn_) { error_ = "Not connected"; return false; }
        auto t0 = chrono::steady_clock::now();
        int rc = mysql_ping(conn_);
        auto t1 = chrono::steady_clock::now();
        ms = (int)chrono::duration_cast<chrono::milliseconds>(t1 - t0).count();
        if (rc != 0) { error_ = mysql_error(conn_); return false; }
        return true;
    }

    unique_ptr<IResultStream> execute(const string& query) override {
        if (!conn_) { error_ = "Not connected"; return nullptr; }
        auto t0 = chrono::steady_clock::now();
        if (mysql_query(conn_, query.c_str()) != 0) {
            error_ = mysql_error(conn_);
            return nullptr;
        }
        auto t1 = chrono::steady_clock::now();

        MYSQL_RES* res = mysql_store_result(conn_);
        QueryMeta meta;
        meta.execution_time_ms = chrono::duration<double, milli>(t1 - t0).count();

        vector<ColumnInfo> cols;
        vector<Row> rows;

        if (res) {
            int ncols = mysql_num_fields(res);
            MYSQL_FIELD* fields = mysql_fetch_fields(res);
            for (int i = 0; i < ncols; ++i) {
                ColumnInfo ci;
                ci.name = fields[i].name;
                ci.type = fields[i].type == MYSQL_TYPE_LONG ? "int" :
                          fields[i].type == MYSQL_TYPE_VARCHAR ? "varchar" : "text";
                ci.nullable = !(fields[i].flags & NOT_NULL_FLAG);
                ci.primary_key = !!(fields[i].flags & PRI_KEY_FLAG);
                cols.push_back(ci);
            }
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res))) {
                Row r;
                for (int i = 0; i < ncols; ++i)
                    r.push_back({ cols[i].name, row[i] ? row[i] : "NULL" });
                rows.push_back(move(r));
            }
            meta.total_rows = (int64_t)rows.size();
            mysql_free_result(res);
        } else {
            meta.affected_rows = mysql_affected_rows(conn_);
        }

        return make_unique<MySQLResultStream>(move(cols), move(rows), meta);
    }

    vector<string> list_databases() override {
        vector<string> dbs;
        if (!conn_) return dbs;
        MYSQL_RES* res = mysql_list_dbs(conn_, nullptr);
        if (res) {
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res))) {
                if (row[0]) dbs.push_back(row[0]);
            }
            mysql_free_result(res);
        }
        return dbs;
    }

    vector<string> list_tables(const string& database) override {
        vector<string> tables;
        if (!conn_) return tables;
        if (!database.empty()) mysql_select_db(conn_, database.c_str());
        MYSQL_RES* res = mysql_list_tables(conn_, nullptr);
        if (res) {
            MYSQL_ROW row;
            while ((row = mysql_fetch_row(res))) {
                if (row[0]) tables.push_back(row[0]);
            }
            mysql_free_result(res);
        }
        return tables;
    }

    vector<ColumnInfo> get_table_schema(const string& table) override {
        vector<ColumnInfo> cols;
        if (!conn_) return cols;
        string sql = "DESCRIBE `" + table + "`";
        if (mysql_query(conn_, sql.c_str()) == 0) {
            MYSQL_RES* res = mysql_store_result(conn_);
            if (res) {
                MYSQL_ROW row;
                while ((row = mysql_fetch_row(res))) {
                    ColumnInfo ci;
                    ci.name = row[0] ? row[0] : "";
                    ci.type = row[1] ? row[1] : "";
                    ci.nullable = row[2] && string(row[2]) == "YES";
                    ci.primary_key = row[3] && string(row[3]) == "PRI";
                    ci.default_value = row[4] ? row[4] : "";
                    cols.push_back(ci);
                }
                mysql_free_result(res);
            }
        }
        return cols;
    }

    string last_error() const override { return error_; }
};

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::MySQLPlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
