#include "../include/engine.h"
#include <iostream>
#include <string>

using namespace std;
using namespace tablemax;

int main() {
    cout << "=== TableMax Core Engine Test ===" << endl;

    Engine engine;
    cout << "[OK] Engine created" << endl;

    int count = engine.load_plugins("./plugins");
    cout << "[OK] Loaded " << count << " plugins" << endl;

    string dbType = "postgres";
    string connStr = "host=localhost";
    int ms = 0;
    bool ok = engine.test_connection(dbType, connStr, ms);
    cout << "[" << (ok ? "OK" : "FAIL") << "] Test connection: " << engine.last_error() << endl;

    cout << "=== Done ===" << endl;
    return 0;
}
