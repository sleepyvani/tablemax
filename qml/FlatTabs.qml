import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

Item {
    id: root

    property alias model: tabRepeater.model
    property int currentIndex: 0

    signal tabClicked(int index)

    implicitWidth: tabRow.implicitWidth
    implicitHeight: 36

    Rectangle {
        id: tabBar
        anchors.fill: parent
        color: Theme.muted
        radius: Theme.radius

        RowLayout {
            id: tabRow
            anchors.fill: parent
            anchors.margins: 2
            spacing: 2

            Repeater {
                id: tabRepeater

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    radius: Theme.radiusSm
                    color: root.currentIndex === index
                           ? Theme.background
                           : (tabMouse.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04) : "transparent")

                    Behavior on color { ColorAnimation { duration: Theme.duration } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: root.currentIndex === index ? Font.Medium : Font.Normal
                        color: root.currentIndex === index
                               ? Theme.foreground
                               : Theme.mutedForeground

                        Behavior on color { ColorAnimation { duration: Theme.duration } }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentIndex = index
                            root.tabClicked(index)
                        }
                    }
                }
            }
        }
    }
}
