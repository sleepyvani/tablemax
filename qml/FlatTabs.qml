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
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
        radius: Theme.r6

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

                    radius: Theme.r4
                    color: root.currentIndex === index
                           ? Theme.bgSurface
                           : (tabMouse.containsMouse ? Theme.bgHover : "transparent")

                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Theme.sans
                        font.pixelSize: Theme.t12
                        font.weight: root.currentIndex === index ? Font.DemiBold : Font.Normal
                        color: root.currentIndex === index ? Theme.fg : Theme.fgMuted

                        Behavior on color { ColorAnimation { duration: Theme.fast } }
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
