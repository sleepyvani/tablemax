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
}
