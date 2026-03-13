// HistoryService.h — Query history with search
// Ported from TablePro QueryHistoryStorage

#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QDateTime>
#include <QSettings>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

class HistoryService : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList entries READ entries NOTIFY historyChanged)
    Q_PROPERTY(int count READ count NOTIFY historyChanged)

public:
    explicit HistoryService(QObject* p = nullptr) : QObject(p) { load(); }

    QVariantList entries() const { return m_entries; }
    int count() const { return m_entries.size(); }

    Q_INVOKABLE void addEntry(const QString& query, const QString& database, const QString& dbType,
                               int rowsAffected, double executionTime, bool success) {
        QVariantMap entry;
        entry["query"] = query.trimmed();
        entry["database"] = database;
        entry["dbType"] = dbType;
        entry["rowsAffected"] = rowsAffected;
        entry["executionTime"] = executionTime;
        entry["success"] = success;
        entry["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

        // Deduplicate — don't add exact same query consecutively
        if (!m_entries.isEmpty()) {
            auto last = m_entries.first().toMap();
            if (last["query"].toString() == entry["query"].toString())
                m_entries.removeFirst();
        }

        m_entries.prepend(entry);

        // Cap at 500 entries
        while (m_entries.size() > 500) m_entries.removeLast();

        save();
        emit historyChanged();
    }

    Q_INVOKABLE QVariantList search(const QString& query) const {
        if (query.isEmpty()) return m_entries;
        QVariantList results;
        QString q = query.toLower();
        for (const auto& e : m_entries) {
            auto m = e.toMap();
            if (m["query"].toString().toLower().contains(q) ||
                m["database"].toString().toLower().contains(q))
                results.append(e);
        }
        return results;
    }

    Q_INVOKABLE void clearHistory() {
        m_entries.clear();
        save();
        emit historyChanged();
    }

    Q_INVOKABLE void removeEntry(int index) {
        if (index >= 0 && index < m_entries.size()) {
            m_entries.removeAt(index);
            save();
            emit historyChanged();
        }
    }

    Q_INVOKABLE void toggleFavorite(int index) {
        if (index >= 0 && index < m_entries.size()) {
            auto m = m_entries[index].toMap();
            m["favorite"] = !m.value("favorite", false).toBool();
            m_entries[index] = m;
            save();
            emit historyChanged();
        }
    }

signals:
    void historyChanged();

private:
    QVariantList m_entries;

    void load() {
        QSettings s("VaniStudio", "TableMax");
        auto data = s.value("queryHistory").toByteArray();
        if (!data.isEmpty()) {
            auto doc = QJsonDocument::fromJson(data);
            m_entries = doc.array().toVariantList();
        }
    }

    void save() {
        QSettings s("VaniStudio", "TableMax");
        auto doc = QJsonDocument(QJsonArray::fromVariantList(m_entries));
        s.setValue("queryHistory", doc.toJson(QJsonDocument::Compact));
    }
};
