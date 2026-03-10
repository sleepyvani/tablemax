# TableMax – Architecture & Development Guide

Native multi-database desktop client built with Qt6 QML + C++.

- Qt6 QML (GPU-rendered UI, shadcn-style)
- C++ (Backend + Core Engine)
- GPL v3 License

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Qt6 QML, shadcn-style custom controls |
| Backend | C++ (QObject classes, Qt Models) |
| Engine | C++ core (query engine, plugin loader, streaming) |
| Build | CMake, MSVC 2022 |

### Database Drivers

| Database | Driver |
|---|---|
| PostgreSQL | Qt SQL (QPSQL) + libpq |
| MySQL | Qt SQL (QMYSQL) + libmysqlclient |
| MariaDB | Qt SQL (QMYSQL) — compatible |
| SQLite | Qt SQL (QSQLITE) — built-in |
| SQL Server | Qt SQL (QODBC) + ODBC driver |
| Oracle | Qt SQL (QOCI) + OCI |
| Amazon Redshift | Qt SQL (QODBC) — PostgreSQL wire protocol |
| CockroachDB | Qt SQL (QPSQL) — PostgreSQL wire protocol |
| MongoDB | mongocxx (C++ driver) |
| Redis | hiredis (C driver) |
| Cassandra | cpp-driver (DataStax) |
| Gel (EdgeDB) | EdgeDB C/C++ client |

---

## Architecture

```
┌──────────────────────────────────────────┐
│         QML UI (shadcn-style)            │
│   GPU rendered · 60fps · dark theme      │
├──────────────────────────────────────────┤
│         C++ Backend (Qt QObject)         │
│   ConnectionManager · DatabaseService    │
│   TabManager · SchemaService             │
├──────────────────────────────────────────┤
│         C++ Core Engine                  │
│   QueryEngine · ResultStream · Plugins   │
├──────────────────────────────────────────┤
│         Database Drivers                 │
│   Qt SQL · mongocxx · hiredis · etc.     │
├──────────────────────────────────────────┤
│         Database Servers                 │
└──────────────────────────────────────────┘
```

Query Flow:

```
QML QueryEditor (user types SQL)
       ↓
C++ DatabaseService::executeQuery()
       ↓
Qt SQL / mongocxx / hiredis
       ↓
Database Server
       ↓
QueryResultModel (QAbstractTableModel)
       ↓
QML TableView (GPU rendered, virtual scroll)
```

No IPC. No webview. No bridge. Direct C++ calls.

---

## Project Structure

```
tablemax/
├── CMakeLists.txt
├── src/
│   ├── main.cpp
│   ├── ConnectionManager.h/.cpp
│   ├── DatabaseService.h/.cpp
│   ├── TabManager.h/.cpp
│   ├── SchemaService.h/.cpp
│   └── models/
│       ├── ConnectionModel.h
│       ├── QueryResultModel.h
│       └── SchemaTreeModel.h
├── qml/
│   ├── Main.qml
│   ├── Theme.qml
│   ├── components/
│   │   ├── Sidebar.qml
│   │   ├── ConnectionList.qml
│   │   ├── ConnectionDialog.qml
│   │   ├── SchemaTree.qml
│   │   ├── QueryEditor.qml
│   │   ├── QueryTabs.qml
│   │   ├── DataGrid.qml
│   │   ├── MongoDocView.qml
│   │   └── StatusBar.qml
│   └── controls/
│       ├── FlatButton.qml
│       ├── FlatInput.qml
│       ├── FlatSelect.qml
│       ├── FlatDialog.qml
│       ├── FlatTooltip.qml
│       ├── FlatBadge.qml
│       ├── FlatTabs.qml
│       └── FlatToast.qml
├── core/
│   ├── CMakeLists.txt
│   ├── include/
│   │   ├── engine.h
│   │   └── plugin_interface.h
│   └── src/
│       ├── query_engine.cpp
│       ├── plugin_loader.cpp
│       └── logger.cpp
├── plugins/
│   ├── postgres/
│   ├── mysql/
│   ├── sqlite/
│   ├── mongodb/
│   ├── redis/
│   ├── sqlserver/
│   ├── oracle/
│   ├── redshift/
│   ├── cockroachdb/
│   ├── cassandra/
│   ├── mariadb/
│   └── gel/
├── resources/
│   ├── icons/
│   └── fonts/
├── LICENSE
└── README.md
```

---

## Backend Classes

### ConnectionManager

