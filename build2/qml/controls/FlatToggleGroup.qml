import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property alias model: repeater.model
    property int currentIndex: 0

    signal toggled(int index)

    implicitWidth: row.implicitWidth + 4
    implicitHeight: 32
    radius: Theme.radius
    color: Theme.muted
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
                radius: Theme.radiusSm

                color: root.currentIndex === index
                       ? Theme.background
                       : (toggleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent")

                Behavior on color {
                    ColorAnimation { duration: Theme.duration; easing.type: Easing.OutCubic }
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: root.currentIndex === index ? Font.Medium : Font.Normal
                    color: root.currentIndex === index ? Theme.foreground : Theme.mutedForeground

                    Behavior on color { ColorAnimation { duration: Theme.duration } }
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
