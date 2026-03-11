#include "plugin_interface.h"

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <sql.h>
#include <sqlext.h>
#else
// ODBC on Linux/Mac needs unixODBC
#include <sql.h>
#include <sqlext.h>
#endif

#include <chrono>
#include <sstream>

using namespace std;

namespace tablemax {

class MSSQLResultStream : public IResultStream {
    vector<ColumnInfo> cols_;
    vector<Row> rows_;
    QueryMeta meta_;
    size_t pos_ = 0;
public:
    MSSQLResultStream(vector<ColumnInfo> c, vector<Row> r, QueryMeta m)
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

class MSSQLPlugin : public IDbPlugin {
    SQLHENV env_ = SQL_NULL_HENV;
    SQLHDBC dbc_ = SQL_NULL_HDBC;
    string cs_, error_;

    string get_diag(SQLSMALLINT type, SQLHANDLE handle) {
        SQLCHAR state[8], msg[1024];
        SQLINTEGER native;
        SQLSMALLINT len;
        if (SQLGetDiagRecA(type, handle, 1, state, &native, msg, sizeof(msg), &len) == SQL_SUCCESS)
            return string((char*)msg, len);
        return "Unknown ODBC error";
    }

    // Build ODBC conn string from Server=host,port;Database=db;User=u;Password=p
    string build_odbc_string(const string& cs) {
        // If already contains "Driver=", use as-is
        if (cs.find("Driver=") != string::npos || cs.find("DRIVER=") != string::npos)
            return cs;
        // Otherwise prepend ODBC driver
        return "Driver={ODBC Driver 17 for SQL Server};" + cs;
    }

public:
    ~MSSQLPlugin() override { disconnect(); }

    string name() const override { return "SQL Server"; }
    string version() const override { return "0.2.0"; }
    string db_type() const override { return "mssql"; }

    bool connect(const string& cs) override {
        disconnect();
        cs_ = cs;

        if (SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env_) != SQL_SUCCESS) {
            error_ = "Failed to allocate ODBC environment";
            return false;
        }
        SQLSetEnvAttr(env_, SQL_ATTR_ODBC_VERSION, (void*)SQL_OV_ODBC3, 0);

        if (SQLAllocHandle(SQL_HANDLE_DBC, env_, &dbc_) != SQL_SUCCESS) {
            error_ = "Failed to allocate ODBC connection";
            SQLFreeHandle(SQL_HANDLE_ENV, env_); env_ = SQL_NULL_HENV;
            return false;
        }

        // Set timeout
        SQLSetConnectAttrA(dbc_, SQL_LOGIN_TIMEOUT, (SQLPOINTER)5, 0);

        string odbc_cs = build_odbc_string(cs);
        SQLCHAR out[1024];
        SQLSMALLINT outLen;
        SQLRETURN ret = SQLDriverConnectA(dbc_, nullptr,
            (SQLCHAR*)odbc_cs.c_str(), (SQLSMALLINT)odbc_cs.size(),
            out, sizeof(out), &outLen, SQL_DRIVER_NOPROMPT);

        if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
            error_ = get_diag(SQL_HANDLE_DBC, dbc_);
            SQLFreeHandle(SQL_HANDLE_DBC, dbc_); dbc_ = SQL_NULL_HDBC;
            SQLFreeHandle(SQL_HANDLE_ENV, env_); env_ = SQL_NULL_HENV;
            return false;
        }
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
    }

    bool is_connected() const override { return dbc_ != SQL_NULL_HDBC; }

    bool test_connection(int& ms) override {
        if (dbc_ == SQL_NULL_HDBC) { error_ = "Not connected"; return false; }
        SQLHSTMT stmt;
        SQLAllocHandle(SQL_HANDLE_STMT, dbc_, &stmt);
        auto t0 = chrono::steady_clock::now();
        SQLRETURN ret = SQLExecDirectA(stmt, (SQLCHAR*)"SELECT 1", SQL_NTS);
        auto t1 = chrono::steady_clock::now();
        ms = (int)chrono::duration_cast<chrono::milliseconds>(t1 - t0).count();
        bool ok = (ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO);
        if (!ok) error_ = get_diag(SQL_HANDLE_STMT, stmt);
        SQLFreeHandle(SQL_HANDLE_STMT, stmt);
        return ok;
    }

