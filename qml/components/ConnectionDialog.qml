import QtQuick
import QtQuick.Layouts

FlatDialog {
    id: dialog
    dialogTitle: "New Connection"
    dialogDescription: "Add a database connection"

    property int editIndex: -1

    contentItem: ColumnLayout {
        spacing: 12

        FlatField {
            label: "Connection Name"
            Layout.fillWidth: true
            FlatInput {
                id: nameInput
                placeholderText: "My Database"
                Layout.fillWidth: true
            }
        }

        FlatField {
            label: "Database Type"
            Layout.fillWidth: true
            FlatSelect {
                id: dbTypeSelect
                model: ["postgres", "mysql", "sqlite", "mongodb", "redis", "mssql", "mariadb"]
                Layout.fillWidth: true
            }
        }

        FlatField {
            label: "Connection String"
            Layout.fillWidth: true
            FlatInput {
                id: connStrInput
                placeholderText: "host=localhost port=5432 dbname=mydb"
                Layout.fillWidth: true
            }
        }

        FlatField {
            label: "Color"
            Layout.fillWidth: true
            FlatColorPicker {
                id: colorPicker
                Layout.fillWidth: true
            }
        }

        // Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            FlatButton {
                text: "Test"
                variant: "outline"
                onClicked: {
                    var ok = databaseService.testConnection(
                        dbTypeSelect.currentText, connStrInput.text
                    )
                    toast.show(ok ? "Connection OK!" : "Connection failed", ok ? "success" : "destructive")
                }
            }

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Cancel"
                variant: "ghost"
                onClicked: dialog.close()
            }

            FlatButton {
                text: dialog.editIndex >= 0 ? "Update" : "Save"
                onClicked: {
                    var conn = {
                        name: nameInput.text,
                        dbType: dbTypeSelect.currentText,
                        connectionString: connStrInput.text,
                        color: colorPicker.selectedColor.toString()
                    }
                    if (dialog.editIndex >= 0) {
                        connectionManager.update(dialog.editIndex, conn)
                    } else {
                        connectionManager.add(conn)
                    }
                    dialog.close()
                }
            }
        }
    }

    onOpened: {
        if (editIndex >= 0) {
            var c = connectionManager.get(editIndex)
            nameInput.text = c.name || ""
            connStrInput.text = c.connectionString || ""
        } else {
            nameInput.text = ""
            connStrInput.text = ""
        }
    }
}
