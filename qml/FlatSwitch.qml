import QtQuick
import QtQuick.Controls.Basic as T

T.Switch {
    id: root

    implicitWidth: 36
    implicitHeight: 20

    opacity: enabled ? 1.0 : 0.5

    indicator: Rectangle {
        width: 36
        height: 20
        radius: Theme.rFull
        color: root.checked ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.15)

        Behavior on color { ColorAnimation { duration: Theme.slow } }

        Rectangle {
            x: root.checked ? parent.width - width - 2 : 2
            y: 2; width: 16; height: 16
            radius: Theme.rFull
            color: "#ffffff"

            Behavior on x {
                NumberAnimation { duration: Theme.slow; easing.type: Easing.InOutCubic }
            }

            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
