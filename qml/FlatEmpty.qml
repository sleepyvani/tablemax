import QtQuick
import QtQuick.Layouts
import "Icons.js" as Icons

Item {
    id: root

    property string icon: Icons.database
    property string title: "No data"
    property string description: ""
    property string actionText: ""     // optional CTA button label
    signal actionClicked()

    implicitWidth: 280
    implicitHeight: emptyLayout.implicitHeight

    ColumnLayout {
        id: emptyLayout
        anchors.centerIn: parent
        spacing: Theme.s12

        // Large icon
        FlatIcon {
            icon: root.icon
            size: 36
            color: Theme.fgDim
            opacity: 0.35
            Layout.alignment: Qt.AlignHCenter
            visible: root.icon.length > 0
        }

        Text {
            text: root.title
            font.family: Theme.sans
            font.pixelSize: Theme.t14
            font.weight: Font.DemiBold
            color: Theme.fg
            opacity: 0.7
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.description
            font.family: Theme.sans
            font.pixelSize: Theme.t12
            color: Theme.fgMuted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: text.length > 0
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 240
        }

        // Optional action button
        Rectangle {
            visible: root.actionText.length > 0
            Layout.alignment: Qt.AlignHCenter
            height: 28; width: actionLbl.implicitWidth + 24; radius: Theme.r6
            color: actMa.containsMouse ? Theme.bgHover : Theme.bgSurface
            border.width: 1; border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            Text {
                id: actionLbl; anchors.centerIn: parent
                text: root.actionText
                font.family: Theme.sans; font.pixelSize: Theme.t12
                color: Theme.accent
            }
            MouseArea { id: actMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.actionClicked() }
        }
    }
}
