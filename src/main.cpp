#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QFontDatabase>

#include "ConnectionManager.h"
#include "DatabaseService.h"
#include "TabManager.h"
#include "SchemaService.h"
#include "ThemeProvider.h"
#include "SyntaxHighlighter.h"
#include "ChangeTracker.h"
#include "HistoryService.h"
#include "AppSettings.h"
#include "models/QueryResultModel.h"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("TableMax");
    app.setOrganizationName("VaniStudio");
    app.setApplicationVersion("0.2.0");

    // Backend services
    ConnectionManager connectionManager;
    DatabaseService databaseService;
    TabManager tabManager;
    SchemaService schemaService;
    QueryResultModel resultModel;
    ThemeProvider theme;
    SyntaxHighlighter syntaxHighlighter;
    syntaxHighlighter.setTheme(&theme);
    ChangeTracker changeTracker;
    HistoryService historyService;
    AppSettings appSettings;

    // Auto-load database plugins from app directory
    QString pluginDir = QCoreApplication::applicationDirPath();
    databaseService.loadPlugins(pluginDir);
    qDebug() << "Loaded plugins from:" << pluginDir;

    // Load bundled icon font
    int fontId = QFontDatabase::addApplicationFont(":/resources/fonts/Phosphor.ttf");
    if (fontId < 0)
        qWarning() << "Failed to load Phosphor icon font";
    else
        qDebug() << "Loaded Phosphor Icons:" << QFontDatabase::applicationFontFamilies(fontId);

    // QML engine
    QQmlApplicationEngine engine;

    // Expose to QML
    auto* ctx = engine.rootContext();
    ctx->setContextProperty("connectionManager", &connectionManager);
    ctx->setContextProperty("databaseService", &databaseService);
    ctx->setContextProperty("tabManager", &tabManager);
    ctx->setContextProperty("schemaService", &schemaService);
    ctx->setContextProperty("resultModel", &resultModel);
    ctx->setContextProperty("Theme", &theme);
    ctx->setContextProperty("syntaxHighlighter", &syntaxHighlighter);
    ctx->setContextProperty("changeTracker", &changeTracker);
    ctx->setContextProperty("historyService", &historyService);
    ctx->setContextProperty("appSettings", &appSettings);

    // Load QML
    engine.addImportPath("qrc:/");
    engine.loadFromModule("TableMax", "Main");

    return app.exec();
}
