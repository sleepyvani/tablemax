import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "DbHelper.js" as DB
import "Icons.js" as Icons

Rectangle {
    color: "transparent"

    // Active DB type helper
    property string _dbType: {
        if (!connectionManager) return ""
        var c = connectionManager.get(connectionManager.activeIndex)
        return c ? (c.dbType || "") : ""
    }

    // Helper: choose icon for node type
    function nodeIcon(type) {
        if (type === "database") return Icons.database
        if (type === "table")   return Icons.table
        if (type === "column")  return Icons.column
        return Icons.folder
    }

    // Helper: choose color for node type
    function nodeColor(type) {
        if (type === "database") return Theme.info
        if (type === "table")   return Theme.synKeyword
        return Theme.fgDim
    }

    // ── Loading indicator ──
    Rectangle {
        anchors.top: parent.top; width: parent.width; height: 2
        color: "transparent"; clip: true; visible: schemaService && schemaService.loading
        z: 10

        Rectangle {
            id: _schemaLoadBar
            width: parent.width * 0.3; height: 2; radius: 1
            color: Theme.accent

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: schemaService && schemaService.loading
                NumberAnimation { from: -_schemaLoadBar.width; to: _schemaLoadBar.parent.width; duration: 1000; easing.type: Easing.InOutQuad }
            }
        }
    }

    FlatScrollArea {
        anchors.fill: parent

        ColumnLayout {
            width: parent.width; spacing: 0

            Repeater {
                model: schemaService ? schemaService.tree : []

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    property bool open: true

                    // ── Parent node (database / schema) ──
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 26
                        color: _ndMa.containsMouse ? Theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.s6; anchors.rightMargin: Theme.s8
                            spacing: Theme.s4

                            // Chevron
                            FlatIcon {
                                icon: open ? Icons.down : Icons.right
                                size: 8; color: Theme.fgDim
                                Layout.preferredWidth: 12
                            }

                            // Node icon
                            FlatIcon {
                                icon: nodeIcon(modelData.type)
                                size: 13; color: nodeColor(modelData.type)
                            }

                            // Name
                            Text {
                                text: modelData.name || ""
                                font.family: Theme.sans; font.pixelSize: Theme.t12
                                font.weight: Font.DemiBold
                                color: Theme.fg; elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Children count
                            Text {
                                visible: modelData.children && modelData.children.length > 0
                                text: modelData.children ? modelData.children.length : ""
                                font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim; opacity: 0.4
                            }
                        }

                        MouseArea {
                            id: _ndMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    _treeCtx.nodeName = modelData.name || ""
                                    _treeCtx.nodeType = modelData.type || ""
                                    _treeCtx.x = mouse.x; _treeCtx.y = mouse.y
                                    _treeCtx.open()
                                    return
                                }
                                // Database/schema nodes → toggle only
                                if (modelData.type === "database") {
                                    open = !open
                                    return
                                }
                                // Table/collection → toggle expand + auto-execute query
                                open = !open
                                if (modelData.type === "table" && databaseService && databaseService.connected) {
                                    var entityName = modelData.name
                                    var query = DB.buildSelectQuery(_dbType, entityName)
                                    tabManager.addTab(entityName, query, "table")
                                    root.currentTableName = entityName
                                    
                                    // Trigger execution
                                    var res = databaseService.executeQuery(query, resultModel)
                                    if (res.success) {
                                        root.toast(res.rowCount + " rows from " + entityName, "success")
                                    } else {
                                        root.toast("Error: " + res.error, "destructive")
                                    }
                                }
                            }
                        }
                    }

                    // ── Children (tables under database, or columns under table) ──
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        visible: open; clip: true

                        Repeater {
                            model: modelData.children || []

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 24
                                color: _chMa.containsMouse ? Theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.fast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 28; anchors.rightMargin: Theme.s8
                                    spacing: Theme.s4

                                    // Node icon — tables get table icon, columns get column icon
                                    FlatIcon {
                                        icon: nodeIcon(modelData.type)
                                        size: 11
                                        color: nodeColor(modelData.type)
                                        opacity: 0.7
                                    }

                                    // Name
                                    Text {
                                        text: modelData.name || ""
                                        font.family: Theme.sans; font.pixelSize: Theme.t11
                                        color: Theme.fg; opacity: 0.85
                                        elide: Text.ElideRight; Layout.fillWidth: true
                                    }

                                    // Column type (right-aligned, muted)
                                    Text {
                                        visible: modelData.type === "column" && (modelData.colType || "").length > 0
                                        text: modelData.colType || ""
                                        font.family: Theme.mono; font.pixelSize: 9
                                        color: Theme.fgDim; opacity: 0.4
                                    }

                                    // Primary key icon
                                    FlatIcon {
                                        visible: modelData.primaryKey === true
                                        icon: Icons.key; size: 9; color: Theme.warning; opacity: 0.7
                                    }
                                }

                                MouseArea {
                                    id: _chMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            _treeCtx.nodeName = modelData.name || ""
                                            _treeCtx.nodeType = modelData.type || ""
                                            _treeCtx.x = mouse.x; _treeCtx.y = mouse.y
                                            _treeCtx.open()
                                            return
                                        }
                                        // Click table → auto-execute query immediately (MongoDB Compass style)
                                        if (modelData.type === "table" && databaseService && databaseService.connected) {
                                            var tName = modelData.name
                                            var sql = DB.buildSelectQuery(_dbType, tName)
                                            tabManager.addTab(tName, sql, "table")
                                            root.currentTableName = tName
                                            
                                            // Trigger execution
                                            var r = databaseService.executeQuery(sql, resultModel)
                                            if (r.success) {
                                                root.toast(r.rowCount + " rows from " + tName, "success")
                                            } else {
                                                root.toast("Error: " + r.error, "destructive")
                                            }
                                        } else if (modelData.type === "column") {
                                            // Click column → insert name into editor
                                            if (tabManager && tabManager.tabs.length > 0) {
                                                var t = tabManager.getTab(tabManager.currentIndex)
                                                tabManager.updateContent(tabManager.currentIndex,
                                                    (t.content || "") + modelData.name + " ")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Empty state ──
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 72
                visible: !schemaService || schemaService.tree.length === 0

                Column {
                    anchors.centerIn: parent; spacing: Theme.s6

                    FlatIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: databaseService && databaseService.connected ? Icons.table : Icons.database
                        size: 20; color: Theme.fgDim; opacity: 0.3
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: databaseService && databaseService.connected
                            ? "No " + DB.tableLabel(_dbType).toLowerCase() + " found"
                            : "Not connected"
                        font.family: Theme.sans; font.pixelSize: Theme.t11; color: Theme.fgDim; opacity: 0.4
                    }
                }
            }
        }
    }

    // ── Context Menu — DB-aware ──
    FlatContextMenu {
        id: _treeCtx
        property string nodeName: ""
        property string nodeType: ""

        menuModel: {
            if (nodeType === "table") {
                var selectLabel = DB.isRedis(_dbType) ? "GET Key" : DB.isMongo(_dbType) ? "Find Documents" : "SELECT TOP 100"
                var copyLabel = DB.isMongo(_dbType) ? "Copy Collection Name" : DB.isRedis(_dbType) ? "Copy Key Name" : "Copy Table Name"
                return [selectLabel, copyLabel, "-", "View Schema"]
            }
            if (nodeType === "column") {
                var colCopyLabel = DB.isMongo(_dbType) ? "Copy Field Name" : "Copy Column Name"
                return [colCopyLabel, "Insert into Query"]
            }
            if (nodeType === "database") return ["Copy Database Name"]
            return []
        }

        onMenuItemClicked: function(idx, text) {
            if (text.indexOf("Copy") === 0) {
                _clipHelper.text = nodeName; _clipHelper.selectAll(); _clipHelper.copy()
                root.toast("Copied: " + nodeName, "success")
            } else if (idx === 0 && nodeType === "table" && databaseService && databaseService.connected) {
                var sql = DB.buildSelectQuery(_dbType, nodeName)
                tabManager.addTab(nodeName, sql, "table")
                root.currentTableName = nodeName
                var r = databaseService.executeQuery(sql, resultModel)
                if (r.success) root.toast(r.rowCount + " rows from " + nodeName, "success")
                else root.toast("Error: " + r.error, "destructive")
            } else if (text === "Insert into Query") {
                if (tabManager && tabManager.tabs.length > 0) {
                    var t = tabManager.getTab(tabManager.currentIndex)
                    tabManager.updateContent(tabManager.currentIndex, (t.content || "") + nodeName + " ")
                }
            } else if (text === "View Schema") {
                var cols = databaseService.getTableSchema(nodeName)
                if (cols && cols.length > 0) {
                    var info = cols.map(function(c) { return c.name + " " + c.type }).join("\n")
                    if (tabManager.tabs.length === 0) tabManager.addTab()
                    tabManager.updateContent(tabManager.currentIndex, "-- Schema: " + nodeName + "\n-- " + info.replace(/\n/g, "\n-- "))
                }
            }
        }
    }

    TextEdit { id: _clipHelper; visible: false }
}
