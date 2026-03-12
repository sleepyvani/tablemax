#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include "DatabaseService.h"

using namespace std;

class SchemaService : public QObject {
    Q_OBJECT

    Q_PROPERTY(QVariantList tree READ tree NOTIFY treeChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

public:
    explicit SchemaService(QObject* parent = nullptr) : QObject(parent) {}

    QVariantList tree() const { return tree_; }
    bool loading() const { return loading_; }

    Q_INVOKABLE void refresh(DatabaseService* db) {
        if (!db || !db->connected()) return;
        setLoading(true);
        tree_.clear();

        auto databases = db->listDatabases();
        if (databases.isEmpty()) {
            // SQL databases — list tables directly
            auto tables = db->listTables();
            for (auto& t : tables) {
                QVariantMap node;
                node["name"] = t;
                node["type"] = "table";
                node["children"] = schemaColumns(db, t);
                tree_.append(node);
            }
        } else {
            // NoSQL/multi-database — list databases then tables
            for (auto& database : databases) {
                QVariantMap dbNode;
                dbNode["name"] = database;
                dbNode["type"] = "database";
                QVariantList tableNodes;
                auto tables = db->listTables(database);
                for (auto& t : tables) {
                    QVariantMap tNode;
                    tNode["name"] = t;
                    tNode["type"] = "table";
                    tNode["children"] = schemaColumns(db, t);
                    tableNodes.append(tNode);
                }
                dbNode["children"] = tableNodes;
                tree_.append(dbNode);
            }
        }

        setLoading(false);
        emit treeChanged();
    }

signals:
    void treeChanged();
    void loadingChanged();

private:
    QVariantList tree_;
    bool loading_ = false;

    void setLoading(bool v) { if (loading_ != v) { loading_ = v; emit loadingChanged(); } }

    QVariantList schemaColumns(DatabaseService* db, const QString& table) {
        QVariantList cols;
        auto schema = db->getTableSchema(table);
        for (auto& c : schema) {
            auto m = c.toMap();
            m["colType"] = m["type"];  // preserve SQL type (e.g. "varchar") for display
            m["type"] = "column";      // node type for tree rendering
            cols.append(m);
        }
        return cols;
    }
};
