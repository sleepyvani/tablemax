import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "DbHelper.js" as DB

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

    // ── Search shortcut: press / to focus search ──
    Shortcut {
        sequence: "/"
        enabled: !_search.activeFocus
        onActivated: _search.forceActiveFocus()
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

        // ══════════════════════════════════════════
        //  CONNECTIONS SECTION
        // ══════════════════════════════════════════
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 28
            Layout.leftMargin: 14; Layout.rightMargin: 10

            Row {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; spacing: 6

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
            // FIX #6: Dynamic height — give more space when schema is empty
            Layout.preferredHeight: {
                var schemaEmpty = !schemaService || schemaService.tree.length === 0
                var maxRatio = schemaEmpty ? 0.55 : 0.35
                return Math.min(contentHeight + 4, sidebar.height * maxRatio)
            }
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

            // Smooth scroll
            ScrollBar.vertical: ScrollBar {
                policy: _connList.contentHeight > _connList.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                contentItem: Rectangle { implicitWidth: 3; radius: 2; color: Theme.borderLight; opacity: 0.5 }
            }

            delegate: Item {
                width: _connList.width
                // FIX #5: Active row is taller to fit inline disconnect
                height: _row.active && databaseService.connected ? 56 : 38

                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

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

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: _row.active ? 12 : 10
                        anchors.rightMargin: 8
                        anchors.topMargin: 4; anchors.bottomMargin: 4
                        spacing: 2

                        // Top row: icon + name + indicators
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Color dot
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: modelData.color || "#6366f1"
                                opacity: _row.active ? 1.0 : _row.hovered ? 0.7 : 0.4
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }

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
                                    text: DB.displayName(modelData.dbType || "")
                                    font.family: Theme.mono; font.pixelSize: 9
                                    color: Theme.fgDim
                                }
                            }

                            // Connected indicator (pulsing dot)
                            Rectangle {
                                visible: _row.active && databaseService.connected
                                width: 7; height: 7; radius: 4
                                color: Theme.success

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite; running: _row.active && databaseService.connected
                                    NumberAnimation { to: 0.4; duration: 1500 }
                                    NumberAnimation { to: 1; duration: 1500 }
                                }
                            }

                            // FIX #2: Delete on hover — z:2 so it catches click before _rowMa
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
                                    id: _delMa; anchors.fill: parent; z: 2
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        mouse.accepted = true
                                        _delDlg.deleteIdx = index; _delDlg.open()
                                    }
                                }
                            }
                        }

                        // FIX #5: Inline disconnect button (only for active + connected)
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 22; radius: 4
                            visible: _row.active && databaseService.connected

                            color: _inlineDiscoMa.containsMouse
                                ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.08)
                                : "transparent"
                            border.width: 1
                            border.color: _inlineDiscoMa.containsMouse
                                ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2)
                                : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.5)

                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }

                            Row {
                                anchors.centerIn: parent; spacing: 4
                                Text {
                                    text: "⏻"; font.pixelSize: 9
                                    color: _inlineDiscoMa.containsMouse ? Theme.error : Theme.fgDim
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                                Text {
                                    text: "Disconnect"
                                    font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.Medium
                                    color: _inlineDiscoMa.containsMouse ? Theme.error : Theme.fgDim
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }
                            MouseArea {
                                id: _inlineDiscoMa; anchors.fill: parent; z: 2
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    mouse.accepted = true
                                    databaseService.disconnect()
                                    connectionManager.activeIndex = -1
                                    // FIX #4: Disconnect toast
                                    root.toast("Disconnected", "info")
                                }
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
                                // FIX #1: Toast feedback for connection attempt
                                root.toast("Connecting to " + (modelData.name || "database") + "…", "info")
                                databaseService.connect(modelData.dbType, modelData.connectionString)
                            }
                        }
                    }

                    // FIX #8: Dynamic context menu (Connect/Disconnect based on state)
                    FlatContextMenu {
                        id: _ctx
                        property int connIdx: -1
                        menuModel: {
                            var isActive = connectionManager.activeIndex === index && databaseService.connected
                            var connectLabel = isActive ? "Disconnect" : "Connect"
                            return [connectLabel, "Edit", "-", "Copy Connection String", "Duplicate", "-", "Delete"]
                        }
                        onMenuItemClicked: function(idx, label) {
                            var ci = _ctx.connIdx
                            if (label === "Connect") {
                                connectionManager.activeIndex = ci
                                var c = connectionManager.get(ci)
                                root.toast("Connecting to " + (c.name || "database") + "…", "info")
                                databaseService.connect(c.dbType, c.connectionString)
                            } else if (label === "Disconnect") {
                                databaseService.disconnect()
                                connectionManager.activeIndex = -1
                                root.toast("Disconnected", "info")
                            } else if (label === "Edit") {
                                connDialog.editIdx = ci; connDialog.open()
                            } else if (label === "Copy Connection String") {
                                var cc = connectionManager.get(ci)
                                if (cc) { _clip.text = cc.connectionString || ""; _clip.selectAll(); _clip.copy() }
                                root.toast("Connection string copied", "success")
                            } else if (label === "Duplicate") {
                                var dc = connectionManager.get(ci)
                                if (dc) connectionManager.add({
                                    name: (dc.name || "Untitled") + " (copy)",
                                    dbType: dc.dbType, connectionString: dc.connectionString, color: dc.color
                                })
                            } else if (label === "Delete") {
                                _delDlg.deleteIdx = ci; _delDlg.open()
                            }
                        }
                    }
                }
            }

            // Empty state
            footer: Item {
                width: _connList.width; height: 80
                visible: !connectionManager || connectionManager.connections.length === 0

                Column {
                    anchors.centerIn: parent; spacing: 8

                    // Empty icon
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 32; height: 32; radius: 8
                        color: Theme.bgSurface
                        Text {
                            anchors.centerIn: parent; text: "⊘"
                            font.pixelSize: 14; color: Theme.fgDim
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No connections yet"
                        font.family: Theme.sans; font.pixelSize: 12; color: Theme.fgDim
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: _emptyTxt.implicitWidth + 24; height: 26; radius: 6
                        color: _emptyBtnMa.containsMouse
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                            : "transparent"
                        border.width: 1
                        border.color: _emptyBtnMa.containsMouse
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                            : Theme.border

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "+"; font.pixelSize: 12; color: Theme.accent }
                            Text {
                                id: _emptyTxt; text: "Add Connection"
                                font.family: Theme.sans; font.pixelSize: 11; color: Theme.fg
                            }
                        }
                        MouseArea {
                            id: _emptyBtnMa
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

        // ══════════════════════════════════════════
        //  SCHEMA EXPLORER SECTION
        // ══════════════════════════════════════════
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 28
            Layout.leftMargin: 14; Layout.rightMargin: 10

            RowLayout {
                anchors.fill: parent; spacing: 6

                Text {
                    text: {
                        if (!connectionManager) return "EXPLORER"
                        var c = connectionManager.get(connectionManager.activeIndex)
                        return databaseService && databaseService.connected
                            ? DB.tableLabel(c ? c.dbType : "")
                            : "EXPLORER"
                    }
                    font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.DemiBold
                    font.letterSpacing: 1.0; color: Theme.fgDim; opacity: 0.7
                    Layout.fillWidth: true
                }

                // Collapse toggle
                Rectangle {
                    visible: databaseService && databaseService.connected
                    width: 22; height: 22; radius: 4
                    color: _collapseMa.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent; text: _schemaCollapsed ? "▸" : "▾"
                        font.pixelSize: 8; color: Theme.fgDim
                    }
                    MouseArea {
                        id: _collapseMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: _schemaCollapsed = !_schemaCollapsed
                    }
                }

                // Refresh
                Rectangle {
                    visible: databaseService && databaseService.connected
                    width: 22; height: 22; radius: 4
                    color: _refreshMa.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        id: _refreshIcon
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

        property bool _schemaCollapsed: false

        // ── Schema Tree ──
        SchemaTree {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: !sidebar._schemaCollapsed
        }

        // FIX #7: Collapsed schema — clickable to expand
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: sidebar._schemaCollapsed

            Column {
                anchors.centerIn: parent; spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "▸  Schema explorer collapsed"
                    font.family: Theme.sans; font.pixelSize: 11; color: Theme.fgDim; opacity: 0.5
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Click to expand"
                    font.family: Theme.sans; font.pixelSize: 10; color: Theme.accent; opacity: 0.6
                }
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: sidebar._schemaCollapsed = false
            }
        }

        // ══════════════════════════════════════════
        //  BOTTOM STATUS BAR
        // ══════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32
            color: "transparent"

            Rectangle {
                anchors.top: parent.top; width: parent.width; height: 1
                color: Theme.border
            }

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                spacing: 6

                // Connection status dot
                Rectangle {
                    Layout.preferredWidth: 6; Layout.preferredHeight: 6
                    radius: 3
                    color: databaseService && databaseService.connected ? Theme.success : Theme.fgDim
                    opacity: databaseService && databaseService.connected ? 1.0 : 0.3
                }

                Text {
                    text: {
                        if (databaseService && databaseService.connected) {
                            var c = connectionManager.get(connectionManager.activeIndex)
                            if (c) return DB.displayName(c.dbType || "") + " · " + (c.name || "")
                            return "Connected"
                        }
                        return "Disconnected"
                    }
                    font.family: Theme.mono; font.pixelSize: 10
                    color: Theme.fgDim; elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: "v0.2.0"
                    font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim; opacity: 0.4
                }
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
            spacing: 8
            Layout.topMargin: 8

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Cancel"
                variant: "ghost"
                size: "sm"
                onClicked: _delDlg.close()
            }
            FlatButton {
                text: "Delete"
                variant: "destructive"
                size: "sm"
                onClicked: {
                    connectionManager.remove(_delDlg.deleteIdx)
                    _delDlg.close()
                }
            }
        }
    }
}
