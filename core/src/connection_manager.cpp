#include "engine.h"
#include <filesystem>

using namespace std;
namespace fs = filesystem;

namespace tablemax {

// Forward declaration from plugin_loader.cpp
struct LoadedPlugin;
LoadedPlugin load_plugin(const string& path);
vector<LoadedPlugin> scan_plugins(const string& dir);

int Engine::load_plugins(const string& dir) {
    auto loaded = scan_plugins(dir);
    for (auto& lp : loaded) {
        plugins_.push_back({
            lp.path, lp.db_type, lp.create_fn, lp.destroy_fn, lp.handle
        });
    }
    return (int)loaded.size();
}

}