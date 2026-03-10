#include "engine.h"

#ifdef _WIN32
    #ifndef NOMINMAX
    #define NOMINMAX
    #endif
    #define byte win_byte_override
    #include <windows.h>
    #undef byte
#else
    #include <dlfcn.h>
    #include <dirent.h>
#endif

using namespace std;

namespace tablemax {

// Defined in plugin_loader.cpp
struct LoadedPlugin {
    void* handle = nullptr;
    CreatePluginFn create_fn = nullptr;
    DestroyPluginFn destroy_fn = nullptr;
    string path, db_type;
};
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