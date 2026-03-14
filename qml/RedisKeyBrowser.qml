// RedisKeyBrowser.qml — Redis key-value browser
// Displays data grouped by type with TTL/type badges

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    color: Theme.bg

    property var resultModel: null
    property int totalRows: resultModel ? resultModel.totalRows : 0
    property int totalColumns: resultModel ? resultModel.totalColumns : 0

    signal toast(string message, string type)

    TextEdit { id: _clip; visible: false }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Toolbar ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 36; color: Theme.bgElevated
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8
                FlatIcon { icon: Icons.key; size: 14; color: "#ef4444" }
                Text {
                    text: totalRows + " key" + (totalRows !== 1 ? "s" : "")
                    font.pixelSize: Theme.t12; font.weight: Font.Medium; color: Theme.fg; font.family: Theme.fontFamily
                }
                Item { Layout.fillWidth: true }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ── Key List ──
        ListView {
            id: keyListView
            Layout.fillWidth: true; Layout.fillHeight: true
            model: totalRows; clip: true; spacing: 0
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: keyDelegate
                required property int index
                property int keyIdx: index

                width: keyListView.width; height: 42
                color: keyMa.containsMouse ? Theme.bgHover : keyIdx % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.s12
                    anchors.rightMargin: Theme.s12
                    spacing: Theme.s8

                    // Key icon based on type
                    Rectangle {
                        width: 24; height: 24; radius: Theme.r6
                        color: getTypeColor(getRedisType(keyDelegate.keyIdx), 0.12)
                        FlatIcon {
                            anchors.centerIn: parent
                            icon: getTypeIcon(getRedisType(keyDelegate.keyIdx))
                            size: 12; color: getTypeColor(getRedisType(keyDelegate.keyIdx), 1)
                        }
                    }

                    // Key name
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text {
                            text: getKeyName(keyDelegate.keyIdx)
                            font.pixelSize: Theme.t12; font.family: "Cascadia Code, Consolas, monospace"
                            color: Theme.fg; elide: Text.ElideMiddle; Layout.fillWidth: true
                        }
                        Text {
                            text: getKeyPreview(keyDelegate.keyIdx)
                            font.pixelSize: Theme.t11; font.family: "Cascadia Code, Consolas, monospace"
                            color: Theme.fgMuted; elide: Text.ElideRight; Layout.fillWidth: true
                            visible: text !== ""
                        }
                    }

                    // Type badge
                    Rectangle {
                        width: typeLbl.implicitWidth + Theme.s8; height: 18; radius: Theme.rFull
                        color: getTypeColor(getRedisType(keyDelegate.keyIdx), 0.1)
                        Text {
                            id: typeLbl; anchors.centerIn: parent
                            text: getRedisType(keyDelegate.keyIdx).toUpperCase()
                            font.pixelSize: 9; font.weight: Font.Medium
                            font.family: Theme.fontFamily; color: getTypeColor(getRedisType(keyDelegate.keyIdx), 1)
                        }
                    }

                    // TTL badge
                    Rectangle {
                        visible: getTTL(keyDelegate.keyIdx) !== ""
                        width: ttlLbl.implicitWidth + Theme.s8; height: 18; radius: Theme.rFull
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                        RowLayout {
                            anchors.centerIn: parent; spacing: 3
                            FlatIcon { icon: Icons.clock; size: 8; color: Theme.fgMuted }
                            Text { id: ttlLbl; text: getTTL(keyDelegate.keyIdx); font.pixelSize: 9; color: Theme.fgMuted; font.family: Theme.fontFamily }
                        }
                    }

                    // Copy button
                    Rectangle {
                        width: 24; height: 24; radius: Theme.r4; color: copyKeyMa.containsMouse ? Theme.bgHover : "transparent"
                        FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 11; color: Theme.fgMuted }
                        MouseArea {
                            id: copyKeyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { _clip.text = getKeyValue(keyDelegate.keyIdx); _clip.selectAll(); _clip.copy(); root.toast("Value copied", "success") }
                        }
                    }
                }

                MouseArea { id: keyMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.3 }
            }
        }

        // Empty state
        FlatEmpty {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter; visible: totalRows === 0
            icon: Icons.key; title: "No keys"; description: "Run a Redis command to see results"
        }
    }

    // ── Helpers ──
    function getKeyName(row) {
        if (!resultModel || totalColumns < 1) return ""
        return String(resultModel.data(resultModel.index(row, 0), 0) || "")
    }

    function getKeyValue(row) {
        if (!resultModel || totalColumns < 2) return ""
        return String(resultModel.data(resultModel.index(row, 1), 0) || "")
    }

    function getRedisType(row) {
        if (!resultModel || totalColumns < 3) return "string"
        var t = String(resultModel.data(resultModel.index(row, 2), 0) || "string")
        return t.toLowerCase()
    }

    function getTTL(row) {
        if (!resultModel || totalColumns < 4) return ""
        var ttl = resultModel.data(resultModel.index(row, 3), 0)
        if (ttl === undefined || ttl === null || ttl === "-1" || ttl === -1) return ""
        var n = parseInt(ttl)
        if (n < 60) return n + "s"
        if (n < 3600) return Math.floor(n / 60) + "m"
        if (n < 86400) return Math.floor(n / 3600) + "h"
        return Math.floor(n / 86400) + "d"
    }

    function getKeyPreview(row) {
        var val = getKeyValue(row)
        if (val.length > 60) return val.substring(0, 60) + "…"
        return val
    }

    function getTypeIcon(type) {
        if (type === "string") return Icons.formatText
        if (type === "list") return Icons.list
        if (type === "set") return Icons.grid
        if (type === "zset") return Icons.chart
        if (type === "hash") return Icons.code
        if (type === "stream") return Icons.lightning
        return Icons.key
    }

    function getTypeColor(type, alpha) {
        if (type === "string") return Qt.rgba(0.22, 0.56, 0.93, alpha)
        if (type === "list") return Qt.rgba(0.93, 0.55, 0.22, alpha)
        if (type === "set") return Qt.rgba(0.55, 0.22, 0.93, alpha)
        if (type === "zset") return Qt.rgba(0.22, 0.78, 0.56, alpha)
        if (type === "hash") return Qt.rgba(0.93, 0.22, 0.44, alpha)
        if (type === "stream") return Qt.rgba(0.22, 0.78, 0.93, alpha)
        return Qt.rgba(0.5, 0.5, 0.5, alpha)
    }
}
