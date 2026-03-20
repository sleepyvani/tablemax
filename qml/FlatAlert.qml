import QtQuick
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root

    property string alertTitle: ""
    property string alertDescription: ""
    property string variant: "default"   // default, destructive, success, warning, info

    implicitWidth: 320
    implicitHeight: contentLayout.implicitHeight + 24
    radius: Theme.r6
    border.width: 1

    color: {
        switch (variant) {
            case "destructive": return Qt.rgba(Theme.error.r,   Theme.error.g,   Theme.error.b,   0.06)
            case "success":     return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.06)
            case "warning":     return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.06)
            case "info":        return Qt.rgba(Theme.info.r,    Theme.info.g,    Theme.info.b,    0.06)
            default:            return Theme.bgSurface
        }
    }

    border.color: {
        switch (variant) {
            case "destructive": return Qt.rgba(Theme.error.r,   Theme.error.g,   Theme.error.b,   0.3)
            case "success":     return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.3)
            case "warning":     return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3)
            case "info":        return Qt.rgba(Theme.info.r,    Theme.info.g,    Theme.info.b,    0.3)
            default:            return Theme.border
        }
    }

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: Theme.s12
        spacing: Theme.s8

        // Variant icon
        FlatIcon {
            size: 14; visible: root.variant !== "default"
            icon: {
                switch (root.variant) {
                    case "destructive": return Icons.error
                    case "success":     return Icons.success
                    case "warning":     return Icons.warning
                    case "info":        return Icons.info
                    default:            return ""
                }
            }
            color: {
                switch (root.variant) {
                    case "destructive": return Theme.error
                    case "success":     return Theme.success
                    case "warning":     return Theme.warning
                    case "info":        return Theme.info
                    default:            return Theme.fg
                }
            }
            Layout.alignment: Qt.AlignTop
        }

        ColumnLayout {
            spacing: Theme.s4; Layout.fillWidth: true

            Text {
                text: root.alertTitle
                font.family: Theme.sans
                font.pixelSize: Theme.t13
                font.weight: Font.DemiBold
                color: {
                    switch (root.variant) {
                        case "destructive": return Theme.error
                        case "success":     return Theme.success
                        case "warning":     return Theme.warning
                        case "info":        return Theme.info
                        default:            return Theme.fg
                    }
                }
                visible: text.length > 0
                Layout.fillWidth: true
            }

            Text {
                text: root.alertDescription
                font.family: Theme.sans
                font.pixelSize: Theme.t12
                color: Theme.fgMuted
                wrapMode: Text.WordWrap
                visible: text.length > 0
                Layout.fillWidth: true
            }
        }
    }
}
