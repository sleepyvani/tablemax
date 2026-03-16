import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "DbHelper.js" as DB
import "Icons.js" as Icons

Rectangle {
    id: sidebar
    color: Theme.bgSidebar

    // ── Clipboard helper ──
    TextEdit { id: _clip; visible: false }

    // ── Auto-refresh schema on connect + toast feedback ──
    Connections {
        target: databaseService
        function onConnectedChanged() {
            if (databaseService.connected) {
                schemaService.refresh(databaseService)
                var c = connectionManager.get(connectionManager.activeIndex)
                root.toast("Connected to " + (c ? c.name : "database"), "success")
            }
        }
        function onErrorChanged() {
            if (databaseService.error)
                root.toast("Connection failed: " + databaseService.error, "destructive")
        }
    }

    // Search shortcut scoped to sidebar focus
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Slash && !_search.activeFocus) {
            _search.forceActiveFocus()
            event.accepted = true
        }
    }
    focus: false

    // ════════════════════════════════════════════
    //  LAYOUT
    // ════════════════════════════════════════════
    Item {
        anchors.fill: parent

        // ════ CONNECTION MODE ════
        ColumnLayout {
            anchors.fill: parent; spacing: 0
            visible: !databaseService || !databaseService.connected

            // ── Search + Actions Bar ──
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 38
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.s8; anchors.rightMargin: Theme.s8; spacing: Theme.s4
                    Rectangle {
                        Layout.fillWidth: true; height: 26; radius: Theme.r6; color: Theme.bgSurface
                        border.width: 1; border.color: _search.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5) : Theme.border
                        Behavior on border.color { ColorAnimation { duration: Theme.fast } }
                        Row {
                            anchors.fill: parent; anchors.leftMargin: Theme.s6; anchors.rightMargin: Theme.s6; spacing: Theme.s4
                            FlatIcon { anchors.verticalCenter: parent.verticalCenter; icon: Icons.search; size: 11; color: Theme.fgDim }
                            TextInput {
                                id: _search; width: parent.width - 40; anchors.verticalCenter: parent.verticalCenter
                                font.family: Theme.sans; font.pixelSize: Theme.t11; color: Theme.fg; selectByMouse: true; clip: true; focus: false
                                Text { visible: !_search.text && !_search.activeFocus; text: "Filter…"; font: parent.font; color: Theme.fgDim; opacity: 0.5 }
                                Keys.onEscapePressed: { _search.text = ""; sidebar.forceActiveFocus() }
                            }
                            Text { anchors.verticalCenter: parent.verticalCenter; visible: !_search.activeFocus && !_search.text; text: "/"; font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim; opacity: 0.4 }
                        }
                    }
                    Rectangle {
                        width: 26; height: 26; radius: Theme.r6; color: _addMa.containsMouse ? Theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        FlatIcon { anchors.centerIn: parent; icon: Icons.add; size: 12; color: Theme.fgMuted }
                        MouseArea { id: _addMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: connDialog.open() }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border; opacity: 0.5 }

            // ── Connections Label ──
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 22; Layout.leftMargin: Theme.s8; Layout.topMargin: Theme.s4
                Text { anchors.verticalCenter: parent.verticalCenter; text: "CONNECTIONS"; font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 1.0; color: Theme.fgDim; opacity: 0.7 }
            }

            // ── Connection List ──
            ListView {
                id: _connList; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 0; boundsBehavior: Flickable.StopAtBounds
                model: {
                    if (!connectionManager) return []
                    var all = connectionManager.connections
                    if (!_search.text) return all
                    var q = _search.text.toLowerCase()
                    return all.filter(function(c) { return (c.name || "").toLowerCase().indexOf(q) >= 0 || (c.dbType || "").toLowerCase().indexOf(q) >= 0 })
                }
                ScrollBar.vertical: ScrollBar { policy: _connList.contentHeight > _connList.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff; contentItem: Rectangle { implicitWidth: 3; radius: 2; color: Theme.fgDim; opacity: 0.2 } }
                
                delegate: Rectangle {
                    id: _connRow; width: _connList.width; height: 38
                    property bool active: connectionManager.activeIndex === index
                    property bool hovered: _connMa.containsMouse
                    color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08) : hovered ? Theme.bgHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Rectangle { width: 3; height: parent.height; color: Theme.accent; visible: _connRow.active; anchors.left: parent.left }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s8; spacing: Theme.s6
                        Rectangle { width: 6; height: 6; radius: 3; color: _connRow.active && databaseService.connected ? Theme.success : _connRow.active ? Theme.warning : Theme.fgDim; opacity: _connRow.active ? 1.0 : 0.3 }
                        Image { Layout.preferredWidth: 14; Layout.preferredHeight: 14; source: "qrc:/TableMax/icons/" + (modelData.dbType || "postgres").toLowerCase() + ".svg"; sourceSize: Qt.size(14, 14); fillMode: Image.PreserveAspectFit; opacity: _connRow.active ? 1.0 : 0.5 }
                        Text { text: modelData.name || "Untitled"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: _connRow.active ? Font.DemiBold : Font.Normal; color: _connRow.active ? Theme.fg : Theme.fgMuted; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: DB.displayName(modelData.dbType || "").toLowerCase(); font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim; opacity: 0.5; visible: !_connRow.hovered || _connRow.active }
                        Rectangle {
                            visible: _connRow.hovered && !_connRow.active; width: 18; height: 18; radius: Theme.r4; color: _delBtnMa.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                            FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 9; color: _delBtnMa.containsMouse ? Theme.error : Theme.fgDim }
                            MouseArea { id: _delBtnMa; anchors.fill: parent; z: 2; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: function(mouse) { mouse.accepted = true; _delDlg.deleteIdx = index; _delDlg.open() } }
                        }
                    }

                    MouseArea {
                        id: _connMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: -1; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            sidebar.forceActiveFocus()
                            if (mouse.button === Qt.RightButton) { 
                                connCtxMenu.connIdx = index; 
                                // Menu needs global or mapped position, but since FlatContextMenu uses Menu popup,
                                // we can just pass the mouse coordinates and call open
                                connCtxMenu.x = mouse.x; 
                                connCtxMenu.y = mouse.y; 
                                connCtxMenu.popup(null) // Or open() depends on FlatContextMenu API 
                            }
                            else {
                                if (connectionManager.activeIndex === index && databaseService.connected) return
                                connectionManager.activeIndex = index
                                databaseService.connect(modelData.dbType, modelData.connectionString)
                            }
                        }
                    }
                }
                footer: Item {
                    width: _connList.width; height: 48; visible: !connectionManager || connectionManager.connections.length === 0
                    RowLayout { anchors.centerIn: parent; spacing: Theme.s6; FlatIcon { icon: Icons.add; size: 12; color: Theme.fgDim }; Text { text: "Add connection"; font.family: Theme.sans; font.pixelSize: Theme.t11; color: Theme.fgDim; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: connDialog.open() } } }
                }
            }

            // ── Shared Context Menu ──
            FlatContextMenu {
                id: connCtxMenu; property int connIdx: -1
                menuModel: {
                    var isActive = connectionManager.activeIndex === connIdx && databaseService.connected
                    return [isActive ? "Disconnect" : "Connect", "Edit", "-", "Copy Connection String", "Duplicate", "-", "Delete"]
                }
                onMenuItemClicked: function(idx, label) {
                    var ci = connCtxMenu.connIdx
                    if (label === "Connect") {
                        if (connectionManager.activeIndex === ci && databaseService.connected) return
                        connectionManager.activeIndex = ci; var c = connectionManager.get(ci); databaseService.connect(c.dbType, c.connectionString)
                    } else if (label === "Disconnect") { databaseService.disconnect(); connectionManager.activeIndex = -1; root.toast("Disconnected", "info") }
                    else if (label === "Edit") { connDialog.editIdx = ci; connDialog.open() }
                    else if (label === "Copy Connection String") { var cc = connectionManager.get(ci); if (cc) { _clip.text = cc.connectionString || ""; _clip.selectAll(); _clip.copy() }; root.toast("Connection string copied", "success") }
                    else if (label === "Duplicate") { var dc = connectionManager.get(ci); if (dc) connectionManager.add({ name: (dc.name || "Untitled") + " (copy)", dbType: dc.dbType, connectionString: dc.connectionString, color: dc.color }) }
                    else if (label === "Delete") { _delDlg.deleteIdx = ci; _delDlg.open() }
                }
            }
            }
        }

        // ════ WORKSPACE MODE (Only Schema) ════
        ColumnLayout {
            anchors.fill: parent; spacing: 0
            visible: databaseService && databaseService.connected

            // ── Connected Header ──
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 46
                Rectangle { anchors.fill: parent; color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.04) }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.s8; anchors.rightMargin: Theme.s8; spacing: Theme.s8
                    
                    // Back/Disconnect Button
                    Rectangle {
                        width: 28; height: 28; radius: Theme.r4; color: _wsBackMa.containsMouse ? Theme.bgHover : "transparent"
                        FlatIcon { anchors.centerIn: parent; icon: Icons.left; size: 14; color: Theme.fgMuted }
                        MouseArea { 
                            id: _wsBackMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor 
                            onClicked: {
                                databaseService.disconnect()
                                // Wait 100ms then reset activeIndex to visually confirm disconnect
                                connectionManager.activeIndex = -1
                            }
                        }
                        FlatTooltip { visible: _wsBackMa.containsMouse; text: "Disconnect"; y: 32 }
                    }

                    // Server Name
                    Column {
                        Layout.fillWidth: true; spacing: 2
                        Text {
                            text: { var c = connectionManager.get(connectionManager.activeIndex); return c ? c.name : "Server" }
                            font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.DemiBold; color: Theme.fg
                            elide: Text.ElideRight; width: parent.width
                        }
                        Text {
                            text: { var c = connectionManager.get(connectionManager.activeIndex); return c ? DB.displayName(c.dbType) : "Connected" }
                            font.family: Theme.mono; font.pixelSize: 10; color: Theme.success; opacity: 0.8
                        }
                    }

                    // Refresh
                    Rectangle {
                        width: 28; height: 28; radius: Theme.r4; color: _wsRefMa.containsMouse ? Theme.bgHover : "transparent"
                        FlatIcon { anchors.centerIn: parent; icon: Icons.refresh; size: 13; color: Theme.fgMuted }
                        MouseArea { id: _wsRefMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: schemaService.refresh(databaseService) }
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.5 }
            }

            // ── Schema Tree ──
            SchemaTree {
                Layout.fillWidth: true; Layout.fillHeight: true
            }
        }
    }

    // ── Delete Confirmation Dialog ──
    FlatDialog {
        id: _delDlg
        property int deleteIdx: -1
        dialogTitle: "Delete Connection"
        dialogDescription: {
            if (deleteIdx >= 0) {
                var c = connectionManager.get(deleteIdx)
                return "Are you sure you want to delete \"" + (c.name || "Untitled") + "\"? This action cannot be undone."
            }
            return ""
        }

        contentItem: RowLayout {
            spacing: Theme.s8
            Layout.topMargin: Theme.s8

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Cancel"; variant: "ghost"; size: "sm"
                onClicked: _delDlg.close()
            }
            FlatButton {
                text: "Delete"; variant: "destructive"; size: "sm"
                onClicked: {
                    connectionManager.remove(_delDlg.deleteIdx)
                    _delDlg.close()
                }
            }
        }
    }
}
