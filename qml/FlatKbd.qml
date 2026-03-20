import QtQuick

Rectangle {
    id: root
    property string text: ""

    implicitWidth: kbdText.implicitWidth + 12
    implicitHeight: 20
    radius: Theme.r4
    color: Theme.bgSurface
    border.width: 1
    border.color: Theme.border

    Text {
        id: kbdText
        anchors.centerIn: parent
        text: root.text
        font.family: Theme.mono
        font.pixelSize: Theme.t11
        color: Theme.fgMuted
    }
}
