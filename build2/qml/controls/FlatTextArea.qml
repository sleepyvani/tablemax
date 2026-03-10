import QtQuick
import QtQuick.Controls.Basic as T

T.TextArea {
    id: root

    implicitWidth: 200
    implicitHeight: 80

    padding: 10
    font.family: Theme.monoFamily
    font.pixelSize: Theme.fontSizeSm
    color: Theme.foreground
    placeholderTextColor: Theme.mutedForeground
    selectionColor: Theme.ring
    selectedTextColor: Theme.foreground
    wrapMode: TextEdit.Wrap

    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        radius: Theme.radius
        color: Qt.rgba(Theme.input.r, Theme.input.g, Theme.input.b, 0.3)
        border.width: 1
        border.color: root.activeFocus ? Theme.ring : Theme.input

        Behavior on border.color { ColorAnimation { duration: Theme.duration } }
    }

    cursorDelegate: Rectangle {
        width: 1.5
        color: Theme.foreground
        visible: root.activeFocus

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: root.activeFocus
            NumberAnimation { to: 0; duration: 500; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1; duration: 500; easing.type: Easing.InOutQuad }
        }
    }

    Behavior on opacity { NumberAnimation { duration: Theme.duration } }
}
