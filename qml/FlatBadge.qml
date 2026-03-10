import QtQuick

Rectangle {
    id: root

    property string text: ""
    property string variant: "default"  // default, secondary, outline, destructive, success, warning

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 20
    radius: Theme.radiusFull

    color: {
        switch (variant) {
            case "secondary": return Theme.secondary
            case "outline": return "transparent"
            case "destructive": return Qt.rgba(0.94, 0.27, 0.27, 0.1)
            case "success": return Qt.rgba(0.06, 0.73, 0.51, 0.1)
            case "warning": return Qt.rgba(0.96, 0.62, 0.04, 0.1)
            default: return Theme.primary
        }
    }

    border.width: variant === "outline" ? 1 : 0
    border.color: Theme.border

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        font.weight: Font.Medium
        color: {
            switch (root.variant) {
                case "secondary": return Theme.secondaryForeground
                case "outline": return Theme.foreground
                case "destructive": return "#ef4444"
                case "success": return Theme.success
                case "warning": return Theme.warning
                default: return Theme.primaryForeground
            }
        }
    }
}
