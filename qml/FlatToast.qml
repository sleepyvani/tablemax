import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string message: ""
    property string variant: "default"   // default, success, destructive, warning
    property int duration: 4000

    signal dismissed()

    anchors.right: parent ? parent.right : undefined
    anchors.bottom: parent ? parent.bottom : undefined
    anchors.margins: 16

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
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: Theme.durationSlow; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "y"; to: root.parent ? root.parent.height - root.height - 16 : 0; duration: Theme.durationSlow; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: hideAnim
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: Theme.duration; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "y"; to: root.parent ? root.parent.height : 0; duration: Theme.duration; easing.type: Easing.InCubic }
        onFinished: root.dismissed()
    }

    Rectangle {
        id: toastRect
        width: toastContent.implicitWidth + 32
        height: toastContent.implicitHeight + 20
        radius: Theme.radiusMd
        color: Theme.popover
        border.width: 1
        border.color: Theme.border

        RowLayout {
            id: toastContent
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 6
                height: 6
                radius: Theme.radiusFull
                visible: root.variant !== "default"
                color: {
                    switch (root.variant) {
                        case "success": return Theme.success
                        case "destructive": return "#ef4444"
                        case "warning": return Theme.warning
                        default: return "transparent"
                    }
                }
            }

            Text {
                text: root.message
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                color: Theme.foreground
            }

            Text {
                text: "✕"
                font.pixelSize: 12
                color: Theme.mutedForeground

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.hide()
                }
            }
        }
    }
}
