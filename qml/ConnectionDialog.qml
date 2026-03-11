import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

T.Dialog {
    id: dlg

    property int editIdx: -1
    property int modeIdx: 0
    property string testStatus: ""
    property string testMsg: ""
    property int dbTypeIdx: 0
    property var dbTypes: ["postgres", "mysql", "sqlite", "mongodb", "redis", "mssql", "mariadb"]

    anchors.centerIn: parent
    modal: true; dim: true
    implicitWidth: 500
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

    // Use Connections to avoid "duplicate method" error on onOpened
    Connections {
        target: dlg
        function onOpened() { dlg.initForm() }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ─── Header ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 24
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 4

            Text {
                text: dlg.editIdx >= 0 ? "Edit Connection" : "New Connection"
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
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 8

            Text {
                text: "Database"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                color: Theme.foreground
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                    model: [
                        { key: "postgres", label: "PostgreSQL", icon: "qrc:/TableMax/icons/postgres.svg" },
                        { key: "mysql",    label: "MySQL",      icon: "qrc:/TableMax/icons/mysql.svg" },
                        { key: "sqlite",   label: "SQLite",     icon: "qrc:/TableMax/icons/sqlite.svg" },
                        { key: "mongodb",  label: "MongoDB",    icon: "qrc:/TableMax/icons/mongodb.svg" },
                        { key: "redis",    label: "Redis",      icon: "qrc:/TableMax/icons/redis.svg" },
                        { key: "mssql",    label: "MSSQL",      icon: "qrc:/TableMax/icons/mssql.svg" },
                        { key: "mariadb",  label: "MariaDB",    icon: "qrc:/TableMax/icons/mariadb.svg" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: Theme.radius

                        property bool sel: dlg.dbTypeIdx === index

                        color: sel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                                   : cardMa.containsMouse ? Theme.muted : "transparent"
                        border.width: 1
                        border.color: sel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Theme.border

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                source: modelData.icon
                                sourceSize: Qt.size(22, 22)
                                smooth: true
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
                            id: cardMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dlg.dbTypeIdx = index
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 16 }

        // ─── Connection Name ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 6

            Text {
                text: "Connection Name"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                color: Theme.foreground
            }
            FlatInput {
                id: nameIn
                placeholderText: "e.g. Production DB"
                width: parent.width
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ─── Mode Toggle ───
        FlatToggleGroup {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            model: ["Form", "Connection String"]
            currentIndex: dlg.modeIdx
            onToggled: function(idx) { dlg.modeIdx = idx }
        }

        Item { Layout.preferredHeight: 14 }

        // ─── Form Mode ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 12
            visible: dlg.modeIdx === 0

            // Host + Port
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Host"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Medium
                        color: Theme.foreground
                    }
                    FlatInput {
                        id: hostIn
                        placeholderText: "localhost"
                        width: parent.width
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 100
                    spacing: 6

                    Text {
                        text: "Port"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Medium
                        color: Theme.foreground
                    }
                    FlatInput {
                        id: portIn
                        placeholderText: {
                            var ports = ["5432", "3306", "0", "27017", "6379", "1433", "3306"]
                            return ports[dlg.dbTypeIdx] || "5432"
                        }
                        width: parent.width
                    }
                }
            }

            // Username + Password
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Username"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Medium
                        color: Theme.foreground
                    }
                    FlatInput {
                        id: userIn
                        placeholderText: "admin"
                        width: parent.width
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Password"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.Medium
                        color: Theme.foreground
                    }
                    FlatInput {
                        id: passIn
                        placeholderText: "••••••••"
                        echoMode: TextInput.Password
                        width: parent.width
                    }
                }
            }

            // Database
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Database"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Medium
                    color: Theme.foreground
                }
                FlatInput {
                    id: dbNameIn
                    placeholderText: "mydb"
                    width: parent.width
                }
            }
        }

        // ─── Connection String Mode ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 6
            visible: dlg.modeIdx === 1

            Text {
                text: "Connection String"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                color: Theme.foreground
            }
            FlatInput {
                id: connStrIn
                placeholderText: "Enter connection string..."
                width: parent.width
            }
            Text {
                text: {
                    var examples = [
                        "e.g. postgresql://user:pass@localhost:5432/mydb",
                        "e.g. mysql://user:pass@localhost:3306/mydb",
                        "e.g. /path/to/database.db",
                        "e.g. mongodb://user:pass@localhost:27017/mydb",
                        "e.g. redis://localhost:6379",
                        "e.g. Server=localhost;Database=mydb;User=sa;Password=pass",
                        "e.g. mysql://user:pass@localhost:3306/mydb"
                    ]
                    return examples[dlg.dbTypeIdx] || examples[0]
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                color: Theme.mutedForeground
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ─── Color Picker ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 6

            Text {
                text: "Color"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Medium
                color: Theme.foreground
            }
            FlatColorPicker {
                id: colorPick
                width: parent.width
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ─── Test Result Banner ───
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.preferredHeight: dlg.testStatus !== "" ? 36 : 0
            radius: Theme.radius
            visible: dlg.testStatus !== ""
            clip: true

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: Theme.durationSlow; easing.type: Easing.OutCubic }
            }

            color: {
                if (dlg.testStatus === "ok") return Qt.rgba(0.2, 0.83, 0.6, 0.08)
                if (dlg.testStatus === "fail") return Qt.rgba(0.97, 0.44, 0.44, 0.08)
                return Theme.muted
            }
            border.width: 1
            border.color: {
                if (dlg.testStatus === "ok") return Qt.rgba(0.2, 0.83, 0.6, 0.2)
                if (dlg.testStatus === "fail") return Qt.rgba(0.97, 0.44, 0.44, 0.2)
                return Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: {
                        if (dlg.testStatus === "ok") return "✓"
                        if (dlg.testStatus === "fail") return "✗"
                        return "⟳"
                    }
                    font.pixelSize: 13
                    color: {
                        if (dlg.testStatus === "ok") return Theme.success
                        if (dlg.testStatus === "fail") return Theme.error
                        return Theme.mutedForeground
                    }
                }
                Text {
                    text: dlg.testMsg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    color: {
                        if (dlg.testStatus === "ok") return Theme.success
                        if (dlg.testStatus === "fail") return Theme.error
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
            Layout.preferredHeight: 1
            color: Theme.border
        }

        // ─── Footer ───
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            spacing: 8

            FlatButton {
                text: "Test Connection"
                variant: "outline"
                onClicked: dlg.runTest()
            }

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Cancel"
                variant: "ghost"
                onClicked: dlg.close()
            }

            FlatButton {
                text: dlg.editIdx >= 0 ? "Update" : "Save"
                onClicked: dlg.saveConn()
            }
        }
    }

    // ─── Functions (named to avoid base class conflicts) ───

    function buildConnStr(): string {
        if (dlg.modeIdx === 1) return connStrIn.text
        var h = hostIn.text || "localhost"
        var p = portIn.text || ""
        var u = userIn.text || ""
        var pw = passIn.text || ""
        var db = dbNameIn.text || ""
        var t = dlg.dbTypes[dlg.dbTypeIdx]
        if (t === "postgres" || t === "mysql" || t === "mariadb")
            return t + "://" + (u ? u + (pw ? ":" + pw : "") + "@" : "") + h + (p ? ":" + p : "") + "/" + db
        if (t === "mongodb") return "mongodb://" + (u ? u + (pw ? ":" + pw : "") + "@" : "") + h + (p ? ":" + p : "") + "/" + db
        if (t === "redis") return "redis://" + h + (p ? ":" + p : "")
        if (t === "sqlite") return db || h
        if (t === "mssql") return "Server=" + h + (p ? "," + p : "") + ";Database=" + db + (u ? ";User=" + u : "") + (pw ? ";Password=" + pw : "")
        return h
    }

    function runTest(): void {
        dlg.testStatus = "testing"
        dlg.testMsg = "Testing connection..."
        var cs = dlg.buildConnStr()
        var t = dlg.dbTypes[dlg.dbTypeIdx]
        var ok = databaseService.testConnection(t, cs)
        dlg.testStatus = ok ? "ok" : "fail"
        dlg.testMsg = ok ? "Connection successful!" : (databaseService.error || "Connection failed")
    }

    function saveConn(): void {
        var c = {
            name: nameIn.text || "Untitled",
            dbType: dlg.dbTypes[dlg.dbTypeIdx],
            connectionString: dlg.buildConnStr(),
            color: colorPick.selectedColor.toString()
        }
        if (dlg.editIdx >= 0) connectionManager.update(dlg.editIdx, c)
        else connectionManager.add(c)
        dlg.close()
    }

    function clearForm(): void {
        nameIn.text = ""
        hostIn.text = ""
        portIn.text = ""
        userIn.text = ""
        passIn.text = ""
        dbNameIn.text = ""
        connStrIn.text = ""
        dlg.dbTypeIdx = 0
        dlg.modeIdx = 0
        dlg.testStatus = ""
        dlg.testMsg = ""
    }

    function initForm(): void {
        if (dlg.editIdx >= 0) {
            var c = connectionManager.get(dlg.editIdx)
            nameIn.text = c.name || ""
            connStrIn.text = c.connectionString || ""
            var idx = dlg.dbTypes.indexOf(c.dbType || "postgres")
            dlg.dbTypeIdx = idx >= 0 ? idx : 0
            dlg.modeIdx = 1
        } else {
            dlg.clearForm()
        }
    }
}
