#ifdef _WIN32
#define byte win_byte_override
#include <winsock2.h>
#undef byte
#endif

#include <libpq-fe.h>
#include "plugin_interface.h"
#include <chrono>
#include <sstream>

using namespace std;

namespace tablemax {

class PgResultStream : public IResultStream {
    vector<ColumnInfo> cols_;
    vector<Row> rows_;
    QueryMeta meta_;
    size_t pos_ = 0;
public:
    PgResultStream(vector<ColumnInfo> c, vector<Row> r, QueryMeta m)
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

class PostgresPlugin : public IDbPlugin {
    PGconn* conn_ = nullptr;
    string cs_, error_;

public:
    ~PostgresPlugin() override { disconnect(); }

    string name() const override { return "PostgreSQL"; }
    string version() const override { return "0.2.0"; }
    string db_type() const override { return "postgres"; }

    bool connect(const string& cs) override {
        disconnect();
        cs_ = cs;
        conn_ = PQconnectdb(cs.c_str());
        if (PQstatus(conn_) != CONNECTION_OK) {
            error_ = PQerrorMessage(conn_);
            PQfinish(conn_);
            conn_ = nullptr;
            return false;
        }
        return true;
    }

    void disconnect() override {
        if (conn_) { PQfinish(conn_); conn_ = nullptr; }
    }

    bool is_connected() const override { return conn_ && PQstatus(conn_) == CONNECTION_OK; }

    bool test_connection(int& ms) override {
        if (!conn_) { error_ = "Not connected"; return false; }
        auto t0 = chrono::steady_clock::now();
        PGresult* res = PQexec(conn_, "SELECT 1");
        auto t1 = chrono::steady_clock::now();
        ms = (int)chrono::duration_cast<chrono::milliseconds>(t1 - t0).count();
        bool ok = PQresultStatus(res) == PGRES_TUPLES_OK;
        if (!ok) error_ = PQerrorMessage(conn_);
        PQclear(res);
        return ok;
    }

    unique_ptr<IResultStream> execute(const string& query) override {
        if (!conn_) { error_ = "Not connected"; return nullptr; }
        auto t0 = chrono::steady_clock::now();
        PGresult* res = PQexec(conn_, query.c_str());
        auto t1 = chrono::steady_clock::now();

        ExecStatusType st = PQresultStatus(res);
        if (st != PGRES_TUPLES_OK && st != PGRES_COMMAND_OK) {
            error_ = PQerrorMessage(conn_);
            PQclear(res);
            return nullptr;
        }

        vector<ColumnInfo> cols;
        vector<Row> rows;
        QueryMeta meta;
        meta.execution_time_ms = chrono::duration<double, milli>(t1 - t0).count();

        if (st == PGRES_COMMAND_OK) {
            const char* ar = PQcmdTuples(res);
            meta.affected_rows = ar && ar[0] ? atoll(ar) : 0;
        } else {
            int ncols = PQnfields(res);
            for (int i = 0; i < ncols; ++i) {
                ColumnInfo ci;
                ci.name = PQfname(res, i);
                ci.type = "text"; // PG OID would need mapping
                cols.push_back(ci);
            }
            int nrows = PQntuples(res);
            for (int r = 0; r < nrows; ++r) {
                Row row;
                for (int c = 0; c < ncols; ++c)
                    row.push_back({ cols[c].name, PQgetisnull(res, r, c) ? "NULL" : PQgetvalue(res, r, c) });
                rows.push_back(move(row));
            }
            meta.total_rows = nrows;
        }

        PQclear(res);
        return make_unique<PgResultStream>(move(cols), move(rows), meta);
    }

    vector<string> list_databases() override {
        vector<string> dbs;
        if (!conn_) return dbs;
        PGresult* res = PQexec(conn_, "SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname");
        if (PQresultStatus(res) == PGRES_TUPLES_OK) {
            for (int i = 0; i < PQntuples(res); ++i)
                dbs.push_back(PQgetvalue(res, i, 0));
        }
        PQclear(res);
        return dbs;
    }

    vector<string> list_tables(const string& database) override {
        vector<string> tables;
        if (!conn_) return tables;
        PGresult* res = PQexec(conn_, "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename");
        if (PQresultStatus(res) == PGRES_TUPLES_OK) {
            for (int i = 0; i < PQntuples(res); ++i)
                tables.push_back(PQgetvalue(res, i, 0));
        }
        PQclear(res);
        return tables;
    }

    vector<ColumnInfo> get_table_schema(const string& table) override {
        vector<ColumnInfo> cols;
        if (!conn_) return cols;
        string sql = "SELECT column_name, data_type, is_nullable, column_default "
                     "FROM information_schema.columns WHERE table_name = '" + table + "' "
                     "AND table_schema = 'public' ORDER BY ordinal_position";
        PGresult* res = PQexec(conn_, sql.c_str());
        if (PQresultStatus(res) == PGRES_TUPLES_OK) {
            for (int i = 0; i < PQntuples(res); ++i) {
                ColumnInfo ci;
                ci.name = PQgetvalue(res, i, 0);
                ci.type = PQgetvalue(res, i, 1);
                ci.nullable = string(PQgetvalue(res, i, 2)) == "YES";
                ci.default_value = PQgetisnull(res, i, 3) ? "" : PQgetvalue(res, i, 3);
                cols.push_back(ci);
            }
        }
        PQclear(res);
        return cols;
    }

    string last_error() const override { return error_; }
};

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::PostgresPlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
