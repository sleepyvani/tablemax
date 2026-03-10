#pragma once

#include <QAbstractTableModel>
#include <QVariantList>
#include <QVariantMap>

using namespace std;

class QueryResultModel : public QAbstractTableModel {
    Q_OBJECT

    Q_PROPERTY(int totalRows READ totalRows NOTIFY dataChanged)
    Q_PROPERTY(int totalColumns READ totalColumns NOTIFY dataChanged)

public:
    explicit QueryResultModel(QObject* parent = nullptr) : QAbstractTableModel(parent) {}

    int rowCount(const QModelIndex& = {}) const override { return rows_.size(); }
    int columnCount(const QModelIndex& = {}) const override { return columns_.size(); }

    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override {
        if (!index.isValid() || role != Qt::DisplayRole) return {};
        if (index.row() >= rows_.size() || index.column() >= columns_.size()) return {};
        auto row = rows_[index.row()].toList();
        if (index.column() >= row.size()) return {};
        return row[index.column()];
    }

    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override {
        if (role != Qt::DisplayRole) return {};
        if (orientation == Qt::Horizontal && section < columns_.size())
            return columns_[section];
        return section + 1;
    }

    QHash<int, QByteArray> roleNames() const override {
        return {{ Qt::DisplayRole, "display" }};
    }

    int totalRows() const { return rows_.size(); }
    int totalColumns() const { return columns_.size(); }

    Q_INVOKABLE void setData(const QStringList& columns, const QVariantList& rows) {
        beginResetModel();
        columns_ = columns;
        rows_ = rows;
        endResetModel();
        emit dataChanged();
    }

    Q_INVOKABLE void appendRows(const QVariantList& newRows) {
        if (newRows.isEmpty()) return;
        beginInsertRows({}, rows_.size(), rows_.size() + newRows.size() - 1);
        rows_.append(newRows);
        endInsertRows();
        emit dataChanged();
    }

    Q_INVOKABLE void clear() {
        beginResetModel();
        columns_.clear();
        rows_.clear();
        endResetModel();
        emit dataChanged();
    }

    Q_INVOKABLE QVariant cellValue(int row, int col) const {
        if (row < 0 || row >= rows_.size()) return {};
        auto r = rows_[row].toList();
        if (col < 0 || col >= r.size()) return {};
        return r[col];
    }

    Q_INVOKABLE QString columnName(int col) const {
        if (col < 0 || col >= columns_.size()) return "";
        return columns_[col];
    }

signals:
    void dataChanged();

private:
    QStringList columns_;
    QVariantList rows_;
};
