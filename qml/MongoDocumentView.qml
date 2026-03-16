// MongoDocumentView.qml — MongoDB Compass-style document browser
// Displays query results as expandable JSON document cards

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

    signal toast(string message, string type)

    TextEdit { id: _clip; visible: false }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Toolbar ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 36; color: Theme.bgElevated
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8
                FlatIcon { icon: Icons.list; size: 14; color: Theme.accent }
                Text {
                    text: totalRows + " document" + (totalRows !== 1 ? "s" : "")
                    font.pixelSize: Theme.t12; font.weight: Font.Medium; color: Theme.fg; font.family: Theme.sans
                }
                Item { Layout.fillWidth: true }

                // View mode toggle
                Row {
                    id: viewModeRow
                    spacing: Theme.s2
                    property string viewMode: "list"

                    Rectangle {
                        width: 28; height: 24; radius: Theme.r4
                        color: parent.viewMode === "list" ? Theme.accent : vm1Ma.containsMouse ? Theme.bgHover : "transparent"
                        FlatIcon { anchors.centerIn: parent; icon: Icons.list; size: 12; color: parent.parent.viewMode === "list" ? "#fff" : Theme.fgMuted }
                        MouseArea { id: vm1Ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: viewModeRow.viewMode = "list" }
                    }
                    Rectangle {
                        width: 28; height: 24; radius: Theme.r4
                        color: parent.viewMode === "json" ? Theme.accent : vm2Ma.containsMouse ? Theme.bgHover : "transparent"
                        FlatIcon { anchors.centerIn: parent; icon: Icons.code; size: 12; color: parent.parent.viewMode === "json" ? "#fff" : Theme.fgMuted }
                        MouseArea { id: vm2Ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: viewModeRow.viewMode = "json" }
                    }
                }
            }
            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }



        // ── Document List View (Compass-style) ──
        ListView {
            id: docListView
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: viewModeRow.viewMode === "list"
            model: totalRows; clip: true; spacing: Theme.s8
            boundsBehavior: Flickable.StopAtBounds
            topMargin: Theme.s8; bottomMargin: Theme.s8; leftMargin: Theme.s12; rightMargin: Theme.s12

            delegate: Rectangle {
                id: docDelegate
                required property int index
                width: docListView.width - 24; height: docContent.implicitHeight + 20
                radius: Theme.r8; color: Theme.bgElevated
                border.color: docMa.containsMouse ? Theme.accent : Theme.border; border.width: 1

                property bool expanded: false
                property int docIndex: index

                ColumnLayout {
                    id: docContent
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: Theme.s4

                    // Document header
                    RowLayout {
                        Layout.fillWidth: true; spacing: Theme.s8

                        Rectangle {
                            width: 20; height: 20; radius: Theme.r4; color: "transparent"
                            FlatIcon {
                                anchors.centerIn: parent
                                icon: docDelegate.expanded ? Icons.down : Icons.right
                                size: 10; color: Theme.fgMuted
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: docDelegate.expanded = !docDelegate.expanded }
                        }

                        FlatIcon { icon: Icons.file; size: 12; color: Theme.accent }

                        Text {
                            text: "Document " + (docDelegate.docIndex + 1)
                            font.pixelSize: Theme.t11; font.weight: Font.DemiBold; color: Theme.fg; font.family: Theme.sans
                        }

                        // _id badge
                        Rectangle {
                            visible: totalColumns > 0 && resultModel !== null
                            width: idLabel.implicitWidth + Theme.s12; height: 18; radius: Theme.rFull
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                            Text {
                                id: idLabel; anchors.centerIn: parent
                                text: resultModel ? String(resultModel.data(resultModel.index(docDelegate.docIndex, 0), 0) || "") : ""
                                font.pixelSize: 9; font.family: Theme.mono; color: Theme.accent
                                elide: Text.ElideMiddle; maximumLineCount: 1
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 22; height: 22; radius: Theme.r4; color: copyDocMa.containsMouse ? Theme.bgHover : "transparent"
                            FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 11; color: Theme.fgMuted }
                            MouseArea {
                                id: copyDocMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { copyDocument(docDelegate.docIndex); root.toast("Document copied", "success") }
                            }
                        }
                    }

                    // Collapsed preview
                    RowLayout {
                        visible: !docDelegate.expanded; Layout.fillWidth: true; spacing: 0; Layout.leftMargin: 28
                        Text {
                            Layout.fillWidth: true
                            text: getDocPreview(docDelegate.docIndex)
                            font.pixelSize: Theme.t11; font.family: Theme.mono
                            color: Theme.fgMuted; elide: Text.ElideRight; maximumLineCount: 1
                        }
                    }

                    // Expanded — show all fields
                    ColumnLayout {
                        visible: docDelegate.expanded; spacing: Theme.s2; Layout.leftMargin: 28; Layout.fillWidth: true

                        Repeater {
                            model: totalColumns

                            RowLayout {
                                required property int index
                                property int colIdx: index
                                Layout.fillWidth: true; spacing: Theme.s8

                                Text {
                                    text: resultModel ? String(resultModel.headerData(colIdx, Qt.Horizontal, 0) || ("col_" + colIdx)) : ""
                                    font.pixelSize: Theme.t11; font.family: Theme.mono
                                    font.weight: Font.Medium; color: Theme.accent
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
                                        if (v === "true" || v === "false") return Theme.warning
                                        if (!isNaN(v) && v !== "") return Theme.info
                                        return Theme.fg
                                    }
                                    Layout.fillWidth: true; wrapMode: Text.WrapAnywhere
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: docMa; anchors.fill: parent; hoverEnabled: true; z: -1
                    onDoubleClicked: docDelegate.expanded = !docDelegate.expanded
                }
            }
        }

        // ── JSON Raw View ──
        ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: viewModeRow.viewMode === "json"

            TextArea {
                text: generateAllDocsJson()
                font.pixelSize: Theme.t12; font.family: Theme.mono
                color: Theme.fg; readOnly: true; wrapMode: Text.WrapAnywhere
                background: Rectangle { color: "transparent" }
                padding: 16
            }
        }

        }
    }
    
    // Empty state (absolute positioned in root so it centers perfectly)
    FlatEmpty {
        anchors.centerIn: parent
        visible: totalRows === 0
        icon: Icons.database; title: "No documents"; description: "Run a query to see results"
    }

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
        for (var r = 0; r < Math.min(totalRows, 50); r++) {
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
