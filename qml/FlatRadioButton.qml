import QtQuick
import QtQuick.Controls.Basic as T

T.RadioButton {
    id: root

    implicitWidth: contentItem.implicitWidth + indicator.width + spacing
    implicitHeight: 20
    spacing: 8

    font.family: Theme.sans
    font.pixelSize: Theme.t13

    opacity: enabled ? 1.0 : 0.5

    indicator: Rectangle {
        x: 0
        y: (root.height - height) / 2
        width: 16; height: 16
        radius: Theme.rFull
        color: "transparent"
        border.width: 1.5
        border.color: root.checked
            ? Theme.accent
            : (root.hovered ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5) : Theme.border)

        Behavior on border.color { ColorAnimation { duration: Theme.fast } }

        Rectangle {
            anchors.centerIn: parent
            width: 8; height: 8
            radius: Theme.rFull
            color: Theme.accent

            scale: root.checked ? 1.0 : 0.0
            opacity: root.checked ? 1.0 : 0.0

            Behavior on scale   { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        }
    }

    contentItem: Text {
        leftPadding: root.indicator.width + root.spacing
        text: root.text
        font: root.font
        color: Theme.fg
        verticalAlignment: Text.AlignVCenter
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
