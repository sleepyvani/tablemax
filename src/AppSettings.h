// AppSettings.h — Application settings with QSettings persistence
// Ported from TablePro AppSettingsManager

#pragma once
#include <QObject>
#include <QSettings>
#include <QFont>

class AppSettings : public QObject {
    Q_OBJECT

    // General
    Q_PROPERTY(bool autoConnect READ autoConnect WRITE setAutoConnect NOTIFY settingsChanged)
    Q_PROPERTY(bool confirmOnClose READ confirmOnClose WRITE setConfirmOnClose NOTIFY settingsChanged)
    Q_PROPERTY(bool restoreTabs READ restoreTabs WRITE setRestoreTabs NOTIFY settingsChanged)

    // Editor
    Q_PROPERTY(QString editorFont READ editorFont WRITE setEditorFont NOTIFY settingsChanged)
    Q_PROPERTY(int editorFontSize READ editorFontSize WRITE setEditorFontSize NOTIFY settingsChanged)
    Q_PROPERTY(bool editorLineNumbers READ editorLineNumbers WRITE setEditorLineNumbers NOTIFY settingsChanged)
    Q_PROPERTY(bool editorWordWrap READ editorWordWrap WRITE setEditorWordWrap NOTIFY settingsChanged)
    Q_PROPERTY(bool editorAutocomplete READ editorAutocomplete WRITE setEditorAutocomplete NOTIFY settingsChanged)
    Q_PROPERTY(bool editorVimMode READ editorVimMode WRITE setEditorVimMode NOTIFY settingsChanged)

    // Data Grid
    Q_PROPERTY(int rowHeight READ rowHeight WRITE setRowHeight NOTIFY settingsChanged)
    Q_PROPERTY(bool alternateRows READ alternateRows WRITE setAlternateRows NOTIFY settingsChanged)
    Q_PROPERTY(int pageSize READ pageSize WRITE setPageSize NOTIFY settingsChanged)
    Q_PROPERTY(QString nullDisplay READ nullDisplay WRITE setNullDisplay NOTIFY settingsChanged)
    Q_PROPERTY(QString dateFormat READ dateFormat WRITE setDateFormat NOTIFY settingsChanged)

    // AI
    Q_PROPERTY(QString aiProvider READ aiProvider WRITE setAiProvider NOTIFY settingsChanged)
    Q_PROPERTY(QString aiApiKey READ aiApiKey WRITE setAiApiKey NOTIFY settingsChanged)
    Q_PROPERTY(QString aiModel READ aiModel WRITE setAiModel NOTIFY settingsChanged)
    Q_PROPERTY(bool aiInlineSuggestions READ aiInlineSuggestions WRITE setAiInlineSuggestions NOTIFY settingsChanged)

public:
    explicit AppSettings(QObject* p = nullptr) : QObject(p), m_settings("VaniStudio", "TableMax") {}

    // General
    bool autoConnect() const { return m_settings.value("general/autoConnect", true).toBool(); }
    void setAutoConnect(bool v) { m_settings.setValue("general/autoConnect", v); emit settingsChanged(); }
    bool confirmOnClose() const { return m_settings.value("general/confirmOnClose", true).toBool(); }
    void setConfirmOnClose(bool v) { m_settings.setValue("general/confirmOnClose", v); emit settingsChanged(); }
    bool restoreTabs() const { return m_settings.value("general/restoreTabs", true).toBool(); }
    void setRestoreTabs(bool v) { m_settings.setValue("general/restoreTabs", v); emit settingsChanged(); }

    // Editor
    QString editorFont() const { return m_settings.value("editor/font", "Cascadia Code").toString(); }
    void setEditorFont(const QString& v) { m_settings.setValue("editor/font", v); emit settingsChanged(); }
    int editorFontSize() const { return m_settings.value("editor/fontSize", 13).toInt(); }
    void setEditorFontSize(int v) { m_settings.setValue("editor/fontSize", v); emit settingsChanged(); }
    bool editorLineNumbers() const { return m_settings.value("editor/lineNumbers", true).toBool(); }
    void setEditorLineNumbers(bool v) { m_settings.setValue("editor/lineNumbers", v); emit settingsChanged(); }
    bool editorWordWrap() const { return m_settings.value("editor/wordWrap", false).toBool(); }
    void setEditorWordWrap(bool v) { m_settings.setValue("editor/wordWrap", v); emit settingsChanged(); }
    bool editorAutocomplete() const { return m_settings.value("editor/autocomplete", true).toBool(); }
    void setEditorAutocomplete(bool v) { m_settings.setValue("editor/autocomplete", v); emit settingsChanged(); }
    bool editorVimMode() const { return m_settings.value("editor/vimMode", false).toBool(); }
    void setEditorVimMode(bool v) { m_settings.setValue("editor/vimMode", v); emit settingsChanged(); }

    // Data Grid
    int rowHeight() const { return m_settings.value("grid/rowHeight", 28).toInt(); }
    void setRowHeight(int v) { m_settings.setValue("grid/rowHeight", v); emit settingsChanged(); }
    bool alternateRows() const { return m_settings.value("grid/alternateRows", true).toBool(); }
    void setAlternateRows(bool v) { m_settings.setValue("grid/alternateRows", v); emit settingsChanged(); }
    int pageSize() const { return m_settings.value("grid/pageSize", 100).toInt(); }
    void setPageSize(int v) { m_settings.setValue("grid/pageSize", v); emit settingsChanged(); }
    QString nullDisplay() const { return m_settings.value("grid/nullDisplay", "NULL").toString(); }
    void setNullDisplay(const QString& v) { m_settings.setValue("grid/nullDisplay", v); emit settingsChanged(); }
    QString dateFormat() const { return m_settings.value("grid/dateFormat", "yyyy-MM-dd HH:mm:ss").toString(); }
    void setDateFormat(const QString& v) { m_settings.setValue("grid/dateFormat", v); emit settingsChanged(); }

    // AI
    QString aiProvider() const { return m_settings.value("ai/provider", "openai").toString(); }
    void setAiProvider(const QString& v) { m_settings.setValue("ai/provider", v); emit settingsChanged(); }
    QString aiApiKey() const { return m_settings.value("ai/apiKey", "").toString(); }
    void setAiApiKey(const QString& v) { m_settings.setValue("ai/apiKey", v); emit settingsChanged(); }
    QString aiModel() const { return m_settings.value("ai/model", "gpt-4o-mini").toString(); }
    void setAiModel(const QString& v) { m_settings.setValue("ai/model", v); emit settingsChanged(); }
    bool aiInlineSuggestions() const { return m_settings.value("ai/inlineSuggestions", false).toBool(); }
    void setAiInlineSuggestions(bool v) { m_settings.setValue("ai/inlineSuggestions", v); emit settingsChanged(); }

    // Reset all
    Q_INVOKABLE void resetAll() { m_settings.clear(); emit settingsChanged(); }

signals:
    void settingsChanged();

private:
    mutable QSettings m_settings;
};
