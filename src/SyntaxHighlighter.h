#pragma once

#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QRegularExpression>
#include <QQuickTextDocument>

#include "ThemeProvider.h"

class SyntaxHighlighter : public QSyntaxHighlighter {
    Q_OBJECT

    Q_PROPERTY(QQuickTextDocument* document READ quickDocument WRITE setQuickDocument NOTIFY documentChanged)
    Q_PROPERTY(ThemeProvider* theme READ theme WRITE setTheme NOTIFY themeChanged)

public:
    explicit SyntaxHighlighter(QObject* parent = nullptr)
        : QSyntaxHighlighter(static_cast<QTextDocument*>(nullptr))
    {
        Q_UNUSED(parent)
        buildRules();
    }

    QQuickTextDocument* quickDocument() const { return quickDoc_; }
    ThemeProvider* theme() const { return theme_; }

    void setQuickDocument(QQuickTextDocument* doc) {
        if (quickDoc_ == doc) return;
        quickDoc_ = doc;
        if (doc) setDocument(doc->textDocument());
        else setDocument(nullptr);
        emit documentChanged();
    }

    void setTheme(ThemeProvider* t) {
        if (theme_ == t) return;
        theme_ = t;
        if (t) {
            connect(t, &ThemeProvider::themeChanged, this, &SyntaxHighlighter::onThemeChanged);
            applyThemeColors();
            rehighlight();
        }
        emit themeChanged();
    }

signals:
    void documentChanged();
    void themeChanged();

protected:
    void highlightBlock(const QString& text) override {
        // Apply keyword/type/function/number/string/comment rules
        for (auto& rule : rules_) {
            auto it = rule.pattern.globalMatch(text);
            while (it.hasNext()) {
                auto match = it.next();
                setFormat(match.capturedStart(), match.capturedLength(), rule.format);
            }
        }

        // Multi-line block comments: /* ... */
        setCurrentBlockState(0);
        int startIdx = 0;
        if (previousBlockState() != 1)
            startIdx = text.indexOf(commentStart_);

        while (startIdx >= 0) {
            auto endMatch = commentEnd_.match(text, startIdx + 2);
            int endIdx = endMatch.hasMatch() ? endMatch.capturedStart() : -1;
            int commentLen;
            if (endIdx == -1) {
                setCurrentBlockState(1);
                commentLen = text.length() - startIdx;
            } else {
                commentLen = endIdx - startIdx + endMatch.capturedLength();
            }
            setFormat(startIdx, commentLen, commentFmt_);
            startIdx = text.indexOf(commentStart_, startIdx + commentLen);
        }
    }

private:
    struct HighlightRule {
        QRegularExpression pattern;
        QTextCharFormat format;
    };

    QVector<HighlightRule> rules_;
    QQuickTextDocument* quickDoc_ = nullptr;
    ThemeProvider* theme_ = nullptr;

    QRegularExpression commentStart_{R"(/\*)"};
    QRegularExpression commentEnd_{R"(\*/)"};
    QTextCharFormat commentFmt_;

    // Format indices for theme updates
    enum FormatIdx { FmtKeyword = 0, FmtType, FmtFunction, FmtNumber, FmtString, FmtComment, FmtCount };
    int formatStart_[FmtCount] = {};
    int formatCount_[FmtCount] = {};

