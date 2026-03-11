import QtQuick
import QtQuick.Controls.Basic as T

T.Button {
    id: root

    property string variant: "default"   // default, outline, secondary, ghost, destructive, link
    property string size: "default"      // xs, sm, default, lg, icon

    implicitWidth: size === "icon" ? implicitHeight : contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: {
        switch (size) {
            case "xs": return 24
            case "sm": return 28
            case "default": return 32
            case "lg": return 36
            case "icon": return 32
            default: return 32
        }
    }

    leftPadding: {
        if (size === "icon") return 0
        switch (size) {
            case "xs": return 8
            case "sm": return 10
            default: return 12
        }
    }
    rightPadding: leftPadding
    topPadding: 0
    bottomPadding: 0

    font.family: Theme.fontFamily
    font.pixelSize: size === "xs" ? Theme.fontSizeXs : (size === "sm" ? Theme.fontSizeSm : Theme.fontSize)
    font.weight: Font.Medium

    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        radius: size === "xs" ? Theme.radiusSm : Theme.radius

        color: {
            switch (root.variant) {
                case "outline":
                    return root.down ? Qt.darker(Theme.background, 1.2) :
                           root.hovered ? Theme.muted : Theme.background
                case "secondary":
                    return root.down ? Qt.darker(Theme.secondary, 1.2) :
                           root.hovered ? Qt.lighter(Theme.secondary, 1.2) : Theme.secondary
                case "ghost":
                    return root.down ? Qt.darker(Theme.muted, 1.1) :
                           root.hovered ? Theme.muted : "transparent"
                case "destructive":
                    return root.down ? Qt.rgba(0.94, 0.27, 0.27, 0.25) :
                           root.hovered ? Qt.rgba(0.94, 0.27, 0.27, 0.15) : Qt.rgba(0.94, 0.27, 0.27, 0.1)
                case "link":
                    return "transparent"
                default:
                    return root.down ? Qt.darker(Theme.primary, 1.15) :
                           root.hovered ? Qt.darker(Theme.primary, 1.1) : Theme.primary
            }
        }

        border.width: root.variant === "outline" ? 1 : 0
        border.color: Theme.border

        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: {
            switch (root.variant) {
                case "outline": return Theme.foreground
                case "secondary": return Theme.secondaryForeground
                case "ghost": return Theme.foreground
                case "destructive": return Theme.error
                case "link": return Theme.primary
                default: return Theme.primaryForeground
            }
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }

    Behavior on opacity { NumberAnimation { duration: Theme.duration } }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
