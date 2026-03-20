import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property alias cardTitle: titleText.text
    property alias cardDescription: descText.text
    default property alias content: contentArea.data

    implicitWidth: 320
    color: Theme.bgSurface
    border.width: 1
    border.color: Theme.border
    radius: Theme.r12

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.s24
        spacing: Theme.s8

        Text {
            id: titleText
            font.family: Theme.sans
            font.pixelSize: Theme.t16
            font.weight: Font.DemiBold
            color: Theme.fg
            visible: text.length > 0
            Layout.fillWidth: true
        }

        Text {
            id: descText
            font.family: Theme.sans
            font.pixelSize: Theme.t13
            color: Theme.fgMuted
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
