// ChangeTracker.h — Inline editing, undo/redo, SQL generation
// Ported from TablePro DataChangeManager.swift + SQLStatementGenerator.swift

#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QStack>
#include <QSet>

class ChangeTracker : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool hasChanges READ hasChanges NOTIFY changesChanged)
    Q_PROPERTY(int changeCount READ changeCount NOTIFY changesChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY changesChanged)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY changesChanged)

public:
    explicit ChangeTracker(QObject* p = nullptr) : QObject(p) {}

    bool hasChanges() const { return !m_changes.isEmpty(); }
    int changeCount() const { return m_changes.size(); }
    bool canUndo() const { return !m_undoStack.isEmpty(); }
    bool canRedo() const { return !m_redoStack.isEmpty(); }

    // ── Configure for table ──
    Q_INVOKABLE void configure(const QString& table, const QStringList& columns, const QString& pkColumn, const QString& dbType) {
        clear();
        m_table = table; m_columns = columns; m_pk = pkColumn; m_dbType = dbType;
    }

    // ── Cell edit tracking ──
    Q_INVOKABLE void recordCellEdit(int row, int col, const QString& colName, const QVariant& oldVal, const QVariant& newVal) {
        if (oldVal == newVal) return;
        m_redoStack.clear();

        // Find existing change for this row
        for (int idx = 0; idx < m_changes.size(); idx++) {
            QVariantMap change = m_changes[idx].toMap();
            if (change.value("row").toInt() == row && change.value("type").toString() == "update") {
                QVariantList cells = change.value("cells").toList();
                // Update existing cell change or add new
                for (int i = 0; i < cells.size(); i++) {
                    QVariantMap c = cells[i].toMap();
                    if (c.value("col").toInt() == col) {
                        // Check if reverted to original
                        if (c.value("oldValue") == newVal) {
                            cells.removeAt(i);
                            if (cells.isEmpty()) {
                                m_changes.removeAt(idx);
                            } else {
                                change["cells"] = cells;
                                m_changes[idx] = change;
                            }
                            pushUndo("cellEdit", row, col, colName, oldVal, newVal);
                            emit changesChanged();
                            return;
                        }
                        c["newValue"] = newVal;
                        cells[i] = c;
                        change["cells"] = cells;
                        m_changes[idx] = change;
                        pushUndo("cellEdit", row, col, colName, oldVal, newVal);
                        emit changesChanged();
                        return;
                    }
                }
                // New column change for existing row
                QVariantMap cell;
                cell["col"] = col; cell["colName"] = colName;
                cell["oldValue"] = oldVal; cell["newValue"] = newVal;
                cells.append(cell);
                change["cells"] = cells;
                m_changes[idx] = change;
                pushUndo("cellEdit", row, col, colName, oldVal, newVal);
                emit changesChanged();
                return;
            }
        }

        // New row change
        QVariantMap change;
        change["row"] = row; change["type"] = "update";
        QVariantMap cell;
        cell["col"] = col; cell["colName"] = colName;
        cell["oldValue"] = oldVal; cell["newValue"] = newVal;
        change["cells"] = QVariantList{cell};
        m_changes.append(change);
        pushUndo("cellEdit", row, col, colName, oldVal, newVal);
        emit changesChanged();
    }

    // ── Row operations ──
    Q_INVOKABLE void recordRowDeletion(int row, const QVariantList& originalRow) {
        m_redoStack.clear();
        // Remove any existing update for this row
        for (int i = m_changes.size() - 1; i >= 0; i--) {
            QVariantMap c = m_changes[i].toMap();
            if (c.value("row").toInt() == row && c.value("type").toString() == "update")
                m_changes.removeAt(i);
        }
        QVariantMap change;
        change["row"] = row; change["type"] = "delete"; change["originalRow"] = QVariant::fromValue(originalRow);
        m_changes.append(change);
        m_deletedRows.insert(row);
        pushUndo("rowDelete", row, -1, QString(), QVariant(), QVariant::fromValue(originalRow));
        emit changesChanged();
    }

    Q_INVOKABLE void recordRowInsertion(int row, const QVariantList& values) {
        m_redoStack.clear();
        QVariantMap change;
        change["row"] = row; change["type"] = "insert"; change["values"] = QVariant::fromValue(values);
        m_changes.append(change);
        m_insertedRows.insert(row);
        pushUndo("rowInsert", row, -1, QString(), QVariant(), QVariant());
        emit changesChanged();
    }

    // ── State queries ──
    Q_INVOKABLE bool isRowDeleted(int row) const { return m_deletedRows.contains(row); }
    Q_INVOKABLE bool isRowInserted(int row) const { return m_insertedRows.contains(row); }
    Q_INVOKABLE bool isCellModified(int row, int col) const {
        for (int idx = 0; idx < m_changes.size(); idx++) {
            QVariantMap c = m_changes[idx].toMap();
            if (c.value("row").toInt() == row && c.value("type").toString() == "update") {
                QVariantList cells = c.value("cells").toList();
                for (int j = 0; j < cells.size(); j++) {
                    if (cells[j].toMap().value("col").toInt() == col) return true;
                }
            }
        }
        return false;
    }

    // ── SQL Generation ──
    Q_INVOKABLE QStringList generateSQL() const {
        QStringList stmts;
        QString q = (m_dbType == "postgresql" || m_dbType == "redshift") ? "\"" : "`";

        for (int idx = 0; idx < m_changes.size(); idx++) {
            QVariantMap c = m_changes[idx].toMap();
            int row = c.value("row").toInt();
            QString type = c.value("type").toString();

            if (type == "insert") {
                QVariantList vals = c.value("values").toList();
                QStringList colNames, placeholders;
                for (int i = 0; i < m_columns.size() && i < vals.size(); i++) {
                    colNames << (q + m_columns[i] + q);
                    placeholders << escapeValue(vals[i]);
                }
                stmts << QString("INSERT INTO %1%2%3 (%4) VALUES (%5)")
                    .arg(q, m_table, q, colNames.join(", "), placeholders.join(", "));
            }
            else if (type == "update") {
                QVariantList cells = c.value("cells").toList();
                QStringList setClauses;
                for (int j = 0; j < cells.size(); j++) {
                    QVariantMap cc = cells[j].toMap();
                    setClauses << QString("%1%2%3 = %4")
                        .arg(q, cc.value("colName").toString(), q, escapeValue(cc.value("newValue")));
                }
                QString where = buildWhereForRow(c, q);
                stmts << QString("UPDATE %1%2%3 SET %4 WHERE %5")
                    .arg(q, m_table, q, setClauses.join(", "), where);
            }
            else if (type == "delete") {
                QString where = buildWhereForDeletedRow(c, q);
                stmts << QString("DELETE FROM %1%2%3 WHERE %4").arg(q, m_table, q, where);
            }
        }
        return stmts;
    }

    // ── Undo / Redo ──
    Q_INVOKABLE void undo() {
        if (m_undoStack.isEmpty()) return;
        QVariantMap action = m_undoStack.pop();
        m_redoStack.push(action);
        applyUndoAction(action);
        emit changesChanged();
    }

    Q_INVOKABLE void redo() {
        if (m_redoStack.isEmpty()) return;
        QVariantMap action = m_redoStack.pop();
        m_undoStack.push(action);
        applyRedoAction(action);
        emit changesChanged();
    }

    Q_INVOKABLE void clear() {
        m_changes.clear();
        m_deletedRows.clear();
        m_insertedRows.clear();
        m_undoStack.clear();
        m_redoStack.clear();
        emit changesChanged();
    }

    // ── Get original values for discard ──
    Q_INVOKABLE QVariantList getOriginalValues() const {
        QVariantList result;
        for (int idx = 0; idx < m_changes.size(); idx++) {
            QVariantMap c = m_changes[idx].toMap();
            if (c.value("type").toString() == "update") {
                QVariantList cells = c.value("cells").toList();
                for (int j = 0; j < cells.size(); j++) {
                    QVariantMap cc = cells[j].toMap();
                    QVariantMap entry;
                    entry["row"] = c.value("row"); entry["col"] = cc.value("col");
                    entry["value"] = cc.value("oldValue");
                    result.append(entry);
                }
            }
        }
        return result;
    }

