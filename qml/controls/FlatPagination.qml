import QtQuick
import QtQuick.Layouts

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
        spacing: 4

        // Previous
        Rectangle {
            width: 32; height: 32
            radius: Theme.radius
            color: prevMouse.containsMouse ? Theme.muted : "transparent"
            opacity: root.currentPage > 1 ? 1.0 : 0.4

            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            Text {
                anchors.centerIn: parent
                text: "‹"
                font.pixelSize: 16
                color: Theme.foreground
            }

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
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
                radius: Theme.radius
                color: modelData === root.currentPage
                       ? Theme.primary
                       : (pageMouse.containsMouse ? Theme.muted : "transparent")

                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: modelData === root.currentPage ? Font.Medium : Font.Normal
                    color: modelData === root.currentPage
                           ? Theme.primaryForeground
                           : Theme.foreground
                }

                MouseArea {
                    id: pageMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pageChanged(modelData)
                }
            }
        }

        // Next
        Rectangle {
            width: 32; height: 32
            radius: Theme.radius
            color: nextMouse.containsMouse ? Theme.muted : "transparent"
            opacity: root.currentPage < root.totalPages ? 1.0 : 0.4

            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            Text {
                anchors.centerIn: parent
                text: "›"
                font.pixelSize: 16
                color: Theme.foreground
            }

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.currentPage < root.totalPages ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (root.currentPage < root.totalPages) root.pageChanged(root.currentPage + 1)
            }
        }
    }
}
