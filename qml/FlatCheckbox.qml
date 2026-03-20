import QtQuick
import QtQuick.Controls.Basic as T
import "Icons.js" as Icons

T.CheckBox {
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
        width: 16
        height: 16
        radius: Theme.r4
        color: root.checked ? Theme.accent : "transparent"
        border.width: root.checked ? 0 : 1
        border.color: root.hovered ? Theme.accent : Theme.border

        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on border.color { ColorAnimation { duration: Theme.fast } }

        FlatIcon {
            anchors.centerIn: parent
            icon: Icons.check
            size: 10
            color: "#ffffff"
            visible: root.checked

            scale: root.checked ? 1.0 : 0.5
            opacity: root.checked ? 1.0 : 0.0

            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
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
