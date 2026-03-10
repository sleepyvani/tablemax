#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

using namespace std;

class TabManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(QVariantList tabs READ tabs NOTIFY tabsChanged)
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)

public:
    explicit TabManager(QObject* parent = nullptr) : QObject(parent) {}

    QVariantList tabs() const { return tabs_; }
    int currentIndex() const { return currentIndex_; }

    void setCurrentIndex(int i) {
        if (i != currentIndex_ && i >= 0 && i < tabs_.size()) {
            currentIndex_ = i;
            emit currentIndexChanged();
        }
    }

    Q_INVOKABLE int addTab(const QString& title = "Query", const QString& content = "") {
        QVariantMap tab;
        tab["title"] = title;
        tab["content"] = content;
        tab["result"] = QVariantList();
        tab["error"] = "";
        tab["executionTime"] = 0.0;
        tabs_.append(tab);
        setCurrentIndex(tabs_.size() - 1);
        emit tabsChanged();
        return tabs_.size() - 1;
    }

    Q_INVOKABLE void closeTab(int index) {
        if (index < 0 || index >= tabs_.size()) return;
        tabs_.removeAt(index);
        if (currentIndex_ >= tabs_.size()) setCurrentIndex(qMax(0, (int)tabs_.size() - 1));
        emit tabsChanged();
    }

    Q_INVOKABLE void updateContent(int index, const QString& content) {
        if (index < 0 || index >= tabs_.size()) return;
        auto tab = tabs_[index].toMap();
        tab["content"] = content;
        tabs_[index] = tab;
    }

    Q_INVOKABLE void updateResult(int index, const QVariantList& result, double execTime, const QString& error = "") {
        if (index < 0 || index >= tabs_.size()) return;
        auto tab = tabs_[index].toMap();
        tab["result"] = result;
        tab["executionTime"] = execTime;
        tab["error"] = error;
        tabs_[index] = tab;
        emit tabsChanged();
    }

    Q_INVOKABLE QVariantMap getTab(int index) const {
        if (index < 0 || index >= tabs_.size()) return {};
        return tabs_[index].toMap();
    }

signals:
    void tabsChanged();
    void currentIndexChanged();

private:
    QVariantList tabs_;
    int currentIndex_ = -1;
};
