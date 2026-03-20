import QtQuick
import QtQuick.Controls.Basic as T

T.ToolTip {
    id: root

    delay: 500
    timeout: 3000

    font.family: Theme.sans
    font.pixelSize: Theme.t11

    contentItem: Text {
        text: root.text
        font: root.font
        color: Theme.fg
    }

    background: Rectangle {
        color: Theme.bgElevated
        border.width: 1
        border.color: Theme.border
        radius: Theme.r4
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast }
    }
}