    unique_ptr<IResultStream> execute(const string& query) override {
        if (dbc_ == SQL_NULL_HDBC) { error_ = "Not connected"; return nullptr; }
        SQLHSTMT stmt;
        SQLAllocHandle(SQL_HANDLE_STMT, dbc_, &stmt);

        auto t0 = chrono::steady_clock::now();
        SQLRETURN ret = SQLExecDirectA(stmt, (SQLCHAR*)query.c_str(), SQL_NTS);
        auto t1 = chrono::steady_clock::now();

        if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) {
            error_ = get_diag(SQL_HANDLE_STMT, stmt);
            SQLFreeHandle(SQL_HANDLE_STMT, stmt);
            return nullptr;
        }

        // Columns
        SQLSMALLINT ncols;
        SQLNumResultCols(stmt, &ncols);
        vector<ColumnInfo> cols;
        for (SQLSMALLINT i = 1; i <= ncols; ++i) {
            SQLCHAR cname[256];
            SQLSMALLINT nameLen, dataType, nullable;
            SQLULEN colSize;
            SQLSMALLINT decDigits;
            SQLDescribeColA(stmt, i, cname, sizeof(cname), &nameLen, &dataType, &colSize, &decDigits, &nullable);
            ColumnInfo ci;
            ci.name = string((char*)cname, nameLen);
            ci.type = "text";
            ci.nullable = nullable == SQL_NULLABLE;
            cols.push_back(ci);
        }

        // Rows
        vector<Row> rows;
        char buf[4096];
        SQLLEN ind;
        while (SQLFetch(stmt) == SQL_SUCCESS) {
            Row row;
            for (SQLSMALLINT i = 1; i <= ncols; ++i) {
                ret = SQLGetData(stmt, i, SQL_C_CHAR, buf, sizeof(buf), &ind);
                string val = (ind == SQL_NULL_DATA) ? "NULL" : string(buf);
                row.push_back({ cols[i-1].name, val });
            }
            rows.push_back(move(row));
        }

        SQLFreeHandle(SQL_HANDLE_STMT, stmt);

        QueryMeta meta;
        meta.total_rows = (int64_t)rows.size();
        meta.execution_time_ms = chrono::duration<double, milli>(t1 - t0).count();
        return make_unique<MSSQLResultStream>(move(cols), move(rows), meta);
    }

    vector<string> list_databases() override {
        vector<string> dbs;
        auto res = execute("SELECT name FROM sys.databases ORDER BY name");
        if (res) {
            auto chunk = res->next_chunk(1000);
            for (auto& row : chunk)
                if (!row.empty()) dbs.push_back(row[0].second);
        }
        return dbs;
    }

    vector<string> list_tables(const string& database) override {
        vector<string> tables;
        string sql = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME";
        auto res = execute(sql);
        if (res) {
            auto chunk = res->next_chunk(1000);
            for (auto& row : chunk)
                if (!row.empty()) tables.push_back(row[0].second);
        }
        return tables;
    }

    vector<ColumnInfo> get_table_schema(const string& table) override {
        vector<ColumnInfo> cols;
        string sql = "SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT "
                     "FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '" + table + "' "
                     "ORDER BY ORDINAL_POSITION";
        auto res = execute(sql);
        if (res) {
            auto chunk = res->next_chunk(1000);
            for (auto& row : chunk) {
                ColumnInfo ci;
                ci.name = row.size() > 0 ? row[0].second : "";
                ci.type = row.size() > 1 ? row[1].second : "";
                ci.nullable = row.size() > 2 && row[2].second == "YES";
                ci.default_value = row.size() > 3 ? row[3].second : "";
                cols.push_back(ci);
            }
        }
        return cols;
    }

    string last_error() const override { return error_; }
};

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::MSSQLPlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
