// HistoryPanel.qml — Searchable query history sidebar
// Ported from TablePro HistoryPanelView.swift

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    color: Theme.bg

    signal querySelected(string query)
    signal close()
    property var historyService: null

    property string searchQuery: ""
    property var filteredEntries: {
        if (!historyService) return []
        return historyService.search(searchQuery)
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Header ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 40; color: Theme.bgElevated
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8
                FlatIcon { icon: Icons.clock; size: 14; color: Theme.accent }
                Text { text: "Query History"; font.pixelSize: Theme.t13; font.weight: Font.DemiBold; color: Theme.fg; font.family: Theme.fontFamily; Layout.fillWidth: true }
                Text {
                    text: filteredEntries.length
                    font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.fontFamily
                    visible: filteredEntries.length > 0
                }
                Rectangle {
                    width: 20; height: 20; radius: Theme.r4; color: closeMa.containsMouse ? Theme.bgHover : "transparent"
                    FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 10; color: Theme.fgMuted }
                    MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ── Search ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 36; color: Theme.bgElevated
            RowLayout {
                anchors.fill: parent; anchors.margins: Theme.s8; spacing: Theme.s6
                FlatIcon { icon: Icons.search; size: 12; color: Theme.fgMuted }
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true; Layout.fillHeight: true
                    font.pixelSize: Theme.t12; font.family: Theme.fontFamily; color: Theme.fg
                    selectByMouse: true; clip: true
                    onTextChanged: searchQuery = text
                    Text {
                        visible: !parent.text; text: "Search queries..."
                        font: parent.font; color: Theme.fgDim; anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Rectangle {
                    width: 16; height: 16; radius: Theme.rFull; color: clearMa.containsMouse ? Theme.bgHover : "transparent"
                    visible: searchInput.text.length > 0
                    FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 8; color: Theme.fgMuted }
                    MouseArea { id: clearMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { searchInput.text = ""; searchQuery = "" } }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ── History List ──
        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true
            model: filteredEntries; clip: true; spacing: 0
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                width: ListView.view.width; height: histCol.implicitHeight + 16
                color: histItemMa.containsMouse ? Theme.bgHover : "transparent"

                ColumnLayout {
                    id: histCol
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                    spacing: Theme.s4

                    // Query text
                    Text {
                        Layout.fillWidth: true
                        text: modelData.query || ""
                        font.pixelSize: Theme.t12; font.family: "Cascadia Code, Consolas, monospace"
                        color: Theme.fg; wrapMode: Text.NoWrap; elide: Text.ElideRight
                        maximumLineCount: 2
                    }

                    // Metadata row
                    RowLayout {
                        spacing: Theme.s8
                        // Database badge
                        Rectangle {
                            width: dbLabel.implicitWidth + Theme.s8; height: 16; radius: Theme.r4
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                            Text { id: dbLabel; anchors.centerIn: parent; text: modelData.database || "" ;font.pixelSize: Theme.t11; color: Theme.accent; font.family: Theme.fontFamily }
                        }
                        // Status
                        FlatIcon {
                            icon: modelData.success ? Icons.success : Icons.error
                            size: 10; color: modelData.success ? Theme.success : Theme.error
                        }
                        // Execution time
                        Text {
                            text: (modelData.executionTime || 0).toFixed(0) + "ms"
                            font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.fontFamily
                        }
                        // Rows affected
                        Text {
                            text: (modelData.rowsAffected || 0) + " rows"
                            font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.fontFamily
                            visible: (modelData.rowsAffected || 0) > 0
                        }
                        Item { Layout.fillWidth: true }
                        // Timestamp
                        Text {
                            text: formatTimestamp(modelData.timestamp || "")
                            font.pixelSize: 10; color: Theme.fgDim; font.family: Theme.fontFamily
                        }
                    }
                }

                MouseArea {
                    id: histItemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.querySelected(modelData.query || "")
                    onDoubleClicked: root.querySelected(modelData.query || "")
                }

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.3 }
            }

            // Empty state
            FlatEmpty {
                anchors.centerIn: parent
                visible: filteredEntries.length === 0
                icon: Icons.clock; title: searchQuery ? "No results" : "No history yet"
                description: searchQuery ? "Try a different search" : "Run some queries to see them here"
            }
        }

        // ── Footer ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32; color: Theme.bgElevated
            visible: filteredEntries.length > 0
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12
                Item { Layout.fillWidth: true }
                FlatButton {
                    text: "Clear History"; variant: "ghost"; size: "sm"
                    onClicked: if (historyService) historyService.clearHistory()
                }
            }
        }
    }

    function formatTimestamp(ts) {
        if (!ts) return ""
        var d = new Date(ts)
        var now = new Date()
        var diff = now - d
        if (diff < 60000) return "just now"
        if (diff < 3600000) return Math.floor(diff / 60000) + "m ago"
        if (diff < 86400000) return Math.floor(diff / 3600000) + "h ago"
        if (diff < 604800000) return Math.floor(diff / 86400000) + "d ago"
        return d.toLocaleDateString()
    }
}
