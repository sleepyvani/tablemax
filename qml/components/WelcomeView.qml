import QtQuick
import QtQuick.Layouts
import TableMax.Controls

Rectangle {
    color: Theme.background

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        // Logo
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 64; height: 64
            radius: 16
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#6366f1" }
                GradientStop { position: 1.0; color: "#8b5cf6" }
            }

            Text {
                anchors.centerIn: parent
                text: "T"
                font.pixelSize: 28
                font.weight: Font.Bold
                color: "#ffffff"
            }

            // Glow
            Rectangle {
                anchors.centerIn: parent
                width: 80; height: 80
                radius: 20
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(0.4, 0.4, 1, 0.1)
            }
        }

        // Title
        Text {
            text: "Welcome to TableMax"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize2xl
            font.weight: Font.Bold
            color: Theme.foreground
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "Your modern database management tool"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Theme.mutedForeground
            Layout.alignment: Qt.AlignHCenter
        }

        Item { height: 8 }

        // Quick actions
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            // New Connection
            Rectangle {
                width: 180; height: 80
                radius: Theme.radiusMd
                color: newConnMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent"
                border.width: 1
                border.color: newConnMouse.containsMouse ? Qt.lighter(Theme.border, 1.3) : Theme.border

                Behavior on color { ColorAnimation { duration: Theme.duration } }
                Behavior on border.color { ColorAnimation { duration: Theme.duration } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "+"
                        font.pixelSize: 22
                        font.weight: Font.Light
                        color: "#6366f1"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "New Connection"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Medium
                        color: Theme.foreground
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                MouseArea {
                    id: newConnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: connectionDialog.open()
                }
            }

            // New Query
            Rectangle {
                width: 180; height: 80
                radius: Theme.radiusMd
                color: newQueryMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent"
                border.width: 1
                border.color: newQueryMouse.containsMouse ? Qt.lighter(Theme.border, 1.3) : Theme.border

                Behavior on color { ColorAnimation { duration: Theme.duration } }
                Behavior on border.color { ColorAnimation { duration: Theme.duration } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "▶"
                        font.pixelSize: 18
                        color: "#8b5cf6"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "New Query"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Medium
                        color: Theme.foreground
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                MouseArea {
                    id: newQueryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tabManager.addTab()
                }
            }
        }

        Item { height: 12 }

        // Shortcuts
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Repeater {
                model: [
                    { key: "Ctrl+N", desc: "New query tab" },
                    { key: "Ctrl+B", desc: "Toggle sidebar" },
                    { key: "Ctrl+Enter", desc: "Execute query" },
                    { key: "Ctrl+W", desc: "Close tab" },
                ]

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    FlatKbd { text: modelData.key }

                    Text {
                        text: modelData.desc
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.mutedForeground
                    }
                }
            }
        }
    }
}
