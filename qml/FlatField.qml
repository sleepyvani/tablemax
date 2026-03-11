import QtQuick
import QtQuick.Layouts

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
        spacing: 6

        Text {
            text: root.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: Theme.foreground
            visible: text.length > 0
            Layout.fillWidth: true
        }

        Item {
            id: fieldContent
            Layout.fillWidth: true
            implicitHeight: childrenRect.height
        }

        Text {
            text: root.description
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            color: Theme.mutedForeground
            wrapMode: Text.WordWrap
            visible: text.length > 0 && root.error.length === 0
            Layout.fillWidth: true
        }

        Text {
            text: root.error
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            color: Theme.error
            wrapMode: Text.WordWrap
            visible: text.length > 0
            Layout.fillWidth: true

            opacity: text.length > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.duration } }
        }
    }
}
