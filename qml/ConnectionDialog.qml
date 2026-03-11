import QtQuick
import QtQuick.Layouts

FlatDialog {
    id: dlg
    dialogTitle: editIdx >= 0 ? "Edit Connection" : "New Connection"
    dialogDescription: editIdx >= 0 ? "Update your database connection" : "Configure a new database connection"

    property int editIdx: -1

    contentItem: ColumnLayout {
        spacing: Theme.s12

        FlatField {
            label: "Name"; Layout.fillWidth: true
            FlatInput { id: nameIn; placeholderText: "My Database"; Layout.fillWidth: true }
        }

        FlatField {
            label: "Database Type"; Layout.fillWidth: true
            FlatSelect { id: dbType; model: ["postgres", "mysql", "sqlite", "mongodb", "redis", "mssql", "mariadb"]; Layout.fillWidth: true }
        }

        FlatField {
            label: "Connection String"; description: "e.g. host=localhost port=5432 dbname=mydb"; Layout.fillWidth: true
            FlatInput { id: connStr; placeholderText: "host=localhost port=5432 user=admin"; Layout.fillWidth: true }
        }

        FlatField {
            label: "Color"; Layout.fillWidth: true
            FlatColorPicker { id: colorPick; Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        RowLayout {
            Layout.fillWidth: true; spacing: Theme.s8

            // Test
            Rectangle {
                width: testRow.implicitWidth + 16; height: 28; radius: Theme.r6
                color: testMa.containsMouse ? Theme.bgHover : "transparent"; border.width: 1; border.color: Theme.border
                RowLayout {
                    id: testRow; anchors.centerIn: parent; spacing: Theme.s4
                    Text { text: "⚡"; font.pixelSize: 11 }
                    Text { text: "Test"; font.family: Theme.sans; font.pixelSize: Theme.t12; color: Theme.fg }
                }
                MouseArea { id: testMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { var ok = databaseService.testConnection(dbType.currentText, connStr.text); root.toast(ok ? "Connection OK!" : "Failed", ok ? "success" : "error") } }
            }

            Item { Layout.fillWidth: true }

            FlatButton { text: "Cancel"; variant: "ghost"; onClicked: dlg.close() }

            Rectangle {
                width: saveLabel.implicitWidth + 20; height: 28; radius: Theme.r6
                color: saveMa.containsMouse ? Theme.accentHover : Theme.accent
                scale: saveMa.pressed ? 0.96 : 1; Behavior on scale { NumberAnimation { duration: Theme.fast } }
                Text { id: saveLabel; anchors.centerIn: parent; text: editIdx >= 0 ? "Update" : "Save"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.DemiBold; color: "#fff" }
                MouseArea {
                    id: saveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var c = { name: nameIn.text, dbType: dbType.currentText, connectionString: connStr.text, color: colorPick.selectedColor.toString() }
                        if (editIdx >= 0) connectionManager.update(editIdx, c); else connectionManager.add(c)
                        dlg.close()
                    }
                }
            }
        }
    }

    onOpened: { if (editIdx >= 0) { var c = connectionManager.get(editIdx); nameIn.text = c.name || ""; connStr.text = c.connectionString || "" } else { nameIn.text = ""; connStr.text = "" } }
}