```cpp
class ConnectionManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList connections READ connections NOTIFY connectionsChanged)
    Q_PROPERTY(QString activeConnectionId READ activeConnectionId NOTIFY activeChanged)

public:
    Q_INVOKABLE void addConnection(const QVariantMap& conn);
    Q_INVOKABLE void removeConnection(const QString& id);
    Q_INVOKABLE void updateConnection(const QVariantMap& conn);
    Q_INVOKABLE void connectToDatabase(const QString& id);
    Q_INVOKABLE void disconnectFromDatabase(const QString& id);
    Q_INVOKABLE QVariantMap testConnection(const QVariantMap& conn);

signals:
    void connectionsChanged();
    void activeChanged();
    void connectionError(const QString& error);
};
```

### DatabaseService

```cpp
class DatabaseService : public QObject {
    Q_OBJECT
    Q_PROPERTY(QueryResultModel* resultModel READ resultModel NOTIFY resultChanged)
    Q_PROPERTY(bool isExecuting READ isExecuting NOTIFY executingChanged)

public:
    Q_INVOKABLE void executeQuery(const QString& query);
    Q_INVOKABLE QStringList listDatabases();
    Q_INVOKABLE QStringList listTables(const QString& database);
    Q_INVOKABLE QStringList listCollections(const QString& database);

    // MongoDB specific
    Q_INVOKABLE void mongoInsert(const QString& collection, const QString& json);
    Q_INVOKABLE void mongoUpdate(const QString& collection, const QString& filter, const QString& update);
    Q_INVOKABLE void mongoDelete(const QString& collection, const QString& filter);

signals:
    void resultChanged();
    void executingChanged();
    void queryFinished(int rowCount, int elapsedMs);
    void queryError(const QString& error);
};
```

### Models

```cpp
// SQL result grid
class QueryResultModel : public QAbstractTableModel { ... };

// Connection list
class ConnectionModel : public QAbstractListModel { ... };

// Schema tree (Database → Table → Column)
class SchemaTreeModel : public QAbstractItemModel { ... };
```

---

## QML UI — shadcn Style

### Theme System

```qml
pragma Singleton
QtObject {
    // Colors (shadcn dark theme)
    readonly property color background: "#09090b"
    readonly property color card: "#0c0c10"
    readonly property color popover: "#111116"
    readonly property color border: "#27272a"
    readonly property color input: "#27272a"
    readonly property color primary: "#fafafa"
    readonly property color primaryForeground: "#18181b"
    readonly property color secondary: "#27272a"
    readonly property color muted: "#27272a"
    readonly property color mutedForeground: "#a1a1aa"
    readonly property color accent: "#27272a"
    readonly property color destructive: "#ef4444"
    readonly property color ring: "#d4d4d8"

    // Radius
    readonly property real radiusSm: 4
    readonly property real radius: 6
    readonly property real radiusMd: 8
    readonly property real radiusLg: 12

    // Fonts
    readonly property string fontFamily: "Inter"
    readonly property string monoFamily: "JetBrains Mono"
}
```

### UI Layout

```
┌───────────┬───────────────────────────────┐
│           │      Top Bar                  │
│           ├───────────────────────────────┤
│  Sidebar  │      Query Tabs              │
│  (220px)  ├───────────────────────────────┤
│           │      Query Editor            │
│  - Conns  ├───────────────────────────────┤
│  - Schema │      DataGrid / MongoView    │
│           ├───────────────────────────────┤
│           │      Status Bar              │
└───────────┴───────────────────────────────┘
```

### Data Grid

QML `TableView` with:
- Native virtual scrolling (built-in)
- `QueryResultModel` backing (C++ QAbstractTableModel)
- Column resize, sort, selection
- Cell type detection (null, number, date, JSON, ObjectId)
- 10M+ rows at 60fps

---

## Performance Targets

| Metric | Target |
|---|---|
| Startup RAM | 15–30 MB |
| Startup time | < 500ms |
| App binary | < 30 MB |
| Scroll 10M rows | 60fps |
| Query execution | Native driver speed |

---

## Engineering Rules

1. Never load full result sets. Always stream in chunks.
2. UI must not contain database logic. All DB logic in C++ backend.
3. Each database driver is isolated.
4. All state exposed to QML via Q_PROPERTY + NOTIFY.
5. Theme defined once in Theme.qml. No hardcoded colors.
6. Custom controls follow shadcn design language: muted borders, subtle hover, rounded corners, Inter font.

---

## Roadmap

- [x] C++ core engine + plugin system
- [ ] Qt6 project setup + CMake
- [ ] ConnectionManager + persistence
- [ ] Main window + shadcn theme
- [ ] shadcn-style control library
- [ ] Connection form dialog
- [ ] Schema tree
- [ ] Query editor + tabs
- [ ] SQL execution + DataGrid
- [ ] MongoDB support
- [ ] Redis support
- [ ] SQL Server / Oracle / Redshift support
- [ ] CockroachDB / MariaDB support
- [ ] Cassandra / Gel support
- [ ] Syntax highlighting
- [ ] Query history + saved queries
- [ ] AI SQL assistant
- [ ] Cross-platform (macOS, Linux)