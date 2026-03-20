import QtQuick

Rectangle {
    id: root

    property string text: ""
    property string src: ""
    property int size: 32

    width: size; height: size
    radius: Theme.rFull
    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.1)
    clip: true

    Image {
        anchors.fill: parent
        source: root.src
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        text: root.text ? root.text.charAt(0).toUpperCase() : ""
        font.family: Theme.sans
        font.pixelSize: root.size * 0.38
        font.weight: Font.DemiBold
        color: Theme.fg
        visible: !root.src || root.src.length === 0
    }
}