signals:
    void changesChanged();

private:
    QString m_table, m_pk, m_dbType;
    QStringList m_columns;
    QVariantList m_changes;
    QSet<int> m_deletedRows, m_insertedRows;
    QStack<QVariantMap> m_undoStack, m_redoStack;

    void pushUndo(const QString& type, int row, int col, const QString& colName,
                  const QVariant& oldVal, const QVariant& newVal) {
        QVariantMap action;
        action["type"] = type; action["row"] = row; action["col"] = col;
        action["colName"] = colName; action["oldValue"] = oldVal; action["newValue"] = newVal;
        m_undoStack.push(action);
    }

    void applyUndoAction(const QVariantMap& action) {
        QString type = action.value("type").toString();
        if (type == "cellEdit") {
            int row = action.value("row").toInt();
            int col = action.value("col").toInt();
            for (int idx = 0; idx < m_changes.size(); idx++) {
                QVariantMap c = m_changes[idx].toMap();
                if (c.value("row").toInt() == row && c.value("type").toString() == "update") {
                    QVariantList cells = c.value("cells").toList();
                    for (int i = 0; i < cells.size(); i++) {
                        QVariantMap cc = cells[i].toMap();
                        if (cc.value("col").toInt() == col) {
                            if (cc.value("oldValue") == action.value("oldValue")) {
                                cells.removeAt(i);
                                if (cells.isEmpty()) {
                                    m_changes.removeAt(idx);
                                } else {
                                    c["cells"] = cells;
                                    m_changes[idx] = c;
                                }
                            } else {
                                cc["newValue"] = action.value("oldValue");
                                cells[i] = cc;
                                c["cells"] = cells;
                                m_changes[idx] = c;
                            }
                            return;
                        }
                    }
                }
            }
        } else if (type == "rowDelete") {
            int row = action.value("row").toInt();
            for (int i = m_changes.size() - 1; i >= 0; i--) {
                QVariantMap c = m_changes[i].toMap();
                if (c.value("row").toInt() == row && c.value("type").toString() == "delete") {
                    m_changes.removeAt(i); m_deletedRows.remove(row); break;
                }
            }
        } else if (type == "rowInsert") {
            int row = action.value("row").toInt();
            for (int i = m_changes.size() - 1; i >= 0; i--) {
                QVariantMap c = m_changes[i].toMap();
                if (c.value("row").toInt() == row && c.value("type").toString() == "insert") {
                    m_changes.removeAt(i); m_insertedRows.remove(row); break;
                }
            }
        }
    }

    void applyRedoAction(const QVariantMap& action) {
        QString type = action.value("type").toString();
        if (type == "cellEdit") {
            recordCellEdit(action.value("row").toInt(), action.value("col").toInt(),
                           action.value("colName").toString(), action.value("oldValue"), action.value("newValue"));
            m_undoStack.pop(); // Remove duplicate undo
        }
    }

    static QString escapeValue(const QVariant& v) {
        if (v.isNull() || !v.isValid()) return QStringLiteral("NULL");
        QString s = v.toString();
        s.replace(QLatin1Char('\''), QLatin1String("''"));
        return QStringLiteral("'") + s + QStringLiteral("'");
    }

    QString buildWhereForRow(const QVariantMap& change, const QString& q) const {
        if (!m_pk.isEmpty()) {
            QVariantList cells = change.value("cells").toList();
            for (int i = 0; i < cells.size(); i++) {
                QVariantMap cc = cells[i].toMap();
                if (cc.value("colName").toString() == m_pk)
                    return QString("%1%2%3 = %4").arg(q, m_pk, q, escapeValue(cc.value("oldValue")));
            }
            return q + m_pk + q + " = " + escapeValue(change.value("pkValue"));
        }
        return QStringLiteral("1=1 /* no PK */");
    }

    QString buildWhereForDeletedRow(const QVariantMap& change, const QString& q) const {
        QVariantList original = change.value("originalRow").toList();
        if (!m_pk.isEmpty()) {
            int pkIdx = m_columns.indexOf(m_pk);
            if (pkIdx >= 0 && pkIdx < original.size())
                return QString("%1%2%3 = %4").arg(q, m_pk, q, escapeValue(original[pkIdx]));
        }
        QStringList conds;
        for (int i = 0; i < m_columns.size() && i < original.size(); i++) {
            if (original[i].isNull())
                conds << QString("%1%2%3 IS NULL").arg(q, m_columns[i], q);
            else
                conds << QString("%1%2%3 = %4").arg(q, m_columns[i], q, escapeValue(original[i]));
        }
        return conds.isEmpty() ? QStringLiteral("1=0") : conds.join(" AND ");
    }
};
