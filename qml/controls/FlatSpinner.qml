import QtQuick

Item {
    id: root

    property int size: 20
    property color color: Theme.foreground

    implicitWidth: size
    implicitHeight: size

    Item {
        id: spinner
        anchors.centerIn: parent
        width: root.size
        height: root.size

        RotationAnimation on rotation {
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 700
            running: root.visible
        }

        Repeater {
            model: 8

            Rectangle {
                required property int index

                width: root.size * 0.15
                height: root.size * 0.3
                radius: width / 2
                color: root.color
                opacity: (index + 1) / 8

                x: spinner.width / 2 - width / 2
                y: 0
                transformOrigin: Item.Bottom

                transform: [
                    Translate { y: spinner.height / 2 - height },
                    Rotation {
                        angle: index * 45
                        origin.x: width / 2
                        origin.y: spinner.height / 2
                    }
                ]
            }
        }
    }
}
