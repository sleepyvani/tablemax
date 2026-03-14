// RowDetailDrawer.qml — Side panel showing all fields of a selected row
// Inspired by Drizzle Studio row detail view + MongoDB Compass document inspector

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons
import "FormatHelper.js" as Fmt

Rectangle {
    id: root
    color: Theme.bgSurface
    visible: isOpen

    property bool isOpen: false
    property int selectedRow: -1
    property var resultModel: null
    property string tableName: ""

    signal closed()
    signal cellEdited(int row, int col, string colName, var oldVal, var newVal)
    signal rowDeleted(int row)
    signal rowDuplicated(int row)

    function openRow(row) {
        selectedRow = row
        isOpen = true
    }

    function close() {
        isOpen = false
        closed()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 44; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s8
                spacing: Theme.s8

                FlatIcon { icon: Icons.info; size: 14; color: Theme.accent }

                Text {
                    text: tableName ? "Row #" + (selectedRow + 1) + " — " + tableName : "Row #" + (selectedRow + 1)
                    font.pixelSize: Theme.t13; font.weight: Font.DemiBold
                    font.family: Theme.sans; color: Theme.fg
                    Layout.fillWidth: true; elide: Text.ElideRight
                }

                // Copy as JSON
                Rectangle {
                    width: 28; height: 28; radius: Theme.r6
                    color: jsonCopyMa.containsMouse ? Theme.bgHover : "transparent"
                    FlatIcon { anchors.centerIn: parent; icon: Icons.code; size: 13; color: Theme.fgMuted }
                    MouseArea {
                        id: jsonCopyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var json = buildJson()
                            _clip.text = json; _clip.selectAll(); _clip.copy()
                            root.toast("Copied as JSON", "success")
                        }
                    }
                    FlatTooltip { visible: jsonCopyMa.containsMouse; text: "Copy as JSON"; y: -30 }
                }

                // Copy as SQL INSERT
                Rectangle {
                    width: 28; height: 28; radius: Theme.r6
                    color: sqlCopyMa.containsMouse ? Theme.bgHover : "transparent"
                    FlatIcon { anchors.centerIn: parent; icon: Icons.database; size: 13; color: Theme.fgMuted }
                    MouseArea {
                        id: sqlCopyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var sql = buildInsertSQL()
                            _clip.text = sql; _clip.selectAll(); _clip.copy()
                            root.toast("Copied as INSERT SQL", "success")
                        }
                    }
                    FlatTooltip { visible: sqlCopyMa.containsMouse; text: "Copy as INSERT SQL"; y: -30 }
                }

                // Close button
                Rectangle {
                    width: 28; height: 28; radius: Theme.r6
                    color: closeMa.containsMouse ? Theme.bgHover : "transparent"
                    FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 14; color: Theme.fgMuted }
                    MouseArea {
                        id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ── Row navigation ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s6

                Rectangle {
                    width: 24; height: 24; radius: Theme.r4
                    color: prevMa.containsMouse ? Theme.bgHover : "transparent"; opacity: selectedRow > 0 ? 1 : 0.3
                    FlatIcon { anchors.centerIn: parent; icon: Icons.left; size: 12; color: Theme.fgMuted }
                    MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (selectedRow > 0) selectedRow-- }
                }

                Text {
                    text: (selectedRow + 1) + " / " + (resultModel ? resultModel.totalRows : 0)
                    font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgDim
                    Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: 24; height: 24; radius: Theme.r4
                    color: nextMa.containsMouse ? Theme.bgHover : "transparent"; opacity: resultModel && selectedRow < resultModel.totalRows - 1 ? 1 : 0.3
                    FlatIcon { anchors.centerIn: parent; icon: Icons.right; size: 12; color: Theme.fgMuted }
                    MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (resultModel && selectedRow < resultModel.totalRows - 1) selectedRow++ }
                }
            }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ── Fields ──
        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true
            contentHeight: fieldsCol.implicitHeight + 24
            clip: true; boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: fieldsCol
                anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 0; spacing: 0

                Repeater {
                    model: resultModel ? resultModel.totalColumns : 0

                    Rectangle {
                        id: fieldItem
                        required property int index
                        property int colIdx: index

                        Layout.fillWidth: true
                        Layout.preferredHeight: fieldContent.implicitHeight + 24
                        color: fieldMa.containsMouse ? Theme.bgHover : colIdx % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)

                        ColumnLayout {
                            id: fieldContent
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.s4

                            // Column name + type badge
                            RowLayout {
                                spacing: Theme.s6
                                Text {
                                    text: resultModel ? resultModel.columnName(fieldItem.colIdx) : ""
                                    font.pixelSize: Theme.t11; font.weight: Font.DemiBold
                                    font.family: Theme.sans; color: Theme.fgMuted
                                }
                                // Type badge
                                Rectangle {
                                    height: 14; width: typeLbl.implicitWidth + Theme.s8; radius: Theme.rFull
                                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                                    visible: resultModel !== null
                                    Text {
                                        id: typeLbl; anchors.centerIn: parent
                                        text: {
                                            if (!resultModel || selectedRow < 0) return ""
                                            var v = resultModel.data(resultModel.index(selectedRow, fieldItem.colIdx), 0)
                                            return Fmt.valueType(v)
                                        }
                                        font.pixelSize: 8; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono
                                    }
                                }
                            }

                            // Value
                            Text {
                                text: {
                                    if (!resultModel || selectedRow < 0) return ""
                                    var v = resultModel.data(resultModel.index(selectedRow, fieldItem.colIdx), 0)
                                    return v !== undefined && v !== null ? String(v) : "NULL"
                                }
                                font.pixelSize: Theme.t13; font.family: Theme.mono
                                color: {
                                    if (!resultModel || selectedRow < 0) return Theme.fg
                                    var v = resultModel.data(resultModel.index(selectedRow, fieldItem.colIdx), 0)
                                    var vt = Fmt.valueType(v)
                                    if (vt === "null") return Theme.fgDim
                                    if (vt === "bool") return Theme.success
                                    if (vt === "number") return Theme.info
                                    return Theme.fg
                                }
                                font.italic: {
                                    if (!resultModel || selectedRow < 0) return false
                                    var v = resultModel.data(resultModel.index(selectedRow, fieldItem.colIdx), 0)
                                    return Fmt.valueType(v) === "null"
                                }
                                wrapMode: Text.WrapAnywhere
                                Layout.fillWidth: true
                            }
                        }

                        // Copy single value
                        MouseArea {
                            id: fieldMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!resultModel || selectedRow < 0) return
                                var v = resultModel.data(resultModel.index(selectedRow, fieldItem.colIdx), 0)
                                _clip.text = v !== undefined && v !== null ? String(v) : ""; _clip.selectAll(); _clip.copy()
                            }
                        }

                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.3 }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
            }
        }

        // ── Bottom action bar ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 40; color: Theme.bgElevated

            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                FlatButton { text: "Duplicate Row"; variant: "ghost"; size: "sm"; onClicked: root.rowDuplicated(selectedRow) }

                Item { Layout.fillWidth: true }

                FlatButton { text: "Delete"; variant: "destructive"; size: "sm"; onClicked: root.rowDeleted(selectedRow) }
            }
        }
    }

    // Clipboard helper
    TextEdit { id: _clip; visible: false }

    // Helper: toast (reaches up to root window)
    function toast(msg, type) {
        if (typeof root.parent !== "undefined" && root.parent && typeof root.parent.toast === "function")
            root.parent.toast(msg, type)
    }

    // Helpers: build JSON / SQL from current row
    function buildJson() {
        if (!resultModel || selectedRow < 0) return "{}"
        var obj = {}
        for (var i = 0; i < resultModel.totalColumns; i++) {
            var key = resultModel.columnName(i)
            var val = resultModel.data(resultModel.index(selectedRow, i), 0)
            obj[key] = val !== undefined ? val : null
        }
        return JSON.stringify(obj, null, 2)
    }

    function buildInsertSQL() {
        if (!resultModel || selectedRow < 0) return ""
        var cols = [], vals = []
        for (var i = 0; i < resultModel.totalColumns; i++) {
            cols.push('"' + resultModel.columnName(i) + '"')
            var v = resultModel.data(resultModel.index(selectedRow, i), 0)
            if (v === null || v === undefined) vals.push("NULL")
            else vals.push("'" + String(v).replace(/'/g, "''") + "'")
        }
        var t = tableName || "table_name"
        return "INSERT INTO " + t + " (" + cols.join(", ") + ") VALUES (" + vals.join(", ") + ");"
    }

    Keys.onEscapePressed: close()
}
