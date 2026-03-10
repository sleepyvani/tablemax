import QtQuick
import QtQuick.Controls.Basic as T

T.Popup {
    id: root

    padding: 12

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationFast }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: Theme.durationFast; easing.type: Easing.OutQuad }
        }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationFast }
    }

    background: Rectangle {
        color: Theme.popover
        border.width: 1
        border.color: Theme.border
        radius: Theme.radiusMd
    }
}
