import QtQuick
import QtQuick.Layouts

FlatDialog {
    id: dialog
    dialogTitle: editIndex >= 0 ? "Edit Connection" : "New Connection"
    dialogDescription: editIndex >= 0 ? "Update your database connection" : "Add a new database connection"

    property int editIndex: -1

    contentItem: ColumnLayout {
        spacing: 14

        FlatField {
            label: "Name"
            Layout.fillWidth: true
            FlatInput {
                id: nameInput
                placeholderText: "My Database"
                Layout.fillWidth: true
            }
        }

        FlatField {
            label: "Database"
            Layout.fillWidth: true
            FlatSelect {
                id: dbTypeSelect
                model: ["postgres", "mysql", "sqlite", "mongodb", "redis", "mssql", "mariadb"]
                Layout.fillWidth: true
            }
        }

        FlatField {
            label: "Connection String"
            description: "e.g. host=localhost port=5432 dbname=mydb"
            Layout.fillWidth: true
            FlatInput {
                id: connStrInput
                placeholderText: "host=localhost port=5432 user=admin"
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

        // Separator
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        // Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Test button
            Rectangle {
                Layout.preferredWidth: testRow.implicitWidth + 20
                Layout.preferredHeight: 32
                radius: Theme.radius
                color: testMouse.containsMouse ? Theme.muted : "transparent"
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    id: testRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "⚡"
                        font.pixelSize: 12
                    }
                    Text {
                        text: "Test"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Medium
                        color: Theme.foreground
                    }
                }

                MouseArea {
                    id: testMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var ok = databaseService.testConnection(dbTypeSelect.currentText, connStrInput.text)
                        app.showToast(ok ? "Connection successful!" : "Connection failed", ok ? "success" : "destructive")
                    }
                }
            }

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Cancel"
                variant: "ghost"
                onClicked: dialog.close()
            }

            Rectangle {
                Layout.preferredWidth: saveRow.implicitWidth + 24
                Layout.preferredHeight: 32
                radius: Theme.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: saveMouse.containsMouse ? "#4f46e5" : "#6366f1" }
                    GradientStop { position: 1.0; color: saveMouse.containsMouse ? "#7c3aed" : "#8b5cf6" }
                }

                RowLayout {
                    id: saveRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: editIndex >= 0 ? "Update" : "Save"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                    }
                }

                MouseArea {
                    id: saveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var conn = {
                            name: nameInput.text,
                            dbType: dbTypeSelect.currentText,
                            connectionString: connStrInput.text,
                            color: colorPicker.selectedColor.toString()
                        }
                        if (editIndex >= 0) connectionManager.update(editIndex, conn)
                        else connectionManager.add(conn)
                        dialog.close()
                    }
                }

                scale: saveMouse.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
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
