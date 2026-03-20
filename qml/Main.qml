import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

ApplicationWindow {
    id: root
    visible: true
    width: 1280; height: 800
    minimumWidth: 960; minimumHeight: 640
    title: "TableMax"
    color: Theme.bg

    property bool showSidebar: true
    property bool showInfoPanel: false
    property bool showFilterPanel: false
    property bool showHistoryPanel: false
    property bool showRowDetail: false
    property bool showSearchBar: false
    property bool executing: false
    property string currentTableName: ""

    // Active DB type helper
    property string activeDbType: {
        if (!connectionManager) return ""
        var c = connectionManager.get(connectionManager.activeIndex)
        return c ? (c.dbType || "") : ""
    }

    function toast(msg: string, type: string) : void { toastBar.show(msg, type || "info") }

    // Background Grid
    BlueprintGrid {
        anchors.fill: parent
        z: -1 
        gridOpacity: Theme.darkMode ? 0.2 : 0.4
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // â”€â”€ Left Sidebar â”€â”€
        Sidebar {
            id: sidebar
            Layout.preferredWidth: root.showSidebar ? 252 : 0
            Layout.fillHeight: true
            clip: true
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
        }

        // Dashed divider with crosshairs
        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            visible: root.showSidebar

            DashedLine { anchors.fill: parent; color: Theme.border }

            // Crosshairs at top and bottom of sidebar divider
            BlueprintCrosshair { 
                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: -size/2
            }
            BlueprintCrosshair { 
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: -size/2
            }
        }

        // â”€â”€ Main area â”€â”€
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            TabBar_ {}

            // â”€â”€ Breadcrumb Navigation â”€â”€
            BreadcrumbNav {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.minimumHeight: 32
                visible: databaseService && databaseService.connected && tabManager && tabManager.tabs.length > 0
                serverName: {
                    if (!connectionManager) return ""
                    var c = connectionManager.get(connectionManager.activeIndex)
                    return c ? (c.name || "Server") : "Server"
                }
                databaseName: { if (!connectionManager) return ""; var _c = connectionManager.get(connectionManager.activeIndex); return _c ? (_c.database || "") : "" }
                tableName: root.currentTableName
                dbType: activeDbType
                onDatabaseClicked: dbSwitcher.open()
            }

            // â”€â”€ Toolbar â”€â”€
            Toolbar {
                id: toolbar
                Layout.fillWidth: true
                visible: tabManager && tabManager.tabs.length > 0
                connected: databaseService ? databaseService.connected : false
                tabType: {
                    var t = tabManager && tabManager.tabs && tabManager.tabs.length > 0 ? tabManager.getTab(tabManager.currentIndex) : null
                    return (t && t.type === "table") ? "table" : "query"
                }
                connectionName: {
                    if (!connectionManager) return ""
                    var c = connectionManager.get(connectionManager.activeIndex)
                    return c ? (c.name || "Unnamed") : ""
                }
                dbType: activeDbType
                executing: root.executing
                hasChanges: changeTracker ? changeTracker.hasChanges : false
                canUndo: changeTracker ? changeTracker.canUndo : false
                canRedo: changeTracker ? changeTracker.canRedo : false
                filterActive: root.showFilterPanel
                filterCount: filterPanel ? filterPanel.filterCount : 0

                onExecuteQuery: {
                    if (!tabManager || tabManager.tabs.length === 0) return
                    var t = tabManager.getTab(tabManager.currentIndex)
                    if (t && t.content) {
                        root.executing = true
                        databaseService.executeQuery(t.content, function(ok, err) {
                            root.executing = false
                            if (!ok) root.toast("Error: " + err, "error")
                            else {
                                root.toast("Query executed", "success")
                                if (historyService) { var _conn = connectionManager ? connectionManager.get(connectionManager.activeIndex) : null; historyService.addEntry(t.content, _conn ? (_conn.database || _conn.name || "") : "", activeDbType, resultModel ? resultModel.totalRows : 0, 0.0, ok) }
                            }
                        })
                    }
                }
                onFormatQuery: root.toast("SQL formatted", "info")
                onSaveChanges: {
                    if (!changeTracker) return
                    var stmts = changeTracker.generateSQL()
                    if (stmts.length === 0) {
                        root.toast("No changes to save", "info")
                        return
                    }
                    var res = databaseService.executeBatch(stmts)
                    if (res.success) {
                        root.toast("Saved " + res.executed + " changes successfully", "success")
                        changeTracker.clear()
                    } else {
                        root.toast("Failed after " + res.executed + " queries: " + res.error, "error")
                    }
                }
                onDiscardChanges: {
                    if (changeTracker) changeTracker.clear()
                    root.toast("Changes discarded", "info")
                }
                onUndoAction: { if (changeTracker) changeTracker.undo() }
                onRedoAction: { if (changeTracker) changeTracker.redo() }
                onToggleHistory: root.showHistoryPanel = !root.showHistoryPanel
                onToggleFilter: root.showFilterPanel = !root.showFilterPanel
                onExportData: exportDialog.open()
                onImportData: importDialog.open()
                onShowShortcuts: shortcutsDialog.open()
                onToggleSettings: settingsDialog.open()
                onAddRow: {
                    if (!databaseService || !databaseService.connected || !root.currentTableName) {
                        root.toast("Select a table to add rows to", "warning"); return
                    }
                    var sc = databaseService.getTableSchema(root.currentTableName)
                    if (!sc || sc.length === 0) { root.toast("Cannot retrieve schema", "error"); return }
                    var npc = sc.filter(function(c) { return !c.primaryKey })
                    if (npc.length === 0) { root.toast("No editable columns", "warning"); return }
                    var colStr = npc.map(function(c) { return '"' + c.name + '"' }).join(", ")
                    var valStr = npc.map(function() { return "NULL" }).join(", ")
                    var isql = 'INSERT INTO "' + root.currentTableName + '" (' + colStr + ') VALUES (' + valStr + ');'
                    var ires = databaseService.executeBatch([isql])
                    if (ires.success) {
                        root.toast("Row inserted  double-click a cell to edit its value", "success")
                        databaseService.executeQuery('SELECT * FROM "' + root.currentTableName + '" LIMIT 500', resultModel)
                    } else { root.toast("Insert failed: " + ires.error, "error") }
                }
                onDeleteRows: {
                    if (!changeTracker || !changeTracker.hasChanges) {
                        root.toast("Right-click rows to mark for deletion first", "info"); return
                    }
                    var dstmts = changeTracker.generateSQL()
                    if (dstmts.length === 0) { root.toast("Nothing to delete", "info"); return }
                    var dr = databaseService.executeBatch(dstmts)
                    if (dr.success) {
                        root.toast("Deleted " + dr.executed + " row(s) successfully", "success")
                        changeTracker.clear()
                        databaseService.executeQuery('SELECT * FROM "' + root.currentTableName + '" LIMIT 500', resultModel)
                    } else { root.toast("Delete failed: " + dr.error, "error") }
                }
                onRefreshData: {
                    if (!databaseService || !databaseService.connected) { root.toast("Not connected", "warning"); return }
                    var rt = tabManager && tabManager.tabs.length > 0 ? tabManager.getTab(tabManager.currentIndex) : null
                    if (!rt || !rt.content) { root.toast("No active query to refresh", "info"); return }
                    var rr = databaseService.executeQuery(rt.content, resultModel)
                    if (rr.success) root.toast("Refreshed: " + rr.rowCount + " rows", "success")
                    else root.toast("Refresh error: " + rr.error, "error")
                }
            }

            // Content area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                WelcomeView {
                    anchors.fill: parent
                    visible: !tabManager || tabManager.tabs.length === 0
                }

                ColumnLayout {
                    anchors.fill: parent
                    visible: tabManager && tabManager.tabs.length > 0
                    spacing: 0

                    // Filter panel (collapsible)
                    FilterPanel {
                        id: filterPanel
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.showFilterPanel ? implicitHeight : 0
                        Layout.margins: root.showFilterPanel ? 8 : 0
                        visible: root.showFilterPanel
                        clip: true
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                        onFiltersApplied: function(where) {
                            root.toast(where ? "Filters applied" : "Filters cleared", "info")
                        }
                        onFiltersClosed: root.showFilterPanel = false
                    }

                    FlatResizable {
                        id: mainContentSplit
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: Qt.Vertical
                        splitPosition: 0.45

                        property bool isTableMode: {
                            var t = tabManager && tabManager.tabs && tabManager.tabs.length > 0 ? tabManager.getTab(tabManager.currentIndex) : null
                            return (t && t.type === "table")
                        }

                        firstVisible: !isTableMode
                        first: Component { QueryEditor { focus: !mainContentSplit.isTableMode } }
                        second: Component {
                            Item {
                                ColumnLayout {
                                    anchors.fill: parent; spacing: 0

                                    SearchFilterBar {
                                        id: searchBar
                                        Layout.fillWidth: true
                                        isOpen: root.showSearchBar
                                        resultModel: resultModel
                                        onClosed: root.showSearchBar = false
                                    }

                                    DataGrid {
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        visible: root.activeDbType !== "mongodb" && root.activeDbType !== "redis"
                                    }

                                    MongoDocumentView {
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        visible: root.activeDbType === "mongodb"
                                        resultModel: resultModel
                                        onToast: function(msg, type) { root.toast(msg, type) }
                                    }

                                    RedisKeyBrowser {
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        visible: root.activeDbType === "redis"
                                        resultModel: resultModel
                                        onToast: function(msg, type) { root.toast(msg, type) }
                                    }

                                    PaginationBar {
                                        Layout.fillWidth: true
                                        visible: resultModel && resultModel.totalRows > 0
                                        totalRows: resultModel ? resultModel.totalRows : 0
                                        pageSize: appSettings ? appSettings.pageSize : 100
                                        onPageChanged: function(page) { root.toast("Page " + (page + 1), "info") }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StatusBar {}
        }

        // â”€â”€ Right side panels â”€â”€
        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            visible: root.showInfoPanel || root.showHistoryPanel || root.showRowDetail

            DashedLine { anchors.fill: parent; color: Theme.border }

            BlueprintCrosshair { 
                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: -size/2
            }
            BlueprintCrosshair { 
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: -size/2
            }
        }

        // Info Panel
        InfoPanel {
            id: infoPanel
            Layout.preferredWidth: root.showInfoPanel ? 280 : 0
            Layout.fillHeight: true
            clip: true
            visible: root.showInfoPanel
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
            // Bindings
            tableName: root.currentTableName
            dbType: root.activeDbType
            rowCount: resultModel ? resultModel.totalRows : 0
            queryTime: databaseService ? databaseService.lastExecTime : 0
            schema: {
                if (!databaseService || !root.currentTableName) return []
                return databaseService.getTableSchema(root.currentTableName) || []
            }
        }

        // History Panel
        HistoryPanel {
            id: historyPanel
            Layout.preferredWidth: root.showHistoryPanel ? 320 : 0
            Layout.fillHeight: true
            clip: true
            visible: root.showHistoryPanel
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
            historyService: historyService
            onQuerySelected: function(query) {
                if (!tabManager || tabManager.tabs.length === 0) return
                var t = tabManager.getTab(tabManager.currentIndex)
                if (t) {
                    tabManager.updateContent(tabManager.currentIndex, query)
                }
                root.toast("Query loaded to editor", "success")
            }
            onClose: root.showHistoryPanel = false
        }

        // Row Detail Drawer
        RowDetailDrawer {
            id: rowDetail
            Layout.preferredWidth: root.showRowDetail ? 340 : 0
            Layout.fillHeight: true
            clip: true
            isOpen: root.showRowDetail
            resultModel: resultModel
            tableName: root.currentTableName
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
            onClosed: root.showRowDetail = false
            onRowDeleted: function(row) {
                if (changeTracker) {
                    var originalRow = []
                    for (var i = 0; i < resultModel.totalColumns; i++)
                        originalRow.push(resultModel.data(resultModel.index(row, i), 0))
                    changeTracker.recordRowDeletion(row, originalRow)
                }
                root.toast("Row marked for deletion", "info")
            }
        }
    }

    // â”€â”€ Dialogs â”€â”€
    ConnectionDialog { id: connDialog }
    FlatToast { id: toastBar }

    CreateTableDialog {
        id: createTableDialog
        onTableCreated: function(tName) {
            schemaService.refresh(databaseService)
            // Optionally auto-open the new table
            if (tabManager) {
                var sql = DB.buildSelectQuery(createTableDialog.dbType, tName)
                tabManager.addTab(tName, sql, "table")
                root.currentTableName = tName
                databaseService.executeQuery(sql, resultModel)
            }
        }
    }

    ExportDialog {
        id: exportDialog
        resultModel: null // Set when export is triggered
    }

    ImportDialog { id: importDialog }

    
    FlatDialog {
        id: tableStructureDialog
        dialogTitle: 'Table Structure'
        dialogDescription: 'View and alter table schema'
        width: 650; height: 500
        contentItem: TableStructureView {
            width: parent.width; height: parent.height - 40
            schemaService: schemaService
            tableName: tableStructureDialog.targetTable
            columns: {
                if (!databaseService || !tableStructureDialog.targetTable) return [];
                return databaseService.getTableSchema(tableStructureDialog.targetTable);
            }
            onClosed: tableStructureDialog.close()
            onDropColumnRequested: function(tName, cName) {
                var sql = DB.buildDropColumnSql(tName, cName, connectionManager.get(connectionManager.activeIndex).dbType);
                var res = databaseService.executeBatch([sql]);
                if (res.success) {
                    toast('Dropped column ' + cName, 'success');
                    tableStructureDialog.targetTable = '';
                    tableStructureDialog.targetTable = tName; // trigger bound UI update
                    schemaService.refresh(databaseService);
                } else {
                    toast('Error: ' + res.error, 'error');
                }
            }
        }
        property string targetTable: ''
        function view(tName) { targetTable = tName; open(); }
    }
    SettingsDialog {
        id: settingsDialog
        appSettings: appSettings
    }

    SQLPreviewDialog {
        id: sqlPreview
        changeTracker: changeTracker
        onConfirmed: {
            var stmts = sqlPreview.statements
            var res = databaseService.executeBatch(stmts)
            if (res.success) {
                root.toast("Saved " + res.executed + " changes successfully", "success")
                changeTracker.clear()
            } else {
                root.toast("Failed after " + res.executed + " queries: " + res.error, "error")
            }
        }
    }

    QuickSwitcher {
        id: quickSwitcher
        tables: databaseService && databaseService.connected ? databaseService.listTables() : []
        databases: databaseService && databaseService.connected ? databaseService.listDatabases() : []

        onTableSelected: function(name) {
            var sql = 'SELECT * FROM "' + name + '" LIMIT 100'
            tabManager.addTab(name, sql, "table")
            root.currentTableName = name
            if (databaseService && databaseService.connected) {
                var r = databaseService.executeQuery(sql, resultModel)
                if (r.success) root.toast(r.rowCount + " rows from " + name, "success")
                else root.toast("Error: " + r.error, "destructive")
            }
        }
        onDatabaseSelected: function(name) {
            databaseService.switchDatabase(name)
            root.toast("Switched to " + name, "success")
        }
        onActionTriggered: function(action) {
            if      (action === "newTab")       tabManager.addTab()
            else if (action === "toggleTheme")  Theme.toggleTheme()
            else if (action === "export")       exportDialog.open()
            else if (action === "import")       importDialog.open()
            else if (action === "settings")     settingsDialog.open()
            else if (action === "history")      root.showHistoryPanel = !root.showHistoryPanel
            else if (action === "toggleSidebar") root.showSidebar = !root.showSidebar
            else if (action === "createTable")  root.showCreateTableDialog()
        }
    }

    DatabaseSwitcher {
        id: dbSwitcher
        databases: databaseService && databaseService.connected ? databaseService.listDatabases() : []
        onDatabaseSelected: function(name) {
            databaseService.switchDatabase(name)
            root.toast("Switched to " + name, "success")
        }
    }

    // â”€â”€ Inline Cell Editor (overlay) â”€â”€
    CellEditor {
        id: cellEditor
        parent: Overlay.overlay
        onCommitted: function(row, col, value) {
            if (changeTracker) {
                var colName = resultModel ? resultModel.columnName(col) : ""
                var oldVal = resultModel ? resultModel.data(resultModel.index(row, col), 0) : ""
                changeTracker.recordCellEdit(row, col, colName, oldVal, value)
            }
        }
    }

    // â”€â”€ Keyboard Shortcuts Dialog â”€â”€
    FlatDialog {
        id: shortcutsDialog
        dialogTitle: "Keyboard Shortcuts"
        dialogDescription: "All available shortcuts"

        contentItem: Column {
            spacing: Theme.s2; width: 420

            Repeater {
                model: [
                    { keys: "Ctrl+N", desc: "New query tab" },
                    { keys: "Ctrl+W", desc: "Close current tab" },
                    { keys: "Ctrl+Enter", desc: "Execute query" },
                    { keys: "Ctrl+S", desc: "Save changes" },
                    { keys: "Ctrl+Z", desc: "Undo" },
                    { keys: "Ctrl+Y", desc: "Redo" },
                    { keys: "Ctrl+B", desc: "Toggle sidebar" },
                    { keys: "Ctrl+I", desc: "Toggle info panel" },
                    { keys: "Ctrl+H", desc: "Toggle history panel" },
                    { keys: "Ctrl+K", desc: "Quick switcher" },
                    { keys: "Ctrl+E", desc: "Export data" },
                    { keys: "Ctrl+Shift+I", desc: "Import SQL file" },
                    { keys: "Ctrl+F", desc: "Toggle filters" },
                    { keys: "Ctrl+T", desc: "Toggle dark/light theme" },
                    { keys: "Ctrl+,", desc: "Settings" },
                    { keys: "Ctrl+/", desc: "Show shortcuts" }
                ]

                Rectangle {
                    width: parent.width; height: 32; radius: Theme.r4
                    color: index % 2 === 0 ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02) : "transparent"

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                        Row {
                            spacing: Theme.s4; Layout.preferredWidth: 180
                            Repeater {
                                model: modelData.keys.split("+")
                                Rectangle {
                                    width: kbdT.implicitWidth + Theme.s12; height: 20; radius: Theme.r4
                                    color: Theme.bgSurface; border.width: 1; border.color: Theme.border
                                    Text {
                                        id: kbdT; anchors.centerIn: parent
                                        text: modelData; font.family: Theme.mono; font.pixelSize: Theme.t11; font.weight: Font.Medium
                                        color: Theme.fg
                                    }
                                }
                            }
                        }

                        Text {
                            text: modelData.desc; font.family: Theme.sans; font.pixelSize: Theme.t12
                            color: Theme.fgMuted; Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (tabManager && tabManager.tabs.length === 0) tabManager.addTab()
    }

    // â”€â”€ Shortcuts â”€â”€
    Shortcut { sequence: "Ctrl+N"; onActivated: tabManager.addTab() }
    Shortcut {
        sequence: "Ctrl+W"
        onActivated: {
            if (!tabManager || tabManager.tabs.length === 0) return
            tabManager.closeTab(tabManager.currentIndex)
        }
    }
    Shortcut { sequence: "Ctrl+B"; onActivated: root.showSidebar = !root.showSidebar }
    Shortcut { sequence: "Ctrl+I"; onActivated: root.showInfoPanel = !root.showInfoPanel }
    Shortcut { sequence: "Ctrl+H"; onActivated: root.showHistoryPanel = !root.showHistoryPanel }
    Shortcut { sequence: "Ctrl+K"; onActivated: quickSwitcher.open() }
    Shortcut { sequence: "Ctrl+E"; onActivated: exportDialog.open() }
    Shortcut { sequence: "Ctrl+Shift+I"; onActivated: importDialog.open() }
    Shortcut { sequence: "Ctrl+F"; onActivated: root.showFilterPanel = !root.showFilterPanel }
    Shortcut { sequence: "Ctrl+T"; onActivated: Theme.toggleTheme() }
    Shortcut { sequence: "Ctrl+/"; onActivated: shortcutsDialog.open() }
    Shortcut { sequence: "Ctrl+,"; onActivated: settingsDialog.open() }
    Shortcut { sequence: "Ctrl+S"; onActivated: {
        if (changeTracker && changeTracker.hasChanges) {
            var stmts = changeTracker.generateSQL()
            sqlPreview.showPreview(stmts)
        }
    }}
    Shortcut { sequence: "Ctrl+Z"; onActivated: { if (changeTracker) changeTracker.undo() } }
    Shortcut { sequence: "Ctrl+Y"; onActivated: { if (changeTracker) changeTracker.redo() } }
    Shortcut { sequence: "Ctrl+G"; onActivated: { root.showSearchBar = true } }
}


