// CellEditor.qml — Inline cell editor overlay for DataGrid
// Ported from TablePro CellOverlayEditor.swift

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    visible: false
    color: Theme.bg
    border.color: Theme.accent; border.width: 2; radius: Theme.r4
    z: 100

    property int editRow: -1
    property int editCol: -1
    property string editValue: ""
    property string columnName: ""
    property string columnType: ""

    signal committed(int row, int col, string value)
    signal cancelled()

    function startEdit(row, col, value, colName, colType, x, y, w, h) {
        editRow = row; editCol = col; editValue = value || ""
        columnName = colName; columnType = colType
        root.x = x; root.y = y; root.width = Math.max(w, 200); root.height = Math.max(h, 32)
        visible = true

        // Choose editor based on column type
        if (isBoolType(colType)) {
            boolEditor.visible = true
            textEditor.visible = false
            jsonEditor.visible = false
            boolEditor.checked = (editValue === "1" || editValue.toLowerCase() === "true")
        } else if (isJsonType(colType) || looksLikeJson(editValue)) {
            jsonEditor.visible = true
            textEditor.visible = false
            boolEditor.visible = false
            jsonTextArea.text = tryPrettyJson(editValue)
            root.height = 300; root.width = Math.max(w, 400)
            jsonTextArea.forceActiveFocus()
        } else {
            textEditor.visible = true
            boolEditor.visible = false
            jsonEditor.visible = false
            textInput.text = editValue
            textInput.forceActiveFocus()
            textInput.selectAll()
        }
    }

    function commit() {
        var newValue = ""
        if (boolEditor.visible) newValue = boolEditor.checked ? "1" : "0"
        else if (jsonEditor.visible) newValue = jsonTextArea.text
        else newValue = textInput.text

        visible = false
        if (newValue !== editValue) committed(editRow, editCol, newValue)
    }

    function cancel() {
        visible = false; cancelled()
    }

    // ── Text editor (default) ──
    ColumnLayout {
        id: textEditor; visible: false; anchors.fill: parent; anchors.margins: 2; spacing: 0
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            TextInput {
                id: textInput
                Layout.fillWidth: true; Layout.fillHeight: true
                font.pixelSize: 12; font.family: "Cascadia Code, Consolas, monospace"
                color: Theme.fg; selectByMouse: true; clip: true
                verticalAlignment: TextInput.AlignVCenter
                leftPadding: 6

                Keys.onReturnPressed: root.commit()
                Keys.onEnterPressed: root.commit()
                Keys.onEscapePressed: root.cancel()
                Keys.onTabPressed: root.commit()
            }

            // NULL button
            Rectangle {
                width: 36; height: 22; radius: 4
                color: nullMa.containsMouse ? Theme.bgHover : "transparent"
                border.color: Theme.border; border.width: 1
                Text { anchors.centerIn: parent; text: "NULL"; font.pixelSize: 9; font.weight: Font.Medium; color: Theme.fgMuted; font.family: Theme.fontFamily }
                MouseArea {
                    id: nullMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { textInput.text = ""; root.committed(editRow, editCol, null) ; root.visible = false }
                }
            }

            // Confirm button
            Rectangle {
                width: 22; height: 22; radius: 4; color: commitMa.containsMouse ? Theme.accent : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                FlatIcon { anchors.centerIn: parent; icon: Icons.check; size: 11; color: commitMa.containsMouse ? "#fff" : Theme.accent }
                MouseArea { id: commitMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.commit() }
            }
        }
    }

    // ── Boolean editor ──
    RowLayout {
        id: boolEditor; visible: false; anchors.fill: parent; anchors.margins: 6; spacing: 8

        property bool checked: false

        FlatSwitch {
            checked: boolEditor.checked
            onCheckedChanged: { boolEditor.checked = checked; root.commit() }
        }
        Text { text: boolEditor.checked ? "TRUE" : "FALSE"; font.pixelSize: 12; font.weight: Font.Medium; color: boolEditor.checked ? Theme.success : Theme.fgMuted; font.family: Theme.fontFamily }
        Item { Layout.fillWidth: true }
    }

    // ── JSON editor ──
    ColumnLayout {
        id: jsonEditor; visible: false; anchors.fill: parent; anchors.margins: 2; spacing: 0

        // JSON toolbar
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 28; color: Theme.bgElevated
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 6
                FlatIcon { icon: Icons.code; size: 12; color: Theme.accent }
                Text { text: "JSON Editor"; font.pixelSize: 11; font.weight: Font.Medium; color: Theme.fg; font.family: Theme.fontFamily }
                Item { Layout.fillWidth: true }
                FlatButton { text: "Format"; flat: true; size: "small"; onClicked: jsonTextArea.text = tryPrettyJson(jsonTextArea.text) }
                FlatButton { text: "Save"; size: "small"; onClicked: root.commit() }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true
            TextArea {
                id: jsonTextArea
                font.pixelSize: 12; font.family: "Cascadia Code, Consolas, monospace"
                color: Theme.fg; wrapMode: Text.WrapAnywhere; selectByMouse: true
                background: Rectangle { color: "transparent" }
                padding: 8

                Keys.onEscapePressed: root.cancel()
            }
        }
    }

    // Dismiss on outside click
    MouseArea {
        parent: root.parent; anchors.fill: parent; z: root.z - 1
        visible: root.visible; onClicked: root.cancel()
    }

    // ── Helpers ──
    function isBoolType(t) {
        t = t.toLowerCase()
        return t === "boolean" || t === "bool" || t === "tinyint(1)" || t === "bit"
    }

    function isJsonType(t) {
        t = t.toLowerCase()
        return t === "json" || t === "jsonb" || t === "object" || t === "document"
    }

    function looksLikeJson(s) {
        if (!s) return false
        s = s.trim()
        return (s.startsWith("{") && s.endsWith("}")) || (s.startsWith("[") && s.endsWith("]"))
    }

    function tryPrettyJson(s) {
        try { return JSON.stringify(JSON.parse(s), null, 2) }
        catch (e) { return s }
    }
}
