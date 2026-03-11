import QtQuick
import QtQuick.Layouts

Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 38
    color: Theme.bgElevated

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 2
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

                Text {
                    anchors.centerIn: parent
                    text: "☰"; font.pixelSize: 14
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
                Layout.preferredWidth: Math.min(tabLabel.implicitWidth + 52, 160)
                Layout.preferredHeight: 38
                color: "transparent"

                property bool isActive: tabManager.currentIndex === index

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    radius: Theme.r6
                    color: isActive ? Theme.bgSurface : tabMa.containsMouse ? Theme.bgHover : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    // Active indicator
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
                        anchors.leftMargin: 12
                        anchors.rightMargin: 6
                        spacing: 6

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
                                text: "×"; font.pixelSize: 13
                                color: tabClose.containsMouse ? Theme.fg : Theme.fgMuted
                            }

                            MouseArea {
                                id: tabClose
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tabManager.closeTab(index)
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
                    onClicked: tabManager.currentIndex = index
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

                Text {
                    anchors.centerIn: parent
                    text: "+"; font.pixelSize: 16
                    color: Theme.fgMuted
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

        // Connection status pill
        Rectangle {
            Layout.preferredHeight: 22
            Layout.preferredWidth: connPillText.implicitWidth + 20
            radius: Theme.rFull
            color: databaseService.connected ? Qt.rgba(0.2, 0.83, 0.6, 0.1) : Theme.bgSurface
            border.width: 1
            border.color: databaseService.connected ? Qt.rgba(0.2, 0.83, 0.6, 0.2) : Theme.border

            Text {
                id: connPillText
                anchors.centerIn: parent
                font.family: Theme.sans
                font.pixelSize: 10
                text: databaseService.connected ? "● Connected" : "Disconnected"
                color: databaseService.connected ? Theme.success : Theme.fgDim
            }
        }
    }

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width; height: 1
        color: Theme.border
    }
}
