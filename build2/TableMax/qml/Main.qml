import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: app
    visible: true
    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 600
    title: "TableMax"
    color: Theme.background

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Sidebar {
            Layout.preferredWidth: 240
            Layout.fillHeight: true
        }

        // Separator
        FlatSeparator { orientation: Qt.Vertical }

        // Main content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Tab bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: Theme.background

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    spacing: 4

                    Repeater {
                        model: tabManager.tabs

                        Rectangle {
                            Layout.preferredWidth: tabTitle.implicitWidth + 40
                            Layout.fillHeight: true
                            Layout.topMargin: 4
                            radius: Theme.radiusSm
                            color: tabManager.currentIndex === index
                                ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                Text {
                                    id: tabTitle
                                    text: modelData.title || "Query"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    color: tabManager.currentIndex === index
                                        ? Theme.foreground : Theme.mutedForeground
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "✕"
                                    font.pixelSize: 10
                                    color: Theme.mutedForeground
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: tabManager.closeTab(index)
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                z: -1
                                onClicked: tabManager.currentIndex = index
                            }
                        }
                    }

                    // New tab button
                    FlatButton {
                        text: "+"
                        variant: "ghost"
                        size: "icon"
                        onClicked: tabManager.addTab()
                    }

                    Item { Layout.fillWidth: true }
                }

                FlatSeparator {
                    anchors.bottom: parent.bottom
                    orientation: Qt.Horizontal
                }
            }

            // Content area
            FlatResizable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Vertical
                splitPosition: 0.5

                first: Component {
                    QueryEditor {}
                }

                second: Component {
                    DataGrid {}
                }
            }
        }
    }

    // Connection dialog
    ConnectionDialog {
        id: connectionDialog
    }

    // Toast notifications
    FlatToast {
        id: toast
    }

    Component.onCompleted: {
        if (tabManager.tabs.length === 0) tabManager.addTab()
    }
}
