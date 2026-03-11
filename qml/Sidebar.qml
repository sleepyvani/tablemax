import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: sb
    color: Theme.bgSidebar

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ─── Header ───
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 38

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s8; spacing: Theme.s8

                // Logo
                Rectangle {
                    width: 22; height: 22; radius: 6
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#6366f1" }
                        GradientStop { position: 1; color: "#8b5cf6" }
                    }
                    Text { anchors.centerIn: parent; text: "T"; font.pixelSize: 11; font.weight: Font.Bold; color: "#fff" }
                }

                Text { text: "TableMax"; font.family: Theme.sans; font.pixelSize: Theme.t14; font.weight: Font.DemiBold; color: Theme.fg; Layout.fillWidth: true }

                // Add
                Rectangle {
                    width: 24; height: 24; radius: Theme.r6
                    color: addBtnMa.containsMouse ? Theme.bgHover : "transparent"
                    Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 15; color: Theme.fgMuted }
                    MouseArea { id: addBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: connDialog.open() }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        // ─── Search ───
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 44; Layout.leftMargin: Theme.s8; Layout.rightMargin: Theme.s8

            Rectangle {
                anchors.centerIn: parent; width: parent.width; height: 30; radius: Theme.r6
                color: Theme.bgSurface; border.width: 1; border.color: searchField.activeFocus ? Theme.borderFocus : Theme.border
                Behavior on border.color { ColorAnimation { duration: Theme.normal } }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.s8; anchors.rightMargin: Theme.s8; spacing: Theme.s6
                    Text { text: "⌕"; font.pixelSize: 12; color: Theme.fgDim }
                    TextInput {
                        id: searchField; Layout.fillWidth: true; Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter; font.family: Theme.sans; font.pixelSize: Theme.t12
                        color: Theme.fg; selectByMouse: true; clip: true
                        Text {
                            anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                            text: "Search..."; font: parent.font; color: Theme.fgDim; visible: !parent.text && !parent.activeFocus
                        }
                    }
                }
            }
        }

        // ─── Section: Connections ───
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 28; Layout.leftMargin: Theme.s12
            Text { anchors.verticalCenter: parent.verticalCenter; text: "CONNECTIONS"; font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 1; color: Theme.fgDim }
        }

        // ─── List ───
        FlatScrollArea {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.maximumHeight: parent.height * 0.45

            ColumnLayout {
                width: parent.width; spacing: Theme.s2

                Repeater {
                    model: connectionManager ? connectionManager.connections : []
                    delegate: Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 36; Layout.leftMargin: Theme.s6; Layout.rightMargin: Theme.s6
                        radius: Theme.r6
                        property bool active: connectionManager.activeIndex === index
                        property bool hov: cMa.containsMouse

                        color: active ? Theme.accentDim : hov ? Theme.bgHover : "transparent"
                        border.width: active ? 1 : 0; border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                        Behavior on color { ColorAnimation { duration: Theme.fast } }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: Theme.s8

                            // Dot
                            Rectangle {
                                width: 7; height: 7; radius: 4; color: modelData.color || Theme.accent
                                Rectangle {
                                    anchors.centerIn: parent; width: 13; height: 13; radius: 7
                                    color: parent.color; opacity: active && databaseService.connected ? 0.25 : 0
                                    Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                                }
                            }

                            ColumnLayout {
                                spacing: 0; Layout.fillWidth: true
                                Text { text: modelData.name || "Unnamed"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: active ? Font.DemiBold : Font.Normal; color: Theme.fg; elide: Text.ElideRight; Layout.fillWidth: true }
                                Text { text: (modelData.dbType || "").toUpperCase(); font.family: Theme.sans; font.pixelSize: 10; color: Theme.fgDim; font.letterSpacing: 0.3 }
                            }

                            Rectangle {
                                width: 20; height: 20; radius: Theme.r4; visible: hov || active
                                color: delMa.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.12) : "transparent"
                                Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 12; color: delMa.containsMouse ? Theme.error : Theme.fgDim }
                                MouseArea { id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: connectionManager.remove(index) }
                            }
                        }

                        MouseArea {
                            id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; z: -1
                            onClicked: { connectionManager.activeIndex = index; databaseService.connect(modelData.dbType, modelData.connectionString) }
                        }
                    }
                }

                // Empty
                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: 50; visible: !connectionManager || connectionManager.connections.length === 0
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 2
                        Text { text: "No connections yet"; font.family: Theme.sans; font.pixelSize: Theme.t12; color: Theme.fgDim; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "Press + to add"; font.family: Theme.sans; font.pixelSize: Theme.t11; color: Theme.fgDim; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        // ─── Schema ───
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 28; Layout.leftMargin: Theme.s12; Layout.topMargin: Theme.s4
            RowLayout {
                anchors.fill: parent
                Text { text: "SCHEMA"; font.family: Theme.sans; font.pixelSize: 10; font.weight: Font.Medium; font.letterSpacing: 1; color: Theme.fgDim; Layout.fillWidth: true }
                Rectangle {
                    width: 22; height: 22; radius: Theme.r4; Layout.rightMargin: Theme.s8
                    color: refMa.containsMouse ? Theme.bgHover : "transparent"
                    Text { anchors.centerIn: parent; text: "↻"; font.pixelSize: 12; color: Theme.fgMuted }
                    MouseArea { id: refMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                }
            }
        }

        SchemaTree { Layout.fillWidth: true; Layout.fillHeight: true }
    }
}
