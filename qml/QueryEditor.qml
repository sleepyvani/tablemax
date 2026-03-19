import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "DbHelper.js" as DB
import "FormatHelper.js" as Fmt

Rectangle {
    color: Theme.bg

    // Active DB type
    property string _dbType: {
        if (!connectionManager) return ""
        var c = connectionManager.get(connectionManager.activeIndex)
        return c ? (c.dbType || "") : ""
    }

    //  Sync syntax highlighter with editor document 
    Timer {
        interval: 0; running: true; repeat: false
        onTriggered: {
            if (syntaxHighlighter && editor.textDocument)
                syntaxHighlighter.document = editor.textDocument
        }
    }

    //  Load content when switching tabs 
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
            root.toast(Fmt.formatNumber(res.rowCount) + " rows returned (" + Fmt.formatExecTime(res.execTime) + ")", "success")
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

    //  AutoComplete Logic 
    property var sqlKeywords: [
        "SELECT", "FROM", "WHERE", "INSERT", "INTO", "UPDATE", "SET", "DELETE", "JOIN", 
        "INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "ON", "GROUP BY", "ORDER BY", "HAVING", 
        "LIMIT", "OFFSET", "AND", "OR", "NOT", "IN", "EXISTS", "BETWEEN", "LIKE", "IS NULL", "AS",
        "CREATE TABLE", "DROP TABLE", "ALTER TABLE", "ADD COLUMN", "PRIMARY KEY", "FOREIGN KEY", "COUNT", "MAX", "MIN", "AVG", "SUM"
    ]

    function updateAutoComplete() {
        if (!editor.activeFocus || editor.text.length === 0) {
            autoComplete.close();
            return;
        }

        var textBeforeCursor = editor.text.substring(0, editor.cursorPosition);
        var match = textBeforeCursor.match(/([a-zA-Z0-9_]+)$/);
        
        if (!match) {
            autoComplete.close();
            return;
        }

        var word = match[1].toLowerCase();
        if (word.length < 1) {
            autoComplete.close();
            return;
        }

        var results = [];
        
        // 1. Match Keywords
        for (var i = 0; i < sqlKeywords.length; i++) {
            if (sqlKeywords[i].toLowerCase().indexOf(word) === 0) {
                results.push({ text: sqlKeywords[i], type: "keyword" });
            }
        }
        
        // 2. Match Tables and Columns from SchemaService
        if (schemaService && schemaService.tree) {
            var dbTree = schemaService.tree;
            for (var d = 0; d < dbTree.length; d++) {
                var dNode = dbTree[d];
                // if it's a table node directly (sqlite)
                if (dNode.type === "table") {
                    if (dNode.name.toLowerCase().indexOf(word) >= 0) {
                        results.push({ text: dNode.name, type: "table" });
                    }
                    if (dNode.children) {
                        for (var c = 0; c < dNode.children.length; c++) {
                            if (dNode.children[c].name.toLowerCase().indexOf(word) >= 0) {
                                // Add column only if not already in results
                                var exists = false;
                                for (var k=0; k<results.length; k++) { if (results[k].text === dNode.children[c].name && results[k].type==="column") {exists=true; break;}}
                                if (!exists) results.push({ text: dNode.children[c].name, type: "column" });
                            }
                        }
                    }
                } 
                // if it's a db node (pg/mysql)
                else if (dNode.type === "database" && dNode.children) {
                    for (var t = 0; t < dNode.children.length; t++) {
                        var tNode = dNode.children[t];
                        if (tNode.name.toLowerCase().indexOf(word) >= 0) {
                            results.push({ text: tNode.name, type: "table" });
                        }
                        if (tNode.children) {
                            for (var c2 = 0; c2 < tNode.children.length; c2++) {
                                if (tNode.children[c2].name.toLowerCase().indexOf(word) >= 0) {
                                    var exists2 = false;
                                    for (var k2=0; k2<results.length; k2++) { if (results[k2].text === tNode.children[c2].name && results[k2].type==="column") {exists2=true; break;}}
                                    if (!exists2) results.push({ text: tNode.children[c2].name, type: "column" });
                                }
                            }
                        }
                    }
                }
            }
        }

        // Sort results: exact start match first
        results.sort(function(a, b) {
            var aStart = a.text.toLowerCase().indexOf(word) === 0 ? 0 : 1;
            var bStart = b.text.toLowerCase().indexOf(word) === 0 ? 0 : 1;
            if (aStart !== bStart) return aStart - bStart;
            return a.text.length - b.text.length;
        });

        // Limit results
        if (results.length > 20) results = results.slice(0, 20);

        if (results.length > 0) {
            autoComplete.suggestions = results;
            
            // Calculate popup position
            var rect = editor.positionToRectangle(editor.cursorPosition);
            autoComplete.x = rect.x;
            autoComplete.y = rect.y + rect.height;
            autoComplete.open();
        } else {
            autoComplete.close();
        }
    }

    function insertSuggestion(suggestionText) {
        var textBeforeCursor = editor.text.substring(0, editor.cursorPosition);
        var match = textBeforeCursor.match(/([a-zA-Z0-9_]+)$/);
        if (match) {
            var word = match[1];
            var startPos = editor.cursorPosition - word.length;
            
            editor.remove(startPos, editor.cursorPosition);
            editor.insert(startPos, suggestionText + " ");
        }
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        //  Toolbar 
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
                        Text { text: ""; font.pixelSize: Theme.t11; color: "#fff" }
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
                    Text { id: kbdText; anchors.centerIn: parent; text: "Ctrl+Enter"; font.family: Theme.mono; font.pixelSize: Theme.t11; color: Theme.fgDim }
                }

                // Query mode badge
                Rectangle {
                    height: 18; width: _modeText.implicitWidth + 10; radius: Theme.r4
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                    border.width: 1; border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                    visible: databaseService && databaseService.connected
                    Text {
                        id: _modeText; anchors.centerIn: parent
                        text: DB.queryMode(_dbType)
                        font.family: Theme.mono; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.accent
                    }
                }

                Item { Layout.fillWidth: true }

                // Format  SQL only
                Rectangle {
                    width: 26; height: 26; radius: Theme.r6; color: fmtMa.containsMouse ? Theme.bgHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    visible: DB.isSQL(_dbType)

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

                    Text { anchors.centerIn: parent; text: ""; font.pixelSize: Theme.t13; color: Theme.fgMuted }
                    MouseArea {
                        id: clrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: editor.text = ""
                    }
                    FlatTooltip { visible: clrMa.containsMouse; text: "Clear editor"; y: -30 }
                }
            }

            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        //  Editor Area 
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

            DashedLine { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Theme.border; opacity: 0.5 }

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
                        updateAutoComplete()
                    }

                    Keys.onPressed: (e) => {
                        // Priority 1: Ctrl+Enter to execute query
                        if (e.key === Qt.Key_Return && (e.modifiers & Qt.ControlModifier)) {
                            executeCurrentQuery();
                            e.accepted = true;
                            return;
                        }
                        
                        // Priority 2: AutoComplete interaction
                        if (autoComplete.visible) {
                            if (e.key === Qt.Key_Up) {
                                autoComplete.moveUp();
                                e.accepted = true;
                                return;
                            } else if (e.key === Qt.Key_Down) {
                                autoComplete.moveDown();
                                e.accepted = true;
                                return;
                            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Tab || e.key === Qt.Key_Enter) {
                                if (autoComplete.acceptCurrent()) {
                                    e.accepted = true;
                                    return;
                                }
                            } else if (e.key === Qt.Key_Escape) {
                                autoComplete.close();
                                e.accepted = true;
                                return;
                            }
                        }
                    }

                    // Placeholder  DB-aware
                    Text {
                        x: Theme.s12; y: Theme.s8
                        text: DB.queryPlaceholder(_dbType)
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
                    
                    FlatAutoComplete {
                        id: autoComplete
                        onSuggestionAccepted: (txt) => { insertSuggestion(txt); editor.forceActiveFocus() }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
                }
            }
        }

        //  Loading overlay 
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
}
