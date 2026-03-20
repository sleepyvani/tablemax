import QtQuick
import QtQuick.Controls.Basic as T

T.Button {
    id: root

    property bool active: false

    implicitWidth: contentItem.implicitWidth + 20
    implicitHeight: 32

    font.family: Theme.sans
    font.pixelSize: Theme.t13
    font.weight: Font.Medium

    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        radius: Theme.r6
        color: {
            if (root.active) return root.down ? Qt.darker(Theme.accent, 1.1) : Theme.accent
            return root.down ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) :
                   root.hovered ? Theme.bgHover : "transparent"
        }
        border.width: root.active ? 0 : 1
        border.color: Theme.border

        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on border.width { NumberAnimation { duration: Theme.fast } }
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: root.active ? "#ffffff" : Theme.fg
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    onClicked: active = !active

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
