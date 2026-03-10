import QtQuick
import QtQuick.Layouts

Rectangle {
    color: "transparent"

    FlatScrollArea {
        anchors.fill: parent

        ColumnLayout {
            width: parent.width
            spacing: 0

            Repeater {
                model: schemaService.tree

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    property bool expanded: true

                    // ─── Database / Top-level node ───
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        color: dbMouse.containsMouse ? Qt.rgba(1,1,1,0.02) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            spacing: 6

                            Text {
                                text: expanded ? "▾" : "▸"
                                font.pixelSize: 9
                                color: Theme.mutedForeground
                            }

                            Rectangle {
                                width: 16; height: 16
                                radius: 3
                                color: Theme.muted

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.type === "database" ? "D" : "T"
                                    font.family: Theme.monoFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: modelData.type === "database" ? "#60a5fa" : "#a78bfa"
                                }
                            }

                            Text {
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.foreground
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.children ? modelData.children.length : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.mutedForeground
                                opacity: 0.5
                                Layout.rightMargin: 8
                                visible: modelData.children && modelData.children.length > 0
                            }
                        }

                        MouseArea {
                            id: dbMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: expanded = !expanded
                        }
                    }

                    // ─── Children ───
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: expanded
                        clip: true

                        Repeater {
                            model: modelData.children || []

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                color: childMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.02) : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 32
                                    spacing: 6

                                    Rectangle {
                                        width: 14; height: 14
                                        radius: 2
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.5)

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.type === "table" ? "T" : "C"
                                            font.family: Theme.monoFamily
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                            color: modelData.type === "table" ? "#a78bfa" : Theme.mutedForeground
                                        }
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.foreground
                                        opacity: 0.85
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.type === "column" ? (modelData["type"] || "") : ""
                                        font.family: Theme.monoFamily
                                        font.pixelSize: 10
                                        color: Theme.mutedForeground
                                        opacity: 0.4
                                        visible: text.length > 0
                                        Layout.rightMargin: 8
                                    }
                                }

                                MouseArea {
                                    id: childMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onDoubleClicked: {
                                        // Insert table name into editor
                                        if (modelData.type === "table") {
                                            var idx = tabManager.currentIndex
                                            var tab = tabManager.getTab(idx)
                                            tabManager.updateContent(idx, (tab.content || "") + " " + modelData.name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                visible: schemaService.tree.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: databaseService.connected ? "Empty schema" : "Not connected"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.mutedForeground
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: databaseService.connected ? "No tables found" : "Select a connection"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.mutedForeground
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Loading
            FlatProgress {
                Layout.fillWidth: true
                indeterminate: true
                visible: schemaService.loading
            }
        }
    }
}
