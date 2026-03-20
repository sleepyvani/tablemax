import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "DbHelper.js" as DB
import "Icons.js" as Icons

FlatDialog {
    id: createTableDialog
    dialogTitle: "Create New Table"
    dialogDescription: "Design your table visually or review the generated SQL syntax"
    width: 780
    height: 600

    property string dbType: ""
    property string activeDatabase: ""
    signal tableCreated(string tableName)

    property string generatedSql: ""

    onOpened: {
        tableNameField.text = "new_table"
        columnsModel.clear()
        columnsModel.append({ "name": "id", "type": "INTEGER", "pk": true, "notNull": true, "defaultVal": "" })
        columnsModel.append({ "name": "created_at", "type": "TIMESTAMP", "pk": false, "notNull": false, "defaultVal": "CURRENT_TIMESTAMP" })
        refreshSql()
    }

    function refreshSql() {
        var cols = []
        for (var i = 0; i < columnsModel.count; i++) {
            var item = columnsModel.get(i)
            cols.push({
                name: item.name,
                type: item.type,
                pk: item.pk,
                nullable: !item.notNull,
                defaultVal: item.defaultVal
            })
        }
        generatedSql = DB.buildCreateTableSql(tableNameField.text, cols, dbType)
        sqlPreview.text = generatedSql
    }

    contentItem: RowLayout {
        spacing: 0; width: parent.width; height: 420

        // â”€â”€ Left: Designer â”€â”€
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.s16; spacing: Theme.s16

                RowLayout {
                    spacing: Theme.s12; Layout.fillWidth: true
                    Text { text: "Table Name"; font.pixelSize: Theme.t12; font.family: Theme.sans; color: Theme.fgMuted; font.weight: Font.DemiBold }
                    FlatInput {
                        id: tableNameField; Layout.fillWidth: true
                        placeholderText: "users"
                        onTextChanged: refreshSql()
                    }
                }

                DashedLine { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Columns"; font.pixelSize: Theme.t13; font.family: Theme.sans; color: Theme.fg; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    FlatButton {
                        text: "+ Add Column"
                        onClicked: {
                            columnsModel.append({ "name": "new_column", "type": "VARCHAR(255)", "pk": false, "notNull": false, "defaultVal": "" })
                            refreshSql()
                            colsListView.positionViewAtEnd()
                        }
                    }
                }

                // Columns Headers
                RowLayout {
                    Layout.fillWidth: true; spacing: Theme.s8
                    Text { text: "Name"; font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.mono; Layout.preferredWidth: 120 }
                    Text { text: "Type"; font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.mono; Layout.preferredWidth: 100 }
                    Text { text: "PK"; font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.mono; Layout.preferredWidth: 30 }
                    Text { text: "NOT NULL"; font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.mono; Layout.preferredWidth: 65 }
                    Text { text: "Default"; font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.mono; Layout.fillWidth: true }
                    Text { text: ""; Layout.preferredWidth: 28 }
                }

                FlatScrollArea {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    
                    ListView {
                        id: colsListView; anchors.fill: parent
                        model: ListModel { id: columnsModel }
                        spacing: Theme.s8; clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: RowLayout {
                            width: colsListView.width; spacing: Theme.s8
                            
                            FlatInput { 
                                Layout.preferredWidth: 120; text: model.name
                                onTextChanged: { model.name = text; refreshSql() }
                            }
                            FlatInput { 
                                Layout.preferredWidth: 100; text: model.type
                                onTextChanged: { model.type = text; refreshSql() }
                            }
                            FlatCheckbox { 
                                Layout.preferredWidth: 30; checked: model.pk
                                onCheckedChanged: { model.pk = checked; if(checked) model.notNull = true; refreshSql() }
                            }
                            FlatCheckbox { 
                                Layout.preferredWidth: 65; checked: model.notNull
                                onCheckedChanged: { model.notNull = checked; refreshSql() }
                                enabled: !model.pk
                            }
                            FlatInput { 
                                Layout.fillWidth: true; text: model.defaultVal
                                placeholderText: "NULL"
                                onTextChanged: { model.defaultVal = text; refreshSql() }
                            }
                            Rectangle {
                                width: 28; height: 32; radius: Theme.r4; color: rmMa.containsMouse ? Theme.error : "transparent"
                                FlatIcon { anchors.centerIn: parent; icon: Icons.trash; size: 14; color: rmMa.containsMouse ? "#fff" : Theme.warning }
                                MouseArea {
                                    id: rmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { columnsModel.remove(index); refreshSql() }
                                }
                            }
                        }
                    }
                }
            }
        }

        DashedLine { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.border }

        // â”€â”€ Right: SQL Preview â”€â”€
        Rectangle {
            Layout.preferredWidth: 260; Layout.fillHeight: true; color: Theme.bgElevated

            ColumnLayout {
                anchors.fill: parent; anchors.margins: Theme.s16; spacing: Theme.s8

                Text { text: "Live SQL Preview"; font.pixelSize: Theme.t12; font.family: Theme.sans; color: Theme.fgMuted; font.weight: Font.DemiBold }
                
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    color: Theme.bgSurface; radius: Theme.r6; border.width: 1; border.color: Theme.border
                    clip: true
                    
                    FlatScrollArea {
                        anchors.fill: parent; anchors.margins: Theme.s12
                        TextEdit {
                            id: sqlPreview; width: parent.width - Theme.s24
                            font.family: Theme.mono; font.pixelSize: Theme.t11; color: Theme.fg
                            wrapMode: TextEdit.Wrap; readOnly: true; selectByMouse: true
                            selectionColor: Theme.accentDim; selectedTextColor: Theme.fg
                        }
                    }
                }

                Item { Layout.fillHeight: true } // spacer

                Rectangle {
                    Layout.fillWidth: true; height: 30; radius: Theme.r6
                    color: execMa.containsMouse ? Theme.accentHover : Theme.accent
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    RowLayout {
                        anchors.centerIn: parent; spacing: Theme.s6
                        FlatIcon { icon: Icons.play; size: 12; color: "#fff" }
                        Text { text: "Execute SQL"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.DemiBold; color: "#fff" }
                    }

                    MouseArea {
                        id: execMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!databaseService || !databaseService.connected) return
                            if (generatedSql.trim() === "") return
                            if (activeDatabase && !DB.isSqlite(dbType))
                                databaseService.switchDatabase(activeDatabase)
                            var res = databaseService.executeBatch([generatedSql])
                            if (res.success) {
                                root.toast("Table '" + tableNameField.text + "' created successfully", "success")
                                tableCreated(tableNameField.text)
                                createTableDialog.close()
                            } else {
                                root.toast("Error: " + res.error, "error")
                            }
                        }
                    }
                    FlatTooltip { visible: execMa.containsMouse; text: "CREATE TABLE " + tableNameField.text; y: -30 }
                }
            }
        }
    }
}
