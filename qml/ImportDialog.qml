import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import "Icons.js" as Icons

// â”€â”€ Import Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Execute SQL files with progress feedback

FlatDialog {
    id: importDialog
    dialogTitle: "Import SQL File"
    dialogDescription: "Execute SQL statements from a file"
    width: 440

    property bool importing: false
    property string importResult: ""
    property string selectedFilePath: ""

    function fileBasename(path) {
        if (!path) return ""
        var parts = path.replace(/\\/g, "/").split("/")
        return parts[parts.length - 1]
    }

    contentItem: ColumnLayout {
        spacing: Theme.s16; width: parent.width

        // ── File drop zone ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 90; radius: Theme.r8
            color: dzMa.containsMouse
                   ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.05)
                   : Theme.bgSurface
            border.width: selectedFilePath ? 2 : 1
            border.color: selectedFilePath ? Theme.accent
                         : dzMa.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
                         : Theme.border
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Behavior on border.color { ColorAnimation { duration: Theme.fast } }

            ColumnLayout {
                anchors.centerIn: parent; spacing: Theme.s6

                FlatIcon {
                    icon: selectedFilePath ? Icons.fileCode : Icons.upload
                    size: 24
                    color: selectedFilePath ? Theme.accent : Theme.fgMuted
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: selectedFilePath
                          ? importDialog.fileBasename(selectedFilePath)
                          : "Click to browse for a .sql file"
                    font.family: selectedFilePath ? Theme.mono : Theme.sans
                    font.pixelSize: Theme.t12
                    color: selectedFilePath ? Theme.fg : Theme.fgMuted
                    Layout.alignment: Qt.AlignHCenter
                    elide: Text.ElideMiddle
                    Layout.maximumWidth: 360
                }

                Text {
                    visible: !selectedFilePath
                    text: "or drag and drop"
                    font.family: Theme.sans; font.pixelSize: Theme.t11
                    color: Theme.fgDim
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            MouseArea {
                id: dzMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: fileDialog.open()
            }
        }

        // â”€â”€ Options â”€â”€
        ColumnLayout {
            spacing: Theme.s8; Layout.fillWidth: true
            FlatCheckbox { id: wrapTransaction; text: "Wrap in transaction"; checked: true }
            FlatCheckbox { id: stopOnError; text: "Stop on first error"; checked: true }
        }

        // â”€â”€ Progress â”€â”€
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

        // â”€â”€ Actions â”€â”€
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
        var result = databaseService.importSqlFile(contentItem.selectedFilePath)
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
