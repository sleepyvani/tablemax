import QtQuick

Rectangle {
    id: root
    property string text: ""

    implicitWidth: kbdText.implicitWidth + 12
    implicitHeight: 20
    radius: Theme.radiusSm
    color: Theme.muted
    border.width: 1
    border.color: Theme.border

    Text {
        id: kbdText
        anchors.centerIn: parent
        text: root.text
        font.family: Theme.monoFamily
        font.pixelSize: Theme.fontSizeXs
        color: Theme.mutedForeground
    }
}
