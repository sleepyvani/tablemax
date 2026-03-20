import QtQuick

Rectangle {
    id: root

    property string text: ""
    property string variant: "default"  // default, secondary, outline, destructive, success, warning

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 20
    radius: Theme.rFull

    color: {
        switch (variant) {
            case "secondary":   return Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
            case "outline":     return "transparent"
            case "destructive": return Qt.rgba(Theme.error.r,   Theme.error.g,   Theme.error.b,   0.12)
            case "success":     return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.12)
            case "warning":     return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12)
            default:            return Theme.accent
        }
    }

    border.width: variant === "outline" ? 1 : 0
    border.color: Theme.border

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.family: Theme.sans
        font.pixelSize: Theme.t10
        font.weight: Font.DemiBold
        color: {
            switch (root.variant) {
                case "secondary":   return Theme.fg
                case "outline":     return Theme.fg
                case "destructive": return Theme.error
                case "success":     return Theme.success
                case "warning":     return Theme.warning
                default:            return "#ffffff"
            }
        }
    }
}
