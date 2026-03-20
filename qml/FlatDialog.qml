import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

T.Dialog {
    id: root

    property string dialogTitle: ""
    property string dialogDescription: ""

    parent: T.Overlay.overlay
    anchors.centerIn: parent
    modal: true
    dim: true

    implicitWidth: 420
    padding: Theme.s24

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.slow; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: Theme.slow; easing.type: Easing.OutCubic }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.95; duration: Theme.fast; easing.type: Easing.InCubic }
        }
    }

    header: Item {
        visible: root.dialogTitle.length > 0
        implicitHeight: headerCol.implicitHeight + Theme.s24 + Theme.s8

        ColumnLayout {
            id: headerCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.s24
            anchors.rightMargin: Theme.s24
            anchors.topMargin: Theme.s24
            spacing: Theme.s4

            Text {
                text: root.dialogTitle
                font.family: Theme.sans
                font.pixelSize: Theme.t16
                font.weight: Font.DemiBold
                color: Theme.fg
                Layout.fillWidth: true
            }

            Text {
                text: root.dialogDescription
                font.family: Theme.sans
                font.pixelSize: Theme.t13
                color: Theme.fgMuted
                wrapMode: Text.WordWrap
                visible: root.dialogDescription.length > 0
                Layout.fillWidth: true
            }
        }
    }

    background: Rectangle {
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
        radius: Theme.r12
    }

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.6)
        Behavior on opacity { NumberAnimation { duration: Theme.slow } }
    }
}
