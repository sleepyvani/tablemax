import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

T.Dialog {
    id: root

    property string dialogTitle: ""
    property string dialogDescription: ""

    anchors.centerIn: parent
    modal: true
    dim: true

    implicitWidth: 420
    padding: 24

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationModal; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: Theme.durationModal; easing.type: Easing.OutCubic }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationFast; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.95; duration: Theme.durationFast; easing.type: Easing.InCubic }
        }
    }

    header: ColumnLayout {
        spacing: 4
        visible: root.dialogTitle.length > 0

        Text {
            text: root.dialogTitle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLg
            font.weight: Font.DemiBold
            color: Theme.foreground
            Layout.fillWidth: true
        }

        Text {
            text: root.dialogDescription
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Theme.mutedForeground
            wrapMode: Text.WordWrap
            visible: root.dialogDescription.length > 0
            Layout.fillWidth: true
        }

        Item { height: 8 }
    }

    background: Rectangle {
        color: Theme.background
        border.width: 1
        border.color: Theme.border
        radius: Theme.radiusLg
    }

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.6)

        Behavior on opacity { NumberAnimation { duration: Theme.durationModal } }
    }
}
