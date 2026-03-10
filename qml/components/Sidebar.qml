import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sidebar
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.margins: 12
            spacing: 8

            Text {
                text: "TableMax"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLg
                font.weight: Font.Bold
                color: Theme.foreground
                Layout.fillWidth: true
            }

            FlatButton {
                text: "+"
                variant: "outline"
                size: "icon"
                onClicked: connectionDialog.open()
            }
        }

        FlatSeparator { orientation: Qt.Horizontal }

        // Connections list
        FlatScrollArea {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                width: parent.width
                spacing: 2

                Repeater {
                    model: connectionManager.connections

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        radius: Theme.radiusSm
                        color: connectionManager.activeIndex === index
                            ? Theme.accent : (connMouse.containsMouse ? Qt.rgba(1,1,1,0.02) : "transparent")

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                width: 8; height: 8
                                radius: 4
                                color: modelData.color || Theme.primary
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.name || "Unnamed"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Medium
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.dbType || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.mutedForeground
                                }
                            }
                        }

                        MouseArea {
                            id: connMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                connectionManager.activeIndex = index
                                databaseService.connect(modelData.dbType, modelData.connectionString)
                            }
                        }
                    }
                }
            }
        }

        FlatSeparator { orientation: Qt.Horizontal }

        // Schema tree
        SchemaTree {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
