// Oracle Plugin for TableMax
// Uses ODBC API — requires Oracle ODBC driver installed
// SQL queries ported from TablePro's OraclePlugin.swift

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <sql.h>
#include <sqlext.h>

#include "plugin_interface.h"
#include <chrono>
#include <sstream>
#include <algorithm>

using namespace std;

namespace tablemax {

// ── Result Stream ───────────────────────────────────────────
class OracleResultStream : public IResultStream {
    vector<ColumnInfo> cols_;
    vector<Row> rows_;
    QueryMeta meta_;
    size_t pos_ = 0;
public:
    OracleResultStream(vector<ColumnInfo> c, vector<Row> r, QueryMeta m)
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

// ── ODBC error extraction ───────────────────────────────────
static string odbc_error(SQLSMALLINT htype, SQLHANDLE handle) {
    SQLCHAR state[6], msg[1024];
    SQLINTEGER native;
    SQLSMALLINT len;
    if (SQLGetDiagRec(htype, handle, 1, state, &native, msg, sizeof(msg), &len) == SQL_SUCCESS)
        return string((char*)msg, len);
    return "Unknown ODBC error";
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  OraclePlugin (via ODBC)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class OraclePlugin : public IDbPlugin {
    string error_;
    SQLHENV env_ = SQL_NULL_HENV;
    SQLHDBC dbc_ = SQL_NULL_HDBC;
    bool connected_ = false;
    string current_schema_;

    // Parse oracle://user:pass@host:port/service
    struct ConnParams { string host, user, pass, service, db; int port = 1521; };
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
            p.service = s.substr(slash + 1);
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
        if (p.port <= 0) p.port = 1521;
        if (p.service.empty()) p.service = "ORCL";
        return p;
    }

    // Execute a query via ODBC and extract results
    struct RawResult {
        vector<ColumnInfo> cols;
        vector<Row> rows;
        int64_t affected = 0;
        bool ok = false;
        string error;
    };

    RawResult raw_query(const string& sql) {
        RawResult r;
        if (!connected_) { r.error = "Not connected"; return r; }

        SQLHSTMT stmt = SQL_NULL_HSTMT;
        auto rc = SQLAllocHandle(SQL_HANDLE_STMT, dbc_, &stmt);
        if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
            r.error = odbc_error(SQL_HANDLE_DBC, dbc_);
            return r;
        }

        // Fix: Oracle needs "SELECT 1 FROM DUAL" instead of "SELECT 1"
        string effective = sql;
        {
            string lower = sql;
            for (auto& c : lower) c = (char)tolower(c);
            // trim
            size_t s = lower.find_first_not_of(" \t\n\r");
            if (s != string::npos) lower = lower.substr(s);
            if (lower == "select 1") effective = "SELECT 1 FROM DUAL";
        }

        rc = SQLExecDirect(stmt, (SQLCHAR*)effective.c_str(), SQL_NTS);
        if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
            r.error = odbc_error(SQL_HANDLE_STMT, stmt);
            SQLFreeHandle(SQL_HANDLE_STMT, stmt);
            return r;
        }

        // Get column info
        SQLSMALLINT col_count = 0;
        SQLNumResultCols(stmt, &col_count);

        for (SQLSMALLINT i = 1; i <= col_count; ++i) {
            SQLCHAR col_name[256];
            SQLSMALLINT name_len, data_type, nullable;
            SQLULEN col_size;
            SQLSMALLINT decimal_digits;
            SQLDescribeCol(stmt, i, col_name, sizeof(col_name), &name_len,
                          &data_type, &col_size, &decimal_digits, &nullable);
            ColumnInfo ci;
            ci.name = string((char*)col_name, name_len);
            // Map ODBC type to Oracle type name
            switch (data_type) {
                case SQL_VARCHAR:   ci.type = "VARCHAR2"; break;
                case SQL_CHAR:      ci.type = "CHAR"; break;
                case SQL_INTEGER:   ci.type = "NUMBER"; break;
                case SQL_SMALLINT:  ci.type = "NUMBER"; break;
                case SQL_BIGINT:    ci.type = "NUMBER"; break;
                case SQL_FLOAT:     ci.type = "FLOAT"; break;
                case SQL_DOUBLE:    ci.type = "BINARY_DOUBLE"; break;
                case SQL_REAL:      ci.type = "BINARY_FLOAT"; break;
                case SQL_DECIMAL:
                case SQL_NUMERIC:   ci.type = "NUMBER"; break;
                case SQL_TYPE_DATE: ci.type = "DATE"; break;
                case SQL_TYPE_TIMESTAMP: ci.type = "TIMESTAMP"; break;
                case SQL_LONGVARCHAR: ci.type = "CLOB"; break;
                case SQL_BINARY:
                case SQL_VARBINARY:
                case SQL_LONGVARBINARY: ci.type = "BLOB"; break;
                default:            ci.type = "VARCHAR2"; break;
            }
            ci.nullable = (nullable == SQL_NULLABLE);
            r.cols.push_back(ci);
        }

