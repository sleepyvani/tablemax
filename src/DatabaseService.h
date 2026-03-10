#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QThread>
#include "../core/include/engine.h"

using namespace std;

class DatabaseService : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit DatabaseService(QObject* parent = nullptr) : QObject(parent) {}
    ~DatabaseService() { if (connId_ >= 0) engine_.disconnect(connId_); }

    bool connected() const { return connId_ >= 0; }
    bool loading() const { return loading_; }
    QString error() const { return error_; }

    Q_INVOKABLE void loadPlugins(const QString& dir) {
        engine_.load_plugins(dir.toStdString());
    }

    Q_INVOKABLE void connect(const QString& dbType, const QString& connStr) {
        setLoading(true);
        int id = engine_.connect(dbType.toStdString(), connStr.toStdString());
        if (id < 0) {
            setError(QString::fromStdString(engine_.last_error()));
        } else {
            connId_ = id;
            setError("");
            emit connectedChanged();
        }
        setLoading(false);
    }

    Q_INVOKABLE void disconnect() {
        if (connId_ >= 0) engine_.disconnect(connId_);
        connId_ = -1;
        emit connectedChanged();
    }

    Q_INVOKABLE bool testConnection(const QString& dbType, const QString& connStr) {
        int ms = 0;
        bool ok = engine_.test_connection(dbType.toStdString(), connStr.toStdString(), ms);
        if (!ok) setError(QString::fromStdString(engine_.last_error()));
        else setError("");
        return ok;
    }

    Q_INVOKABLE QStringList listDatabases() {
        if (connId_ < 0) return {};
        QStringList result;
        for (auto& s : engine_.list_databases(connId_)) result << QString::fromStdString(s);
        return result;
    }

    Q_INVOKABLE QStringList listTables(const QString& database = "") {
        if (connId_ < 0) return {};
        QStringList result;
        for (auto& s : engine_.list_tables(connId_, database.toStdString())) result << QString::fromStdString(s);
        return result;
    }

    Q_INVOKABLE QVariantList getTableSchema(const QString& table) {
        if (connId_ < 0) return {};
        QVariantList result;
        for (auto& col : engine_.get_table_schema(connId_, table.toStdString())) {
            QVariantMap m;
            m["name"] = QString::fromStdString(col.name);
            m["type"] = QString::fromStdString(col.type);
            m["nullable"] = col.nullable;
            m["primary_key"] = col.primary_key;
            m["default_value"] = QString::fromStdString(col.default_value);
            result << m;
        }
        return result;
    }

signals:
    void connectedChanged();
    void loadingChanged();
    void errorChanged();

private:
    tablemax::Engine engine_;
    int connId_ = -1;
    bool loading_ = false;
    QString error_;

    void setLoading(bool v) { if (loading_ != v) { loading_ = v; emit loadingChanged(); } }
    void setError(const QString& e) { if (error_ != e) { error_ = e; emit errorChanged(); } }
};
