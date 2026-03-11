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

    Component.onCompleted: {
        if (tabManager && tabManager.tabs.length === 0) tabManager.addTab()
    }

    Shortcut { sequence: "Ctrl+N"; onActivated: tabManager.addTab() }
    Shortcut { sequence: "Ctrl+W"; onActivated: tabManager.closeTab(tabManager.currentIndex) }
    Shortcut { sequence: "Ctrl+B"; onActivated: root.showSidebar = !root.showSidebar }
    Shortcut { sequence: "Ctrl+T"; onActivated: Theme.toggleTheme() }
}
