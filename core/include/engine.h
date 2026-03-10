#pragma once

#include "plugin_interface.h"
#include <unordered_map>
#include <mutex>

using namespace std;

namespace tablemax {

struct PluginEntry {
    string path, db_type;
    CreatePluginFn create_fn = nullptr;
    DestroyPluginFn destroy_fn = nullptr;
    void* lib_handle = nullptr;
};

struct ConnectionEntry {
    string db_type;
    IDbPlugin* plugin = nullptr;
    bool owned = true;
};

class Engine {
public:
    Engine() = default;
    ~Engine();

    // Plugin management
    int load_plugins(const string& dir);
    int plugin_count() const;
    string plugin_name(int index) const;
    bool has_plugin(const string& db_type) const;

    // Connection management
    int connect(const string& db_type, const string& conn_str);
    void disconnect(int conn_id);
    bool test_connection(const string& db_type, const string& conn_str, int& latency_ms);

    // Query execution
    unique_ptr<IResultStream> execute(int conn_id, const string& query);

    // Schema
    vector<string> list_databases(int conn_id);
    vector<string> list_tables(int conn_id, const string& database = "");
    vector<ColumnInfo> get_table_schema(int conn_id, const string& table);

    string last_error() const { return error_; }

private:
    IDbPlugin* find_connection(int conn_id);

    vector<PluginEntry> plugins_;
    unordered_map<int, ConnectionEntry> connections_;
    string error_;
    mutex mutex_;
    int next_id_ = 1;
};

}
