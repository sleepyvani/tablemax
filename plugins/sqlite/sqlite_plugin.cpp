#include "plugin_interface.h"
#include "sqlite3.h"
#include <chrono>
#include <sstream>

using namespace std;

namespace tablemax {

// ─── Result Stream ───
class SQLiteResultStream : public IResultStream {
    vector<ColumnInfo> cols_;
    vector<Row> rows_;
    QueryMeta meta_;
    size_t pos_ = 0;
public:
    SQLiteResultStream(vector<ColumnInfo> cols, vector<Row> rows, QueryMeta meta)
        : cols_(move(cols)), rows_(move(rows)), meta_(move(meta)) {}

    vector<ColumnInfo> columns() const override { return cols_; }
    QueryMeta meta() const override { return meta_; }
    bool has_more() const override { return pos_ < rows_.size(); }
    void close() override { pos_ = rows_.size(); }

    vector<Row> next_chunk(int chunk_size) override {
        vector<Row> chunk;
        for (int i = 0; i < chunk_size && pos_ < rows_.size(); ++i, ++pos_)
            chunk.push_back(rows_[pos_]);
        return chunk;
    }
};

// ─── Plugin ───
class SQLitePlugin : public IDbPlugin {
    sqlite3* db_ = nullptr;
    bool connected_ = false;
    string cs_, error_;

public:
    ~SQLitePlugin() override { if (db_) sqlite3_close(db_); }

    string name() const override { return "SQLite"; }
    string version() const override { return "0.2.0"; }
    string db_type() const override { return "sqlite"; }

    bool connect(const string& cs) override {
        cs_ = cs;
        if (db_) { sqlite3_close(db_); db_ = nullptr; }

        int rc = sqlite3_open(cs.c_str(), &db_);
        if (rc != SQLITE_OK) {
            error_ = db_ ? sqlite3_errmsg(db_) : "Failed to open database";
            if (db_) { sqlite3_close(db_); db_ = nullptr; }
            connected_ = false;
            return false;
        }
        connected_ = true;
        return true;
    }

    void disconnect() override {
        if (db_) { sqlite3_close(db_); db_ = nullptr; }
        connected_ = false;
    }

    bool is_connected() const override { return connected_ && db_ != nullptr; }

    bool test_connection(int& ms) override {
        if (!db_) { error_ = "Not connected"; return false; }
        auto t0 = chrono::steady_clock::now();
        char* err = nullptr;
        int rc = sqlite3_exec(db_, "SELECT 1", nullptr, nullptr, &err);
        auto t1 = chrono::steady_clock::now();
        ms = (int)chrono::duration_cast<chrono::milliseconds>(t1 - t0).count();
        if (rc != SQLITE_OK) {
            error_ = err ? err : "Test query failed";
            if (err) sqlite3_free(err);
            return false;
        }
        return true;
    }

    unique_ptr<IResultStream> execute(const string& query) override {
        if (!db_) { error_ = "Not connected"; return nullptr; }

        auto t0 = chrono::steady_clock::now();
        sqlite3_stmt* stmt = nullptr;
        int rc = sqlite3_prepare_v2(db_, query.c_str(), -1, &stmt, nullptr);
        if (rc != SQLITE_OK) {
            error_ = sqlite3_errmsg(db_);
            return nullptr;
        }

        // Columns
        int ncols = sqlite3_column_count(stmt);
        vector<ColumnInfo> cols;
        for (int i = 0; i < ncols; ++i) {
            ColumnInfo ci;
            ci.name = sqlite3_column_name(stmt, i);
            const char* t = sqlite3_column_decltype(stmt, i);
            ci.type = t ? t : "TEXT";
            cols.push_back(ci);
        }

        // Rows
        vector<Row> rows;
        int64_t affected = 0;
        while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
            Row row;
            for (int i = 0; i < ncols; ++i) {
                const unsigned char* v = sqlite3_column_text(stmt, i);
                row.push_back({ cols[i].name, v ? (const char*)v : "NULL" });
            }
            rows.push_back(move(row));
        }

        if (rc != SQLITE_DONE && rc != SQLITE_ROW) {
            error_ = sqlite3_errmsg(db_);
            sqlite3_finalize(stmt);
            return nullptr;
        }

        affected = sqlite3_changes(db_);
        sqlite3_finalize(stmt);

        auto t1 = chrono::steady_clock::now();
        QueryMeta meta;
        meta.affected_rows = affected;
        meta.total_rows = (int64_t)rows.size();
        meta.execution_time_ms = chrono::duration<double, milli>(t1 - t0).count();

        return make_unique<SQLiteResultStream>(move(cols), move(rows), meta);
    }

    vector<string> list_databases() override { return { cs_ }; }

    vector<string> list_tables(const string&) override {
        vector<string> tables;
        if (!db_) return tables;
        sqlite3_stmt* stmt = nullptr;
        if (sqlite3_prepare_v2(db_, "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name", -1, &stmt, nullptr) == SQLITE_OK) {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                const unsigned char* n = sqlite3_column_text(stmt, 0);
                if (n) tables.push_back((const char*)n);
            }
            sqlite3_finalize(stmt);
        }
        return tables;
    }

    vector<ColumnInfo> get_table_schema(const string& table) override {
        vector<ColumnInfo> cols;
        if (!db_) return cols;
        string sql = "PRAGMA table_info('" + table + "')";
        sqlite3_stmt* stmt = nullptr;
        if (sqlite3_prepare_v2(db_, sql.c_str(), -1, &stmt, nullptr) == SQLITE_OK) {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                ColumnInfo ci;
                const unsigned char* n = sqlite3_column_text(stmt, 1);
                const unsigned char* t = sqlite3_column_text(stmt, 2);
                ci.name = n ? (const char*)n : "";
                ci.type = t ? (const char*)t : "";
                ci.nullable = sqlite3_column_int(stmt, 3) == 0;
                ci.primary_key = sqlite3_column_int(stmt, 5) != 0;
                const unsigned char* d = sqlite3_column_text(stmt, 4);
                ci.default_value = d ? (const char*)d : "";
                cols.push_back(ci);
            }
            sqlite3_finalize(stmt);
        }
        return cols;
    }

    string last_error() const override { return error_; }
};

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::SQLitePlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
