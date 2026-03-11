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

    function toast(msg, type) { toastBar.show(msg, type || "info") }

    // ─── Layout ───
    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            Layout.preferredWidth: showSidebar ? 252 : 0
            Layout.fillHeight: true
            clip: true
            Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
        }

        Rectangle { Layout.fillHeight: true; width: 1; color: Theme.border; visible: showSidebar }

        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 0

            // ─── Tab Bar ───
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 38
                color: Theme.bgElevated

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 2; anchors.rightMargin: Theme.s8
                    spacing: 0

                    // Sidebar toggle
                    Item {
                        width: 36; height: 36
                        Rectangle {
                            anchors.centerIn: parent; width: 28; height: 28; radius: Theme.r6
                            color: sbToggle.containsMouse ? Theme.bgHover : "transparent"
                            Text { anchors.centerIn: parent; text: showSidebar ? "☰" : "☰"; font.pixelSize: 14; color: Theme.fgMuted }
                        }
                        MouseArea { id: sbToggle; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: showSidebar = !showSidebar }
                    }

                    // Tabs
                    Repeater {
                        model: tabManager ? tabManager.tabs : []
                        delegate: Rectangle {
                            width: Math.min(tabLabel.implicitWidth + 48, 160); height: 38
                            color: "transparent"
                            property bool active: tabManager.currentIndex === index

                            Rectangle {
                                anchors.fill: parent; anchors.topMargin: 4; anchors.bottomMargin: 0
                                anchors.leftMargin: 2; anchors.rightMargin: 2
                                radius: Qt.size(Theme.r6, Theme.r6)
                                color: active ? Theme.bgSurface : tabMa.containsMouse ? Theme.bgHover : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.fast } }

                                // Active top accent
                                Rectangle {
                                    anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                    width: active ? parent.width * 0.4 : 0; height: 2; radius: 1
                                    color: Theme.accent; opacity: active ? 1 : 0
                                    Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                                }

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 6; spacing: 6

                                    Text {
                                        id: tabLabel
                                        text: modelData.title || "Query"
                                        font.family: Theme.sans; font.pixelSize: Theme.t12
                                        font.weight: active ? Font.DemiBold : Font.Normal
                                        color: active ? Theme.fg : Theme.fgMuted
                                        elide: Text.ElideRight; Layout.fillWidth: true
                                    }

                                    // Close
                                    Rectangle {
                                        width: 18; height: 18; radius: Theme.r4
                                        color: tabClose.containsMouse ? Theme.bgActive : "transparent"
                                        visible: active || tabMa.containsMouse
                                        Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 13; color: tabClose.containsMouse ? Theme.fg : Theme.fgMuted }
                                        MouseArea { id: tabClose; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tabManager.closeTab(index) }
                                    }
                                }
                            }
                            MouseArea { id: tabMa; anchors.fill: parent; hoverEnabled: true; z: -1; cursorShape: Qt.PointingHandCursor; onClicked: tabManager.currentIndex = index }
                        }
                    }

                    // New tab
                    Item {
                        width: 32; height: 38
                        Rectangle {
                            anchors.centerIn: parent; width: 24; height: 24; radius: Theme.r6
                            color: newTabMa.containsMouse ? Theme.bgHover : "transparent"
                            Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 16; color: Theme.fgMuted }
                        }
                        MouseArea { id: newTabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tabManager.addTab() }
                    }

                    Item { Layout.fillWidth: true }

                    // Connection pill
                    Rectangle {
                        height: 22; width: connPillText.implicitWidth + 20; radius: Theme.rFull
                        color: databaseService.connected ? Qt.rgba(0.2, 0.83, 0.6, 0.1) : Theme.bgSurface
                        border.width: 1; border.color: databaseService.connected ? Qt.rgba(0.2, 0.83, 0.6, 0.2) : Theme.border
                        Text {
                            id: connPillText; anchors.centerIn: parent; font.family: Theme.sans; font.pixelSize: 10
                            text: databaseService.connected ? "● Connected" : "Disconnected"
                            color: databaseService.connected ? Theme.success : Theme.fgDim
                        }
                    }
                }

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
            }

            // ─── Content ───
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true

                WelcomeView { anchors.fill: parent; visible: !tabManager || tabManager.tabs.length === 0 }

                FlatResizable {
                    anchors.fill: parent; visible: tabManager && tabManager.tabs.length > 0
                    orientation: Qt.Vertical; splitPosition: 0.45
                    first: Component { QueryEditor {} }
                    second: Component { DataGrid {} }
                }
            }

            // ─── Status Bar ───
            StatusBar {}
        }
    }

    ConnectionDialog { id: connDialog }
    FlatToast { id: toastBar }

    property bool showSidebar: true

    Component.onCompleted: { if (tabManager && tabManager.tabs.length === 0) tabManager.addTab() }

    Shortcut { sequence: "Ctrl+N"; onActivated: tabManager.addTab() }
    Shortcut { sequence: "Ctrl+W"; onActivated: tabManager.closeTab(tabManager.currentIndex) }
    Shortcut { sequence: "Ctrl+B"; onActivated: showSidebar = !showSidebar }
}
