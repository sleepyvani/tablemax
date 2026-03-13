import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 1280; height: 800
    minimumWidth: 960; minimumHeight: 640
    title: "TableMax"
    color: Theme.bg

    property bool showSidebar: true
    property bool showInfoPanel: false
    property bool showFilterPanel: false

    function toast(msg: string, type: string) : void { toastBar.show(msg, type || "info") }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Left Sidebar ──
        Sidebar {
            id: sidebar
            Layout.preferredWidth: root.showSidebar ? 252 : 0
            Layout.fillHeight: true
            clip: true
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: Theme.border
            visible: root.showSidebar
        }

        // ── Main area ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            TabBar_ {}

            // Content area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                WelcomeView {
                    anchors.fill: parent
                    visible: !tabManager || tabManager.tabs.length === 0
                }

                ColumnLayout {
                    anchors.fill: parent
                    visible: tabManager && tabManager.tabs.length > 0
                    spacing: 0

                    // Filter panel (collapsible)
                    FilterPanel {
                        id: filterPanel
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.showFilterPanel ? implicitHeight : 0
                        Layout.margins: root.showFilterPanel ? 8 : 0
                        visible: root.showFilterPanel
                        clip: true
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                        onFiltersApplied: function(where) {
                            root.toast(where ? "Filters applied" : "Filters cleared", "info")
                        }
                        onFiltersClosed: root.showFilterPanel = false
                    }

                    FlatResizable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: Qt.Vertical
                        splitPosition: 0.45
                        first: Component { QueryEditor {} }
                        second: Component { DataGrid {} }
                    }
                }
            }

            StatusBar {}
        }

        // ── Right Sidebar (Info Panel) ──
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: Theme.border
            visible: root.showInfoPanel
        }

        InfoPanel {
            id: infoPanel
            Layout.preferredWidth: root.showInfoPanel ? 280 : 0
            Layout.fillHeight: true
            clip: true
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
        }
    }

    // ── Dialogs ──
    ConnectionDialog { id: connDialog }
    FlatToast { id: toastBar }

    ExportDialog {
        id: exportDialog
        resultModel: null // Set when export is triggered
    }

    ImportDialog { id: importDialog }

    QuickSwitcher {
        id: quickSwitcher
        tables: database.connected ? database.listTables() : []
        databases: database.connected ? database.listDatabases() : []

        onTableSelected: function(name) {
            // Generate and execute SELECT query for the table
            var t = tabManager.getTab(tabManager.currentIndex)
            if (t) t.query = 'SELECT * FROM "' + name + '" LIMIT 100'
        }
        onDatabaseSelected: function(name) {
            database.switchDatabase(name)
            root.toast("Switched to " + name, "success")
        }
        onActionTriggered: function(action) {
            if (action === "newTab") tabManager.addTab()
            else if (action === "toggleTheme") Theme.toggleTheme()
            else if (action === "export") exportDialog.open()
        }
    }

    DatabaseSwitcher {
        id: dbSwitcher
        databases: database.connected ? database.listDatabases() : []
        onDatabaseSelected: function(name) {
            database.switchDatabase(name)
            root.toast("Switched to " + name, "success")
        }
    }

    // ── Keyboard Shortcuts ──
    FlatDialog {
        id: shortcutsDialog
        dialogTitle: "Keyboard Shortcuts"
        dialogDescription: "All available shortcuts"

        contentItem: Column {
            spacing: 2; width: 380

            Repeater {
                model: [
                    { keys: "Ctrl+N", desc: "New query tab" },
                    { keys: "Ctrl+W", desc: "Close current tab" },
                    { keys: "Ctrl+Enter", desc: "Execute query" },
                    { keys: "Ctrl+B", desc: "Toggle sidebar" },
                    { keys: "Ctrl+I", desc: "Toggle info panel" },
                    { keys: "Ctrl+K", desc: "Quick switcher" },
                    { keys: "Ctrl+E", desc: "Export data" },
                    { keys: "Ctrl+Shift+I", desc: "Import SQL file" },
                    { keys: "Ctrl+F", desc: "Toggle filters" },
                    { keys: "Ctrl+T", desc: "Toggle dark/light theme" },
                    { keys: "Ctrl+/", desc: "Show shortcuts" }
                ]

                Rectangle {
                    width: parent.width; height: 32; radius: 4
                    color: index % 2 === 0 ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02) : "transparent"

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8

                        Row {
                            spacing: 4; Layout.preferredWidth: 160
                            Repeater {
                                model: modelData.keys.split("+")
                                Rectangle {
                                    width: kbdT.implicitWidth + 12; height: 20; radius: 4
                                    color: Theme.bgSurface; border.width: 1; border.color: Theme.border
                                    Text {
                                        id: kbdT; anchors.centerIn: parent
                                        text: modelData; font.family: Theme.mono; font.pixelSize: 10; font.weight: Font.Medium
                                        color: Theme.fg
                                    }
                                }
                            }
                        }

                        Text {
                            text: modelData.desc; font.family: Theme.sans; font.pixelSize: 12
                            color: Theme.fgMuted; Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (tabManager && tabManager.tabs.length === 0) tabManager.addTab()
    }

    // Shortcuts
    Shortcut { sequence: "Ctrl+N"; onActivated: tabManager.addTab() }
    Shortcut {
        sequence: "Ctrl+W"
        onActivated: {
            if (!tabManager || tabManager.tabs.length === 0) return
            tabManager.closeTab(tabManager.currentIndex)
        }
    }
    Shortcut { sequence: "Ctrl+B"; onActivated: root.showSidebar = !root.showSidebar }
    Shortcut { sequence: "Ctrl+I"; onActivated: root.showInfoPanel = !root.showInfoPanel }
    Shortcut { sequence: "Ctrl+K"; onActivated: quickSwitcher.open() }
    Shortcut { sequence: "Ctrl+E"; onActivated: exportDialog.open() }
    Shortcut { sequence: "Ctrl+Shift+I"; onActivated: importDialog.open() }
    Shortcut { sequence: "Ctrl+F"; onActivated: root.showFilterPanel = !root.showFilterPanel }
    Shortcut { sequence: "Ctrl+T"; onActivated: Theme.toggleTheme() }
    Shortcut { sequence: "Ctrl+/"; onActivated: shortcutsDialog.open() }
}

