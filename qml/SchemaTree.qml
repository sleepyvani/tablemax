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

                    // Node
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 26
                        color: ndMa.containsMouse ? Theme.bgHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: Theme.s8; spacing: Theme.s6

                            Text { text: open ? "▾" : "▸"; font.pixelSize: 8; color: Theme.fgDim; Layout.preferredWidth: 10 }

                            Rectangle {
                                width: 14; height: 14; radius: 3; color: Theme.bgSurface
                                Text {
                                    anchors.centerIn: parent; font.family: Theme.mono; font.pixelSize: 8; font.weight: Font.Bold
                                    text: modelData.type === "database" ? "D" : "T"
                                    color: modelData.type === "database" ? Theme.info : Theme.synKeyword
                                }
                            }

                            Text { text: modelData.name || ""; font.family: Theme.sans; font.pixelSize: Theme.t12; color: Theme.fg; elide: Text.ElideRight; Layout.fillWidth: true }

                            Text {
                                text: modelData.children ? modelData.children.length : ""
                                font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim; Layout.rightMargin: Theme.s8
                                visible: modelData.children && modelData.children.length > 0
                            }
                        }
                        MouseArea { id: ndMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: open = !open }
                    }

                    // Children
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0; visible: open; clip: true

                        Repeater {
                            model: modelData.children || []
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 24
                                color: chMa.containsMouse ? Theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.fast } }

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 30; spacing: Theme.s6
                                    Rectangle {
                                        width: 12; height: 12; radius: 2; color: "transparent"; border.width: 1; border.color: Theme.border
                                        Text { anchors.centerIn: parent; text: modelData.type === "table" ? "T" : "C"; font.family: Theme.mono; font.pixelSize: 7; font.weight: Font.Bold; color: modelData.type === "table" ? Theme.synKeyword : Theme.fgDim }
                                    }
                                    Text { text: modelData.name || ""; font.family: Theme.sans; font.pixelSize: Theme.t11; color: Theme.fg; opacity: 0.85; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                MouseArea {
                                    id: chMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onDoubleClicked: { if (modelData.type === "table" && tabManager) { var t = tabManager.getTab(tabManager.currentIndex); tabManager.updateContent(tabManager.currentIndex, (t.content || "") + modelData.name + " ") } }
                                }
                            }
                        }
                    }
                }
            }

            // Empty
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 60; visible: !schemaService || schemaService.tree.length === 0
                ColumnLayout {
                    anchors.centerIn: parent; spacing: Theme.s4
                    Text { text: databaseService && databaseService.connected ? "Empty schema" : "Not connected"; font.family: Theme.sans; font.pixelSize: Theme.t12; color: Theme.fgDim; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }
    }
}
