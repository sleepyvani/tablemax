#include "plugin_interface.h"

#ifdef _WIN32
    #ifndef NOMINMAX
    #define NOMINMAX
    #endif
    #define byte win_byte_override
    #include <windows.h>
    #undef byte
#endif

#include <mongoc/mongoc.h>
#include <bson/bson.h>
#include <chrono>
#include <sstream>

using namespace std;

namespace tablemax {

class MongoResultStream : public IResultStream {
    vector<ColumnInfo> cols_;
    vector<Row> rows_;
    QueryMeta meta_;
    size_t pos_ = 0;
public:
    MongoResultStream(vector<ColumnInfo> c, vector<Row> r, QueryMeta m)
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

class MongoPlugin : public IDbPlugin {
    mongoc_client_t* client_ = nullptr;
    string cs_, error_, db_name_;
    bool connected_ = false;

    static bool inited_;

    void extract_db_from_uri(const string& uri) {
        // Extract database from mongodb://host/dbname
        db_name_ = "admin";
        auto idx = uri.find("://");
        if (idx == string::npos) return;
        auto rest = uri.substr(idx + 3);
        // Skip user:pass@host:port
        auto slash = rest.find('/');
        if (slash != string::npos) {
            auto q = rest.find('?', slash);
            db_name_ = rest.substr(slash + 1, q != string::npos ? q - slash - 1 : string::npos);
        }
        if (db_name_.empty()) db_name_ = "admin";
    }

public:
    ~MongoPlugin() override { disconnect(); }

    string name() const override { return "MongoDB"; }
    string version() const override { return "0.2.0"; }
    string db_type() const override { return "mongodb"; }

    bool connect(const string& cs) override {
        disconnect();
        cs_ = cs;

        if (!inited_) { mongoc_init(); inited_ = true; }

        extract_db_from_uri(cs);
        client_ = mongoc_client_new(cs.c_str());
        if (!client_) {
            error_ = "Failed to create MongoDB client";
            return false;
        }

        // Set timeout
        mongoc_client_set_appname(client_, "TableMax");

        // Ping to verify connection
        bson_t cmd = BSON_INITIALIZER;
        BSON_APPEND_INT32(&cmd, "ping", 1);
        bson_t reply;
        bson_error_t err;
        bool ok = mongoc_client_command_simple(client_, "admin", &cmd, nullptr, &reply, &err);
        bson_destroy(&cmd);
        bson_destroy(&reply);

        if (!ok) {
            error_ = err.message;
            mongoc_client_destroy(client_);
            client_ = nullptr;
            return false;
        }

        connected_ = true;
        return true;
    }

    void disconnect() override {
        if (client_) { mongoc_client_destroy(client_); client_ = nullptr; }
        connected_ = false;
    }

    bool is_connected() const override { return connected_ && client_ != nullptr; }

    bool test_connection(int& ms) override {
        if (!client_) { error_ = "Not connected"; return false; }
        bson_t cmd = BSON_INITIALIZER;
        BSON_APPEND_INT32(&cmd, "ping", 1);
        bson_t reply;
        bson_error_t err;
        auto t0 = chrono::steady_clock::now();
        bool ok = mongoc_client_command_simple(client_, "admin", &cmd, nullptr, &reply, &err);
        auto t1 = chrono::steady_clock::now();
        ms = (int)chrono::duration_cast<chrono::milliseconds>(t1 - t0).count();
        bson_destroy(&cmd);
        bson_destroy(&reply);
        if (!ok) error_ = err.message;
        return ok;
    }

