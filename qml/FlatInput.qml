import QtQuick
import QtQuick.Controls.Basic as T

T.TextField {
    id: root

    property string variant: "default"  // default, error

    implicitWidth: 200
    implicitHeight: 32

    leftPadding: 10
    rightPadding: 10
    topPadding: 4
    bottomPadding: 4

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: Theme.foreground
    placeholderTextColor: Theme.mutedForeground
    selectionColor: Theme.ring
    selectedTextColor: Theme.foreground

    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        radius: Theme.radius
        color: Qt.rgba(Theme.input.r, Theme.input.g, Theme.input.b, 0.3)
        border.width: 1
        border.color: {
            if (root.variant === "error") return Theme.error
            return root.activeFocus ? Theme.ring : Theme.input
        }

        Behavior on border.color { ColorAnimation { duration: Theme.duration } }
    }

    cursorDelegate: Rectangle {
        id: cursor
        width: 1.5
        color: Theme.foreground
        visible: root.activeFocus

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: root.activeFocus
            NumberAnimation { to: 0; duration: 500; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutQuad }
        }
    }

    Behavior on opacity { NumberAnimation { duration: Theme.duration } }
}
