import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import TableMax.Controls

Rectangle {
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Results Header ───
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.2)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "Results"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.Medium
                    color: Theme.foreground
                }

                // Row count badge
                Rectangle {
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: rowCountText.implicitWidth + 12
                    radius: Theme.radiusFull
                    color: Theme.muted
                    visible: resultModel.totalRows > 0

                    Text {
                        id: rowCountText
                        anchors.centerIn: parent
                        text: resultModel.totalRows + " rows"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.mutedForeground
                    }
                }

                Item { Layout.fillWidth: true }

                // View toggle
                FlatToggleGroup {
                    model: ["Table", "JSON"]
                    currentIndex: 0
                    implicitWidth: 120
                    implicitHeight: 24
                    visible: resultModel.totalRows > 0
                }

                // Export button
                Rectangle {
                    width: 26; height: 26
                    radius: Theme.radiusSm
                    color: exportMouse.containsMouse ? Theme.muted : "transparent"
                    visible: resultModel.totalRows > 0

                    Text {
                        anchors.centerIn: parent
                        text: "↓"
                        font.pixelSize: 14
                        color: Theme.mutedForeground
                    }

                    MouseArea {
                        id: exportMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: Theme.border
            }
        }

        // ─── Column Headers ───
        Row {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            visible: resultModel.totalColumns > 0

            Repeater {
                model: resultModel.totalColumns

                Rectangle {
                    width: Math.max(120, (parent.width || 600) / Math.max(1, resultModel.totalColumns))
                    height: 30
                    color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.15)

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        text: resultModel.columnName(index) || ""
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.DemiBold
                        color: Theme.mutedForeground
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 1; height: parent.height
                        color: Theme.border; opacity: 0.5
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 1
                        color: Theme.border
                    }
                }
            }
        }

        // ─── Data Rows ───
        TableView {
            id: tableView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: resultModel
            visible: resultModel.totalRows > 0
            boundsBehavior: Flickable.StopAtBounds
            columnSpacing: 0
            rowSpacing: 0

            columnWidthProvider: function(col) {
                return Math.max(120, tableView.width / Math.max(1, resultModel.totalColumns))
            }

            rowHeightProvider: function() { return 30 }

            delegate: Rectangle {
                implicitWidth: 120
                implicitHeight: 30

                color: row % 2 === 0
                    ? "transparent"
                    : Qt.rgba(1, 1, 1, 0.012)

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: Theme.border; opacity: 0.3
                }
                Rectangle {
                    anchors.right: parent.right
                    width: 1; height: parent.height
                    color: Theme.border; opacity: 0.3
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    text: display !== undefined ? String(display) : ""
                    font.family: Theme.monoFamily
                    font.pixelSize: 12
                    color: {
                        if (display === null || display === "NULL") return Theme.mutedForeground
                        if (display === "true" || display === "false") return "#22c55e"
                        if (!isNaN(display) && display !== "") return "#60a5fa"
                        return Theme.foreground
                    }
                    font.italic: display === null || display === "NULL"
                    elide: Text.ElideRight
                    opacity: (display === null || display === "NULL") ? 0.5 : 1.0
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 5; radius: 2.5
                    color: Theme.border; opacity: 0.8
                }
            }

            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitHeight: 5; radius: 2.5
                    color: Theme.border; opacity: 0.8
                }
            }
        }

        // ─── Empty State ───
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: resultModel.totalRows === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 48; height: 48
                    radius: Theme.radiusMd
                    color: Theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: "▦"
                        font.pixelSize: 22
                        color: Theme.mutedForeground
                        opacity: 0.5
                    }
                }

                Text {
                    text: "No results yet"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    font.weight: Font.DemiBold
                    color: Theme.foreground
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Write a query and press ▶ Run or Ctrl+Enter"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.mutedForeground
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
