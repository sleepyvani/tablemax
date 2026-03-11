import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: sb
    color: Theme.bgSidebar

    // Clipboard helper
    TextEdit { id: clipHelper; visible: false }

    // Schema refresh helper
    Connections {
        target: databaseService
        function onConnectedChanged() {
            if (databaseService.connected)
                schemaService.refresh(databaseService)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            Layout.leftMargin: 12; Layout.rightMargin: 8
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: 7
                gradient: Gradient {
                    GradientStop { position: 0; color: "#6366f1" }
                    GradientStop { position: 1; color: "#8b5cf6" }
                }
                Text {
                    anchors.centerIn: parent; text: "T"
                    font.pixelSize: 12; font.weight: Font.Bold; color: "#fff"; font.family: Theme.sans
                }
            }

            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Text {
                    text: "TableMax"
                    font.family: Theme.sans; font.pixelSize: 13; font.weight: Font.DemiBold
                    color: Theme.fg; font.letterSpacing: -0.2
                }
                Text {
                    text: "v0.2.0"
                    font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim
                }
            }

            // Theme toggle
            Rectangle {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: Theme.r6
                color: themeSbMa.containsMouse ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                Text { anchors.centerIn: parent; text: Theme.darkMode ? "☾" : "☀"; font.pixelSize: 12; color: Theme.fgMuted }
                MouseArea {
                    id: themeSbMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: Theme.toggleTheme()
                }
            }

            // Add connection
            Rectangle {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24; radius: Theme.r6
                color: addMa.containsMouse ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 15; color: Theme.fgMuted }
                MouseArea {
                    id: addMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: connDialog.open()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

        // ─── Search ───
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 40
            Layout.leftMargin: 8; Layout.rightMargin: 8; Layout.topMargin: 4

            Rectangle {
                anchors.centerIn: parent; width: parent.width; height: 30
                radius: Theme.r6; color: Theme.bgSurface
                border.width: 1
                border.color: searchField.activeFocus ? Theme.borderFocus : Theme.border
                Behavior on border.color { ColorAnimation { duration: Theme.normal } }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 6

                    Text { text: "⌕"; font.pixelSize: 12; color: Theme.fgDim }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true; Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.sans; font.pixelSize: 12; color: Theme.fg
                        selectByMouse: true; clip: true
                        activeFocusOnPress: true
                        focus: false

                        Text {
                            anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                            text: "Search connections..."; font: parent.font; color: Theme.fgDim
                            visible: !parent.text && !parent.activeFocus
                        }

                        Keys.onEscapePressed: { searchField.text = ""; searchField.focus = false; sb.forceActiveFocus() }
                    }

                    // Kbd hint
                    Rectangle {
                        visible: !searchField.activeFocus && !searchField.text
                        height: 16; width: 18; radius: 3
                        color: Theme.bgHover; border.width: 1; border.color: Theme.border

                        Text {
                            anchors.centerIn: parent; text: "/"
                            font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim
                        }
                    }
                }

                // Click away from search → lose focus
                MouseArea {
                    anchors.fill: parent; z: -1
                    onPressed: function(mouse) {
                        if (!searchField.activeFocus) {
                            searchField.forceActiveFocus()
                        }
                        mouse.accepted = false
                    }
                }
            }
        }

        // ─── Section: CONNECTIONS ───
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 24; Layout.leftMargin: 12; Layout.topMargin: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "CONNECTIONS"
                font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.DemiBold
                font.letterSpacing: 1.2; color: Theme.fgDim
            }
        }

        // ─── Connection List ───
        FlatScrollArea {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(connListCol.implicitHeight + 6, sb.height * 0.4)
            Layout.minimumHeight: 60

            ColumnLayout {
                id: connListCol
                width: parent.width; spacing: 2

                Repeater {
                    model: {
                        if (!connectionManager) return []
                        var all = connectionManager.connections
                        if (!searchField.text) return all
                        var q = searchField.text.toLowerCase()
                        return all.filter(function(c) {
                            return (c.name || "").toLowerCase().indexOf(q) >= 0 ||
                                   (c.dbType || "").toLowerCase().indexOf(q) >= 0
                        })
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 40
                        Layout.leftMargin: 6; Layout.rightMargin: 6
                        radius: Theme.r6

                        property bool isActive: connectionManager.activeIndex === index
                        property bool isHovered: cMa.containsMouse

                        color: isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                             : isHovered ? Theme.bgHover : "transparent"
                        border.width: isActive ? 1 : 0
                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                        Behavior on color { ColorAnimation { duration: Theme.fast } }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 8

                            // Database icon
                            Image {
                                Layout.preferredWidth: 18; Layout.preferredHeight: 18
                                source: {
                                    var t = (modelData.dbType || "postgres").toLowerCase()
                                    return "qrc:/TableMax/icons/" + t + ".svg"
                                }
                                sourceSize: Qt.size(18, 18)
                                fillMode: Image.PreserveAspectFit
                                opacity: isActive ? 1.0 : 0.6
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 1

                                Text {
                                    text: modelData.name || "Unnamed"
                                    font.family: Theme.sans; font.pixelSize: 12
                                    font.weight: isActive ? Font.DemiBold : Font.Normal
                                    color: Theme.fg; elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Text {
                                    text: (modelData.dbType || "").toUpperCase()
                                    font.family: Theme.mono; font.pixelSize: 9
                                    color: Theme.fgDim; font.letterSpacing: 0.5
                                }
                            }

                            // Status pill
                            Rectangle {
                                visible: isActive && databaseService.connected
                                Layout.preferredHeight: 14; Layout.preferredWidth: 14; radius: 7
                                color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)

                                Rectangle {
                                    anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: Theme.success
                                }
                            }

                            // Delete button
                            Rectangle {
                                Layout.preferredWidth: 20; Layout.preferredHeight: 20; radius: Theme.r4
                                visible: isHovered && !isActive
                                color: delMa.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1) : "transparent"

                                Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 12; color: delMa.containsMouse ? Theme.error : Theme.fgDim }
                                MouseArea { id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: connectionManager.remove(index) }
                            }
                        }

                        MouseArea {
                            id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: -1
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(mouse) {
                                // Unfocus search when clicking connection
                                searchField.focus = false
                                sb.forceActiveFocus()

                                if (mouse.button === Qt.RightButton) {
                                    connCtxMenu.connIndex = index
                                    connCtxMenu.x = mouse.x
                                    connCtxMenu.y = mouse.y
                                    connCtxMenu.open()
                                } else {
                                    connectionManager.activeIndex = index
                                    databaseService.connect(modelData.dbType, modelData.connectionString)
                                }
                            }
                        }

                        FlatContextMenu {
                            id: connCtxMenu
                            property int connIndex: -1
                            menuModel: ["Connect", "Edit", "-", "Copy Connection String", "Duplicate", "-", "Delete"]
                            onMenuItemClicked: function(idx, text) {
                                var ci = connCtxMenu.connIndex
                                if (text === "Connect") {
                                    connectionManager.activeIndex = ci
                                    var c = connectionManager.get(ci)
                                    databaseService.connect(c.dbType, c.connectionString)
                                } else if (text === "Edit") {
                                    connDialog.editIdx = ci
                                    connDialog.open()
                                } else if (text === "Copy Connection String") {
                                    var cc = connectionManager.get(ci)
                                    if (cc) {
                                        clipHelper.text = cc.connectionString || ""
                                        clipHelper.selectAll()
                                        clipHelper.copy()
                                    }
                                } else if (text === "Duplicate") {
                                    var dc = connectionManager.get(ci)
                                    if (dc) connectionManager.add({
                                        name: (dc.name || "Untitled") + " (copy)",
                                        dbType: dc.dbType,
                                        connectionString: dc.connectionString,
                                        color: dc.color
                                    })
                                } else if (text === "Delete") {
                                    connectionManager.remove(ci)
                                }
                            }
                        }
                    }
                }

                // Empty state
                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: 60
                    visible: !connectionManager || connectionManager.connections.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 4

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter; width: 32; height: 32; radius: Theme.r8
                            color: Theme.bgSurface; border.width: 1; border.color: Theme.border

                            Text { anchors.centerIn: parent; text: "⊕"; font.pixelSize: 14; color: Theme.fgDim }
                        }
                        Text { text: "No connections"; font.family: Theme.sans; font.pixelSize: 12; color: Theme.fgDim; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "Press + to add one"; font.family: Theme.sans; font.pixelSize: 10; color: Theme.fgDim; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

        // ─── Section: SCHEMA ───
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 24
            Layout.leftMargin: 12; Layout.topMargin: 4

            RowLayout {
                anchors.fill: parent; anchors.rightMargin: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SCHEMA"
                    font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.DemiBold
                    font.letterSpacing: 1.2; color: Theme.fgDim
                }

                Item { Layout.fillWidth: true }

                // Refresh button
                Rectangle {
                    visible: databaseService && databaseService.connected
                    width: 20; height: 20; radius: Theme.r4
                    color: refreshMa.containsMouse ? Theme.bgHover : "transparent"

                    Text { anchors.centerIn: parent; text: "↻"; font.pixelSize: 12; color: Theme.fgDim }
                    MouseArea {
                        id: refreshMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: schemaService.refresh(databaseService)
                    }
                }
            }
        }

        SchemaTree {
            Layout.fillWidth: true; Layout.fillHeight: true
        }
    }

    // Click anywhere on sidebar background → unfocus search
    MouseArea {
        anchors.fill: parent; z: -10
        onClicked: {
            searchField.focus = false
            sb.forceActiveFocus()
        }
    }
}
