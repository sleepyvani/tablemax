import QtQuick
import QtQuick.Layouts
import "Icons.js" as Icons

Item {
    id: root

    property string message: ""
    property string variant: "default"   // default, success, destructive, warning, info
    property int duration: 4000

    signal dismissed()

    anchors.right: parent ? parent.right : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.margins: Theme.s16

    width: toastRect.width
    height: toastRect.height

    opacity: 0
    y: parent ? parent.height : 0

    function show(msg, v) {
        message = msg
        if (v) variant = v
        showAnim.start()
        dismissTimer.restart()
    }

    function hide() {
        hideAnim.start()
    }

    Timer {
        id: dismissTimer
        interval: root.duration
        onTriggered: root.hide()
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: Theme.slow; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "y"; to: root.parent ? root.parent.height - root.height - Theme.s16 : 0; duration: Theme.slow; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: hideAnim
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: Theme.normal; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "y"; to: root.parent ? root.parent.height : 0; duration: Theme.normal; easing.type: Easing.InCubic }
        onFinished: root.dismissed()
    }

    Rectangle {
        id: toastRect
        width: toastContent.implicitWidth + Theme.s24 * 2
        height: 40
        radius: Theme.r8
        color: Theme.bgSurface
        border.width: 1
        border.color: Theme.border
        clip: true

        // Left accent bar colored by variant
        Rectangle {
            width: 3; height: parent.height
            color: {
                switch (root.variant) {
                    case "success":     return Theme.success
                    case "destructive":
                    case "error":       return Theme.error
                    case "warning":     return Theme.warning
                    case "info":        return Theme.info
                    default:            return Theme.accent
                }
            }
        }

        RowLayout {
            id: toastContent
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: Theme.s16
            anchors.right: parent.right; anchors.rightMargin: Theme.s8
            spacing: Theme.s8

            // variant icon
            FlatIcon {
                size: 13; visible: root.variant !== "default"
                icon: {
                    switch (root.variant) {
                        case "success":     return Icons.success
                        case "destructive":
                        case "error":       return Icons.error
                        case "warning":     return Icons.warning
                        case "info":        return Icons.info
                        default:            return ""
                    }
                }
                color: {
                    switch (root.variant) {
                        case "success":     return Theme.success
                        case "destructive":
                        case "error":       return Theme.error
                        case "warning":     return Theme.warning
                        case "info":        return Theme.info
                        default:            return Theme.fg
                    }
                }
            }

            Text {
                text: root.message
                font.family: Theme.sans
                font.pixelSize: Theme.t12
                color: Theme.fg
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.maximumWidth: 360
            }

            // Dismiss button
            Rectangle {
                width: 20; height: 20; radius: Theme.r4; color: dismissMa.containsMouse ? Theme.bgHover : "transparent"
                FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 10; color: Theme.fgMuted }
                MouseArea { id: dismissMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.hide() }
            }
        }
    }
}
