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
            implicitWidth: 6
            radius: Theme.radiusFull
            color: parent.pressed ? Qt.lighter(Theme.border, 1.3)
                 : parent.hovered ? Qt.lighter(Theme.border, 1.15)
                 : Theme.border
            opacity: parent.active ? 1.0 : 0.0

            Behavior on opacity { NumberAnimation { duration: Theme.durationSlow } }
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
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
            implicitHeight: 6
            radius: Theme.radiusFull
            color: parent.pressed ? Qt.lighter(Theme.border, 1.3)
                 : parent.hovered ? Qt.lighter(Theme.border, 1.15)
                 : Theme.border
            opacity: parent.active ? 1.0 : 0.0

            Behavior on opacity { NumberAnimation { duration: Theme.durationSlow } }
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        }

        background: Item {}
    }
}
