import QtQuick
import QtQuick.Controls.Basic as T

T.ToolTip {
    id: root

    delay: 500
    timeout: 3000

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeXs

    contentItem: Text {
        text: root.text
        font: root.font
        color: Theme.popoverForeground
    }

    background: Rectangle {
        color: Theme.popover
        border.width: 1
        border.color: Theme.border
        radius: Theme.radiusSm
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationFast }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationFast }
    }
}
