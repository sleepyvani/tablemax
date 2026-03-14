// SearchFilterBar.qml — In-grid search and column filter bar
// Inspired by phpMyAdmin search, Compass filter, Drizzle filter panel

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    height: visible ? 40 : 0; color: Theme.bgElevated
    visible: isOpen

    property bool isOpen: false
    property string searchText: ""
    property int matchCount: 0
    property int currentMatch: 0
    property var resultModel: null

    signal searchChanged(string text)
    signal nextMatch()
    signal previousMatch()
    signal closed()

    Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12
        spacing: Theme.s8

        // Search icon
        FlatIcon { icon: Icons.search; size: 14; color: Theme.fgMuted }

        // Search input
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 28
            radius: Theme.r6; color: Theme.bgSurface
            border.width: 1; border.color: searchInput.activeFocus ? Theme.accent : Theme.border

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s8; anchors.rightMargin: Theme.s8; spacing: Theme.s6

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.family: Theme.fontFamily; font.pixelSize: Theme.t12; color: Theme.fg
                    selectByMouse: true; clip: true

                    Text {
                        visible: !searchInput.text && !searchInput.activeFocus
                        text: "Search in results… (Ctrl+G)"
                        font: parent.font; color: Theme.fgDim
                    }

                    onTextChanged: {
                        searchText = text
                        searchChanged(text)
                    }

                    Keys.onEscapePressed: { searchInput.text = ""; root.isOpen = false; root.closed() }
                    Keys.onReturnPressed: root.nextMatch()
                    Keys.onEnterPressed: root.nextMatch()
                }

                // Match counter
                Text {
                    visible: searchInput.text.length > 0
                    text: matchCount > 0 ? (currentMatch + 1) + "/" + matchCount : "0 results"
                    font.pixelSize: Theme.t11; font.family: Theme.mono; color: matchCount > 0 ? Theme.fgDim : Theme.error
                }
            }
        }

        // Prev/Next match
        Rectangle {
            width: 24; height: 24; radius: Theme.r4
            color: prevMatchMa.containsMouse ? Theme.bgHover : "transparent"
            opacity: matchCount > 0 ? 1 : 0.3
            FlatIcon { anchors.centerIn: parent; icon: Icons.chevronUp; size: 12; color: Theme.fgMuted }
            MouseArea { id: prevMatchMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.previousMatch() }
            FlatTooltip { visible: prevMatchMa.containsMouse; text: "Previous match"; y: -28 }
        }

        Rectangle {
            width: 24; height: 24; radius: Theme.r4
            color: nextMatchMa.containsMouse ? Theme.bgHover : "transparent"
            opacity: matchCount > 0 ? 1 : 0.3
            FlatIcon { anchors.centerIn: parent; icon: Icons.chevronDown; size: 12; color: Theme.fgMuted }
            MouseArea { id: nextMatchMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.nextMatch() }
            FlatTooltip { visible: nextMatchMa.containsMouse; text: "Next match"; y: -28 }
        }

        // Separator
        Rectangle { width: 1; height: 20; color: Theme.border; opacity: 0.5 }

        // Column filter dropdown
        Rectangle {
            width: colFilterRow.implicitWidth + Theme.s16; height: 24; radius: Theme.rFull
            color: colFilterMa.containsMouse ? Theme.bgHover : Theme.bgSurface
            border.width: 1; border.color: Theme.border

            RowLayout {
                id: colFilterRow; anchors.centerIn: parent; spacing: Theme.s4
                FlatIcon { icon: Icons.filter; size: 10; color: Theme.fgMuted }
                Text { text: "All Columns"; font.pixelSize: Theme.t11; font.weight: Font.Medium; color: Theme.fgMuted; font.family: Theme.fontFamily }
            }

            MouseArea {
                id: colFilterMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {} // TODO: column filter dropdown
            }
        }

        // Regex toggle
        Rectangle {
            width: 24; height: 24; radius: Theme.r4
            color: regexActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : regexMa.containsMouse ? Theme.bgHover : "transparent"
            border.width: regexActive ? 1 : 0
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)

            property bool regexActive: false

            Text { anchors.centerIn: parent; text: ".*"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: parent.regexActive ? Theme.accent : Theme.fgMuted }
            MouseArea { id: regexMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.regexActive = !parent.regexActive }
            FlatTooltip { visible: regexMa.containsMouse; text: "Toggle regex"; y: -28 }
        }

        // Case toggle
        Rectangle {
            width: 24; height: 24; radius: Theme.r4
            color: caseActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12) : caseMa.containsMouse ? Theme.bgHover : "transparent"
            border.width: caseActive ? 1 : 0
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)

            property bool caseActive: false

            Text { anchors.centerIn: parent; text: "Aa"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.fontFamily; color: parent.caseActive ? Theme.accent : Theme.fgMuted }
            MouseArea { id: caseMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.caseActive = !parent.caseActive }
            FlatTooltip { visible: caseMa.containsMouse; text: "Match case"; y: -28 }
        }

        // Close
        Rectangle {
            width: 24; height: 24; radius: Theme.r4
            color: closeSearchMa.containsMouse ? Theme.bgHover : "transparent"
            FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 12; color: Theme.fgMuted }
            MouseArea { id: closeSearchMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { searchInput.text = ""; root.isOpen = false; root.closed() } }
        }
    }

    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

    function focusSearch() {
        isOpen = true
        searchInput.forceActiveFocus()
    }
}
