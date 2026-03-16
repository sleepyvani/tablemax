import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

T.Drawer {
    id: root

    property string side: "right"  // left, right, top, bottom

    edge: {
        switch (side) {
            case "left": return Qt.LeftEdge
            case "top": return Qt.TopEdge
            case "bottom": return Qt.BottomEdge
            default: return Qt.RightEdge
        }
    }

    width: (side === "left" || side === "right")
           ? Math.min(400, parent.width * 0.8)
           : parent.width

    height: (side === "top" || side === "bottom")
            ? Math.min(400, parent.height * 0.8)
            : parent.height

    background: Rectangle {
        color: Theme.background
        border.width: side === "right" || side === "left" ? 1 : 0
        border.color: Theme.border

        DashedLine {
            visible: side === "top" || side === "bottom"
            width: parent.width
            height: 1
            color: Theme.border
            y: side === "bottom" ? 0 : parent.height - 1
        }
    }

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.6)
        Behavior on opacity { NumberAnimation { duration: Theme.durationModal } }
    }

    enter: Transition {
        NumberAnimation { property: "position"; from: 0; to: 1; duration: Theme.durationSlow; easing.type: Easing.OutCubic }
    }

    exit: Transition {
        NumberAnimation { property: "position"; from: 1; to: 0; duration: Theme.duration; easing.type: Easing.InCubic }
    }
}
