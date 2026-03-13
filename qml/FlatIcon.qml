import QtQuick

// ── FlatIcon ─────────────────────────────────────────────────
// Renders an icon from Segoe Fluent Icons (Windows built-in)
// Usage:  FlatIcon { icon: Icons.search; size: 16; color: Theme.fg }

Text {
    id: root

    property string icon: ""
    property int size: 16
    property alias iconColor: root.color

    text: icon
    font.family: "Phosphor"
    font.pixelSize: size
    color: Theme.fg
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    width: size; height: size
}
