import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string icon: ""
    property string title: "No data"
    property string description: ""

    implicitWidth: 280
    implicitHeight: emptyLayout.implicitHeight

    ColumnLayout {
        id: emptyLayout
        anchors.centerIn: parent
        spacing: 12

        Text {
            text: root.icon
            font.pixelSize: 48
            color: Theme.mutedForeground
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            visible: text.length > 0

            opacity: 0.5
        }

        Text {
            text: root.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLg
            font.weight: Font.DemiBold
            color: Theme.foreground
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.description
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Theme.mutedForeground
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: text.length > 0
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 240
        }
    }
}
