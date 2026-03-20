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

    font.family: Theme.sans
    font.pixelSize: size === "xs" ? Theme.t11 : (size === "sm" ? Theme.t12 : Theme.t13)
    font.weight: Font.Medium

    opacity: enabled ? 1.0 : 0.5

    background: Rectangle {
        radius: Theme.r6

        color: {
            switch (root.variant) {
                case "outline":
                    return root.down ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) :
                           root.hovered ? Theme.bgHover : "transparent"
                case "secondary":
                    return root.down ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12) :
                           root.hovered ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) :
                           Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)
                case "ghost":
                    return root.down ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) :
                           root.hovered ? Theme.bgHover : "transparent"
                case "destructive":
                    return root.down ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.25) :
                           root.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) :
                           Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)
                case "link":
                    return "transparent"
                default:   // "default" → accent
                    return root.down ? Qt.darker(Theme.accent, 1.1) :
                           root.hovered ? Theme.accentHover : Theme.accent
            }
        }

        border.width: root.variant === "outline" ? 1 : 0
        border.color: Theme.border

        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: {
            switch (root.variant) {
                case "outline":     return Theme.fg
                case "secondary":   return Theme.fg
                case "ghost":       return Theme.fg
                case "destructive": return Theme.error
                case "link":        return Theme.accent
                default:            return "#ffffff"   // white on accent background
            }
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Behavior on opacity { NumberAnimation { duration: Theme.fast } }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
