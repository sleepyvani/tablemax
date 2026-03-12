import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    color: Theme.bg

    // ── Sync syntax highlighter with editor document ──
    Connections {
        target: editor
        function onTextDocumentChanged() {
            if (syntaxHighlighter && editor.textDocument)
                syntaxHighlighter.document = editor.textDocument
        }
    }

    // ── Load content when switching tabs ──
    Connections {
        target: tabManager
        function onCurrentIndexChanged() {
            if (!tabManager) return
            var t = tabManager.getTab(tabManager.currentIndex)
            if (t) {
                loadingContent_ = true
                editor.text = t.content || ""
                loadingContent_ = false
            }
        }
    }

    property bool loadingContent_: false

    function executeCurrentQuery() {
        if (!tabManager || !databaseService || !databaseService.connected) return
        var t = tabManager.getTab(tabManager.currentIndex)
        var query = (t.content || "").trim()
        if (!query) return

        var res = databaseService.executeQuery(query, resultModel)
        if (res.success) {
            root.toast(res.rowCount + " rows returned (" + res.execTime.toFixed(1) + " ms)", "success")
        } else {
            root.toast("Error: " + res.error, "destructive")
        }
    }

    function formatSql() {
        if (!editor.text.trim()) return
        var sql = editor.text

        // Uppercase SQL keywords
        var keywords = [
            "SELECT","FROM","WHERE","INSERT","INTO","UPDATE","SET","DELETE","DROP",
            "CREATE","ALTER","TABLE","JOIN","INNER","LEFT","RIGHT","OUTER","CROSS",
            "ON","AND","OR","NOT","IN","EXISTS","BETWEEN","LIKE","IS","NULL","AS",
            "DISTINCT","ORDER","BY","GROUP","HAVING","LIMIT","OFFSET","UNION",
            "INTERSECT","EXCEPT","CASE","WHEN","THEN","ELSE","END","VALUES",
            "PRIMARY","KEY","FOREIGN","REFERENCES","CONSTRAINT","UNIQUE","CHECK",
            "ASC","DESC","WITH","RECURSIVE","BEGIN","COMMIT","ROLLBACK","FULL"
        ]

        for (var i = 0; i < keywords.length; i++) {
            var re = new RegExp("\\b" + keywords[i] + "\\b", "gi")
            sql = sql.replace(re, keywords[i])
        }

        // Add newlines before major clauses
        var clauses = ["SELECT","FROM","WHERE","JOIN","INNER JOIN","LEFT JOIN","RIGHT JOIN",
                       "ORDER BY","GROUP BY","HAVING","LIMIT","UNION","INSERT INTO","UPDATE",
                       "SET","DELETE FROM","VALUES"]
        for (var j = 0; j < clauses.length; j++) {
            var cre = new RegExp("\\s+" + clauses[j].replace(/ /g, "\\s+") + "\\b", "gi")
            sql = sql.replace(cre, "\n" + clauses[j])
        }

        editor.text = sql.trim()
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ─── Toolbar ───
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 38; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s6

                // Run
                Rectangle {
                    width: runContent.implicitWidth + 20; height: 26; radius: Theme.r6
                    color: runMa.containsMouse ? Theme.accentHover : Theme.accent
                    opacity: databaseService && databaseService.connected ? 1.0 : 0.4
                    scale: runMa.pressed ? 0.96 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.fast } }
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    RowLayout {
                        id: runContent; anchors.centerIn: parent; spacing: Theme.s4
                        Text { text: "▶"; font.pixelSize: 9; color: "#fff" }
                        Text { text: "Run"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.DemiBold; color: "#fff" }
                    }
                    MouseArea {
                        id: runMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: executeCurrentQuery()
                    }
                }

                // Shortcut hint
                Rectangle {
                    height: 18; width: kbdText.implicitWidth + 10; radius: Theme.r4; color: Theme.bgSurface; border.width: 1; border.color: Theme.border
                    Text { id: kbdText; anchors.centerIn: parent; text: "Ctrl+Enter"; font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim }
                }

                Item { Layout.fillWidth: true }

                // Format
                Rectangle {
                    width: 26; height: 26; radius: Theme.r6; color: fmtMa.containsMouse ? Theme.bgHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Text { anchors.centerIn: parent; text: "{}"; font.family: Theme.mono; font.pixelSize: Theme.t11; color: Theme.fgMuted }
                    MouseArea {
                        id: fmtMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: formatSql()
                    }
                    FlatTooltip { visible: fmtMa.containsMouse; text: "Format SQL"; y: -30 }
                }

                // Clear
                Rectangle {
                    width: 26; height: 26; radius: Theme.r6; color: clrMa.containsMouse ? Theme.bgHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Text { anchors.centerIn: parent; text: "⌫"; font.pixelSize: 13; color: Theme.fgMuted }
                    MouseArea {
                        id: clrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: editor.text = ""
                    }
                    FlatTooltip { visible: clrMa.containsMouse; text: "Clear editor"; y: -30 }
                }
            }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ─── Editor Area ───
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

            // Line numbers
            Rectangle {
                Layout.fillHeight: true; Layout.preferredWidth: 48; color: Theme.bgElevated

                Flickable {
                    anchors.fill: parent
                    contentY: editorFlick.contentY
                    clip: true; interactive: false

                    Column {
                        anchors.fill: parent; anchors.topMargin: Theme.s8

                        Repeater {
                            model: Math.max(1, editor.text.split("\n").length)
                            delegate: Item {
                                width: 48; height: lineHeight
                                Text {
                                    anchors.right: parent.right; anchors.rightMargin: Theme.s12; anchors.verticalCenter: parent.verticalCenter
                                    text: index + 1; font.family: Theme.mono; font.pixelSize: Theme.t11; color: Theme.fgDim
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillHeight: true; width: 1; color: Theme.border; opacity: 0.5 }

            // Editor
            Flickable {
                id: editorFlick; Layout.fillWidth: true; Layout.fillHeight: true
                contentWidth: width; contentHeight: editor.implicitHeight + Theme.s16
                clip: true; boundsBehavior: Flickable.StopAtBounds

                TextEdit {
                    id: editor; width: parent.width
                    topPadding: Theme.s8; leftPadding: Theme.s12; rightPadding: Theme.s12; bottomPadding: Theme.s12
                    font.family: Theme.mono; font.pixelSize: Theme.t13; color: Theme.fg
                    selectionColor: Theme.accentDim; selectedTextColor: Theme.fg
                    wrapMode: TextEdit.NoWrap; selectByMouse: true; focus: true
                    textFormat: TextEdit.PlainText

                    onTextChanged: {
                        if (!loadingContent_ && tabManager)
                            tabManager.updateContent(tabManager.currentIndex, text)
                    }

                    // Placeholder
                    Text {
                        x: Theme.s12; y: Theme.s8
                        text: "SELECT * FROM table_name\nWHERE id = 1;"
                        font: parent.font; color: Theme.fgDim; opacity: 0.35
                        visible: !parent.text && !parent.activeFocus
                    }

                    cursorDelegate: Rectangle {
                        width: 2; color: Theme.accent; visible: parent.activeFocus
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 500 }
                            NumberAnimation { to: 1; duration: 400 }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
                }
            }
        }

        // ─── Loading overlay ───
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: databaseService && databaseService.loading ? 3 : 0
            color: "transparent"; clip: true

            Rectangle {
                id: loadingBar
                width: parent.width * 0.3
                height: 3; radius: 2
                color: Theme.accent
                visible: databaseService && databaseService.loading

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: databaseService && databaseService.loading
                    NumberAnimation { from: -loadingBar.width; to: loadingBar.parent.width; duration: 1200; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    property real lineHeight: 20

    Keys.onPressed: (e) => { if (e.key === Qt.Key_Return && (e.modifiers & Qt.ControlModifier)) { executeCurrentQuery(); e.accepted = true } }

    Component.onCompleted: {
        if (syntaxHighlighter && editor.textDocument)
            syntaxHighlighter.document = editor.textDocument
    }
}
