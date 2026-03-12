import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    color: Theme.bg

    // Hidden clipboard helper
    TextEdit { id: _csvClip; visible: false }

    property var columnWidths: []

    function calcColWidth(colIdx) {
        if (!resultModel) return 100
        var total = resultModel.totalColumns
        if (total <= 0) return 100
        return Math.max(120, tv.width / total)
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ─── Header Bar ───
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                Text { text: "Results"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.DemiBold; color: Theme.fgMuted }

                Rectangle {
                    height: 16; width: rcText.implicitWidth + 10; radius: Theme.rFull; color: Theme.bgSurface; visible: resultModel && resultModel.totalRows > 0
                    Text { id: rcText; anchors.centerIn: parent; text: (resultModel ? resultModel.totalRows : 0) + " rows"; font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim }
                }

                Item { Layout.fillWidth: true }

                // Copy CSV
                Rectangle {
                    width: 24; height: 24; radius: Theme.r4; color: copyMa.containsMouse ? Theme.bgHover : "transparent"; visible: resultModel && resultModel.totalRows > 0
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Text { anchors.centerIn: parent; text: "⧉"; font.pixelSize: 13; color: Theme.fgMuted }
                    MouseArea {
                        id: copyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var csv = databaseService.exportCsv(resultModel)
                            _csvClip.text = csv; _csvClip.selectAll(); _csvClip.copy()
                            root.toast("Copied " + resultModel.totalRows + " rows to clipboard", "success")
                        }
                    }
                    FlatTooltip { visible: copyMa.containsMouse; text: "Copy as CSV"; x: copyMa.mouseX; y: -30 }
                }

                // Export
                Rectangle {
                    width: 24; height: 24; radius: Theme.r4; color: exportMa.containsMouse ? Theme.bgHover : "transparent"; visible: resultModel && resultModel.totalRows > 0
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Text { anchors.centerIn: parent; text: "↓"; font.pixelSize: 13; color: Theme.fgMuted }
                    MouseArea {
                        id: exportMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var csv = databaseService.exportCsv(resultModel)
                            _csvClip.text = csv; _csvClip.selectAll(); _csvClip.copy()
                            root.toast("CSV data copied to clipboard", "success")
                        }
                    }
                    FlatTooltip { visible: exportMa.containsMouse; text: "Export CSV"; x: exportMa.mouseX; y: -30 }
                }
            }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ─── Column Headers ───
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: resultModel && resultModel.totalColumns > 0 ? 28 : 0
            color: Theme.bgElevated
            visible: resultModel && resultModel.totalColumns > 0
            clip: true

            Row {
                x: -tv.contentX
                height: parent.height

                Repeater {
                    model: resultModel ? resultModel.totalColumns : 0

                    Rectangle {
                        width: calcColWidth(index)
                        height: 28
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: Theme.s8; anchors.rightMargin: 2; spacing: 4

                            Text {
                                text: resultModel ? resultModel.columnName(index) : ""
                                font.family: Theme.sans; font.pixelSize: Theme.t11; font.weight: Font.DemiBold
                                color: Theme.fg; elide: Text.ElideRight
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Right border
                        Rectangle {
                            anchors.right: parent.right; width: 1; height: parent.height
                            color: Theme.border; opacity: 0.4
                        }
                    }
                }
            }

            // Bottom border
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
        }

        // ─── Table ───
        TableView {
            id: tv; Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; model: resultModel; visible: resultModel && resultModel.totalRows > 0
            boundsBehavior: Flickable.StopAtBounds; columnSpacing: 0; rowSpacing: 0

            columnWidthProvider: function(c) { return calcColWidth(c) }
            rowHeightProvider: function() { return 28 }

            delegate: Rectangle {
                implicitWidth: 120; implicitHeight: 28
                color: row % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.4 }
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border; opacity: 0.3 }

                Text {
                    anchors.fill: parent; anchors.leftMargin: Theme.s8; verticalAlignment: Text.AlignVCenter
                    text: display !== undefined ? String(display) : ""
                    font.family: Theme.mono; font.pixelSize: Theme.t12
                    color: {
                        if (display === null || display === "NULL") return Theme.fgDim
                        if (display === "true" || display === "false") return Theme.success
                        if (!isNaN(display) && display !== "") return Theme.info
                        return Theme.fg
                    }
                    font.italic: display === null || display === "NULL"
                    elide: Text.ElideRight; opacity: (display === null || display === "NULL") ? 0.5 : 1
                }

                // Hover highlight + click to copy
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, _cellMa.containsMouse ? 0.04 : 0)
                }
                MouseArea {
                    id: _cellMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var val = display !== undefined ? String(display) : ""
                        _csvClip.text = val; _csvClip.selectAll(); _csvClip.copy()
                        root.toast("Copied: " + (val.length > 40 ? val.substring(0, 40) + "…" : val), "success")
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
            }
            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitHeight: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
            }
        }

        // ─── Empty ───
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true; visible: !resultModel || resultModel.totalRows === 0

            ColumnLayout {
                anchors.centerIn: parent; spacing: Theme.s12

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter; width: 40; height: 40; radius: Theme.r8; color: Theme.bgSurface
                    Text { anchors.centerIn: parent; text: "⊞"; font.pixelSize: 18; color: Theme.fgDim }
                }
                Text { text: "No results"; font.family: Theme.sans; font.pixelSize: Theme.t14; font.weight: Font.DemiBold; color: Theme.fgMuted; Layout.alignment: Qt.AlignHCenter }
                Text { text: "Run a query to see data here"; font.family: Theme.sans; font.pixelSize: Theme.t12; color: Theme.fgDim; Layout.alignment: Qt.AlignHCenter }
            }
        }
    }
}
