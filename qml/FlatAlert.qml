import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string alertTitle: ""
    property string alertDescription: ""
    property string variant: "default"   // default, destructive, success, warning

    implicitWidth: 320
    implicitHeight: contentLayout.implicitHeight + 24
    radius: Theme.radius
    border.width: 1

    color: {
        switch (variant) {
            case "destructive": return Qt.rgba(0.94, 0.27, 0.27, 0.05)
            case "success": return Qt.rgba(0.06, 0.73, 0.51, 0.05)
            case "warning": return Qt.rgba(0.96, 0.62, 0.04, 0.05)
            default: return Theme.background
        }
    }

    border.color: {
        switch (variant) {
            case "destructive": return Qt.rgba(0.94, 0.27, 0.27, 0.3)
            case "success": return Qt.rgba(0.06, 0.73, 0.51, 0.3)
            case "warning": return Qt.rgba(0.96, 0.62, 0.04, 0.3)
            default: return Theme.border
        }
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4

        Text {
            text: root.alertTitle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: {
                switch (root.variant) {
                    case "destructive": return Theme.error
                    case "success": return Theme.success
                    case "warning": return Theme.warning
                    default: return Theme.foreground
                }
            }
            visible: text.length > 0
            Layout.fillWidth: true
        }

        Text {
            text: root.alertDescription
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            color: Theme.mutedForeground
            wrapMode: Text.WordWrap
            visible: text.length > 0
            Layout.fillWidth: true
        }
    }
}
