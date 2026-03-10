#include "plugin_interface.h"

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

struct LoadedPlugin {
    void* handle = nullptr;
    CreatePluginFn create_fn = nullptr;
    DestroyPluginFn destroy_fn = nullptr;
    string path, db_type;
};

LoadedPlugin load_plugin(const string& path) {
    LoadedPlugin p;
    p.path = path;

#ifdef _WIN32
    auto lib = LoadLibraryA(path.c_str());
    if (!lib) return p;
    p.handle = (void*)lib;
    p.create_fn = (CreatePluginFn)GetProcAddress(lib, "create_plugin");
    p.destroy_fn = (DestroyPluginFn)GetProcAddress(lib, "destroy_plugin");
#else
    auto lib = dlopen(path.c_str(), RTLD_LAZY);
    if (!lib) return p;
    p.handle = lib;
    p.create_fn = (CreatePluginFn)dlsym(lib, "create_plugin");
    p.destroy_fn = (DestroyPluginFn)dlsym(lib, "destroy_plugin");
#endif

    if (!p.create_fn || !p.destroy_fn) {
#ifdef _WIN32
        FreeLibrary((HMODULE)p.handle);
#else
        dlclose(p.handle);
#endif
        p.handle = nullptr;
        return p;
    }

    auto* temp = p.create_fn();
    if (temp) {
        p.db_type = temp->db_type();
        p.destroy_fn(temp);
    }
    return p;
}

vector<LoadedPlugin> scan_plugins(const string& dir) {
    vector<LoadedPlugin> result;

#ifdef _WIN32
    WIN32_FIND_DATAA fd;
    auto h = FindFirstFileA((dir + "\\*.dll").c_str(), &fd);
    if (h == INVALID_HANDLE_VALUE) return result;
    do {
        auto p = load_plugin(dir + "\\" + fd.cFileName);
        if (p.handle) result.push_back(move(p));
    } while (FindNextFileA(h, &fd));
    FindClose(h);
#else
    auto* d = opendir(dir.c_str());
    if (!d) return result;
    while (auto* e = readdir(d)) {
        string name = e->d_name;
        if (name.size() > 3 && name.substr(name.size() - 3) == ".so") {
            auto p = load_plugin(dir + "/" + name);
            if (p.handle) result.push_back(move(p));
        }
    }
    closedir(d);
#endif

    return result;
}

}
