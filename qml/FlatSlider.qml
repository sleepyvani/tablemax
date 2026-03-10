import QtQuick
import QtQuick.Controls.Basic as T

T.Slider {
    id: root

    implicitWidth: 200
    implicitHeight: 20

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 6
        radius: Theme.radiusFull
        color: Theme.secondary

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: Theme.radiusFull
            color: Theme.primary

            Behavior on width { NumberAnimation { duration: 50 } }
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 16
        height: 16
        radius: Theme.radiusFull
        color: Theme.primary
        border.width: 2
        border.color: Theme.primary

        scale: root.pressed ? 1.15 : (hoverHandler.hovered ? 1.1 : 1.0)

        Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutBack } }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
        }
    }
}
