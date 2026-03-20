import QtQuick
import QtQuick.Controls.Basic as T

T.ScrollView {
    id: root

    T.ScrollBar.vertical: T.ScrollBar {
        parent: root
        x: root.width - width - 2
        y: 2
        height: root.height - 4
        policy: T.ScrollBar.AsNeeded

        contentItem: Rectangle {
            implicitWidth: 5
            radius: Theme.rFull
            color: parent.pressed ? Theme.fg
                 : parent.hovered ? Theme.fgMuted
                 : Theme.fgDim
            opacity: parent.active ? 0.6 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.slow } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }

        background: Item {}
    }

    T.ScrollBar.horizontal: T.ScrollBar {
        parent: root
        x: 2
        y: root.height - height - 2
        width: root.width - 4
        policy: T.ScrollBar.AsNeeded

        contentItem: Rectangle {
            implicitHeight: 5
            radius: Theme.rFull
            color: parent.pressed ? Theme.fg
                 : parent.hovered ? Theme.fgMuted
                 : Theme.fgDim
            opacity: parent.active ? 0.6 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.slow } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }

        background: Item {}
    }
}
