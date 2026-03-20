import QtQuick

Item {
    id: root

    property real value: 0.0   // 0.0 to 1.0
    property bool indeterminate: false

    implicitWidth: 200
    implicitHeight: 8

    Rectangle {
        anchors.fill: parent
        radius: Theme.rFull
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)

        Rectangle {
            id: bar
            height: parent.height
            radius: Theme.rFull
            color: Theme.accent

            width: root.indeterminate ? parent.width * 0.35 : parent.width * root.value

            Behavior on width {
                enabled: !root.indeterminate
                NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic }
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: root.indeterminate

                NumberAnimation {
                    from: -bar.width
                    to: root.width
                    duration: 1200
                    easing.type: Easing.InOutCubic
                }
            }
        }
    }
}
