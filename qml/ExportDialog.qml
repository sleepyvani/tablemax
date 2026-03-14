import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import "Icons.js" as Icons

// ── Export Dialog ─────────────────────────────────────────────
// Ported from TablePro's Export views (CSV, JSON, SQL)
// Premium UI with format cards, live preview, and options

FlatDialog {
    id: exportDialog
    dialogTitle: "Export Data"
    dialogDescription: "Choose a format and options for export"
    width: 520

    required property var resultModel

    property string selectedFormat: "csv"
    property string previewText: ""

    function refreshPreview() {
        if (!resultModel) return
        if (selectedFormat === "csv")
            previewText = database.exportCsv(resultModel).substring(0, 500)
        else if (selectedFormat === "json")
            previewText = database.exportJson(resultModel, true).substring(0, 500)
        else if (selectedFormat === "sql")
            previewText = database.exportSql(resultModel, tableNameField.text || "table").substring(0, 500)
    }

    onOpened: refreshPreview()

    contentItem: ColumnLayout {
        spacing: Theme.s16; width: parent.width

        // ── Format Cards ──
        RowLayout {
            spacing: Theme.s8; Layout.fillWidth: true

            Repeater {
                model: [
                    { id: "csv",  label: "CSV",  icon: Icons.chart,  desc: "Spreadsheet" },
                    { id: "json", label: "JSON", icon: Icons.code,   desc: "Structured" },
                    { id: "sql",  label: "SQL",  icon: Icons.save,   desc: "Insert stmts" }
                ]

                Rectangle {
                    Layout.fillWidth: true; height: 72; radius: Theme.r8
                    color: selectedFormat === modelData.id ? Theme.accentDim : Theme.bgSurface
                    border.width: selectedFormat === modelData.id ? 2 : 1
                    border.color: selectedFormat === modelData.id ? Theme.accent : Theme.border

                    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: Theme.s4
                        FlatIcon {
                            icon: modelData.icon; size: 20
                            color: selectedFormat === modelData.id ? Theme.accent : Theme.fgMuted
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: modelData.label; font.family: Theme.sans; font.pixelSize: Theme.t13
                            font.weight: Font.DemiBold; color: Theme.fg
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: modelData.desc; font.family: Theme.sans; font.pixelSize: Theme.t11
                            color: Theme.fgMuted; Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { selectedFormat = modelData.id; refreshPreview() }
                    }
                }
            }
        }

        // ── Format-specific options ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: optCol.implicitHeight + 24
            radius: Theme.r8; color: Theme.bgSurface; border.width: 1; border.color: Theme.border

            ColumnLayout {
                id: optCol; anchors.fill: parent; anchors.margins: Theme.s12; spacing: Theme.s8

                RowLayout {
                    spacing: Theme.s6
                    FlatIcon { icon: Icons.settings; size: 12; color: Theme.fgMuted }
                    Text {
                        text: "Options"; font.family: Theme.sans; font.pixelSize: Theme.t12
                        font.weight: Font.DemiBold; color: Theme.fgMuted; font.letterSpacing: 0.5
                    }
                }

                // CSV options
                RowLayout {
                    visible: selectedFormat === "csv"; spacing: Theme.s12
                    Text { text: "Delimiter"; font.pixelSize: Theme.t12; font.family: Theme.sans; color: Theme.fgMuted }
                    FlatSelect { id: delimiterSelect; model: [",", ";", "\\t", "|"]; currentIndex: 0; implicitWidth: 80 }
                    FlatCheckbox { id: headersCheck; text: "Include headers"; checked: true }
                }

                // SQL options
                RowLayout {
                    visible: selectedFormat === "sql"; spacing: Theme.s12
                    FlatInput { id: tableNameField; placeholderText: "Table name"; text: "exported_table"
                        implicitWidth: 200; onTextChanged: refreshPreview() }
                }

                // JSON options
                RowLayout {
                    visible: selectedFormat === "json"; spacing: Theme.s12
                    FlatCheckbox { id: prettyCheck; text: "Pretty print"; checked: true }
                }
            }
        }

        // ── Preview ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 140
            radius: Theme.r8; color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.03)
            border.width: 1; border.color: Theme.border; clip: true

            ColumnLayout {
                anchors.fill: parent; spacing: 0

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 28
                    color: Theme.bgSurface
                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter; x: 10; spacing: Theme.s6
                        FlatIcon { icon: Icons.code; size: 10; color: Theme.fgMuted }
                        Text {
                            text: "Preview"; font.family: Theme.mono; font.pixelSize: Theme.t11
                            color: Theme.fgMuted; font.letterSpacing: 0.5
                        }
                    }
                }

                FlatScrollArea {
                    Layout.fillWidth: true; Layout.fillHeight: true

                    Text {
                        width: parent.width - 16; x: 8; y: 4
                        text: previewText + (previewText.length >= 500 ? "\n..." : "")
                        font.family: Theme.mono; font.pixelSize: Theme.t11
                        color: Theme.fg; wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }

        // ── Action Buttons ──
        RowLayout {
            spacing: Theme.s8; Layout.fillWidth: true; Layout.alignment: Qt.AlignRight

            FlatButton {
                text: "Copy to Clipboard"
                icon.source: ""
                onClicked: {
                    var content = generateExport()
                    if (content) {
                        clipHelper.text = content
                        clipHelper.selectAll()
                        clipHelper.copy()
                        root.toast("Copied to clipboard!", "success")
                    }
                }
            }

            FlatButton {
                text: "Save File"
                onClicked: saveDialog.open()
            }
        }
    }

    TextEdit { id: clipHelper; visible: false }

    FileDialog {
        id: saveDialog
        title: "Save Export"
        fileMode: FileDialog.SaveFile
        nameFilters: {
            if (selectedFormat === "csv") return ["CSV files (*.csv)"]
            if (selectedFormat === "json") return ["JSON files (*.json)"]
            return ["SQL files (*.sql)"]
        }
        onAccepted: {
            var content = generateExport()
            var path = selectedFile.toString().replace("file:///", "")
            if (database.exportToFile(path, content))
                root.toast("Exported successfully!", "success")
            else
                root.toast("Export failed", "error")
            exportDialog.close()
        }
    }

    function generateExport() {
        if (!resultModel) return ""
        if (selectedFormat === "csv")
            return database.exportCsv(resultModel, delimiterSelect.currentText, headersCheck.checked)
        if (selectedFormat === "json")
            return database.exportJson(resultModel, prettyCheck.checked)
        if (selectedFormat === "sql")
            return database.exportSql(resultModel, tableNameField.text || "exported_table")
        return ""
    }
}
