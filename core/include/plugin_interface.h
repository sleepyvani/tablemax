#pragma once

#include <string>
#include <vector>
#include <memory>
#include <functional>

using namespace std;

namespace tablemax {

struct ColumnInfo {
    string name;
    string type;
    bool nullable = true;
    bool primary_key = false;
    string default_value;
};

using Row = vector<pair<string, string>>;

struct QueryMeta {
    int64_t affected_rows = 0;
    int64_t total_rows = -1;
    double execution_time_ms = 0.0;
    string error;
};

class IResultStream {
public:
    virtual ~IResultStream() = default;
    virtual vector<ColumnInfo> columns() const = 0;
    virtual QueryMeta meta() const = 0;
    virtual vector<Row> next_chunk(int chunk_size = 500) = 0;
    virtual bool has_more() const = 0;
    virtual void close() = 0;
};

class IDbPlugin {
public:
    virtual ~IDbPlugin() = default;

    virtual string name() const = 0;
    virtual string version() const = 0;
    virtual string db_type() const = 0;

    virtual bool connect(const string& connection_string) = 0;
    virtual void disconnect() = 0;
    virtual bool is_connected() const = 0;
    virtual bool test_connection(int& latency_ms) = 0;

    virtual unique_ptr<IResultStream> execute(const string& query) = 0;
    virtual vector<string> list_databases() = 0;
    virtual vector<string> list_tables(const string& database = "") = 0;
    virtual vector<ColumnInfo> get_table_schema(const string& table) = 0;

    virtual string last_error() const = 0;
};

using CreatePluginFn = IDbPlugin* (*)();
using DestroyPluginFn = void (*)(IDbPlugin*);

}
