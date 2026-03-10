#include "engine.h"
#include <chrono>
#include <sstream>

using namespace std;
using namespace tablemax;

Engine::~Engine() {
    lock_guard<mutex> lock(mutex_);
    for (auto& [_, conn] : connections_) {
        if (conn.plugin && conn.owned) conn.plugin->disconnect();
    }
    connections_.clear();
    plugins_.clear();
}

int Engine::plugin_count() const { return (int)plugins_.size(); }

string Engine::plugin_name(int i) const {
    if (i < 0 || i >= (int)plugins_.size()) return "";
    return plugins_[i].db_type;
}

bool Engine::has_plugin(const string& db_type) const {
    for (auto& p : plugins_)
        if (p.db_type == db_type) return true;
    return false;
}

int Engine::connect(const string& db_type, const string& conn_str) {
    PluginEntry* found = nullptr;
    for (auto& p : plugins_)
        if (p.db_type == db_type) { found = &p; break; }

    if (!found || !found->create_fn) {
        error_ = "No plugin for: " + db_type;
        return -1;
    }

    auto* plugin = found->create_fn();
    if (!plugin) { error_ = "Failed to create plugin"; return -1; }

    if (!plugin->connect(conn_str)) {
        error_ = plugin->last_error();
        if (found->destroy_fn) found->destroy_fn(plugin);
        return -1;
    }

    lock_guard<mutex> lock(mutex_);
    int id = next_id_++;
    connections_[id] = { db_type, plugin, true };
    return id;
}

void Engine::disconnect(int conn_id) {
    lock_guard<mutex> lock(mutex_);
    auto it = connections_.find(conn_id);
    if (it == connections_.end()) return;
    if (it->second.plugin) it->second.plugin->disconnect();
    connections_.erase(it);
}

bool Engine::test_connection(const string& db_type, const string& conn_str, int& latency_ms) {
    PluginEntry* found = nullptr;
    for (auto& p : plugins_)
        if (p.db_type == db_type) { found = &p; break; }

    if (!found || !found->create_fn) {
        error_ = "No plugin for: " + db_type;
        return false;
    }

    auto* plugin = found->create_fn();
    if (!plugin) return false;

    if (!plugin->connect(conn_str)) {
        error_ = plugin->last_error();
        if (found->destroy_fn) found->destroy_fn(plugin);
        return false;
    }

    bool ok = plugin->test_connection(latency_ms);
    if (!ok) error_ = plugin->last_error();
    plugin->disconnect();
    if (found->destroy_fn) found->destroy_fn(plugin);
    return ok;
}

unique_ptr<IResultStream> Engine::execute(int conn_id, const string& query) {
    auto* plugin = find_connection(conn_id);
    if (!plugin) { error_ = "Connection not found"; return nullptr; }

    auto result = plugin->execute(query);
    if (!result) error_ = plugin->last_error();
    return result;
}

vector<string> Engine::list_databases(int conn_id) {
    auto* plugin = find_connection(conn_id);
    return plugin ? plugin->list_databases() : vector<string>{};
}

vector<string> Engine::list_tables(int conn_id, const string& database) {
    auto* plugin = find_connection(conn_id);
    return plugin ? plugin->list_tables(database) : vector<string>{};
}

vector<ColumnInfo> Engine::get_table_schema(int conn_id, const string& table) {
    auto* plugin = find_connection(conn_id);
    return plugin ? plugin->get_table_schema(table) : vector<ColumnInfo>{};
}

IDbPlugin* Engine::find_connection(int conn_id) {
    lock_guard<mutex> lock(mutex_);
    auto it = connections_.find(conn_id);
    if (it == connections_.end() || !it->second.plugin) return nullptr;
    return it->second.plugin;
}