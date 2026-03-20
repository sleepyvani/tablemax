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
        height: 4
        radius: Theme.rFull
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: Theme.rFull
            color: Theme.accent
            Behavior on width { NumberAnimation { duration: 50 } }
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 16; height: 16
        radius: Theme.rFull
        color: Theme.accent
        border.width: 2
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)

        scale: root.pressed ? 1.15 : (hoverHandler.hovered ? 1.1 : 1.0)
        Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }

        HoverHandler { id: hoverHandler; cursorShape: Qt.PointingHandCursor }
    }
}
