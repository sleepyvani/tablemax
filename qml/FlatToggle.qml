import QtQuick
import QtQuick.Controls.Basic as T

T.Button {
    id: root

    property bool active: false

    implicitWidth: contentItem.implicitWidth + 20
    implicitHeight: 32

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Font.Medium

    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        radius: Theme.radius
        color: {
            if (root.active) return root.down ? Qt.darker(Theme.primary, 1.15) : Theme.primary
            return root.down ? Qt.darker(Theme.muted, 1.1) :
                   root.hovered ? Theme.muted : "transparent"
        }
        border.width: root.active ? 0 : 1
        border.color: Theme.border

        Behavior on color { ColorAnimation { duration: Theme.duration } }
        Behavior on border.width { NumberAnimation { duration: Theme.durationFast } }
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: root.active ? Theme.primaryForeground : Theme.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }

    onClicked: active = !active

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
