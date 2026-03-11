#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>

#include "ConnectionManager.h"
#include "DatabaseService.h"
#include "TabManager.h"
#include "SchemaService.h"
#include "ThemeProvider.h"
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

    // Load QML
    engine.addImportPath("qrc:/");
    engine.loadFromModule("TableMax", "Main");

    return app.exec();
}
