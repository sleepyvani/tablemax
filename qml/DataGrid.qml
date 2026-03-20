import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "FormatHelper.js" as Fmt
import "DbHelper.js" as DB
import "Icons.js" as Icons

Rectangle {
    color: Theme.bg

    // Hidden clipboard helper
    TextEdit { id: _csvClip; visible: false }

    // Active DB type
    property string _dbType: {
        if (!connectionManager) return ""
        var c = connectionManager.get(connectionManager.activeIndex)
        return c ? (c.dbType || "") : ""
    }

    property var columnWidths: []

    function calcColWidth(colIdx) {
        if (!resultModel) return 100
        var total = resultModel.totalColumns
        if (total <= 0) return 100
        return Math.max(120, (tv.width - 48) / total)
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // â”€â”€â”€ Header Bar â”€â”€â”€
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                Text { text: "Results"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.DemiBold; color: Theme.fgMuted }

                Rectangle {
                    height: 16; width: rcText.implicitWidth + Theme.s8; radius: Theme.rFull; color: Theme.bgSurface; visible: resultModel && resultModel.totalRows > 0
                    Text { id: rcText; anchors.centerIn: parent; text: Fmt.formatRowCount(resultModel ? resultModel.totalRows : 0); font.family: Theme.mono; font.pixelSize: Theme.t11; color: Theme.fgDim }
                }

                Item { Layout.fillWidth: true }

                // Copy CSV
                Rectangle {
                    width: 24; height: 24; radius: Theme.r4; color: copyMa.containsMouse ? Theme.bgHover : "transparent"; visible: resultModel && resultModel.totalRows > 0
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 13; color: Theme.fgMuted }
                    MouseArea {
                        id: copyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var csv = databaseService.exportCsv(resultModel)
                            _csvClip.text = csv; _csvClip.selectAll(); _csvClip.copy()
                            root.toast("Copied " + Fmt.formatNumber(resultModel.totalRows) + " rows to clipboard", "success")
                        }
                    }
                    FlatTooltip { visible: copyMa.containsMouse; text: "Copy as CSV"; x: copyMa.mouseX; y: -30 }
                }

                // Export
                Rectangle {
                    width: 24; height: 24; radius: Theme.r4; color: exportMa.containsMouse ? Theme.bgHover : "transparent"; visible: resultModel && resultModel.totalRows > 0
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    FlatIcon { anchors.centerIn: parent; icon: Icons.download; size: 13; color: Theme.fgMuted }
                    MouseArea {
                        id: exportMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof exportDialog !== "undefined" && exportDialog) {
                                exportDialog.open()
                            } else {
                                var csv = databaseService.exportCsv(resultModel)
                                _csvClip.text = csv; _csvClip.selectAll(); _csvClip.copy()
                                root.toast("CSV copied — use File > Export to save to file", "success")
                            }
                        }
                    }
                    FlatTooltip { visible: exportMa.containsMouse; text: "Export CSV"; x: exportMa.mouseX; y: -30 }
                }
            }

            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // â”€â”€â”€ Column Headers â”€â”€â”€
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: resultModel && resultModel.totalColumns > 0 ? 28 : 0
            color: Theme.bgElevated
            visible: resultModel && resultModel.totalColumns > 0
            clip: true

            Row {
                x: -tv.contentX
                height: parent.height

                // Row number header
                Rectangle {
                    width: 48; height: 28; color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "#"; font.family: Theme.mono; font.pixelSize: Theme.t11; font.weight: Font.Bold
                        color: Theme.fgDim; opacity: 0.6
                    }
                    DashedLine { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border; opacity: 0.4 }
                }

                Repeater {
                    model: resultModel ? resultModel.totalColumns : 0

                    Rectangle {
                        width: calcColWidth(index)
                        height: 28
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: Theme.s8; anchors.rightMargin: Theme.s2; spacing: Theme.s4

                            Text {
                                text: resultModel ? resultModel.columnName(index) : ""
                                font.family: Theme.sans; font.pixelSize: Theme.t11; font.weight: Font.DemiBold
                                color: Theme.fg; elide: Text.ElideRight
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Right border
                        DashedLine {
                            anchors.right: parent.right; width: 1; height: parent.height
                            color: Theme.border; opacity: 0.4
                        }
                    }
                }
            }
        }

