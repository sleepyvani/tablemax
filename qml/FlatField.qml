import QtQuick
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root

    property string label: ""
    property string description: ""
    property string error: ""
    default property alias content: fieldContent.data

    implicitWidth: 220
    implicitHeight: fieldLayout.implicitHeight
    color: "transparent"

    ColumnLayout {
        id: fieldLayout
        anchors.fill: parent
        spacing: Theme.s6

        Text {
            text: root.label
            font.family: Theme.sans
            font.pixelSize: Theme.t13
            font.weight: Font.Medium
            color: root.error.length > 0 ? Theme.error : Theme.fg
            visible: text.length > 0
            Layout.fillWidth: true
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }

        Item {
            id: fieldContent
            Layout.fillWidth: true
            implicitHeight: childrenRect.height
        }

        Text {
            text: root.description
            font.family: Theme.sans
            font.pixelSize: Theme.t11
            color: Theme.fgMuted
            wrapMode: Text.WordWrap
            visible: text.length > 0 && root.error.length === 0
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: Theme.s4
            visible: root.error.length > 0
            FlatIcon { icon: Icons.error; size: 11; color: Theme.error }
            Text {
                text: root.error
                font.family: Theme.sans
                font.pixelSize: Theme.t11
                color: Theme.error
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
