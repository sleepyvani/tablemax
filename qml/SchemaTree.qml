import QtQuick
import QtQuick.Layouts

Rectangle {
    color: "transparent"

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
                            Text {
                                text: modelData.children ? modelData.children.length : ""
                                font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim
                                Layout.rightMargin: 4
                                visible: modelData.children && modelData.children.length > 0
                            }
                        }

                        MouseArea {
                            id: _ndMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                open = !open
                                // If it's a table (not database), execute SELECT * on click
                                if (modelData.type === "table" && databaseService && databaseService.connected) {
                                    var tableName = modelData.name
                                    var query = "SELECT * FROM \"" + tableName + "\" LIMIT 100"
                                    // Ensure we have a tab
                                    if (tabManager.tabs.length === 0) tabManager.addTab()
                                    tabManager.updateContent(tabManager.currentIndex, query)
                                    var res = databaseService.executeQuery(query, resultModel)
                                    if (res.success) {
                                        root.toast(res.rowCount + " rows from " + tableName, "success")
                                    } else {
                                        root.toast("Error: " + res.error, "error")
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

                                    // Type info for columns
                                    Text {
                                        visible: modelData.type === "column" && modelData.colType
                                        text: modelData.colType || ""
                                        font.family: Theme.mono; font.pixelSize: 9
                                        color: Theme.fgDim; opacity: 0.6
                                    }
                                }

                                MouseArea {
                                    id: _chMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.type === "table" && databaseService && databaseService.connected) {
                                            var tName = modelData.name
                                            var sql = "SELECT * FROM \"" + tName + "\" LIMIT 100"
                                            if (tabManager.tabs.length === 0) tabManager.addTab()
                                            tabManager.updateContent(tabManager.currentIndex, sql)
                                            var r = databaseService.executeQuery(sql, resultModel)
                                            if (r.success) {
                                                root.toast(r.rowCount + " rows from " + tName, "success")
                                            } else {
                                                root.toast("Error: " + r.error, "error")
                                            }
                                        } else if (modelData.type === "column") {
                                            // Double-click column → insert column name into editor
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
}
