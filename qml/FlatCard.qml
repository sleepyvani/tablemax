import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property alias cardTitle: titleText.text
    property alias cardDescription: descText.text
    default property alias content: contentArea.data

    implicitWidth: 320
    color: Theme.card
    border.width: 1
    border.color: Theme.border
    radius: Theme.radiusLg

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.s24
        spacing: Theme.s8

        Text {
            id: titleText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLg
            font.weight: Font.DemiBold
            color: Theme.foreground
            visible: text.length > 0
            Layout.fillWidth: true
        }

        Text {
            id: descText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Theme.mutedForeground
            wrapMode: Text.WordWrap
            visible: text.length > 0
            Layout.fillWidth: true
        }

        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
