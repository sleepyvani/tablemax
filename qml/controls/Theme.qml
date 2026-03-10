pragma Singleton
import QtQuick

QtObject {
    // ─── Colors (shadcn dark theme) ───
    readonly property color background: "#09090b"
    readonly property color foreground: "#fafafa"

    readonly property color card: "#09090b"
    readonly property color cardForeground: "#fafafa"

    readonly property color popover: "#09090b"
    readonly property color popoverForeground: "#fafafa"

    readonly property color primary: "#fafafa"
    readonly property color primaryForeground: "#18181b"

    readonly property color secondary: "#27272a"
    readonly property color secondaryForeground: "#fafafa"

    readonly property color muted: "#27272a"
    readonly property color mutedForeground: "#a1a1aa"

    readonly property color accent: "#27272a"
    readonly property color accentForeground: "#fafafa"

    readonly property color destructive: "#7f1d1d"
    readonly property color destructiveForeground: "#fafafa"

    readonly property color border: "#27272a"
    readonly property color input: "#27272a"
    readonly property color ring: "#d4d4d8"

    readonly property color success: "#10b981"
    readonly property color warning: "#f59e0b"
    readonly property color info: "#3b82f6"

    // ─── Radius ───
    readonly property real radiusXs: 2
    readonly property real radiusSm: 4
    readonly property real radius: 6
    readonly property real radiusMd: 8
    readonly property real radiusLg: 12
    readonly property real radiusXl: 16
    readonly property real radiusFull: 9999

    // ─── Spacing ───
    readonly property real space0: 0
    readonly property real space1: 4
    readonly property real space2: 8
    readonly property real space3: 12
    readonly property real space4: 16
    readonly property real space5: 20
    readonly property real space6: 24
    readonly property real space8: 32

    // ─── Typography ───
    readonly property string fontFamily: "Inter"
    readonly property string monoFamily: "JetBrains Mono"

    readonly property int fontSizeXs: 11
    readonly property int fontSizeSm: 12
    readonly property int fontSize: 13
    readonly property int fontSizeMd: 14
    readonly property int fontSizeLg: 16
    readonly property int fontSizeXl: 18
    readonly property int fontSize2xl: 22

    // ─── Animation ───
    readonly property int durationFast: 100
    readonly property int duration: 150
    readonly property int durationSlow: 250
    readonly property int durationModal: 200

    // ─── Shadows ───
    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.25)
}
