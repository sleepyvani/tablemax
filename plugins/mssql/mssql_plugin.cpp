#include "plugin_interface.h"

using namespace std;

namespace tablemax {

class MSSQLPlugin : public IDbPlugin {
    bool connected_ = false;
    string cs_, error_;

public:
    string name() const override { return "SQL Server"; }
    string version() const override { return "0.2.0"; }
    string db_type() const override { return "mssql"; }

    bool connect(const string& cs) override { cs_ = cs; connected_ = true; return true; }
    void disconnect() override { connected_ = false; }
    bool is_connected() const override { return connected_; }
    bool test_connection(int& ms) override { ms = 0; return connected_; }

    unique_ptr<IResultStream> execute(const string&) override { error_ = "Not implemented"; return nullptr; }
    vector<string> list_databases() override { return {}; }
    vector<string> list_tables(const string&) override { return {}; }
    vector<ColumnInfo> get_table_schema(const string&) override { return {}; }
    string last_error() const override { return error_; }
};

}

extern "C" {
    tablemax::IDbPlugin* create_plugin() { return new tablemax::MSSQLPlugin(); }
    void destroy_plugin(tablemax::IDbPlugin* p) { delete p; }
}
