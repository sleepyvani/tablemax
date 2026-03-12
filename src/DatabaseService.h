#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QThread>
#include "../core/include/engine.h"
#include "models/QueryResultModel.h"

using namespace std;

class DatabaseService : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(double lastExecTime READ lastExecTime NOTIFY lastExecTimeChanged)

public:
    explicit DatabaseService(QObject* parent = nullptr) : QObject(parent) {}
    ~DatabaseService() { if (connId_ >= 0) engine_.disconnect(connId_); }

    bool connected() const { return connId_ >= 0; }
    bool loading() const { return loading_; }
    QString error() const { return error_; }
    double lastExecTime() const { return lastExecTime_; }

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

    Q_INVOKABLE QVariantMap executeQuery(const QString& query, QObject* model) {
        QVariantMap result;
        result["success"] = false;
        result["rowCount"] = 0;
        result["execTime"] = 0.0;
        result["error"] = "";

        if (connId_ < 0) {
            result["error"] = "Not connected";
            setError("Not connected");
            return result;
        }

        setLoading(true);

        auto stream = engine_.execute(connId_, query.toStdString());
        if (!stream) {
            auto err = QString::fromStdString(engine_.last_error());
            result["error"] = err;
            setError(err);
            setLoading(false);
            return result;
        }

        // Read columns
        auto cols = stream->columns();
        QStringList colNames;
        for (auto& c : cols) colNames << QString::fromStdString(c.name);

        // Read all rows
        QVariantList rows;
        while (stream->has_more()) {
            auto chunk = stream->next_chunk(500);
            for (auto& row : chunk) {
                QVariantList rowData;
                for (auto& [key, val] : row) {
                    rowData << QString::fromStdString(val);
                }
                rows << QVariant(rowData);
            }
        }

        auto meta = stream->meta();
        stream->close();

        // Populate the model
        auto* rm = qobject_cast<QueryResultModel*>(model);
        if (rm) {
            rm->setData(colNames, rows);
        }

        result["success"] = true;
        result["rowCount"] = (int)rows.size();
        result["execTime"] = meta.execution_time_ms;
        lastExecTime_ = meta.execution_time_ms;
        emit lastExecTimeChanged();
        setError("");
        setLoading(false);
        return result;
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

    Q_INVOKABLE QString exportCsv(QObject* model) {
        auto* rm = qobject_cast<QueryResultModel*>(model);
        if (!rm) return "";
        QString csv;
        int cols = rm->totalColumns();
        int rows = rm->totalRows();
        // Header
        for (int c = 0; c < cols; ++c) {
            if (c > 0) csv += ",";
            csv += escapeCsvField(rm->columnName(c));
        }
        csv += "\n";
        // Rows
        for (int r = 0; r < rows; ++r) {
            for (int c = 0; c < cols; ++c) {
                if (c > 0) csv += ",";
                csv += escapeCsvField(rm->cellValue(r, c).toString());
            }
            csv += "\n";
        }
        return csv;
    }

signals:
    void connectedChanged();
    void loadingChanged();
    void errorChanged();
    void lastExecTimeChanged();

private:
    tablemax::Engine engine_;
    int connId_ = -1;
    bool loading_ = false;
    double lastExecTime_ = 0;
    QString error_;

    void setLoading(bool v) { if (loading_ != v) { loading_ = v; emit loadingChanged(); } }
    void setError(const QString& e) { if (error_ != e) { error_ = e; emit errorChanged(); } }

    QString escapeCsvField(const QString& f) {
        if (f.contains(',') || f.contains('"') || f.contains('\n')) {
            QString e = f;
            e.replace("\"", "\"\"");
            return "\"" + e + "\"";
        }
        return f;
    }
};
