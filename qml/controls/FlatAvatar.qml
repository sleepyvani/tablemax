import QtQuick

Rectangle {
    id: root

    property string text: ""
    property string src: ""
    property int size: 32

    width: size
    height: size
    radius: Theme.radiusFull
    color: Theme.muted
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
        font.family: Theme.fontFamily
        font.pixelSize: root.size * 0.4
        font.weight: Font.Medium
        color: Theme.foreground
        visible: !root.src || root.src.length === 0
    }
}