        // Fetch rows (cap at 10000)
        int row_count = 0;
        while (row_count < 10000) {
            rc = SQLFetch(stmt);
            if (rc == SQL_NO_DATA) break;
            if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) break;

            Row row;
            for (SQLSMALLINT i = 1; i <= col_count; ++i) {
                SQLCHAR buf[8192];
                SQLLEN indicator;
                rc = SQLGetData(stmt, i, SQL_C_CHAR, buf, sizeof(buf), &indicator);
                string val;
                if (indicator == SQL_NULL_DATA) {
                    val = "NULL";
                } else if (rc == SQL_SUCCESS || rc == SQL_SUCCESS_WITH_INFO) {
                    val = string((char*)buf);
                } else {
                    val = "NULL";
                }
                row.push_back({r.cols[i-1].name, val});
            }
            r.rows.push_back(move(row));
            ++row_count;
        }

        // Get rows affected for DML
        SQLLEN affected = 0;
        SQLRowCount(stmt, &affected);
        r.affected = affected;

        SQLFreeHandle(SQL_HANDLE_STMT, stmt);
        r.ok = true;
        return r;
    }

public:
    ~OraclePlugin() override { disconnect(); }

    string name() const override { return "Oracle"; }
    string version() const override { return "0.1.0"; }
    string db_type() const override { return "oracle"; }

    bool connect(const string& cs) override {
        disconnect();
        auto p = parse_url(cs);

        // Init ODBC
        SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env_);
        SQLSetEnvAttr(env_, SQL_ATTR_ODBC_VERSION, (void*)SQL_OV_ODBC3, 0);
        SQLAllocHandle(SQL_HANDLE_DBC, env_, &dbc_);

        // Build Oracle ODBC connection string
        // Format: DRIVER={Oracle in OraClient21Home1};DBQ=host:port/service;UID=user;PWD=pass
        string conn_str =
            "DRIVER={Oracle in OraClient21Home1};"
            "DBQ=" + p.host + ":" + to_string(p.port) + "/" + p.service + ";"
            "UID=" + p.user + ";"
            "PWD=" + p.pass + ";";

        SQLCHAR out[1024];
        SQLSMALLINT out_len;
        auto rc = SQLDriverConnect(dbc_, nullptr,
            (SQLCHAR*)conn_str.c_str(), SQL_NTS,
            out, sizeof(out), &out_len, SQL_DRIVER_NOPROMPT);

        if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
            // Try generic Oracle ODBC driver name
            conn_str =
                "DRIVER={Oracle ODBC Driver};"
                "DBQ=" + p.host + ":" + to_string(p.port) + "/" + p.service + ";"
                "UID=" + p.user + ";"
                "PWD=" + p.pass + ";";

            rc = SQLDriverConnect(dbc_, nullptr,
                (SQLCHAR*)conn_str.c_str(), SQL_NTS,
                out, sizeof(out), &out_len, SQL_DRIVER_NOPROMPT);
        }

        if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO) {
            error_ = odbc_error(SQL_HANDLE_DBC, dbc_);
            SQLFreeHandle(SQL_HANDLE_DBC, dbc_);
            SQLFreeHandle(SQL_HANDLE_ENV, env_);
            dbc_ = SQL_NULL_HDBC;
            env_ = SQL_NULL_HENV;
            return false;
        }

        connected_ = true;
        current_schema_ = p.user;

        // Get current schema (from TablePro)
        auto r = raw_query("SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') FROM DUAL");
        if (r.ok && !r.rows.empty() && !r.rows[0].empty() && r.rows[0][0].second != "NULL")
            current_schema_ = r.rows[0][0].second;

        return true;
    }

    void disconnect() override {
        if (dbc_ != SQL_NULL_HDBC) {
            SQLDisconnect(dbc_);
            SQLFreeHandle(SQL_HANDLE_DBC, dbc_);
            dbc_ = SQL_NULL_HDBC;
        }
        if (env_ != SQL_NULL_HENV) {
            SQLFreeHandle(SQL_HANDLE_ENV, env_);
            env_ = SQL_NULL_HENV;
        }
        connected_ = false;
    }

    bool is_connected() const override { return connected_; }

    bool test_connection(int& ms) override {
        auto t0 = chrono::steady_clock::now();
        auto r = raw_query("SELECT 1 FROM DUAL");
        auto t1 = chrono::steady_clock::now();
        ms = (int)chrono::duration_cast<chrono::milliseconds>(t1 - t0).count();
        if (!r.ok) error_ = r.error;
        return r.ok;
    }

    unique_ptr<IResultStream> execute(const string& query) override {
        if (!connected_) { error_ = "Not connected"; return nullptr; }
        auto t0 = chrono::steady_clock::now();
        auto r = raw_query(query);
        auto t1 = chrono::steady_clock::now();

        if (!r.ok) { error_ = r.error; return nullptr; }

        QueryMeta meta;
        meta.execution_time_ms = chrono::duration<double, milli>(t1 - t0).count();
        meta.total_rows = (int64_t)r.rows.size();
        meta.affected_rows = r.affected;

        return make_unique<OracleResultStream>(move(r.cols), move(r.rows), meta);
    }

    // From TablePro: ALL_USERS for databases
    vector<string> list_databases() override {
        vector<string> dbs;
        if (!connected_) return dbs;
        auto r = raw_query("SELECT USERNAME FROM ALL_USERS ORDER BY USERNAME");
        if (r.ok) {
            for (auto& row : r.rows) {
                if (!row.empty() && row[0].second != "NULL")
                    dbs.push_back(row[0].second);
            }
        }
        return dbs;
    }

    // From TablePro: all_tables UNION all_views
    vector<string> list_tables(const string& schema) override {
        vector<string> tables;
        if (!connected_) return tables;

        string escaped = schema.empty() ? current_schema_ : schema;
        for (size_t pos = 0; (pos = escaped.find('\'', pos)) != string::npos; pos += 2)
            escaped.replace(pos, 1, "''");

        auto r = raw_query(
            "SELECT table_name FROM all_tables WHERE owner = '" + escaped + "' "
            "UNION ALL "
            "SELECT view_name FROM all_views WHERE owner = '" + escaped + "' "
            "ORDER BY 1"
        );
        if (r.ok) {
            for (auto& row : r.rows) {
                if (!row.empty() && row[0].second != "NULL")
                    tables.push_back(row[0].second);
            }
        }
        return tables;
    }

    // From TablePro: ALL_TAB_COLUMNS with PK join
    vector<ColumnInfo> get_table_schema(const string& table) override {
        vector<ColumnInfo> cols;
        if (!connected_) return cols;

        string et = table, es = current_schema_;
        for (size_t p = 0; (p = et.find('\'', p)) != string::npos; p += 2) et.replace(p, 1, "''");
        for (size_t p = 0; (p = es.find('\'', p)) != string::npos; p += 2) es.replace(p, 1, "''");

        auto r = raw_query(
            "SELECT c.COLUMN_NAME, c.DATA_TYPE, c.NULLABLE, c.DATA_DEFAULT, "
            "CASE WHEN cc.COLUMN_NAME IS NOT NULL THEN 'Y' ELSE 'N' END AS IS_PK "
            "FROM ALL_TAB_COLUMNS c "
            "LEFT JOIN ("
            "  SELECT acc.COLUMN_NAME FROM ALL_CONS_COLUMNS acc "
            "  JOIN ALL_CONSTRAINTS ac ON acc.CONSTRAINT_NAME = ac.CONSTRAINT_NAME "
            "    AND acc.OWNER = ac.OWNER "
            "  WHERE ac.CONSTRAINT_TYPE = 'P' AND ac.OWNER = '" + es + "' "
            "    AND ac.TABLE_NAME = '" + et + "'"
            ") cc ON c.COLUMN_NAME = cc.COLUMN_NAME "
            "WHERE c.OWNER = '" + es + "' AND c.TABLE_NAME = '" + et + "' "
            "ORDER BY c.COLUMN_ID"
        );

        if (r.ok) {
            for (auto& row : r.rows) {
                if (row.size() < 2) continue;
                ColumnInfo ci;
                ci.name = row[0].second;
                ci.type = row[1].second;
                ci.nullable = (row.size() > 2 && row[2].second == "Y");
                if (row.size() > 3 && row[3].second != "NULL")
                    ci.default_value = row[3].second;
                ci.primary_key = (row.size() > 4 && row[4].second == "Y");
                cols.push_back(ci);
            }
        }
        return cols;
    }

    string last_error() const override { return error_; }
};

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::OraclePlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
