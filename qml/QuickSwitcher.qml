import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

// ── Quick Switcher (Cmd+K) ───────────────────────────────────
// Spotlight-style fuzzy search across tables, databases, actions

FlatDialog {
    id: quickSwitcher
    dialogTitle: ""
    dialogDescription: ""
    width: 480
    modal: true

    property var tables: []
    property var databases: []
    property var recentQueries: []

    signal tableSelected(string tableName)
    signal databaseSelected(string dbName)
    signal actionTriggered(string action)

    contentItem: ColumnLayout {
        spacing: 0

        // ── Search Input ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 48
            color: "transparent"

            RowLayout {
                anchors.fill: parent; spacing: Theme.s8

                FlatIcon { icon: Icons.search; size: 16; color: Theme.fgMuted; Layout.leftMargin: 4 }

                TextInput {
                    id: searchField
                    Layout.fillWidth: true
                    font.family: Theme.sans; font.pixelSize: Theme.t14; color: Theme.fg
                    selectByMouse: true; clip: true

                    Text {
                        visible: !searchField.text
                        text: "Search tables, databases, actions..."
                        font: searchField.font; color: Theme.fgDim
                    }

                    onTextChanged: filterResults()
                    Keys.onUpPressed: moveSelection(-1)
                    Keys.onDownPressed: moveSelection(1)
                    Keys.onReturnPressed: activateSelected()
                    Keys.onEscapePressed: quickSwitcher.close()
                }
            }
        }

        DashedLine { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

        // ── Results ──
        ListView {
            id: resultList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 340)
            clip: true; spacing: 0
            model: ListModel { id: resultsModel }
            currentIndex: 0

            delegate: Rectangle {
                width: resultList.width; height: 40
                color: resultList.currentIndex === index ? Theme.bgHover : "transparent"
                radius: Theme.r4

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                    // Icon Badge
                    Rectangle {
                        width: 24; height: 24; radius: Theme.r4
                        color: {
                            if (itemType === "table") return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
                            if (itemType === "database") return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                            return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                        }

                        FlatIcon {
                            anchors.centerIn: parent; size: 12
                            icon: {
                                if (itemType === "table") return Icons.table
                                if (itemType === "database") return Icons.database
                                return Icons.lightning
                            }
                            color: {
                                if (itemType === "table") return Theme.accent
                                if (itemType === "database") return Theme.success
                                return Theme.warning
                            }
                        }
                    }

                    // Name
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        Text {
                            text: name; font.family: Theme.sans; font.pixelSize: Theme.t13
                            color: Theme.fg; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                        Text {
                            text: itemType; font.pixelSize: Theme.t11; color: Theme.fgMuted
                        }
                    }

                    // Return hint
                    FlatIcon {
                        icon: Icons.forward; size: 10; color: Theme.fgDim
                        visible: resultList.currentIndex === index
                    }
                }

                MouseArea {
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { resultList.currentIndex = index; activateSelected() }
                    onPositionChanged: resultList.currentIndex = index
                }
            }
        }

        // Empty
        ColumnLayout {
            visible: resultsModel.count === 0
            Layout.alignment: Qt.AlignHCenter; Layout.margins: Theme.s24; spacing: Theme.s4
            FlatIcon { icon: Icons.search; size: 24; color: Theme.fgDim; Layout.alignment: Qt.AlignHCenter }
            Text {
                text: searchField.text ? "No results found" : "Start typing to search"
                font.pixelSize: Theme.t13; color: Theme.fgMuted; Layout.alignment: Qt.AlignHCenter
            }
        }

        // ── Footer hints ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32
            color: Theme.bgSurface; radius: Theme.r4

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; spacing: Theme.s16
                Repeater {
                    model: [
                        { keys: "\u2191\u2193", desc: "Navigate" },
                        { keys: "\u21B5",  desc: "Select" },
                        { keys: "Esc", desc: "Close" }
                    ]
                    Row {
                        spacing: Theme.s4
                        Rectangle {
                            width: kt.implicitWidth + Theme.s8; height: 18; radius: Theme.r4
                            color: Theme.bgHover; border.width: 1; border.color: Theme.border
                            Text { id: kt; anchors.centerIn: parent; text: modelData.keys
                                   font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgMuted }
                        }
                        Text { text: modelData.desc; font.pixelSize: Theme.t11; color: Theme.fgDim
                               anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
    }

    onOpened: {
        searchField.text = ""
        filterResults()
        searchField.forceActiveFocus()
    }

    function filterResults() {
        resultsModel.clear()
        var q = searchField.text.toLowerCase()
        var actions = [
            { name: "New Query Tab", itemType: "action", action: "newTab" },
            { name: "Toggle Theme", itemType: "action", action: "toggleTheme" },
            { name: "Export Data", itemType: "action", action: "export" }
        ]
        for (var a = 0; a < actions.length; a++) {
            if (q === "" || actions[a].name.toLowerCase().indexOf(q) >= 0)
                resultsModel.append(actions[a])
        }
        for (var t = 0; t < tables.length; t++) {
            if (q === "" || tables[t].toLowerCase().indexOf(q) >= 0)
                resultsModel.append({ name: tables[t], itemType: "table", action: "" })
        }
        for (var d = 0; d < databases.length; d++) {
            if (q === "" || databases[d].toLowerCase().indexOf(q) >= 0)
                resultsModel.append({ name: databases[d], itemType: "database", action: "" })
        }
        resultList.currentIndex = 0
    }

    function moveSelection(delta) {
        var next = resultList.currentIndex + delta
        if (next >= 0 && next < resultsModel.count)
            resultList.currentIndex = next
    }

    function activateSelected() {
        if (resultsModel.count === 0) return
        var item = resultsModel.get(resultList.currentIndex)
        if (item.itemType === "table") tableSelected(item.name)
        else if (item.itemType === "database") databaseSelected(item.name)
        else actionTriggered(item.action)
        quickSwitcher.close()
    }
}
