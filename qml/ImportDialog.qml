import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import "Icons.js" as Icons

// ── Import Dialog ────────────────────────────────────────────
// Execute SQL files with progress feedback

FlatDialog {
    id: importDialog
    dialogTitle: "Import SQL File"
    dialogDescription: "Execute SQL statements from a file"
    width: 440

    property bool importing: false
    property string importResult: ""
    property string selectedFilePath: ""

    contentItem: ColumnLayout {
        spacing: Theme.s16; width: parent.width

        // ── File info ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 80; radius: Theme.r8
            color: Theme.bgSurface; border.width: 1; border.color: Theme.border

            ColumnLayout {
                anchors.centerIn: parent; spacing: Theme.s8

                FlatIcon {
                    icon: Icons.fileCode; size: 28; color: Theme.fgMuted
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: selectedFilePath || "No file selected"
                    font.family: Theme.mono; font.pixelSize: Theme.t12; color: Theme.fgMuted
                    Layout.alignment: Qt.AlignHCenter; elide: Text.ElideMiddle
                    Layout.maximumWidth: 360
                }
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: fileDialog.open()
            }
        }

        // ── Options ──
        ColumnLayout {
            spacing: Theme.s8; Layout.fillWidth: true
            FlatCheckbox { id: wrapTransaction; text: "Wrap in transaction"; checked: true }
            FlatCheckbox { id: stopOnError; text: "Stop on first error"; checked: true }
        }

        // ── Progress ──
        Rectangle {
            visible: importing || importResult
            Layout.fillWidth: true; Layout.preferredHeight: 56; radius: Theme.r8
            color: importResult.startsWith("\u2705") ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1) :
                   importResult.startsWith("\u274C") ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1) :
                   Theme.bgSurface
            border.width: 1
            border.color: importResult.startsWith("\u2705") ? Theme.success :
                          importResult.startsWith("\u274C") ? Theme.error : Theme.border

            RowLayout {
                anchors.fill: parent; anchors.margins: Theme.s12; spacing: Theme.s8

                FlatSpinner { visible: importing; implicitWidth: 20; implicitHeight: 20 }
                FlatIcon {
                    visible: !importing && importResult
                    icon: importResult.startsWith("\u2705") ? Icons.success : Icons.error
                    size: 16
                    color: importResult.startsWith("\u2705") ? Theme.success : Theme.error
                }

                Text {
                    text: {
                        if (importing) return "Executing statements..."
                        if (importResult.startsWith("\u2705")) return importResult.substring(2)
                        if (importResult.startsWith("\u274C")) return importResult.substring(2)
                        return importResult
                    }
                    font.family: Theme.sans; font.pixelSize: Theme.t12
                    color: Theme.fg; Layout.fillWidth: true; wrapMode: Text.Wrap
                }
            }
        }

        // ── Actions ──
        RowLayout {
            spacing: Theme.s8; Layout.fillWidth: true; Layout.alignment: Qt.AlignRight

            FlatButton {
                text: "Browse..."; onClicked: fileDialog.open()
            }

            FlatButton {
                text: importing ? "Importing..." : "Import"
                highlighted: true; enabled: !importing && selectedFilePath
                onClicked: doImport()
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Select SQL File"
        nameFilters: ["SQL files (*.sql)", "All files (*)"]
        onAccepted: {
            contentItem.selectedFilePath = selectedFile.toString().replace("file:///", "")
            importResult = ""
        }
    }

    function doImport() {
        if (!contentItem.selectedFilePath) return
        importing = true; importResult = ""
        var result = database.importSqlFile(contentItem.selectedFilePath)
        importing = false
        if (result.success) {
            importResult = "\u2705 Successfully executed " + result.executed + " statements"
            root.toast("Import completed: " + result.executed + " statements", "success")
        } else {
            importResult = "\u274C Error after " + result.executed + " statements: " + result.error
            root.toast("Import failed: " + result.error, "error")
        }
    }
}
