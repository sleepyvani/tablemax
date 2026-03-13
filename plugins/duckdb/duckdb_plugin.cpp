// DuckDB Plugin for TableMax
// Uses DuckDB C API (duckdb.h) — embedded/file-based database
// SQL queries ported from TablePro's DuckDBPlugin.swift

#include "plugin_interface.h"
#include "duckdb.h"
#include <chrono>
#include <sstream>

using namespace std;

namespace tablemax {

// ── Result Stream ───────────────────────────────────────────
class DuckDBResultStream : public IResultStream {
    vector<ColumnInfo> cols_;
    vector<Row> rows_;
    QueryMeta meta_;
    size_t pos_ = 0;
public:
    DuckDBResultStream(vector<ColumnInfo> c, vector<Row> r, QueryMeta m)
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

// ── Type name from duckdb_type ──────────────────────────────
static string type_name(duckdb_type t) {
    switch (t) {
        case DUCKDB_TYPE_BOOLEAN:      return "BOOLEAN";
        case DUCKDB_TYPE_TINYINT:      return "TINYINT";
        case DUCKDB_TYPE_SMALLINT:     return "SMALLINT";
        case DUCKDB_TYPE_INTEGER:      return "INTEGER";
        case DUCKDB_TYPE_BIGINT:       return "BIGINT";
        case DUCKDB_TYPE_UTINYINT:     return "UTINYINT";
        case DUCKDB_TYPE_USMALLINT:    return "USMALLINT";
        case DUCKDB_TYPE_UINTEGER:     return "UINTEGER";
        case DUCKDB_TYPE_UBIGINT:      return "UBIGINT";
        case DUCKDB_TYPE_FLOAT:        return "FLOAT";
        case DUCKDB_TYPE_DOUBLE:       return "DOUBLE";
        case DUCKDB_TYPE_TIMESTAMP:    return "TIMESTAMP";
        case DUCKDB_TYPE_DATE:         return "DATE";
        case DUCKDB_TYPE_TIME:         return "TIME";
        case DUCKDB_TYPE_INTERVAL:     return "INTERVAL";
        case DUCKDB_TYPE_HUGEINT:      return "HUGEINT";
        case DUCKDB_TYPE_VARCHAR:      return "VARCHAR";
        case DUCKDB_TYPE_BLOB:         return "BLOB";
        case DUCKDB_TYPE_DECIMAL:      return "DECIMAL";
        case DUCKDB_TYPE_TIMESTAMP_S:  return "TIMESTAMP_S";
        case DUCKDB_TYPE_TIMESTAMP_MS: return "TIMESTAMP_MS";
        case DUCKDB_TYPE_TIMESTAMP_NS: return "TIMESTAMP_NS";
        case DUCKDB_TYPE_ENUM:         return "ENUM";
        case DUCKDB_TYPE_LIST:         return "LIST";
        case DUCKDB_TYPE_STRUCT:       return "STRUCT";
        case DUCKDB_TYPE_MAP:          return "MAP";
        case DUCKDB_TYPE_UUID:         return "UUID";
        case DUCKDB_TYPE_UNION:        return "UNION";
        case DUCKDB_TYPE_BIT:          return "BIT";
        default:                       return "VARCHAR";
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  DuckDBPlugin
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class DuckDBPlugin : public IDbPlugin {
    string error_;
    duckdb_database db_ = nullptr;
    duckdb_connection conn_ = nullptr;
    string db_path_;
    bool connected_ = false;

    // Execute raw query and extract result
    struct RawResult {
        vector<ColumnInfo> cols;
        vector<Row> rows;
        idx_t rows_changed = 0;
        bool ok = false;
        string error;
    };

    RawResult raw_query(const string& sql) {
        RawResult r;
        if (!conn_) { r.error = "Not connected"; return r; }

        duckdb_result result;
        auto state = duckdb_query(conn_, sql.c_str(), &result);
        if (state == DuckDBError) {
            auto err = duckdb_result_error(&result);
            r.error = err ? string(err) : "Unknown DuckDB error";
            duckdb_destroy_result(&result);
            return r;
        }

        auto col_count = duckdb_column_count(&result);
        auto row_count = duckdb_row_count(&result);
        r.rows_changed = duckdb_rows_changed(&result);

        // Columns
        for (idx_t i = 0; i < col_count; ++i) {
            ColumnInfo ci;
            auto name_ptr = duckdb_column_name(&result, i);
            ci.name = name_ptr ? string(name_ptr) : ("column_" + to_string(i));
            ci.type = type_name(duckdb_column_type(&result, i));
            ci.nullable = true; // DuckDB doesn't expose this in result
            r.cols.push_back(ci);
        }

        // Rows (cap at 10000)
        idx_t max_rows = row_count < 10000 ? row_count : 10000;
        for (idx_t row = 0; row < max_rows; ++row) {
            Row rr;
            for (idx_t col = 0; col < col_count; ++col) {
                string val;
                if (duckdb_value_is_null(&result, col, row)) {
                    val = "NULL";
                } else {
                    auto v = duckdb_value_varchar(&result, col, row);
                    if (v) {
                        val = string(v);
                        duckdb_free(v);
                    } else {
                        val = "NULL";
                    }
                }
                rr.push_back({r.cols[col].name, val});
            }
            r.rows.push_back(move(rr));
        }

        duckdb_destroy_result(&result);
        r.ok = true;
        return r;
    }

public:
    ~DuckDBPlugin() override { disconnect(); }

    string name() const override { return "DuckDB"; }
    string version() const override { return "0.1.0"; }
    string db_type() const override { return "duckdb"; }

    bool connect(const string& path) override {
        disconnect();
        db_path_ = path;

        char* err_msg = nullptr;
        auto state = duckdb_open_ext(path.c_str(), &db_, nullptr, &err_msg);
        if (state == DuckDBError) {
            error_ = err_msg ? string(err_msg) : "Failed to open database";
            if (err_msg) duckdb_free(err_msg);
            return false;
        }

        state = duckdb_connect(db_, &conn_);
        if (state == DuckDBError) {
            error_ = "Failed to create connection";
            duckdb_close(&db_);
            db_ = nullptr;
            return false;
        }

        // Enable auto-install and auto-load extensions (like TablePro)
        duckdb_result r;
        duckdb_query(conn_, "SET autoinstall_known_extensions=1", &r);
        duckdb_destroy_result(&r);
        duckdb_query(conn_, "SET autoload_known_extensions=1", &r);
        duckdb_destroy_result(&r);

        connected_ = true;
        return true;
    }

    void disconnect() override {
        if (conn_) { duckdb_disconnect(&conn_); conn_ = nullptr; }
        if (db_) { duckdb_close(&db_); db_ = nullptr; }
        connected_ = false;
    }

    bool is_connected() const override { return connected_; }

    bool test_connection(int& ms) override {
        auto t0 = chrono::steady_clock::now();
        auto r = raw_query("SELECT 1");
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

        if (!r.ok) {
            error_ = r.error;
            return nullptr;
        }

        QueryMeta meta;
        meta.execution_time_ms = chrono::duration<double, milli>(t1 - t0).count();
        meta.total_rows = (int64_t)r.rows.size();
        meta.affected_rows = (int64_t)r.rows_changed;

        return make_unique<DuckDBResultStream>(move(r.cols), move(r.rows), meta);
    }

    vector<string> list_databases() override {
        // DuckDB is single-database; return current database name
        vector<string> dbs;
        if (!connected_) return dbs;
        auto r = raw_query("SELECT current_database()");
        if (r.ok && !r.rows.empty() && !r.rows[0].empty())
            dbs.push_back(r.rows[0][0].second);
        else
            dbs.push_back("main");
        return dbs;
    }

    vector<string> list_tables(const string& /*database*/) override {
        // From TablePro: information_schema.tables WHERE table_schema
        vector<string> tables;
        if (!connected_) return tables;
        auto r = raw_query(
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema = 'main' "
            "ORDER BY table_name"
        );
        if (r.ok) {
            for (auto& row : r.rows) {
                if (!row.empty() && row[0].second != "NULL")
                    tables.push_back(row[0].second);
            }
        }
        return tables;
    }

    vector<ColumnInfo> get_table_schema(const string& table) override {
        vector<ColumnInfo> cols;
        if (!connected_) return cols;

        string escaped = table;
        for (size_t pos = 0; (pos = escaped.find('\'', pos)) != string::npos; pos += 2)
            escaped.replace(pos, 1, "''");

        // From TablePro: information_schema.columns
        auto r = raw_query(
            "SELECT column_name, data_type, is_nullable, column_default "
            "FROM information_schema.columns "
            "WHERE table_schema = 'main' AND table_name = '" + escaped + "' "
            "ORDER BY ordinal_position"
        );

        // Get primary key columns (from TablePro)
        auto pk = raw_query(
            "SELECT kcu.column_name "
            "FROM information_schema.table_constraints tc "
            "JOIN information_schema.key_column_usage kcu "
            "  ON tc.constraint_name = kcu.constraint_name "
            "  AND tc.table_schema = kcu.table_schema "
            "WHERE tc.constraint_type = 'PRIMARY KEY' "
            "  AND tc.table_schema = 'main' "
            "  AND tc.table_name = '" + escaped + "'"
        );
        vector<string> pk_cols;
        if (pk.ok) {
            for (auto& row : pk.rows) {
                if (!row.empty() && row[0].second != "NULL")
                    pk_cols.push_back(row[0].second);
            }
        }

        if (r.ok) {
            for (auto& row : r.rows) {
                if (row.size() < 2) continue;
                ColumnInfo ci;
                ci.name = row[0].second;
                ci.type = row[1].second;
                ci.nullable = (row.size() > 2 && row[2].second == "YES");
                if (row.size() > 3 && row[3].second != "NULL")
                    ci.default_value = row[3].second;
                // Check if primary key
                for (auto& pk_col : pk_cols) {
                    if (pk_col == ci.name) { ci.primary_key = true; break; }
                }
                cols.push_back(ci);
            }
        }
        return cols;
    }

    string last_error() const override { return error_; }
};

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::DuckDBPlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
