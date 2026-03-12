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

    function toast(msg: string, type: string) : void { toastBar.show(msg, type || "info") }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
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

        // Main area
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

                FlatResizable {
                    anchors.fill: parent
                    visible: tabManager && tabManager.tabs.length > 0
                    orientation: Qt.Vertical
                    splitPosition: 0.45
                    first: Component { QueryEditor {} }
                    second: Component { DataGrid {} }
                }
            }

            StatusBar {}
        }
    }

    ConnectionDialog { id: connDialog }
    FlatToast { id: toastBar }

    // ── Keyboard Shortcuts Overlay ──
    FlatDialog {
        id: shortcutsDialog
        title: "Keyboard Shortcuts"
        description: "All available shortcuts"

        contentItem: Column {
            spacing: 2; width: 340

            Repeater {
                model: [
                    { keys: "Ctrl+N", desc: "New query tab" },
                    { keys: "Ctrl+W", desc: "Close current tab" },
                    { keys: "Ctrl+Enter", desc: "Execute query" },
                    { keys: "Ctrl+B", desc: "Toggle sidebar" },
                    { keys: "Ctrl+T", desc: "Toggle dark/light theme" },
                    { keys: "Ctrl+/", desc: "Show shortcuts" }
                ]

                Rectangle {
                    width: parent.width; height: 32; radius: 4
                    color: index % 2 === 0 ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02) : "transparent"

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8

                        // Key badges
                        Row {
                            spacing: 4; Layout.preferredWidth: 130
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

    Shortcut { sequence: "Ctrl+N"; onActivated: tabManager.addTab() }
    Shortcut {
        sequence: "Ctrl+W"
        onActivated: {
            if (!tabManager || tabManager.tabs.length === 0) return
            var t = tabManager.getTab(tabManager.currentIndex)
            // If tab has unsaved content, just close via closeTab
            // (the TabBar's confirmation dialog is a TabBar-level concern;
            //  global shortcut does direct close for clean UX)
            tabManager.closeTab(tabManager.currentIndex)
        }
    }
    Shortcut { sequence: "Ctrl+B"; onActivated: root.showSidebar = !root.showSidebar }
    Shortcut { sequence: "Ctrl+T"; onActivated: Theme.toggleTheme() }
    Shortcut { sequence: "Ctrl+/"; onActivated: shortcutsDialog.open() }
}
