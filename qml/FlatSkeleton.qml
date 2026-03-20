import QtQuick

Rectangle {
    id: root

    implicitWidth: 200
    implicitHeight: 16
    radius: Theme.r4
    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)

    SequentialAnimation on opacity {
        loops: Animation.Infinite
        running: true
        NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
    }
}
