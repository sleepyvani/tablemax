import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string title: ""
    property bool expanded: false
    default property alias content: contentLoader.sourceComponent

    implicitWidth: parent ? parent.width : 300
    implicitHeight: headerRow.height + (expanded ? contentLoader.height + 8 : 0)

    clip: true

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    RowLayout {
        id: headerRow
        width: parent.width
        height: 40
        spacing: 0

        Text {
            text: root.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: headerMouse.containsMouse ? Theme.foreground : Theme.mutedForeground
            Layout.fillWidth: true

            Behavior on color { ColorAnimation { duration: Theme.duration } }
        }

        Text {
            text: "▸"
            font.pixelSize: 12
            color: Theme.mutedForeground
            rotation: root.expanded ? 90 : 0
            Layout.rightMargin: 4

            Behavior on rotation { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    Loader {
        id: contentLoader
        y: headerRow.height
        width: parent.width
        active: root.expanded
        opacity: root.expanded ? 1 : 0
        visible: root.expanded

        Behavior on opacity { NumberAnimation { duration: Theme.duration } }
    }
}