    void buildRules() {
        rules_.clear();

        // ── SQL Keywords ──
        QStringList keywords = {
            "SELECT", "FROM", "WHERE", "INSERT", "INTO", "UPDATE", "SET",
            "DELETE", "DROP", "CREATE", "ALTER", "TABLE", "INDEX", "VIEW",
            "JOIN", "INNER", "LEFT", "RIGHT", "OUTER", "CROSS", "FULL",
            "ON", "AND", "OR", "NOT", "IN", "EXISTS", "BETWEEN", "LIKE",
            "IS", "NULL", "AS", "DISTINCT", "ALL", "ANY", "SOME",
            "ORDER", "BY", "GROUP", "HAVING", "LIMIT", "OFFSET","FETCH",
            "UNION", "INTERSECT", "EXCEPT", "CASE", "WHEN", "THEN",
            "ELSE", "END", "BEGIN", "COMMIT", "ROLLBACK", "TRANSACTION",
            "GRANT", "REVOKE", "WITH", "RECURSIVE", "VALUES", "DEFAULT",
            "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "CONSTRAINT",
            "UNIQUE", "CHECK", "CASCADE", "RESTRICT", "ASC", "DESC",
            "IF", "REPLACE", "TRUNCATE", "EXPLAIN", "ANALYZE",
            "ADD", "COLUMN", "RENAME", "TO", "DATABASE", "USE",
            "SHOW", "DATABASES", "TABLES", "COLUMNS", "DESCRIBE",
            // MongoDB-style
            "find", "aggregate", "insertOne", "insertMany", "updateOne",
            "updateMany", "deleteOne", "deleteMany", "count", "distinct"
        };
        formatStart_[FmtKeyword] = rules_.size();
        QTextCharFormat kwFmt;
        kwFmt.setForeground(QColor("#c084fc")); // default dark
        kwFmt.setFontWeight(QFont::DemiBold);
        for (auto& kw : keywords) {
            rules_.append({
                QRegularExpression("\\b" + kw + "\\b", QRegularExpression::CaseInsensitiveOption),
                kwFmt
            });
        }
        formatCount_[FmtKeyword] = rules_.size() - formatStart_[FmtKeyword];

        // ── Type keywords ──
        QStringList types = {
            "INT", "INTEGER", "BIGINT", "SMALLINT", "TINYINT",
            "FLOAT", "DOUBLE", "DECIMAL", "NUMERIC", "REAL",
            "CHAR", "VARCHAR", "TEXT", "NVARCHAR", "NCHAR",
            "DATE", "DATETIME", "TIMESTAMP", "TIME", "YEAR",
            "BOOLEAN", "BOOL", "BLOB", "CLOB", "JSON", "JSONB",
            "UUID", "SERIAL", "BIGSERIAL", "BYTEA", "ARRAY",
            "MONEY", "INET", "CIDR", "MACADDR", "XML",
            "BIT", "BINARY", "VARBINARY", "IMAGE"
        };
        formatStart_[FmtType] = rules_.size();
        QTextCharFormat typeFmt;
        typeFmt.setForeground(QColor("#f87171"));
        for (auto& t : types) {
            rules_.append({
                QRegularExpression("\\b" + t + "\\b", QRegularExpression::CaseInsensitiveOption),
                typeFmt
            });
        }
        formatCount_[FmtType] = rules_.size() - formatStart_[FmtType];

        // ── Functions (word followed by parenthesis) ──
        formatStart_[FmtFunction] = rules_.size();
        QTextCharFormat fnFmt;
        fnFmt.setForeground(QColor("#fbbf24"));
        rules_.append({
            QRegularExpression(R"(\b[A-Za-z_]\w*(?=\s*\())"),
            fnFmt
        });
        formatCount_[FmtFunction] = 1;

        // ── Numbers ──
        formatStart_[FmtNumber] = rules_.size();
        QTextCharFormat numFmt;
        numFmt.setForeground(QColor("#60a5fa"));
        rules_.append({
            QRegularExpression(R"(\b\d+\.?\d*([eE][+-]?\d+)?\b)"),
            numFmt
        });
        formatCount_[FmtNumber] = 1;

        // ── Strings (single-quoted) ──
        formatStart_[FmtString] = rules_.size();
        QTextCharFormat strFmt;
        strFmt.setForeground(QColor("#4ade80"));
        rules_.append({
            QRegularExpression(R"('(?:[^'\\]|\\.)*')"),
            strFmt
        });
        // Double-quoted identifiers
        rules_.append({
            QRegularExpression(R"("(?:[^"\\]|\\.)*")"),
            strFmt
        });
        formatCount_[FmtString] = 2;

        // ── Single-line comments (-- ...) ──
        formatStart_[FmtComment] = rules_.size();
        QTextCharFormat cmtFmt;
        cmtFmt.setForeground(QColor("#52525b"));
        cmtFmt.setFontItalic(true);
        rules_.append({
            QRegularExpression(R"(--.*)"),
            cmtFmt
        });
        formatCount_[FmtComment] = 1;

        commentFmt_ = cmtFmt;
    }

    void applyThemeColors() {
        if (!theme_) return;

        auto setColor = [this](int idx, int cnt, QColor c, bool bold = false, bool italic = false) {
            for (int i = formatStart_[idx]; i < formatStart_[idx] + cnt && i < rules_.size(); ++i) {
                rules_[i].format.setForeground(c);
                if (bold) rules_[i].format.setFontWeight(QFont::DemiBold);
                if (italic) rules_[i].format.setFontItalic(true);
            }
        };

        setColor(FmtKeyword,  formatCount_[FmtKeyword],  theme_->synKeyword(), true);
        setColor(FmtType,     formatCount_[FmtType],     theme_->synType());
        setColor(FmtFunction, formatCount_[FmtFunction],  theme_->synFunction());
        setColor(FmtNumber,   formatCount_[FmtNumber],   theme_->synNumber());
        setColor(FmtString,   formatCount_[FmtString],   theme_->synString());
        setColor(FmtComment,  formatCount_[FmtComment],  theme_->synComment(), false, true);

        commentFmt_.setForeground(theme_->synComment());
        commentFmt_.setFontItalic(true);
    }

    void onThemeChanged() {
        applyThemeColors();
        rehighlight();
    }
};
