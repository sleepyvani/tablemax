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
        radius: Theme.radiusFull
        color: root.checked ? Theme.primary : Theme.input

        Behavior on color { ColorAnimation { duration: Theme.durationSlow } }

        Rectangle {
            x: root.checked ? parent.width - width - 2 : 2
            y: 2
            width: 16
            height: 16
            radius: Theme.radiusFull
            color: root.checked ? Theme.primaryForeground : Theme.foreground

            Behavior on x {
                NumberAnimation {
                    duration: Theme.durationSlow
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on color { ColorAnimation { duration: Theme.duration } }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
