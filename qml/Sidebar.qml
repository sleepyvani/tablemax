import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: sidebar
    color: Theme.bgSidebar

    // ── Clipboard helper ──
    TextEdit { id: _clip; visible: false }

    // ── Auto-refresh schema on connect ──
    Connections {
        target: databaseService
        function onConnectedChanged() {
            if (databaseService.connected)
                schemaService.refresh(databaseService)
        }
    }

    // ════════════════════════════════════════════
    //  LAYOUT
    // ════════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        spacing: 0

        // ── Brand Bar ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                // Logo
                Rectangle {
                    width: 26; height: 26; radius: 8
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#6366f1" }
                        GradientStop { position: 1.0; color: "#8b5cf6" }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "T"; font.pixelSize: 13; font.weight: Font.Bold
                        font.family: Theme.sans; color: "#ffffff"
                    }
                }

                // App name
                Text {
                    Layout.fillWidth: true
                    text: "TableMax"
                    font.family: Theme.sans; font.pixelSize: 14; font.weight: Font.DemiBold
                    color: Theme.fg; font.letterSpacing: -0.3
                }

                // Theme
                Rectangle {
                    width: 28; height: 28; radius: 6
                    color: _themeMa.containsMouse ? Theme.bgHover : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: Theme.darkMode ? "◑" : "○"
                        font.pixelSize: 14; color: Theme.fgMuted
                    }
                    MouseArea {
                        id: _themeMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.toggleTheme()
                    }
                }

                // New connection
                Rectangle {
                    width: 28; height: 28; radius: 6
                    color: _addMa.containsMouse
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : "transparent"
                    border.width: _addMa.containsMouse ? 1 : 0
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Text {
                        anchors.centerIn: parent
                        text: "+"; font.pixelSize: 16; font.weight: Font.Medium
                        color: _addMa.containsMouse ? Theme.accent : Theme.fgMuted
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id: _addMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: connDialog.open()
                    }
                }
            }
        }

        // ── Thin separator ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        // ── Search ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.leftMargin: 10; Layout.rightMargin: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 32
                radius: 8; color: Theme.bgSurface
                border.width: 1
                border.color: _search.activeFocus
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
                    : Theme.border
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                    spacing: 8

                    // Search icon
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌕"; font.pixelSize: 13; color: Theme.fgDim
                    }

                    TextInput {
                        id: _search
                        width: parent.width - 46
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.sans; font.pixelSize: 12; color: Theme.fg
                        selectByMouse: true; clip: true
                        focus: false

                        Text {
                            visible: !_search.text && !_search.activeFocus
                            text: "Search…"
                            font: parent.font; color: Theme.fgDim
                        }

                        Keys.onEscapePressed: { _search.text = ""; sidebar.forceActiveFocus() }
                    }

                    // Shortcut badge
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !_search.activeFocus && !_search.text
                        width: 20; height: 18; radius: 4
                        color: "transparent"
                        border.width: 1; border.color: Theme.border

                        Text {
                            anchors.centerIn: parent; text: "/"
                            font.family: Theme.mono; font.pixelSize: 10; color: Theme.fgDim
                        }
                    }
                }
            }
        }

        // ── Connections Section ──
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 28
            Layout.leftMargin: 14

            Row {
                anchors.verticalCenter: parent.verticalCenter; spacing: 6

                Text {
                    text: "CONNECTIONS"
                    font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.DemiBold
                    font.letterSpacing: 1.0; color: Theme.fgDim; opacity: 0.7
                }

                // Count badge
                Rectangle {
                    visible: connectionManager && connectionManager.connections.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: _countTxt.implicitWidth + 10; height: 16; radius: 8
                    color: Theme.bgSurface

                    Text {
                        id: _countTxt
                        anchors.centerIn: parent
                        text: connectionManager ? connectionManager.connections.length : "0"
                        font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim
                    }
                }
            }
        }

        // ── Connection List ──
        ListView {
            id: _connList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight + 4, sidebar.height * 0.42)
            Layout.minimumHeight: 52
            clip: true; spacing: 2
            boundsBehavior: Flickable.StopAtBounds

            model: {
                if (!connectionManager) return []
                var all = connectionManager.connections
                if (!_search.text) return all
                var q = _search.text.toLowerCase()
                return all.filter(function(c) {
                    return (c.name || "").toLowerCase().indexOf(q) >= 0 ||
                           (c.dbType || "").toLowerCase().indexOf(q) >= 0
                })
            }

            delegate: Item {
                width: _connList.width; height: 38

                Rectangle {
                    id: _row
                    anchors.fill: parent
                    anchors.leftMargin: 6; anchors.rightMargin: 6
                    radius: 6

                    property bool active: connectionManager.activeIndex === index
                    property bool hovered: _rowMa.containsMouse

                    color: active
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                        : hovered ? Theme.bgHover : "transparent"

                    border.width: active ? 1 : 0
                    border.color: active
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : "transparent"

                    Behavior on color { ColorAnimation { duration: 80 } }

                    // Left accent bar
                    Rectangle {
                        visible: _row.active
                        width: 3; height: 16; radius: 2
                        anchors.left: parent.left; anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.accent
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: _row.active ? 12 : 10
                        anchors.rightMargin: 8
                        spacing: 8

                        // DB icon
                        Image {
                            Layout.preferredWidth: 16; Layout.preferredHeight: 16
                            source: "qrc:/TableMax/icons/" + (modelData.dbType || "postgres").toLowerCase() + ".svg"
                            sourceSize: Qt.size(16, 16)
                            fillMode: Image.PreserveAspectFit
                            opacity: _row.active ? 1.0 : _row.hovered ? 0.8 : 0.5
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                        }

                        // Name + type
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0

                            Text {
                                text: modelData.name || "Untitled"
                                font.family: Theme.sans; font.pixelSize: 12
                                font.weight: _row.active ? Font.DemiBold : Font.Normal
                                color: Theme.fg; elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: (modelData.dbType || "").charAt(0).toUpperCase() +
                                      (modelData.dbType || "").slice(1)
                                font.family: Theme.mono; font.pixelSize: 9
                                color: Theme.fgDim
                            }
                        }

                        // Connected indicator
                        Rectangle {
                            visible: _row.active && databaseService.connected
                            width: 7; height: 7; radius: 4
                            color: Theme.success
                        }

                        // Delete on hover
                        Item {
                            visible: _row.hovered && !_row.active
                            Layout.preferredWidth: 20; Layout.preferredHeight: 20

                            Rectangle {
                                anchors.fill: parent; radius: 4
                                color: _delMa.containsMouse
                                    ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                            }
                            Text {
                                anchors.centerIn: parent; text: "×"
                                font.pixelSize: 13; color: _delMa.containsMouse ? Theme.error : Theme.fgDim
                            }
                            MouseArea {
                                id: _delMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: connectionManager.remove(index)
                            }
                        }
                    }

                    // Click handler
                    MouseArea {
                        id: _rowMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        z: -1
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            sidebar.forceActiveFocus()
                            if (mouse.button === Qt.RightButton) {
                                _ctx.connIdx = index
                                _ctx.x = mouse.x; _ctx.y = mouse.y
                                _ctx.open()
                            } else {
                                connectionManager.activeIndex = index
                                databaseService.connect(modelData.dbType, modelData.connectionString)
                            }
                        }
                    }

                    // Context menu
                    FlatContextMenu {
                        id: _ctx
                        property int connIdx: -1
                        menuModel: ["Connect", "Edit", "-", "Copy Connection String", "Duplicate", "-", "Delete"]
                        onMenuItemClicked: function(idx, label) {
                            var ci = _ctx.connIdx
                            if (label === "Connect") {
                                connectionManager.activeIndex = ci
                                var c = connectionManager.get(ci)
                                databaseService.connect(c.dbType, c.connectionString)
                            } else if (label === "Edit") {
                                connDialog.editIdx = ci; connDialog.open()
                            } else if (label === "Copy Connection String") {
                                var cc = connectionManager.get(ci)
                                if (cc) { _clip.text = cc.connectionString || ""; _clip.selectAll(); _clip.copy() }
                            } else if (label === "Duplicate") {
                                var dc = connectionManager.get(ci)
                                if (dc) connectionManager.add({
                                    name: (dc.name || "Untitled") + " (copy)",
                                    dbType: dc.dbType, connectionString: dc.connectionString, color: dc.color
                                })
                            } else if (label === "Delete") {
                                connectionManager.remove(ci)
                            }
                        }
                    }
                }
            }

            // Empty state
            footer: Item {
                width: _connList.width; height: 72
                visible: !connectionManager || connectionManager.connections.length === 0

                Column {
                    anchors.centerIn: parent; spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No connections yet"
                        font.family: Theme.sans; font.pixelSize: 12; color: Theme.fgDim
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: _emptyTxt.implicitWidth + 20; height: 26; radius: 6
                        color: "transparent"; border.width: 1; border.color: Theme.border

                        Row {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "+"; font.pixelSize: 12; color: Theme.fgDim }
                            Text {
                                id: _emptyTxt; text: "Add Connection"
                                font.family: Theme.sans; font.pixelSize: 11; color: Theme.fgDim
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: connDialog.open()
                        }
                    }
                }
            }
        }

        // ── Separator ──
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        // ── Schema Section Header ──
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 28
            Layout.leftMargin: 14; Layout.rightMargin: 10

            Row {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; spacing: 6

                Text {
                    text: "EXPLORER"
                    font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.DemiBold
                    font.letterSpacing: 1.0; color: Theme.fgDim; opacity: 0.7
                }

                Item { width: parent.width - 80; height: 1 }

                // Refresh
                Rectangle {
                    visible: databaseService && databaseService.connected
                    width: 22; height: 22; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: _refreshMa.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent; text: "↻"
                        font.pixelSize: 12; color: Theme.fgDim
                        rotation: _refreshMa.containsMouse ? 45 : 0
                        Behavior on rotation { NumberAnimation { duration: 200 } }
                    }
                    MouseArea {
                        id: _refreshMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: schemaService.refresh(databaseService)
                    }
                }
            }
        }

        // ── Schema Tree ──
        SchemaTree {
            Layout.fillWidth: true; Layout.fillHeight: true
        }

        // ── Bottom Status ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32
            color: "transparent"

            Rectangle {
                anchors.top: parent.top; width: parent.width; height: 1
                color: Theme.border
            }

            Row {
                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                spacing: 6

                // Connection status dot
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: databaseService && databaseService.connected ? Theme.success : Theme.fgDim
                    opacity: databaseService && databaseService.connected ? 1.0 : 0.3
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: databaseService && databaseService.connected
                        ? "Connected" : "Disconnected"
                    font.family: Theme.mono; font.pixelSize: 10
                    color: Theme.fgDim
                }

                Item { width: 1; Layout.fillWidth: true }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "v0.2.0"
                    font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim; opacity: 0.4
                }
            }
        }
    }
}
