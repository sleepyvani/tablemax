import QtQuick
import QtQuick.Layouts
import "Icons.js" as Icons

Item {
    id: root

    property int currentPage: 1
    property int totalPages: 1

    signal pageChanged(int page)

    implicitWidth: row.implicitWidth
    implicitHeight: 32

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.s2

        // Previous
        Rectangle {
            width: 32; height: 32
            radius: Theme.r6
            color: prevMouse.containsMouse ? Theme.bgHover : "transparent"
            opacity: root.currentPage > 1 ? 1.0 : 0.35
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            FlatIcon { anchors.centerIn: parent; icon: Icons.left; size: 12; color: Theme.fg }

            MouseArea {
                id: prevMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: root.currentPage > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.currentPage > 1) root.pageChanged(root.currentPage - 1)
            }
        }

        // Page numbers
        Repeater {
            model: {
                let pages = []
                let start = Math.max(1, root.currentPage - 2)
                let end = Math.min(root.totalPages, start + 4)
                start = Math.max(1, end - 4)
                for (let i = start; i <= end; i++) pages.push(i)
                return pages
            }

            Rectangle {
                width: 32; height: 32
                radius: Theme.r6
                color: modelData === root.currentPage
                       ? Theme.accent
                       : (pageMouse.containsMouse ? Theme.bgHover : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Theme.sans
                    font.pixelSize: Theme.t12
                    font.weight: modelData === root.currentPage ? Font.DemiBold : Font.Normal
                    color: modelData === root.currentPage ? "#ffffff" : Theme.fg
                }

                MouseArea {
                    id: pageMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pageChanged(modelData)
                }
            }
        }

        // Next
        Rectangle {
            width: 32; height: 32
            radius: Theme.r6
            color: nextMouse.containsMouse ? Theme.bgHover : "transparent"
            opacity: root.currentPage < root.totalPages ? 1.0 : 0.35
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            FlatIcon { anchors.centerIn: parent; icon: Icons.right; size: 12; color: Theme.fg }

            MouseArea {
                id: nextMouse; anchors.fill: parent; hoverEnabled: true
                cursorShape: root.currentPage < root.totalPages ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.currentPage < root.totalPages) root.pageChanged(root.currentPage + 1)
            }
        }
    }
}
