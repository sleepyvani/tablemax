import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property alias model: repeater.model
    property int currentIndex: 0

    signal toggled(int index)

    implicitWidth: row.implicitWidth + 4
    implicitHeight: 32
    radius: Theme.r6
    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
    border.width: 1
    border.color: Theme.border

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 2
        spacing: 2

        Repeater {
            id: repeater

            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.r4

                color: root.currentIndex === index
                       ? Theme.bgSurface
                       : (toggleMouse.containsMouse ? Theme.bgHover : "transparent")

                Behavior on color {
                    ColorAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                }

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
                    id: toggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index
                        root.toggled(index)
                    }
                }
            }
        }
    }
}
