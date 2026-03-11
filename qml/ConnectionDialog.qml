import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

T.Dialog {
    id: dlg

    property int editIdx: -1
    property int modeIdx: 0           // 0 = Form, 1 = Connection String
    property string testStatus: ""    // "", "testing", "ok", "fail"
    property string testMsg: ""

    anchors.centerIn: parent
    modal: true; dim: true
    implicitWidth: 480
    padding: 0

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationSlow; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: Theme.durationSlow; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationFast; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.96; duration: Theme.durationFast; easing.type: Easing.InCubic }
        }
    }

    background: Rectangle {
        color: Theme.background
        border.width: 1
        border.color: Theme.border
        radius: Theme.radiusLg
    }

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.6)
        Behavior on opacity { NumberAnimation { duration: Theme.durationSlow } }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ─── Header ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24; Layout.topMargin: 24
            spacing: 4

            Text {
                text: editIdx >= 0 ? "Edit Connection" : "New Connection"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLg
                font.weight: Font.DemiBold
                color: Theme.foreground
            }
            Text {
                text: "Configure your database connection settings"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                color: Theme.mutedForeground
            }
        }

        Item { Layout.preferredHeight: 20 }

        // ─── Database Type ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            spacing: 8

            Text {
                text: "Database"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                color: Theme.foreground
            }

            // Type cards
            GridLayout {
                Layout.fillWidth: true
                columns: 4; rowSpacing: 6; columnSpacing: 6

                Repeater {
                    model: [
                        { key: "postgres", label: "PostgreSQL", abbr: "PG", clr: "#336791" },
                        { key: "mysql",    label: "MySQL",      abbr: "MY", clr: "#00758f" },
                        { key: "sqlite",   label: "SQLite",     abbr: "SQ", clr: "#003b57" },
                        { key: "mongodb",  label: "MongoDB",    abbr: "MO", clr: "#47A248" },
                        { key: "redis",    label: "Redis",      abbr: "RE", clr: "#DC382D" },
                        { key: "mssql",    label: "MSSQL",      abbr: "MS", clr: "#CC2927" },
                        { key: "mariadb",  label: "MariaDB",    abbr: "MA", clr: "#003545" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: Theme.radius
                        property bool sel: dbTypeIdx === index

                        color: sel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08) : dbCardMa.containsMouse ? Theme.muted : "transparent"
                        border.width: 1
                        border.color: sel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Theme.border

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 2

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 14; height: 14; radius: 3
                                color: modelData.clr

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.abbr.substring(0, 1)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 7; font.weight: Font.Bold
                                    color: "#fff"
                                }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: sel ? Theme.foreground : Theme.mutedForeground
                            }
                        }

                        MouseArea {
                            id: dbCardMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: dbTypeIdx = index
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 16 }

        // ─── Name ───
        FlatField {
            label: "Connection Name"
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24

            FlatInput {
                id: nameIn
                placeholderText: "e.g. Production DB"
                Layout.fillWidth: true
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ─── Mode Toggle ───
        FlatToggleGroup {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            model: ["Form", "Connection String"]
            currentIndex: modeIdx
            onToggled: function(idx) { modeIdx = idx }
        }

        Item { Layout.preferredHeight: 14 }

        // ─── Form Mode ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            spacing: 10
            visible: modeIdx === 0

            RowLayout {
                Layout.fillWidth: true; spacing: 10

                FlatField {
                    label: "Host"
                    Layout.fillWidth: true

                    FlatInput {
                        id: hostIn
                        placeholderText: "localhost"
                        Layout.fillWidth: true
                    }
                }

                FlatField {
                    label: "Port"
                    Layout.preferredWidth: 90

                    FlatInput {
                        id: portIn
                        placeholderText: {
                            var ports = ["5432", "3306", "0", "27017", "6379", "1433", "3306"]
                            return ports[dbTypeIdx] || "5432"
                        }
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 10

                FlatField {
                    label: "Username"
                    Layout.fillWidth: true

                    FlatInput {
                        id: userIn
                        placeholderText: "admin"
                        Layout.fillWidth: true
                    }
                }

                FlatField {
                    label: "Password"
                    Layout.fillWidth: true

                    FlatInput {
                        id: passIn
                        placeholderText: "••••••••"
                        echoMode: TextInput.Password
                        Layout.fillWidth: true
                    }
                }
            }

            FlatField {
                label: "Database"
                Layout.fillWidth: true

                FlatInput {
                    id: dbNameIn
                    placeholderText: "mydb"
                    Layout.fillWidth: true
                }
            }
        }

        // ─── Connection String Mode ───
        FlatField {
            label: "Connection String"
            description: {
                var examples = [
                    "postgresql://user:pass@localhost:5432/mydb",
                    "mysql://user:pass@localhost:3306/mydb",
                    "/path/to/database.db",
                    "mongodb://user:pass@localhost:27017/mydb",
                    "redis://localhost:6379",
                    "Server=localhost;Database=mydb;User=sa;Password=pass",
                    "mysql://user:pass@localhost:3306/mydb"
                ]
                return "e.g. " + (examples[dbTypeIdx] || examples[0])
            }
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            visible: modeIdx === 1

            FlatInput {
                id: connStrIn
                placeholderText: "Enter connection string..."
                Layout.fillWidth: true
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ─── Color ───
        FlatField {
            label: "Color"
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24

            FlatColorPicker {
                id: colorPick
                Layout.fillWidth: true
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ─── Test Result ───
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            Layout.preferredHeight: testStatus !== "" ? 36 : 0
            radius: Theme.radius
            visible: testStatus !== ""
            clip: true

            Behavior on Layout.preferredHeight { NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutCubic } }

            color: {
                if (testStatus === "ok") return Qt.rgba(0.2, 0.83, 0.6, 0.08)
                if (testStatus === "fail") return Qt.rgba(0.97, 0.44, 0.44, 0.08)
                return Theme.muted
            }
            border.width: 1
            border.color: {
                if (testStatus === "ok") return Qt.rgba(0.2, 0.83, 0.6, 0.2)
                if (testStatus === "fail") return Qt.rgba(0.97, 0.44, 0.44, 0.2)
                return Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: {
                        if (testStatus === "testing") return "⟳"
                        if (testStatus === "ok") return "✓"
                        if (testStatus === "fail") return "✗"
                        return ""
                    }
                    font.pixelSize: 13
                    color: {
                        if (testStatus === "ok") return Theme.success
                        if (testStatus === "fail") return Theme.error
                        return Theme.mutedForeground
                    }

                    RotationAnimation on rotation {
                        from: 0; to: 360; duration: 800
                        loops: Animation.Infinite
                        running: testStatus === "testing"
                    }
                }

                Text {
                    text: testMsg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    color: {
                        if (testStatus === "ok") return Theme.success
                        if (testStatus === "fail") return Theme.error
                        return Theme.mutedForeground
                    }
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        // ─── Separator ───
        Rectangle {
            Layout.fillWidth: true
            height: 1; color: Theme.border
        }

        // ─── Footer ───
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            spacing: 8

            FlatButton {
                text: "Test Connection"
                variant: "outline"
                onClicked: doTest()
            }

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Cancel"
                variant: "ghost"
                onClicked: dlg.close()
            }

            FlatButton {
                text: editIdx >= 0 ? "Update" : "Save"
                onClicked: doSave()
            }
        }
    }

    property int dbTypeIdx: 0
    property var dbTypes: ["postgres", "mysql", "sqlite", "mongodb", "redis", "mssql", "mariadb"]

    function buildConnStr() {
        if (modeIdx === 1) return connStrIn.text
        var h = hostIn.text || "localhost"
        var p = portIn.text || ""
        var u = userIn.text || ""
        var pw = passIn.text || ""
        var db = dbNameIn.text || ""
        var t = dbTypes[dbTypeIdx]
        if (t === "postgres" || t === "mysql" || t === "mariadb") {
            return t + "://" + (u ? u + (pw ? ":" + pw : "") + "@" : "") + h + (p ? ":" + p : "") + "/" + db
        }
        if (t === "mongodb") return "mongodb://" + (u ? u + (pw ? ":" + pw : "") + "@" : "") + h + (p ? ":" + p : "") + "/" + db
        if (t === "redis") return "redis://" + h + (p ? ":" + p : "")
        if (t === "sqlite") return db || h
        if (t === "mssql") return "Server=" + h + (p ? "," + p : "") + ";Database=" + db + (u ? ";User=" + u : "") + (pw ? ";Password=" + pw : "")
        return h
    }

    function doTest() {
        testStatus = "testing"
        testMsg = "Testing connection..."
        var cs = buildConnStr()
        var t = dbTypes[dbTypeIdx]
        var ok = databaseService.testConnection(t, cs)
        if (ok) {
            testStatus = "ok"
            testMsg = "Connection successful!"
        } else {
            testStatus = "fail"
            testMsg = databaseService.error || "Connection failed"
        }
    }

    function doSave() {
        var c = {
            name: nameIn.text || "Untitled",
            dbType: dbTypes[dbTypeIdx],
            connectionString: buildConnStr(),
            color: colorPick.selectedColor.toString()
        }
        if (editIdx >= 0) connectionManager.update(editIdx, c)
        else connectionManager.add(c)
        dlg.close()
    }

    function reset() {
        nameIn.text = ""
        hostIn.text = ""
        portIn.text = ""
        userIn.text = ""
        passIn.text = ""
        dbNameIn.text = ""
        connStrIn.text = ""
        dbTypeIdx = 0
        modeIdx = 0
        testStatus = ""
        testMsg = ""
    }

    onOpened: {
        if (editIdx >= 0) {
            var c = connectionManager.get(editIdx)
            nameIn.text = c.name || ""
            connStrIn.text = c.connectionString || ""
            var idx = dbTypes.indexOf(c.dbType || "postgres")
            dbTypeIdx = idx >= 0 ? idx : 0
            modeIdx = 1
        } else {
            reset()
        }
    }
}
