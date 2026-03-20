import QtQuick
import QtQuick.Controls.Basic as T

T.Popup {
    id: root

    padding: 12

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: Theme.fast; easing.type: Easing.OutQuad }
        }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast }
    }

    background: Rectangle {
        color: Theme.bgElevated
        border.width: 1
        border.color: Theme.border
        radius: Theme.r8
    }
}
