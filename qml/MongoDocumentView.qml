// MongoDocumentView.qml — MongoDB Compass-style document browser
// Displays query results as expandable JSON document cards
// Supports inline field editing and document insertion

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    color: Theme.bg

    property var resultModel: null
    property int totalRows: resultModel ? resultModel.totalRows : 0
    property int totalColumns: resultModel ? resultModel.totalColumns : 0

    // Collection name for write operations (populated by QueryEditor/Main)
    property string collectionName: ""

    signal toast(string message, string type)

    TextEdit { id: _clip; visible: false }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Toolbar ──────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 36; color: Theme.bgElevated
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8
                FlatIcon { icon: Icons.database; size: 14; color: Theme.warning }
                Text {
                    text: totalRows + " document" + (totalRows !== 1 ? "s" : "")
                    font.pixelSize: Theme.t12; font.weight: Font.Medium; color: Theme.fg; font.family: Theme.sans
                }

                // Collection name badge
                Rectangle {
                    visible: collectionName !== ""
                    width: colBadge.implicitWidth + Theme.s12; height: 18; radius: Theme.rFull
                    color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.1)
                    Text { id: colBadge; anchors.centerIn: parent; text: collectionName; font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.warning }
                }

                Item { Layout.fillWidth: true }

                // Insert Document button
                Rectangle {
                    width: insertBtnRow.implicitWidth + Theme.s16; height: 26; radius: Theme.r6
                    color: insertDocMa.containsMouse ? Theme.accentHover : Theme.accent
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    RowLayout { id: insertBtnRow; anchors.centerIn: parent; spacing: Theme.s4
                        FlatIcon { icon: Icons.add; size: 11; color: "#fff" }
                        Text { text: "Insert"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.DemiBold; color: "#fff" }
                    }
                    MouseArea { id: insertDocMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: insertDocOverlay.visible = true }
                    FlatTooltip { visible: insertDocMa.containsMouse; text: "Insert new document"; y: 30 }
                }

                // View mode toggle
                Row {
                    id: viewModeRow; spacing: Theme.s2
                    property string viewMode: "list"

                    Rectangle {
                        width: 28; height: 24; radius: Theme.r4
                        color: parent.viewMode === "list" ? Theme.accent : vm1Ma.containsMouse ? Theme.bgHover : "transparent"
                        FlatIcon { anchors.centerIn: parent; icon: Icons.list; size: 12; color: parent.parent.viewMode === "list" ? "#fff" : Theme.fgMuted }
                        MouseArea { id: vm1Ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: viewModeRow.viewMode = "list" }
                        FlatTooltip { visible: vm1Ma.containsMouse; text: "Document view"; y: 30 }
                    }
                    Rectangle {
                        width: 28; height: 24; radius: Theme.r4
                        color: parent.viewMode === "json" ? Theme.accent : vm2Ma.containsMouse ? Theme.bgHover : "transparent"
                        FlatIcon { anchors.centerIn: parent; icon: Icons.code; size: 12; color: parent.parent.viewMode === "json" ? "#fff" : Theme.fgMuted }
                        MouseArea { id: vm2Ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: viewModeRow.viewMode = "json" }
                        FlatTooltip { visible: vm2Ma.containsMouse; text: "JSON view"; y: 30 }
                    }
                }
            }
            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ── Document List View ───────────────────────────────────
        ListView {
            id: docListView
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: viewModeRow.viewMode === "list"
            model: totalRows; clip: true; spacing: Theme.s8
            boundsBehavior: Flickable.StopAtBounds
            topMargin: Theme.s8; bottomMargin: Theme.s8; leftMargin: Theme.s12; rightMargin: Theme.s12

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
            }

            delegate: Rectangle {
                id: docDelegate
                required property int index
                width: docListView.width - 24
                height: docContent.implicitHeight + 20
                radius: Theme.r8; color: Theme.bgElevated
                border.color: editMode ? Theme.accent : docMa.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : Theme.border
                border.width: editMode ? 2 : 1

                Behavior on border.color { ColorAnimation { duration: Theme.fast } }

                property bool expanded: false
                property bool editMode: false
                property int docIndex: index

                // Edit model: list of {key, value} objects for inline editing
                property var editFields: []

                function enterEditMode() {
                    if (!resultModel) return
                    var fields = []
                    for (var c = 0; c < totalColumns; c++) {
                        var k = resultModel.headerData(c, Qt.Horizontal, 0) || ("col_" + c)
                        var v = resultModel.data(resultModel.index(docDelegate.docIndex, c), 0)
                        fields.push({ key: k, value: v !== undefined && v !== null ? String(v) : "" })
                    }
                    editFields = fields
                    editMode = true
                    expanded = true
                }

                function saveEdits() {
                    // Build $set object from editFields
                    var setObj = {}
                    for (var i = 0; i < editFields.length; i++) {
                        if (editFields[i].key !== "_id") {
                            setObj[editFields[i].key] = editFields[i].value
                        }
                    }
                    // Get _id for filter
                    var idVal = ""
                    for (var j = 0; j < editFields.length; j++) {
                        if (editFields[j].key === "_id") { idVal = editFields[j].value; break }
                    }
                    var col = collectionName || "collection"
                    var cmd = 'db.' + col + '.updateOne({_id: ObjectId("' + idVal + '")}, {$set: ' + JSON.stringify(setObj) + '})'
                    if (databaseService && databaseService.connected) {
                        databaseService.executeQuery(cmd, resultModel)
                        root.toast("Document updated", "success")
                    }
                    editMode = false
                }

                ColumnLayout {
                    id: docContent
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: Theme.s4

                    // Document header
                    RowLayout {
                        Layout.fillWidth: true; spacing: Theme.s8

                        // Expand toggle
                        Rectangle {
                            width: 20; height: 20; radius: Theme.r4; color: "transparent"
                            FlatIcon { anchors.centerIn: parent; icon: docDelegate.expanded ? Icons.down : Icons.right; size: 10; color: Theme.fgMuted }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (!editMode) docDelegate.expanded = !docDelegate.expanded }
                        }

                        FlatIcon { icon: Icons.file; size: 12; color: Theme.warning }

                        // _id badge
                        Rectangle {
                            visible: totalColumns > 0 && resultModel !== null
                            width: Math.min(idLabel.implicitWidth + Theme.s12, 180); height: 18; radius: Theme.rFull
                            color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.1)
                            Text {
                                id: idLabel; anchors.centerIn: parent
                                text: resultModel ? String(resultModel.data(resultModel.index(docDelegate.docIndex, 0), 0) || "") : ""
                                font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.warning
                                elide: Text.ElideMiddle; width: parent.width - Theme.s12
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Edit mode indicator
                        Rectangle {
                            visible: docDelegate.editMode
                            width: editLbl.implicitWidth + Theme.s8; height: 18; radius: Theme.r4
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                            border.width: 1; border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                            Text { id: editLbl; anchors.centerIn: parent; text: "EDITING"; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.accent }
                        }

                        // Copy button
                        Rectangle {
                            visible: !docDelegate.editMode
                            width: 22; height: 22; radius: Theme.r4; color: copyDocMa.containsMouse ? Theme.bgHover : "transparent"
                            FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 11; color: Theme.fgMuted }
                            MouseArea {
                                id: copyDocMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { copyDocument(docDelegate.docIndex); root.toast("Document copied as JSON", "success") }
                            }
                        }

                        // Edit button
                        Rectangle {
                            visible: !docDelegate.editMode
                            width: 22; height: 22; radius: Theme.r4; color: editDocMa.containsMouse ? Theme.bgHover : "transparent"
                            FlatIcon { anchors.centerIn: parent; icon: Icons.edit; size: 11; color: Theme.fgMuted }
                            MouseArea {
                                id: editDocMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: docDelegate.enterEditMode()
                            }
                            FlatTooltip { visible: editDocMa.containsMouse; text: "Edit document"; y: -28 }
                        }

                        // Delete button
                        Rectangle {
                            visible: !docDelegate.editMode
                            width: 22; height: 22; radius: Theme.r4; color: delDocMa.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1) : "transparent"
                            FlatIcon { anchors.centerIn: parent; icon: Icons.trash; size: 11; color: delDocMa.containsMouse ? Theme.error : Theme.fgMuted }
                            MouseArea {
                                id: delDocMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var idVal = resultModel ? String(resultModel.data(resultModel.index(docDelegate.docIndex, 0), 0) || "") : ""
                                    var col = collectionName || "collection"
                                    var cmd = 'db.' + col + '.deleteOne({_id: ObjectId("' + idVal + '")})'
                                    if (databaseService && databaseService.connected) {
                                        databaseService.executeQuery(cmd, resultModel)
                                        root.toast("Document deleted", "destructive")
                                    }
                                }
                            }
                            FlatTooltip { visible: delDocMa.containsMouse; text: "Delete document"; y: -28 }
                        }

                        // Save / Cancel when editing
                        FlatButton { visible: docDelegate.editMode; text: "Cancel"; variant: "ghost"; size: "sm"; onClicked: { docDelegate.editMode = false } }
                        FlatButton { visible: docDelegate.editMode; text: "Save"; size: "sm"; onClicked: docDelegate.saveEdits() }
                    }

                    // Collapsed preview
                    RowLayout {
                        visible: !docDelegate.expanded && !docDelegate.editMode
                        Layout.fillWidth: true; spacing: 0; Layout.leftMargin: 28
                        Text {
                            Layout.fillWidth: true
                            text: getDocPreview(docDelegate.docIndex)
                            font.pixelSize: Theme.t11; font.family: Theme.mono
                            color: Theme.fgMuted; elide: Text.ElideRight; maximumLineCount: 1
                        }
                    }

                    // ── View Mode: Expanded fields ──
                    ColumnLayout {
                        visible: docDelegate.expanded && !docDelegate.editMode
                        spacing: Theme.s2; Layout.leftMargin: 28; Layout.fillWidth: true

                        Repeater {
                            model: totalColumns
                            RowLayout {
                                required property int index
                                property int colIdx: index
                                Layout.fillWidth: true; spacing: Theme.s8; height: 22

                                // Field name
                                Text {
                                    text: resultModel ? String(resultModel.headerData(colIdx, Qt.Horizontal, 0) || ("col_" + colIdx)) : ""
                                    font.pixelSize: Theme.t11; font.family: Theme.mono; font.weight: Font.Medium; color: Theme.accent
                                    Layout.preferredWidth: 140; Layout.alignment: Qt.AlignTop
                                }
                                Text { text: ":"; font.pixelSize: Theme.t11; color: Theme.fgDim; Layout.alignment: Qt.AlignTop }
                                Text {
                                    text: {
                                        if (!resultModel) return ""
                                        var val = resultModel.data(resultModel.index(docDelegate.docIndex, colIdx), 0)
                                        return val !== undefined && val !== null ? String(val) : "null"
                                    }
                                    font.pixelSize: Theme.t11; font.family: Theme.mono
                                    color: {
                                        var v = text
                                        if (v === "null") return Theme.fgDim
                                        if (v === "true" || v === "false") return Theme.success
                                        if (!isNaN(v) && v !== "") return Theme.info
                                        return Theme.fg
                                    }
                                    Layout.fillWidth: true; wrapMode: Text.WrapAnywhere
                                }
                            }
                        }
                    }

                    // ── Edit Mode: Editable fields ──
                    ColumnLayout {
                        visible: docDelegate.editMode
                        spacing: Theme.s6; Layout.leftMargin: 28; Layout.fillWidth: true

                        Repeater {
                            model: docDelegate.editFields
                            RowLayout {
                                required property var modelData
                                required property int index
                                property int fieldIdx: index
                                Layout.fillWidth: true; spacing: Theme.s8; height: 34

                                // Field name (read-only except non-_id)
                                Rectangle {
                                    Layout.preferredWidth: 140; height: 28; radius: Theme.r4
                                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04)
                                    Text {
                                        anchors.fill: parent; anchors.leftMargin: Theme.s8; verticalAlignment: Text.AlignVCenter
                                        text: modelData.key || ""
                                        font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.accent
                                        elide: Text.ElideRight
                                    }
                                }

                                Text { text: ":"; font.pixelSize: Theme.t11; color: Theme.fgDim }

                                // Editable value field
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; radius: Theme.r4
                                    color: modelData.key === "_id" ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04) : Theme.bgSurface
                                    border.width: 1; border.color: fieldEdit.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6) : Theme.border
                                    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

                                    TextInput {
                                        id: fieldEdit
                                        anchors.fill: parent; anchors.leftMargin: Theme.s8; anchors.rightMargin: Theme.s8
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: modelData.value || ""
                                        font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.fg
                                        selectByMouse: true; clip: true
                                        readOnly: modelData.key === "_id"
                                        onTextChanged: {
                                            if (fieldIdx < docDelegate.editFields.length) {
                                                var arr = docDelegate.editFields.slice()
                                                arr[fieldIdx] = { key: arr[fieldIdx].key, value: text }
                                                docDelegate.editFields = arr
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea { id: docMa; anchors.fill: parent; hoverEnabled: true; z: -1; onDoubleClicked: if (!editMode) docDelegate.expanded = !docDelegate.expanded }
            }
        }

        // ── JSON Raw View ──────────────────────────────────────
        FlatScrollArea {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: viewModeRow.viewMode === "json"

            TextEdit {
                width: parent.width - 32; x: 16; y: 12
                text: generateAllDocsJson()
                font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.fg
                readOnly: true; wrapMode: TextEdit.WrapAnywhere; selectByMouse: true
            }
        }
    }

    // Empty state
    FlatEmpty {
        anchors.centerIn: parent
        visible: totalRows === 0
        icon: Icons.database; title: "No documents"; description: "Run a query to see results"
    }

    // ── Insert Document Overlay ──────────────────────────────
    Rectangle {
        id: insertDocOverlay
        anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.5)
        visible: false; z: 100

        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }

        MouseArea { anchors.fill: parent; onClicked: insertDocOverlay.visible = false }

        Rectangle {
            width: Math.min(parent.width - 64, 560)
            height: Math.min(parent.height - 80, 480)
            anchors.centerIn: parent
            radius: Theme.r12; color: Theme.bg
            border.width: 1; border.color: Theme.border

            MouseArea { anchors.fill: parent } // prevent click-through

            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.s24; spacing: Theme.s16

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    FlatIcon { icon: Icons.add; size: 16; color: Theme.warning }
                    Text { text: "Insert Document"; font.family: Theme.sans; font.pixelSize: Theme.t16; font.weight: Font.DemiBold; color: Theme.fg; Layout.fillWidth: true }
                    Rectangle {
                        width: 24; height: 24; radius: Theme.r4; color: closeInsertMa.containsMouse ? Theme.bgHover : "transparent"
                        FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 12; color: Theme.fgMuted }
                        MouseArea { id: closeInsertMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: insertDocOverlay.visible = false }
                    }
                }

                Text { text: "Paste or type a JSON document to insert"; font.family: Theme.sans; font.pixelSize: Theme.t13; color: Theme.fgMuted }

                // JSON Editor
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: Theme.r8; color: Theme.bgSurface
                    border.width: 1; border.color: insertJsonEdit.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.7) : Theme.border
                    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

                    Flickable {
                        anchors.fill: parent; anchors.margins: 1
                        contentWidth: width; contentHeight: insertJsonEdit.implicitHeight + 24
                        clip: true; boundsBehavior: Flickable.StopAtBounds

                        TextEdit {
                            id: insertJsonEdit
                            width: parent.width
                            topPadding: Theme.s12; leftPadding: Theme.s12; rightPadding: Theme.s12; bottomPadding: Theme.s12
                            font.family: Theme.mono; font.pixelSize: Theme.t12; color: Theme.fg
                            wrapMode: TextEdit.Wrap; selectByMouse: true; textFormat: TextEdit.PlainText
                            text: "{\n  \n}"

                            Text {
                                x: Theme.s12; y: Theme.s12
                                text: "Enter valid JSON document..."
                                font: parent.font; color: Theme.fgDim; opacity: 0.4
                                visible: parent.text === "" || parent.text === "{\n  \n}"
                            }
                        }
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }
                    }
                }

                // Validation hint
                Text {
                    id: insertValidHint
                    property bool isValid: {
                        try { JSON.parse(insertJsonEdit.text); return true } catch(e) { return false }
                    }
                    text: isValid ? "✓ Valid JSON" : "⚠ Invalid JSON"
                    font.family: Theme.sans; font.pixelSize: Theme.t12
                    color: isValid ? Theme.success : Theme.warning
                    visible: insertJsonEdit.text.trim() !== "" && insertJsonEdit.text !== "{\n  \n}"
                }

                // Actions
                RowLayout {
                    Layout.fillWidth: true; spacing: Theme.s8
                    Item { Layout.fillWidth: true }
                    FlatButton { text: "Cancel"; variant: "ghost"; size: "sm"; onClicked: insertDocOverlay.visible = false }
                    FlatButton {
                        text: "Insert Document"; size: "sm"
                        enabled: insertValidHint.isValid
                        opacity: enabled ? 1.0 : 0.5
                        onClicked: {
                            var col = collectionName || "collection"
                            var cmd = 'db.' + col + '.insertOne(' + insertJsonEdit.text + ')'
                            if (databaseService && databaseService.connected) {
                                var res = databaseService.executeQuery(cmd, resultModel)
                                if (res && res.success) {
                                    root.toast("Document inserted", "success")
                                    insertDocOverlay.visible = false
                                } else {
                                    root.toast("Insert failed: " + (res ? res.error : "unknown"), "destructive")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Helper Functions ──────────────────────────────────────
    function getDocPreview(row) {
        if (!resultModel) return ""
        var parts = []
        var cols = Math.min(4, totalColumns)
        for (var c = 0; c < cols; c++) {
            var name = resultModel.headerData(c, Qt.Horizontal, 0) || ("col_" + c)
            var val = resultModel.data(resultModel.index(row, c), 0)
            if (val !== undefined && val !== null) {
                var s = String(val)
                if (s.length > 30) s = s.substring(0, 30) + "…"
                parts.push(name + ": " + s)
            }
        }
        return "{ " + parts.join(", ") + (totalColumns > cols ? ", …" : "") + " }"
    }

    function copyDocument(row) {
        if (!resultModel) return
        var doc = {}
        for (var c = 0; c < totalColumns; c++) {
            var name = resultModel.headerData(c, Qt.Horizontal, 0) || ("col_" + c)
            doc[name] = resultModel.data(resultModel.index(row, c), 0)
        }
        _clip.text = JSON.stringify(doc, null, 2)
        _clip.selectAll(); _clip.copy()
    }

    function generateAllDocsJson() {
        if (!resultModel) return "[]"
        var docs = []
        for (var r = 0; r < Math.min(totalRows, 100); r++) {
            var doc = {}
            for (var c = 0; c < totalColumns; c++) {
                var name = resultModel.headerData(c, Qt.Horizontal, 0) || ("col_" + c)
                doc[name] = resultModel.data(resultModel.index(r, c), 0)
            }
            docs.push(doc)
        }
        return JSON.stringify(docs, null, 2)
    }
}
