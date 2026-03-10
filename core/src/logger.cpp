#include <iostream>
#include <chrono>
#include <iomanip>
#include <sstream>

using namespace std;

namespace tablemax {

enum class LogLevel { Debug, Info, Warn, Error };

class Logger {
public:
    static void set_level(LogLevel level) { level_ = level; }

    static void debug(const string& tag, const string& msg) { log(LogLevel::Debug, tag, msg); }
    static void info(const string& tag, const string& msg)  { log(LogLevel::Info,  tag, msg); }
    static void warn(const string& tag, const string& msg)  { log(LogLevel::Warn,  tag, msg); }
    static void error(const string& tag, const string& msg) { log(LogLevel::Error, tag, msg); }

private:
    static inline LogLevel level_ = LogLevel::Info;

    static void log(LogLevel level, const string& tag, const string& msg) {
        if (level < level_) return;
        static const char* names[] = { "DEBUG", "INFO", "WARN", "ERROR" };
        cerr << "[" << timestamp() << "] [" << names[(int)level] << "] [" << tag << "] " << msg << endl;
    }

    static string timestamp() {
        auto now = chrono::system_clock::now();
        auto t = chrono::system_clock::to_time_t(now);
        ostringstream ss;
        ss << put_time(localtime(&t), "%H:%M:%S");
        return ss.str();
    }
};

}