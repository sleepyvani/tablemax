import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "DbHelper.js" as DB

Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 38
    color: Theme.bgElevated

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.s2
        anchors.rightMargin: Theme.s8
        spacing: 0

        // Sidebar toggle
        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            color: "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 28; height: 28; radius: Theme.r6
                color: sbToggle.containsMouse ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                Text {
                    anchors.centerIn: parent
                    text: "☰"; font.pixelSize: Theme.t14
                    color: Theme.fgMuted
                }
            }

            MouseArea {
                id: sbToggle
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showSidebar = !root.showSidebar
            }
        }

        // Tab buttons
        Repeater {
            model: tabManager ? tabManager.tabs : []

            Rectangle {
                    Layout.preferredWidth: Math.min(tabLabel.implicitWidth + 52, 180)
                    Layout.preferredHeight: 38

                property bool isActive: tabManager.currentIndex === index

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: Theme.s4
                    anchors.leftMargin: Theme.s2
                    anchors.rightMargin: Theme.s2
                    radius: Theme.r6
                    color: isActive ? Theme.bgSurface : tabMa.containsMouse ? Theme.bgHover : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    // Active indicator line
                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: isActive ? parent.width * 0.4 : 0
                        height: 2; radius: 1
                        color: Theme.accent
                        opacity: isActive ? 1 : 0

                        Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.s8
                        anchors.rightMargin: Theme.s6
                        spacing: Theme.s4

                        // Modified indicator dot
                        Rectangle {
                            width: 5; height: 5; radius: 3
                            color: Theme.accent; opacity: 0.6
                            visible: {
                                var t = tabManager.getTab(index)
                                return t && t.content && t.content.trim().length > 0
                            }
                        }

                        Text {
                            id: tabLabel
                            text: modelData.title || "Query"
                            font.family: Theme.sans
                            font.pixelSize: Theme.t12
                            font.weight: isActive ? Font.DemiBold : Font.Normal
                            color: isActive ? Theme.fg : Theme.fgMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            radius: Theme.r4
                            color: tabClose.containsMouse ? Theme.bgActive : "transparent"
                            visible: isActive || tabMa.containsMouse

                            Text {
                                anchors.centerIn: parent
                                text: "×"; font.pixelSize: Theme.t13
                                color: tabClose.containsMouse ? Theme.fg : Theme.fgMuted
                            }

                            MouseArea {
                                id: tabClose
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var t = tabManager.getTab(index)
                                    if (t && t.content && t.content.trim().length > 0) {
                                        _closeDlg.closeIdx = index
                                        _closeDlg.open()
                                    } else {
                                        tabManager.closeTab(index)
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: tabMa
                    anchors.fill: parent
                    hoverEnabled: true
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            _tabCtx.tabIdx = index
                            _tabCtx.x = mouse.x; _tabCtx.y = mouse.y
                            _tabCtx.open()
                        } else {
                            tabManager.currentIndex = index
                        }
                    }
                }
            }
        }

        // New tab button
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 38
            color: "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 24; height: 24; radius: Theme.r6
                color: newTabMa.containsMouse ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                Text {
                    anchors.centerIn: parent
                    text: "+"; font.pixelSize: Theme.t16
                    color: newTabMa.containsMouse ? Theme.accent : Theme.fgMuted
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }
            }

            MouseArea {
                id: newTabMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tabManager.addTab()
            }
        }

        Item { Layout.fillWidth: true }

        // Active DB pill
        Rectangle {
            Layout.preferredHeight: 22
            Layout.preferredWidth: connPillRow.implicitWidth + Theme.s16
            radius: Theme.rFull
            color: databaseService.connected ? Qt.rgba(0.2, 0.83, 0.6, 0.08) : Theme.bgSurface
            border.width: 1
            border.color: databaseService.connected ? Qt.rgba(0.2, 0.83, 0.6, 0.15) : Theme.border

            Row {
                id: connPillRow
                anchors.centerIn: parent
                spacing: Theme.s4

                Rectangle {
                    width: 5; height: 5; radius: 3; anchors.verticalCenter: parent.verticalCenter
                    color: databaseService.connected ? Theme.success : Theme.fgDim
                    opacity: databaseService.connected ? 1 : 0.3
                }

                Text {
                    font.family: Theme.sans
                    font.pixelSize: Theme.t11
                    text: {
                        if (databaseService.connected && connectionManager) {
                            var c = connectionManager.get(connectionManager.activeIndex)
                            return c ? (c.name || "Connected") : "Connected"
                        }
                        return "No connection"
                    }
                    color: databaseService.connected ? Theme.success : Theme.fgDim
                }
            }
        }
    }

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: 1
        color: Theme.border
    }

    // ── Tab Context Menu ──
    FlatContextMenu {
        id: _tabCtx
        property int tabIdx: -1
        menuModel: ["Close Tab", "Close Other Tabs", "Close All Tabs"]
        onMenuItemClicked: function(idx, label) {
            if (label === "Close Tab") {
                var t = tabManager.getTab(_tabCtx.tabIdx)
                if (t && t.content && t.content.trim().length > 0) {
                    _closeDlg.closeIdx = _tabCtx.tabIdx
                    _closeDlg.open()
                } else {
                    tabManager.closeTab(_tabCtx.tabIdx)
                }
            } else if (label === "Close Other Tabs") {
                // Close all tabs except the one right-clicked
                var keep = _tabCtx.tabIdx
                var total = tabManager.tabs.length
                for (var i = total - 1; i >= 0; i--) {
                    if (i !== keep) tabManager.closeTab(i)
                }
            } else if (label === "Close All Tabs") {
                var cnt = tabManager.tabs.length
                for (var j = cnt - 1; j >= 0; j--) tabManager.closeTab(j)
            }
        }
    }

    // ── Close tab confirmation ──
    FlatDialog {
        id: _closeDlg
        property int closeIdx: -1
        dialogTitle: "Close Tab"
        dialogDescription: "This tab has unsaved query content. Close anyway?"

        contentItem: RowLayout {
            spacing: Theme.s8
            Item { Layout.fillWidth: true }
            FlatButton {
                text: "Cancel"
                variant: "ghost"
                size: "sm"
                onClicked: _closeDlg.close()
            }
            FlatButton {
                text: "Close Tab"
                variant: "destructive"
                size: "sm"
                onClicked: {
                    tabManager.closeTab(_closeDlg.closeIdx)
                    _closeDlg.close()
                }
            }
        }
    }
}
