pragma Singleton
import QtQuick

QtObject {
    // ─── Colors ───
    readonly property color bg: "#0a0a0f"
    readonly property color bgSidebar: "#0d0d14"
    readonly property color bgElevated: "#111118"
    readonly property color bgSurface: "#16161f"
    readonly property color bgHover: "#1a1a24"
    readonly property color bgActive: "#1e1e2a"

    readonly property color fg: "#e4e4e9"
    readonly property color fgMuted: "#6b6b80"
    readonly property color fgDim: "#4a4a5e"

    readonly property color border: "#1e1e2a"
    readonly property color borderLight: "#2a2a38"
    readonly property color borderFocus: "#6366f1"

    readonly property color accent: "#6366f1"
    readonly property color accentHover: "#818cf8"
    readonly property color accentDim: Qt.rgba(0.39, 0.4, 0.95, 0.12)

    readonly property color success: "#34d399"
    readonly property color warning: "#fbbf24"
    readonly property color error: "#f87171"
    readonly property color info: "#60a5fa"

    // Syntax
    readonly property color synKeyword: "#c084fc"
    readonly property color synString: "#34d399"
    readonly property color synNumber: "#60a5fa"
    readonly property color synComment: "#4a4a5e"
    readonly property color synFunction: "#fbbf24"
    readonly property color synType: "#f87171"

    // ─── Radius ───
    readonly property real r4: 4
    readonly property real r6: 6
    readonly property real r8: 8
    readonly property real r12: 12
    readonly property real rFull: 9999

    // ─── Spacing ───
    readonly property real s2: 2
    readonly property real s4: 4
    readonly property real s6: 6
    readonly property real s8: 8
    readonly property real s12: 12
    readonly property real s16: 16
    readonly property real s20: 20
    readonly property real s24: 24

    // ─── Typography ───
    readonly property string sans: "Segoe UI"
    readonly property string mono: "Cascadia Code"
    readonly property int t11: 11
    readonly property int t12: 12
    readonly property int t13: 13
    readonly property int t14: 14
    readonly property int t16: 16
    readonly property int t20: 20
    readonly property int t24: 24

    // ─── Animation ───
    readonly property int fast: 80
    readonly property int normal: 140
    readonly property int slow: 220

    // ═══════════════════════════════════════════════
    // Backward compatibility aliases for Flat* controls
    // ═══════════════════════════════════════════════
    readonly property color background: bg
    readonly property color foreground: fg
    readonly property color primary: accent
    readonly property color primaryForeground: "#ffffff"
    readonly property color secondary: bgSurface
    readonly property color secondaryForeground: fg
    readonly property color muted: bgSurface
    readonly property color mutedForeground: fgMuted
    readonly property color card: bgElevated
    readonly property color cardForeground: fg
    readonly property color popover: bgElevated
    readonly property color popoverForeground: fg
    readonly property color destructive: error
    readonly property color destructiveForeground: "#ffffff"
    readonly property color input: borderLight
    readonly property color ring: borderFocus
    readonly property color accentColor: accentDim
    readonly property color accentForeground: fg

    readonly property string fontFamily: sans
    readonly property string monoFamily: mono
    readonly property int fontSizeXs: 10
    readonly property int fontSizeSm: t12
    readonly property int fontSize: t13
    readonly property int fontSizeMd: t14
    readonly property int fontSizeLg: t16
    readonly property int fontSizeXl: t20
    readonly property int fontSize2xl: t24

    readonly property real radius: r6
    readonly property real radiusSm: r4
    readonly property real radiusMd: r8
    readonly property real radiusLg: r12
    readonly property real radiusFull: rFull

    readonly property int duration: normal
    readonly property int durationFast: fast
    readonly property int durationSlow: slow
    readonly property int durationModal: slow
}
