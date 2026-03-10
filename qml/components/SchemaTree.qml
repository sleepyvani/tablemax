import QtQuick
import QtQuick.Layouts

Rectangle {
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.margins: 8

            Text {
                text: "Schema"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                font.weight: Font.Medium
                color: Theme.mutedForeground
                Layout.fillWidth: true
            }

            FlatButton {
                text: "↻"
                variant: "ghost"
                size: "icon-sm"
                onClicked: schemaService.refresh(databaseService)
            }
        }

        FlatSeparator { orientation: Qt.Horizontal }

        // Tree
        FlatScrollArea {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: parent.width
                spacing: 0

                Repeater {
                    model: schemaService.tree

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        // Node
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            color: nodeMouse.containsMouse ? Qt.rgba(1,1,1,0.02) : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: modelData.type === "column" ? 24 : (modelData.type === "table" ? 12 : 8)
                                spacing: 6

                                Text {
                                    text: modelData.type === "database" ? "🗄" : (modelData.type === "table" ? "▦" : "•")
                                    font.pixelSize: 10
                                    color: Theme.mutedForeground
                                }

                                Text {
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.foreground
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.type === "column" ? (modelData["type"] || "") : ""
                                    font.family: Theme.monoFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.mutedForeground
                                    visible: text.length > 0
                                }
                            }

                            MouseArea {
                                id: nodeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        // Children
                        Repeater {
                            model: modelData.children || []

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                color: childMouse.containsMouse ? Qt.rgba(1,1,1,0.02) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 28
                                    spacing: 4

                                    Text {
                                        text: "•"
                                        font.pixelSize: 8
                                        color: Theme.mutedForeground
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.foreground
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    id: childMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }

                // Empty
                FlatEmpty {
                    visible: schemaService.tree.length === 0
                    title: "No schema"
                    description: "Connect to see tables"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
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
