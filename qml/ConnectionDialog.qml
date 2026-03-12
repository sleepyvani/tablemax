import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts
import "ConnHelper.js" as Conn

T.Dialog {
    id: dlg

    property int editIdx: -1
    property int modeIdx: 0
    property string testStatus: ""
    property string testMsg: ""
    property int dbTypeIdx: 0
    property var dbTypes: ["postgres", "mysql", "sqlite", "mongodb", "redis", "mssql", "mariadb"]
    property string selectedColor: "#6366f1"

    anchors.centerIn: parent
    modal: true
    dim: true
    implicitWidth: 520
    padding: 0

    // ── Animations ──
    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100; easing.type: Easing.InCubic }
        }
    }

    background: Rectangle {
        color: Theme.background
        border.width: 1
        border.color: Theme.border
        radius: 12
    }

    T.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.5)
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    Connections {
        target: dlg
        function onOpened() { dlg.initForm() }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        //  HEADER
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 24
            Layout.bottomMargin: 20
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 4

            Text {
                text: dlg.editIdx >= 0 ? "Edit Connection" : "New Connection"
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: Theme.foreground
            }
            Text {
                text: "Choose a database type and enter credentials"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.mutedForeground
            }
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        //  DATABASE TYPE — horizontal pill strip
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            contentWidth: dbRow.width
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: dbRow
                spacing: 6

                Repeater {
                    model: [
                        { label: "PostgreSQL", icon: "qrc:/TableMax/icons/postgres.svg" },
                        { label: "MySQL",      icon: "qrc:/TableMax/icons/mysql.svg" },
                        { label: "SQLite",     icon: "qrc:/TableMax/icons/sqlite.svg" },
                        { label: "MongoDB",    icon: "qrc:/TableMax/icons/mongodb.svg" },
                        { label: "Redis",      icon: "qrc:/TableMax/icons/redis.svg" },
                        { label: "MSSQL",      icon: "qrc:/TableMax/icons/mssql.svg" },
                        { label: "MariaDB",    icon: "qrc:/TableMax/icons/mariadb.svg" }
                    ]

                    Rectangle {
                        width: pillRow.implicitWidth + 24
                        height: 32
                        radius: 8

                        property bool sel: dlg.dbTypeIdx === index

                        color: sel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                                   : pillMa.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04) : "transparent"
                        border.width: 1
                        border.color: sel ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
                                          : pillMa.containsMouse ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08) : Theme.border

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Row {
                            id: pillRow
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16; height: 16
                                source: modelData.icon
                                sourceSize: Qt.size(32, 32)
                                smooth: true; mipmap: true
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: sel ? Font.DemiBold : Font.Normal
                                color: sel ? Theme.foreground : Theme.mutedForeground
                            }
                        }

                        MouseArea {
                            id: pillMa
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

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        //  CONNECTION NAME
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 6

            Text {
                text: "Name"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Theme.mutedForeground
            }
            FlatInput {
                id: nameIn
                placeholderText: "e.g. Production DB"
                Layout.fillWidth: true
            }
        }

        Item { Layout.preferredHeight: 16 }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        //  MODE TOGGLE
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        FlatToggleGroup {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            model: ["Form", "Connection String"]
            currentIndex: dlg.modeIdx
            onToggled: function(idx) { dlg.modeIdx = idx }
        }

        Item { Layout.preferredHeight: 16 }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        //  FORM MODE — grouped in a subtle card
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            implicitHeight: formContent.implicitHeight + 32
            radius: 10
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02)
            border.width: 1
            border.color: Theme.border
            visible: dlg.modeIdx === 0

            ColumnLayout {
                id: formContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 14

                // ── SQLite: File Path ──
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 5
                    visible: dlg.dbTypes[dlg.dbTypeIdx] === "sqlite"

                    Text { text: "Database File"; font.family: Theme.fontFamily; font.pixelSize: 12; color: Theme.mutedForeground }
                    FlatInput { id: sqliteFileIn; placeholderText: "C:\\path\\to\\database.db"; Layout.fillWidth: true }
                    Text { text: "Enter the full path to your SQLite database file"; font.family: Theme.sans; font.pixelSize: 10; color: Theme.fgDim }
                }

                // ── Host + Port (all except SQLite) ──
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    visible: dlg.dbTypes[dlg.dbTypeIdx] !== "sqlite"

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 5
                        Text { text: "Host"; font.family: Theme.fontFamily; font.pixelSize: 12; color: Theme.mutedForeground }
                        FlatInput { id: hostIn; placeholderText: "localhost"; Layout.fillWidth: true }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 90; Layout.maximumWidth: 90; spacing: 5
                        Text { text: "Port"; font.family: Theme.fontFamily; font.pixelSize: 12; color: Theme.mutedForeground }
                        FlatInput {
                            id: portIn
                            placeholderText: Conn.defaultPort(dlg.dbTypes[dlg.dbTypeIdx])
                            Layout.fillWidth: true
                        }
                    }
                }

                // ── Username + Password (not SQLite, not Redis) ──
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    visible: dlg.dbTypes[dlg.dbTypeIdx] !== "sqlite" && dlg.dbTypes[dlg.dbTypeIdx] !== "redis"

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 5
                        Text { text: "Username"; font.family: Theme.fontFamily; font.pixelSize: 12; color: Theme.mutedForeground }
                        FlatInput {
                            id: userIn
                            placeholderText: Conn.defaultUser(dlg.dbTypes[dlg.dbTypeIdx])
                            Layout.fillWidth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 5
                        Text { text: "Password"; font.family: Theme.fontFamily; font.pixelSize: 12; color: Theme.mutedForeground }
                        FlatInput { id: passIn; placeholderText: "••••••••"; echoMode: TextInput.Password; Layout.fillWidth: true }
                    }
                }

                // ── Redis: Password only ──
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 5
                    visible: dlg.dbTypes[dlg.dbTypeIdx] === "redis"

                    Text { text: "Password (optional)"; font.family: Theme.fontFamily; font.pixelSize: 12; color: Theme.mutedForeground }
                    FlatInput { id: redisPassIn; placeholderText: "Leave empty if no auth"; echoMode: TextInput.Password; Layout.fillWidth: true }
                }

                // ── Database name (not SQLite, not Redis) ──
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 5
                    visible: dlg.dbTypes[dlg.dbTypeIdx] !== "sqlite" && dlg.dbTypes[dlg.dbTypeIdx] !== "redis"

                    Text { text: "Database"; font.family: Theme.fontFamily; font.pixelSize: 12; color: Theme.mutedForeground }
                    FlatInput {
                        id: dbNameIn
                        placeholderText: Conn.defaultDatabase(dlg.dbTypes[dlg.dbTypeIdx])
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        //  CONNECTION STRING MODE
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            implicitHeight: connStrContent.implicitHeight + 32
            radius: 10
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.02)
            border.width: 1
            border.color: Theme.border
            visible: dlg.modeIdx === 1

            ColumnLayout {
                id: connStrContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 6

                Text {
                    text: "Connection String"
                    font.family: Theme.fontFamily; font.pixelSize: 12
                    color: Theme.mutedForeground
                }
                FlatInput {
                    id: connStrIn
                    placeholderText: Conn.connStrPlaceholder(dlg.dbTypes[dlg.dbTypeIdx])
                    Layout.fillWidth: true
                }
                Text {
                    text: Conn.connStrPlaceholder(dlg.dbTypes[dlg.dbTypeIdx])
                    font.family: Theme.fontFamily; font.pixelSize: 11
                    color: Theme.mutedForeground; opacity: 0.5
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.preferredHeight: 14 }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        //  COLOR — compact dot row
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 8

            Text {
                text: "Color"
                font.family: Theme.fontFamily; font.pixelSize: 12
                color: Theme.mutedForeground
            }

            Item { Layout.preferredWidth: 8 }

            Repeater {
                model: ["#6366f1","#8b5cf6","#ec4899","#ef4444","#f97316","#eab308","#22c55e","#06b6d4","#3b82f6","#64748b"]

                Rectangle {
                    width: 18; height: 18; radius: 9
                    color: modelData
                    border.width: dlg.selectedColor === modelData ? 2 : 0
                    border.color: Theme.fg
                    opacity: dlg.selectedColor === modelData ? 1.0 : 0.6
                    scale: colorDotMa.containsMouse ? 1.15 : 1.0

                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    MouseArea {
                        id: colorDotMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dlg.selectedColor = modelData
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        Item { Layout.preferredHeight: 10 }

        // ── Test Status ──
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.preferredHeight: dlg.testStatus !== "" ? 34 : 0
            radius: 8
            visible: dlg.testStatus !== ""
            clip: true

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            color: dlg.testStatus === "ok" ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.08)
                 : dlg.testStatus === "fail" ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.08)
                 : Qt.rgba(Theme.fgMuted.r, Theme.fgMuted.g, Theme.fgMuted.b, 0.05)
            border.width: 1
            border.color: dlg.testStatus === "ok" ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.2)
                        : dlg.testStatus === "fail" ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2)
                        : Theme.border

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 6

                Text {
                    text: dlg.testStatus === "ok" ? "✓" : dlg.testStatus === "fail" ? "✗" : "⟳"
                    font.pixelSize: 13; font.weight: Font.Bold
                    color: dlg.testStatus === "ok" ? Theme.success : dlg.testStatus === "fail" ? Theme.error : Theme.fgMuted
                }
                Text {
                    text: dlg.testMsg
                    font.family: Theme.fontFamily; font.pixelSize: 12
                    color: dlg.testStatus === "ok" ? Theme.success : dlg.testStatus === "fail" ? Theme.error : Theme.fgMuted
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
            }
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        //  FOOTER
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Item { Layout.preferredHeight: 12 }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            spacing: 8

            FlatButton {
                text: "Test Connection"
                variant: "outline"
                size: "sm"
                onClicked: dlg.runTest()
            }

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Cancel"
                variant: "ghost"
                size: "sm"
                onClicked: dlg.close()
            }

            FlatButton {
                text: dlg.editIdx >= 0 ? "Save Changes" : "Connect"
                size: "sm"
                onClicked: dlg.saveConn()
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  LOGIC
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    function buildConnStr(): string {
        if (dlg.modeIdx === 1) return connStrIn.text
        var t = dlg.dbTypes[dlg.dbTypeIdx]
        if (t === "sqlite") return sqliteFileIn.text
        return Conn.buildConnStr(t, hostIn.text, portIn.text, userIn.text, passIn.text, dbNameIn.text, redisPassIn.text)
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
            color: dlg.selectedColor
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
        sqliteFileIn.text = ""
        redisPassIn.text = ""
        dlg.dbTypeIdx = 0
        dlg.modeIdx = 0
        dlg.testStatus = ""
        dlg.testMsg = ""
        dlg.selectedColor = "#6366f1"
    }

    function initForm(): void {
        if (dlg.editIdx >= 0) {
            var c = connectionManager.get(dlg.editIdx)
            nameIn.text = c.name || ""
            connStrIn.text = c.connectionString || ""
            var idx = dlg.dbTypes.indexOf(c.dbType || "postgres")
            dlg.dbTypeIdx = idx >= 0 ? idx : 0
            dlg.modeIdx = 1
            dlg.selectedColor = c.color || "#6366f1"
        } else {
            dlg.clearForm()
        }
    }
}
