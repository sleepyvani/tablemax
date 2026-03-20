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

            // Bottom dashed border
            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
            BlueprintCrosshair { anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.bottomMargin: -size/2; anchors.rightMargin: -size/2 }
        }

        // â”€â”€â”€ Table â”€â”€â”€
        TableView {
            id: tv; Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; model: resultModel; visible: resultModel && resultModel.totalRows > 0
            boundsBehavior: Flickable.StopAtBounds; columnSpacing: 0; rowSpacing: 0

            columnWidthProvider: function(c) { return calcColWidth(c) }
            rowHeightProvider: function() { return 28 }

            // Row numbers overlay
            ListView {
                z: 2
                anchors.left: parent.left
                anchors.top: parent.top
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

            // Bottom dashed border
            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
            BlueprintCrosshair { anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.bottomMargin: -size/2; anchors.rightMargin: -size/2 }
        }

        // â”€â”€â”€ Table â”€â”€â”€
        TableView {
            id: tv; Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; model: resultModel; visible: resultModel && resultModel.totalRows > 0
            boundsBehavior: Flickable.StopAtBounds; columnSpacing: 0; rowSpacing: 0

            columnWidthProvider: function(c) { return calcColWidth(c) }
            rowHeightProvider: function() { return 28 }

            // Row numbers overlay
            ListView {
                z: 2
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 48
                visible: resultModel && resultModel.totalRows > 0
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                model: resultModel ? resultModel.totalRows : 0
                contentY: tv.contentY

                delegate: Rectangle {
                    required property int index
                    property int rowIdx: index
                    width: 48; height: 28
                    color: {
                        if (changeTracker && changeTracker.isRowDeleted(rowIdx)) return Qt.rgba(1, 0, 0, 0.08)
                        if (changeTracker && changeTracker.isRowInserted(rowIdx)) return Qt.rgba(0, 1, 0, 0.08)
                        return rowIdx % 2 === 0 ? Theme.bgElevated : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02)
                    }
                    border.width: 0

                    Text {
                        anchors.centerIn: parent
                        text: (rowIdx + 1).toString()
                        font.family: Theme.mono; font.pixelSize: Theme.t11
                        color: Theme.fgDim; opacity: 0.5
                    }

                    // Row state indicator
                    Rectangle {
                        anchors.left: parent.left; width: 3; height: parent.height; radius: 1
                        visible: changeTracker && (changeTracker.isRowDeleted(rowIdx) || changeTracker.isRowInserted(rowIdx))
                        color: changeTracker && changeTracker.isRowDeleted(rowIdx) ? Theme.error : Theme.success
                    }

                    // Right-click on row number → context menu
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                rowCtxMenu.targetRow = rowIdx
                                rowCtxMenu.menuModel = [
                                    "Copy Row (TSV)", "Copy Row (JSON)", "Generate INSERT SQL",
                                    "-",
                                    changeTracker && changeTracker.isRowDeleted(rowIdx) ? "Unmark Delete" : "Mark for Delete",
                                    "Duplicate Row"
                                ]
                                rowCtxMenu.x = mouse.x
                                rowCtxMenu.y = mouse.y
                                rowCtxMenu.open()
                            }
                        }
                    }

                    DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.3 }
                    DashedLine { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border; opacity: 0.4 }
                }
            }

            // Data cells â€” shifted right by row number column width
            leftMargin: 48

            delegate: Rectangle {
                implicitWidth: 120; implicitHeight: 28
                color: {
                    if (changeTracker && changeTracker.isRowDeleted(row)) return Qt.rgba(1, 0, 0, 0.06)
                    if (changeTracker && changeTracker.isRowInserted(row)) return Qt.rgba(0, 1, 0, 0.06)
                    if (changeTracker && changeTracker.isCellModified(row, column)) return Qt.rgba(1, 0.7, 0, 0.08)
                    return row % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)
                }

                DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.4 }
                DashedLine { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border; opacity: 0.3 }

                // Modified cell indicator (top-right triangle)
                Canvas {
                    anchors.right: parent.right; anchors.top: parent.top
                    width: 8; height: 8; visible: changeTracker && changeTracker.isCellModified(row, column)
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.fillStyle = Theme.warning
                        ctx.beginPath()
                        ctx.moveTo(width, 0)
                        ctx.lineTo(width, height)
                        ctx.lineTo(0, 0)
                        ctx.fill()
                    }
                }

                Text {
                    anchors.fill: parent; anchors.leftMargin: Theme.s8; verticalAlignment: Text.AlignVCenter
                    text: display !== undefined ? String(display) : ""
                    font.family: Theme.mono; font.pixelSize: Theme.t12
                    color: {
                        var vt = Fmt.valueType(display)
                        if (vt === "null") return Theme.fgDim
                        if (vt === "bool") return Theme.success
                        if (vt === "number") return Theme.info
                        return Theme.fg
                    }
                    font.italic: Fmt.valueType(display) === "null"
                    elide: Text.ElideRight; opacity: Fmt.valueType(display) === "null" ? 0.5 : 1
                    font.strikeout: changeTracker !== undefined && changeTracker !== null && changeTracker.isRowDeleted(row)
                }

                // Hover highlight + click to copy + double-click to edit
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, _cellMa.containsMouse ? 0.04 : 0)
                }
                MouseArea {
                    id: _cellMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            rowCtxMenu.targetRow = row
                            rowCtxMenu.menuModel = [
                                "Copy Row (TSV)", "Copy Row (JSON)", "Generate INSERT SQL",
                                "-",
                                changeTracker && changeTracker.isRowDeleted(row) ? "Unmark Delete" : "Mark for Delete",
                                "Duplicate Row"
                            ]
                            rowCtxMenu.x = mouse.x
                            rowCtxMenu.y = mouse.y
                            rowCtxMenu.open()
                            return
                        }
                        var val = display !== undefined ? String(display) : ""
                        _csvClip.text = val; _csvClip.selectAll(); _csvClip.copy()
                        root.toast("Copied: " + Fmt.truncate(val, 40), "success")
                    }
                    onDoubleClicked: {
                        // Inline edit via CellEditor overlay
                        if (typeof cellEditor !== "undefined" && cellEditor) {
                            var globalPos = mapToItem(null, 0, 0)
                            var colName = resultModel ? resultModel.columnName(column) : ""
                            cellEditor.startEdit(row, column, display !== undefined ? String(display) : "", colName, "", globalPos.x, globalPos.y, width, height)
                        }
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

        //  Empty  DB-aware 
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true; visible: !resultModel || resultModel.totalRows === 0

            ColumnLayout {
                anchors.centerIn: parent; spacing: Theme.s12

                FlatIcon {
                    Layout.alignment: Qt.AlignHCenter
                    icon: Icons.table; size: 48; color: Theme.fgMuted; opacity: 0.5
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No data available"; font.family: Theme.sans; font.pixelSize: Theme.t16; font.weight: Font.DemiBold; color: Theme.fg
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Run a SQL query or select a table from the sidebar to view data."; font.family: Theme.sans; font.pixelSize: Theme.t13; color: Theme.fgMuted
                }
            }
        }
    }

    // Cell Editor Dialog
    CellEditor {
        id: cellEditorDlg
        onCommitted: function(row, col, val) {
            if (changeTracker && resultModel) {
                var colName = resultModel.columnName(col)
                var oldVal = resultModel.cellValue(row, col)
                changeTracker.recordCellEdit(row, col, colName, oldVal, val)
            }
            root.toast("Cell updated", "success")
        }
    }

    // ── Row Context Menu ──────────────────────────────────────
    FlatContextMenu {
        id: rowCtxMenu
        property int targetRow: -1
        onMenuItemClicked: function(idx, label) {
            var r = rowCtxMenu.targetRow
            if (r < 0 || !resultModel) return
            if (label === "Copy Row (TSV)") {
                _csvClip.text = generateRowTSV(r); _csvClip.selectAll(); _csvClip.copy()
                root.toast("Row copied as TSV", "success")
            } else if (label === "Copy Row (JSON)") {
                _csvClip.text = generateRowJSON(r); _csvClip.selectAll(); _csvClip.copy()
                root.toast("Row copied as JSON", "success")
            } else if (label === "Generate INSERT SQL") {
                _csvClip.text = generateInsertSQL(r); _csvClip.selectAll(); _csvClip.copy()
                root.toast("INSERT SQL copied!", "success")
            } else if (label === "Mark for Delete") {
                if (changeTracker) changeTracker.markRowDeleted(r)
                root.toast("Row marked for deletion", "warning")
            } else if (label === "Unmark Delete") {
                if (changeTracker) changeTracker.unmarkRowDeleted(r)
                root.toast("Deletion unmarked", "info")
            } else if (label === "Duplicate Row") {
                var sql = generateInsertSQL(r)
                if (sql && databaseService && databaseService.connected) {
                    databaseService.executeQuery(sql, resultModel)
                    root.toast("Row duplicated", "success")
                }
            }
        }
    }

    // ── Row helper functions ──────────────────────────────────
    function generateRowTSV(row) {
        if (!resultModel) return ""
        var cols = resultModel.totalColumns
        var parts = []
        for (var c = 0; c < cols; c++) {
            var v = resultModel.cellValue(row, c)
            parts.push(v !== undefined && v !== null ? String(v) : "")
        }
        return parts.join("\t")
    }

    function generateRowJSON(row) {
        if (!resultModel) return "{}"
        var cols = resultModel.totalColumns
        var obj = {}
        for (var c = 0; c < cols; c++) {
            var k = resultModel.columnName(c) || ("col_" + c)
            obj[k] = resultModel.cellValue(row, c)
        }
        return JSON.stringify(obj, null, 2)
    }

    function generateInsertSQL(row) {
        if (!resultModel) return ""
        var cols = resultModel.totalColumns
        var colNames = [], values = []
        for (var c = 0; c < cols; c++) {
            var cn = resultModel.columnName(c) || ("col_" + c)
            var v = resultModel.cellValue(row, c)
            var vs = v !== undefined && v !== null ? String(v) : null
            colNames.push(DB.quoteIdentifier(cn, _dbType))
            if (vs === null || vs.toLowerCase() === "null") values.push("NULL")
            else if (!isNaN(vs) && vs !== "") values.push(vs)
            else values.push("'" + vs.replace(/'/g, "''") + "'")
        }
        var tname = tabManager ? (tabManager.getTab(tabManager.currentIndex).title || "_table") : "_table"
        var q = DB.quoteIdentifier(tname, _dbType)
        return "INSERT INTO " + q + " (" + colNames.join(", ") + ") VALUES (" + values.join(", ") + ")"
    }
}
