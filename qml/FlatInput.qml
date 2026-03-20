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

    font.family: Theme.sans
    font.pixelSize: Theme.t13
    color: Theme.fg
    placeholderTextColor: Theme.fgDim
    selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
    selectedTextColor: Theme.fg

    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        radius: Theme.r6
        color: Theme.bgSurface
        border.width: 1
        border.color: {
            if (root.variant === "error") return Theme.error
            return root.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.7) : Theme.border
        }

        Behavior on border.color { ColorAnimation { duration: Theme.fast } }
    }

    cursorDelegate: Rectangle {
        id: cursor
        width: 1.5
        color: Theme.fg
        visible: root.activeFocus

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: root.activeFocus
            NumberAnimation { to: 0; duration: 500; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutQuad }
        }
    }

    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
}