    unique_ptr<IResultStream> execute(const string& query) override {
        if (!client_) { error_ = "Not connected"; return nullptr; }

        auto t0 = chrono::steady_clock::now();

        // Try to parse as JSON command and run against the database
        bson_error_t err;
        bson_t* cmd = bson_new_from_json((const uint8_t*)query.c_str(), query.size(), &err);
        if (!cmd) {
            error_ = string("Invalid JSON: ") + err.message;
            return nullptr;
        }

        mongoc_database_t* db = mongoc_client_get_database(client_, db_name_.c_str());
        bson_t reply;
        bool ok = mongoc_database_command_simple(db, cmd, nullptr, &reply, &err);
        mongoc_database_destroy(db);
        bson_destroy(cmd);

        if (!ok) {
            error_ = err.message;
            bson_destroy(&reply);
            return nullptr;
        }

        auto t1 = chrono::steady_clock::now();

        // Convert reply to rows
        char* json = bson_as_relaxed_extended_json(&reply, nullptr);
        bson_destroy(&reply);

        vector<ColumnInfo> cols = {{ "result", "json", true, false, "" }};
        vector<Row> rows;
        rows.push_back({{"result", json ? json : "{}"}});
        if (json) bson_free(json);

        QueryMeta meta;
        meta.total_rows = 1;
        meta.execution_time_ms = chrono::duration<double, milli>(t1 - t0).count();
        return make_unique<MongoResultStream>(move(cols), move(rows), meta);
    }

    vector<string> list_databases() override {
        vector<string> dbs;
        if (!client_) return dbs;
        bson_error_t err;
        char** names = mongoc_client_get_database_names_with_opts(client_, nullptr, &err);
        if (names) {
            for (int i = 0; names[i]; ++i) dbs.push_back(names[i]);
            bson_strfreev(names);
        }
        return dbs;
    }

    vector<string> list_tables(const string& database) override {
        vector<string> colls;
        if (!client_) return colls;
        string db = database.empty() ? db_name_ : database;
        mongoc_database_t* mdb = mongoc_client_get_database(client_, db.c_str());
        bson_error_t err;
        char** names = mongoc_database_get_collection_names_with_opts(mdb, nullptr, &err);
        if (names) {
            for (int i = 0; names[i]; ++i) colls.push_back(names[i]);
            bson_strfreev(names);
        }
        mongoc_database_destroy(mdb);
        return colls;
    }

    vector<ColumnInfo> get_table_schema(const string& table) override {
        // MongoDB is schema-less — sample first document
        vector<ColumnInfo> cols;
        if (!client_) return cols;
        mongoc_collection_t* coll = mongoc_client_get_collection(client_, db_name_.c_str(), table.c_str());
        bson_t q = BSON_INITIALIZER;
        mongoc_cursor_t* cursor = mongoc_collection_find_with_opts(coll, &q, nullptr, nullptr);
        bson_destroy(&q);

        const bson_t* doc;
        if (mongoc_cursor_next(cursor, &doc)) {
            bson_iter_t iter;
            if (bson_iter_init(&iter, doc)) {
                while (bson_iter_next(&iter)) {
                    ColumnInfo ci;
                    ci.name = bson_iter_key(&iter);
                    switch (bson_iter_type(&iter)) {
                        case BSON_TYPE_UTF8: ci.type = "string"; break;
                        case BSON_TYPE_INT32: ci.type = "int32"; break;
                        case BSON_TYPE_INT64: ci.type = "int64"; break;
                        case BSON_TYPE_DOUBLE: ci.type = "double"; break;
                        case BSON_TYPE_BOOL: ci.type = "bool"; break;
                        case BSON_TYPE_DOCUMENT: ci.type = "object"; break;
                        case BSON_TYPE_ARRAY: ci.type = "array"; break;
                        case BSON_TYPE_OID: ci.type = "ObjectId"; break;
                        case BSON_TYPE_DATE_TIME: ci.type = "date"; break;
                        default: ci.type = "unknown"; break;
                    }
                    cols.push_back(ci);
                }
            }
        }
        mongoc_cursor_destroy(cursor);
        mongoc_collection_destroy(coll);
        return cols;
    }

    string last_error() const override { return error_; }
};

bool MongoPlugin::inited_ = false;

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::MongoPlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
