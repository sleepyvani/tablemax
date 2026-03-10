import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: app
    visible: true
    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 640
    title: databaseService.connected
        ? "TableMax — " + connectionManager.get(connectionManager.activeIndex).name
        : "TableMax"
    color: Theme.background

    // ─── Global Toast ───
    function showToast(msg, variant) { toast.show(msg, variant || "default") }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Sidebar ───
        Sidebar {
            id: sidebar
            Layout.preferredWidth: sidebarVisible ? 260 : 0
            Layout.fillHeight: true
            clip: true
            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutCubic }
            }
        }

        // ─── Separator ───
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: Theme.border
            visible: sidebarVisible
        }

        // ─── Main Content ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ─── Tab bar ───
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 1)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 8
                    spacing: 0

                    // Toggle sidebar
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.leftMargin: 4
                        radius: Theme.radiusSm
                        color: sidebarToggleMouse.containsMouse ? Theme.muted : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        Text {
                            anchors.centerIn: parent
                            text: sidebarVisible ? "◀" : "▶"
                            font.pixelSize: 11
                            color: Theme.mutedForeground
                        }

                        MouseArea {
                            id: sidebarToggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sidebarVisible = !sidebarVisible
                        }
                    }

                    Rectangle { Layout.preferredWidth: 4; color: "transparent" }

                    // Tabs
                    Repeater {
                        model: tabManager.tabs

                        Rectangle {
                            Layout.preferredWidth: Math.min(tabRow.implicitWidth + 12, 180)
                            Layout.preferredHeight: 32
                            Layout.topMargin: 5
                            radius: Theme.radiusSm
                            property bool isActive: tabManager.currentIndex === index

                            color: isActive ? Theme.muted
                                 : tabHover.containsMouse ? Qt.rgba(1, 1, 1, 0.02)
                                 : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                            RowLayout {
                                id: tabRow
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 6
                                spacing: 6

                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: (modelData.error && modelData.error !== "") ? "#ef4444"
                                         : (modelData.result && modelData.result.length > 0) ? Theme.success
                                         : Theme.mutedForeground
                                    opacity: 0.7
                                }

                                Text {
                                    text: modelData.title || "Query"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: isActive ? Font.Medium : Font.Normal
                                    color: isActive ? Theme.foreground : Theme.mutedForeground
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true

                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                                }

                                // Close button
                                Rectangle {
                                    width: 18; height: 18
                                    radius: Theme.radiusSm
                                    color: closeMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                                    visible: tabHover.containsMouse || isActive

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 9
                                        color: Theme.mutedForeground
                                    }

                                    MouseArea {
                                        id: closeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: tabManager.closeTab(index)
                                    }
                                }
                            }

                            MouseArea {
                                id: tabHover
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tabManager.currentIndex = index
                            }
                        }
                    }

                    // New tab
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.topMargin: 2
                        radius: Theme.radiusSm
                        color: newTabMouse.containsMouse ? Theme.muted : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 16
                            font.weight: Font.Light
                            color: Theme.mutedForeground
                        }

                        MouseArea {
                            id: newTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tabManager.addTab()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Connection badge
                    Rectangle {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: connBadgeText.implicitWidth + 16
                        radius: Theme.radiusFull
                        color: databaseService.connected ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                             : Qt.rgba(1, 1, 1, 0.03)
                        border.width: 1
                        border.color: databaseService.connected ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.3) : Theme.border

                        Text {
                            id: connBadgeText
                            anchors.centerIn: parent
                            text: databaseService.connected ? "● Connected" : "○ Disconnected"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: databaseService.connected ? Theme.success : Theme.mutedForeground
                        }
                    }
                }

                // Bottom border
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }
            }

            // ─── Content Area ───
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Welcome screen (no tabs)
                WelcomeView {
                    anchors.fill: parent
                    visible: tabManager.tabs.length === 0
                }

                // Editor + Results split
                FlatResizable {
                    anchors.fill: parent
                    visible: tabManager.tabs.length > 0
                    orientation: Qt.Vertical
                    splitPosition: 0.45

                    first: Component {
                        QueryEditor {}
                    }

                    second: Component {
                        DataGrid {}
                    }
                }
            }

            // ─── Status Bar ───
            StatusBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
            }
        }
    }

    // ─── Dialogs ───
    ConnectionDialog {
        id: connectionDialog
    }

    // ─── Toast ───
    FlatToast {
        id: toast
    }

    // ─── State ───
    property bool sidebarVisible: true

    Component.onCompleted: {
        if (tabManager.tabs.length === 0) tabManager.addTab()
    }

    // Keyboard shortcuts
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: tabManager.addTab()
    }
    Shortcut {
        sequence: "Ctrl+W"
        onActivated: tabManager.closeTab(tabManager.currentIndex)
    }
    Shortcut {
        sequence: "Ctrl+B"
        onActivated: sidebarVisible = !sidebarVisible
    }
}
