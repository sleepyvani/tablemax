import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    color: "transparent"

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

                    // ── Parent node (database or table) ──
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 28
                        color: _ndMa.containsMouse ? Theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10; anchors.rightMargin: 8
                            spacing: 6

                            // Chevron
                            Text {
                                text: open ? "▾" : "▸"
                                font.pixelSize: 8; color: Theme.fgDim
                                Layout.preferredWidth: 10

                                Behavior on text { enabled: false }
                                rotation: open ? 0 : -90
                            }

                            // Type badge
                            Rectangle {
                                width: 16; height: 16; radius: 4
                                color: Qt.rgba(
                                    modelData.type === "database" ? Theme.info.r : Theme.synKeyword.r,
                                    modelData.type === "database" ? Theme.info.g : Theme.synKeyword.g,
                                    modelData.type === "database" ? Theme.info.b : Theme.synKeyword.b,
                                    0.12
                                )
                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.mono; font.pixelSize: 8; font.weight: Font.Bold
                                    text: modelData.type === "database" ? "D" : "T"
                                    color: modelData.type === "database" ? Theme.info : Theme.synKeyword
                                }
                            }

                            // Name
                            Text {
                                text: modelData.name || ""
                                font.family: Theme.sans; font.pixelSize: 12
                                color: Theme.fg; elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Children count
                            Rectangle {
                                height: 14; width: _cntText.implicitWidth + 8; radius: Theme.rFull
                                color: Theme.bgSurface
                                visible: modelData.children && modelData.children.length > 0

                                Text {
                                    id: _cntText
                                    anchors.centerIn: parent
                                    text: modelData.children ? modelData.children.length : ""
                                    font.family: Theme.mono; font.pixelSize: 8; color: Theme.fgDim
                                }
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
                                open = !open
                                // If it's a table, execute SELECT * on click
                                if (modelData.type === "table" && databaseService && databaseService.connected) {
                                    var tableName = modelData.name
                                    var query = "SELECT * FROM \"" + tableName + "\" LIMIT 100"
                                    if (tabManager.tabs.length === 0) tabManager.addTab()
                                    tabManager.updateContent(tabManager.currentIndex, query)
                                    var res = databaseService.executeQuery(query, resultModel)
                                    if (res.success) {
                                        root.toast(res.rowCount + " rows from " + tableName, "success")
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
                                Layout.fillWidth: true; Layout.preferredHeight: 26
                                color: _chMa.containsMouse ? Theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 32; anchors.rightMargin: 8
                                    spacing: 6

                                    // Icon
                                    Rectangle {
                                        width: 14; height: 14; radius: 3
                                        color: Qt.rgba(
                                            modelData.type === "table" ? Theme.synKeyword.r : Theme.fgDim.r,
                                            modelData.type === "table" ? Theme.synKeyword.g : Theme.fgDim.g,
                                            modelData.type === "table" ? Theme.synKeyword.b : Theme.fgDim.b,
                                            0.1
                                        )
                                        border.width: 1
                                        border.color: Qt.rgba(
                                            modelData.type === "table" ? Theme.synKeyword.r : Theme.fgDim.r,
                                            modelData.type === "table" ? Theme.synKeyword.g : Theme.fgDim.g,
                                            modelData.type === "table" ? Theme.synKeyword.b : Theme.fgDim.b,
                                            0.2
                                        )
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.type === "table" ? "T"
                                                : modelData.type === "column" ? "C" : "·"
                                            font.family: Theme.mono; font.pixelSize: 7; font.weight: Font.Bold
                                            color: modelData.type === "table" ? Theme.synKeyword : Theme.fgDim
                                        }
                                    }

                                    // Name
                                    Text {
                                        text: modelData.name || ""
                                        font.family: Theme.sans; font.pixelSize: 11
                                        color: Theme.fg; opacity: 0.85
                                        elide: Text.ElideRight; Layout.fillWidth: true
                                    }

                                    // Type info for columns — use colType field
                                    Rectangle {
                                        visible: modelData.type === "column" && (modelData.colType || "").length > 0
                                        height: 14; width: _colTypeText.implicitWidth + 8; radius: Theme.r4
                                        color: Qt.rgba(Theme.fgDim.r, Theme.fgDim.g, Theme.fgDim.b, 0.08)

                                        Text {
                                            id: _colTypeText
                                            anchors.centerIn: parent
                                            text: modelData.colType || ""
                                            font.family: Theme.mono; font.pixelSize: 8
                                            color: Theme.fgDim
                                        }
                                    }

                                    // Primary key indicator
                                    Text {
                                        visible: modelData.primaryKey === true
                                        text: "🔑"; font.pixelSize: 9
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
                                        if (modelData.type === "table" && databaseService && databaseService.connected) {
                                            var tName = modelData.name
                                            var sql = "SELECT * FROM \"" + tName + "\" LIMIT 100"
                                            if (tabManager.tabs.length === 0) tabManager.addTab()
                                            tabManager.updateContent(tabManager.currentIndex, sql)
                                            var r = databaseService.executeQuery(sql, resultModel)
                                            if (r.success) {
                                                root.toast(r.rowCount + " rows from " + tName, "success")
                                            } else {
                                                root.toast("Error: " + r.error, "destructive")
                                            }
                                        } else if (modelData.type === "column") {
                                            // Click column → insert column name into editor
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
                    anchors.centerIn: parent; spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: databaseService && databaseService.connected ? "Empty schema" : "Not connected"
                        font.family: Theme.sans; font.pixelSize: 12; color: Theme.fgDim
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: databaseService && databaseService.connected
                            ? "No tables found" : "Connect to a database to explore"
                        font.family: Theme.sans; font.pixelSize: 10; color: Theme.fgDim; opacity: 0.5
                    }
                }
            }
        }
    }

    // ── Context Menu ──
    FlatContextMenu {
        id: _treeCtx
        property string nodeName: ""
        property string nodeType: ""

        menuModel: {
            if (nodeType === "table") return ["SELECT TOP 100", "Copy Table Name", "-", "View Schema"]
            if (nodeType === "column") return ["Copy Column Name", "Insert into Query"]
            if (nodeType === "database") return ["Copy Database Name"]
            return []
        }

        onMenuItemClicked: function(idx, text) {
            if (text === "Copy Table Name" || text === "Copy Column Name" || text === "Copy Database Name") {
                _clipHelper.text = nodeName; _clipHelper.selectAll(); _clipHelper.copy()
                root.toast("Copied: " + nodeName, "success")
            } else if (text === "SELECT TOP 100" && databaseService && databaseService.connected) {
                var sql = "SELECT * FROM \"" + nodeName + "\" LIMIT 100"
                if (tabManager.tabs.length === 0) tabManager.addTab()
                tabManager.updateContent(tabManager.currentIndex, sql)
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
