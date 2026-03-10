import QtQuick
import QtQuick.Controls.Basic as T

T.CheckBox {
    id: root

    implicitWidth: contentItem.implicitWidth + indicator.width + spacing
    implicitHeight: 20
    spacing: 8

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    opacity: enabled ? 1.0 : 0.5

    indicator: Rectangle {
        x: 0
        y: (root.height - height) / 2
        width: 16
        height: 16
        radius: Theme.radiusSm
        color: root.checked ? Theme.primary : "transparent"
        border.width: root.checked ? 0 : 1
        border.color: root.hovered ? Theme.ring : Theme.input

        Behavior on color { ColorAnimation { duration: Theme.duration } }
        Behavior on border.color { ColorAnimation { duration: Theme.duration } }

        Text {
            anchors.centerIn: parent
            text: "✓"
            font.pixelSize: 11
            font.weight: Font.Bold
            color: Theme.primaryForeground
            visible: root.checked

            scale: root.checked ? 1.0 : 0.5
            opacity: root.checked ? 1.0 : 0.0

            Behavior on scale { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
        }
    }

    contentItem: Text {
        leftPadding: root.indicator.width + root.spacing
        text: root.text
        font: root.font
        color: Theme.foreground
        verticalAlignment: Text.AlignVCenter
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
