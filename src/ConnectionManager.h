#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>
#include <QFile>
#include <QStandardPaths>

using namespace std;

class ConnectionManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(QVariantList connections READ connections NOTIFY connectionsChanged)
    Q_PROPERTY(int activeIndex READ activeIndex WRITE setActiveIndex NOTIFY activeIndexChanged)

public:
    explicit ConnectionManager(QObject* parent = nullptr) : QObject(parent) { load(); }

    QVariantList connections() const { return connections_; }
    int activeIndex() const { return activeIndex_; }
    void setActiveIndex(int i) { if (activeIndex_ != i) { activeIndex_ = i; emit activeIndexChanged(); } }

    Q_INVOKABLE void add(const QVariantMap& conn) {
        connections_.append(conn);
        save();
        emit connectionsChanged();
    }

    Q_INVOKABLE void update(int index, const QVariantMap& conn) {
        if (index < 0 || index >= connections_.size()) return;
        connections_[index] = conn;
        save();
        emit connectionsChanged();
    }

    Q_INVOKABLE void remove(int index) {
        if (index < 0 || index >= connections_.size()) return;
        connections_.removeAt(index);
        if (activeIndex_ >= connections_.size()) setActiveIndex(connections_.size() - 1);
        save();
        emit connectionsChanged();
    }

    Q_INVOKABLE QVariantMap get(int index) const {
        if (index < 0 || index >= connections_.size()) return {};
        return connections_[index].toMap();
    }

signals:
    void connectionsChanged();
    void activeIndexChanged();

private:
    QVariantList connections_;
    int activeIndex_ = -1;

    QString configPath() const {
        return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/connections.json";
    }

    void save() {
        QJsonArray arr;
        for (auto& c : connections_) arr.append(QJsonObject::fromVariantMap(c.toMap()));
        QFile f(configPath());
        if (f.open(QIODevice::WriteOnly)) f.write(QJsonDocument(arr).toJson());
    }

    void load() {
        QFile f(configPath());
        if (!f.open(QIODevice::ReadOnly)) return;
        auto arr = QJsonDocument::fromJson(f.readAll()).array();
        for (auto v : arr) connections_.append(v.toObject().toVariantMap());
    }
};
