// MongoPipelineBuilder.qml — Visual MongoDB Aggregation Pipeline Builder
// Inspired by MongoDB Compass Aggregation Builder
// Each stage is a card with a JSON editor + stage-specific quick templates

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    color: Theme.bg

    property var resultModel: null
    property string collectionName: ""
    property bool isRunning: false

    signal toast(string message, string type)
    signal runPipeline(string pipeline)

    // Defined stages in order
    property var stages: []

    // Stage definitions
    readonly property var stageTypes: [
        { label: "$match",   icon: Icons.filter,     color: "#3b82f6", hint: "Filter documents", template: '{\n  "field": "value"\n}' },
        { label: "$project", icon: Icons.columns,    color: "#8b5cf6", hint: "Include/exclude fields", template: '{\n  "field": 1,\n  "_id": 0\n}' },
        { label: "$group",   icon: Icons.grid,       color: "#10b981", hint: "Group by field", template: '{\n  "_id": "$field",\n  "count": { "$sum": 1 }\n}' },
        { label: "$sort",    icon: Icons.sort,       color: "#f59e0b", hint: "Sort documents", template: '{\n  "field": 1\n}' },
        { label: "$limit",   icon: Icons.key,        color: "#ef4444", hint: "Limit results", template: "100" },
        { label: "$skip",    icon: Icons.right,      color: "#6b7280", hint: "Skip N documents", template: "0" },
        { label: "$unwind",  icon: Icons.lightning,  color: "#ec4899", hint: "Deconstruct array field", template: '"$arrayField"' },
        { label: "$lookup",  icon: Icons.table,      color: "#14b8a6", hint: "Left outer join", template: '{\n  "from": "otherCollection",\n  "localField": "field",\n  "foreignField": "otherField",\n  "as": "joined"\n}' }
    ]

    function addStage(stageLabel) {
        var tmpl = ""
        for (var i = 0; i < stageTypes.length; i++) {
            if (stageTypes[i].label === stageLabel) { tmpl = stageTypes[i].template; break }
        }
        var arr = stages.slice()
        arr.push({ stage: stageLabel, body: tmpl, enabled: true })
        stages = arr
    }

    function removeStage(idx) {
        var arr = stages.slice()
        arr.splice(idx, 1)
        stages = arr
    }

    function buildPipeline() {
        var parts = []
        for (var i = 0; i < stages.length; i++) {
            var s = stages[i]
            if (!s.enabled) continue
            try {
                var parsed = JSON.parse(s.body)
                var obj = {}
                obj[s.stage] = parsed
                parts.push(JSON.stringify(obj))
            } catch(e) {
                root.toast("Stage " + (i + 1) + " has invalid JSON: " + s.stage, "destructive")
                return null
            }
        }
        return "[" + parts.join(",\n") + "]"
    }

    TextEdit { id: _clip; visible: false }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Toolbar ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 44; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                // Stage picker
                Rectangle {
                    width: 24; height: 24; color: "transparent"
                    FlatIcon { anchors.centerIn: parent; icon: Icons.database; size: 14; color: Theme.warning }
                }
                Text {
                    text: collectionName ? ("db." + collectionName + ".aggregate") : "Aggregation Pipeline"
                    font.family: Theme.mono; font.pixelSize: Theme.t13; font.weight: Font.DemiBold; color: Theme.fg
                }

                // Stage count
                Rectangle {
                    visible: stages.length > 0
                    width: stageCntLbl.implicitWidth + Theme.s8; height: 18; radius: Theme.rFull
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                    Text { id: stageCntLbl; anchors.centerIn: parent; text: stages.length + " stage" + (stages.length !== 1 ? "s" : ""); font.pixelSize: Theme.t11; font.family: Theme.sans; color: Theme.accent }
                }

                Item { Layout.fillWidth: true }

                // Add Stage dropdown
                Row {
                    spacing: Theme.s4

                    Repeater {
                        model: stageTypes
                        Rectangle {
                            height: 26; width: addStageLbl.implicitWidth + Theme.s12; radius: Theme.r4
                            color: addStageMa.containsMouse ? Qt.rgba(stageColor.r, stageColor.g, stageColor.b, 0.2) : Qt.rgba(stageColor.r, stageColor.g, stageColor.b, 0.08)
                            border.width: 1; border.color: Qt.rgba(stageColor.r, stageColor.g, stageColor.b, 0.3)
                            property color stageColor: modelData.color
                            Behavior on color { ColorAnimation { duration: Theme.fast } }

                            Text {
                                id: addStageLbl; anchors.centerIn: parent
                                text: modelData.label; font.family: Theme.mono; font.pixelSize: 10; color: addStageMa.containsMouse ? stageColor : Qt.rgba(stageColor.r, stageColor.g, stageColor.b, 0.8)
                                font.weight: Font.Bold
                            }
                            MouseArea { id: addStageMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.addStage(modelData.label) }
                            FlatTooltip { visible: addStageMa.containsMouse; text: modelData.hint; y: 30 }
                        }
                    }
                }

                // Copy pipeline as JS
                Rectangle {
                    width: 26; height: 26; radius: Theme.r4; color: cpMa.containsMouse ? Theme.bgHover : "transparent"
                    visible: stages.length > 0
                    FlatTooltip { visible: cpMa.containsMouse; text: "Copy as JS"; y: 30 }
                    FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 12; color: Theme.fgMuted }
                    MouseArea { id: cpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var pipeline = root.buildPipeline()
                            if (pipeline) {
                                var col = collectionName || "collection"
                                _clip.text = "db." + col + ".aggregate(" + pipeline + ")"
                                _clip.selectAll(); _clip.copy()
                                root.toast("Pipeline copied!", "success")
                            }
                        }
                    }
                }

                // Clear all
                Rectangle {
                    width: 26; height: 26; radius: Theme.r4; color: clrMa.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1) : "transparent"
                    visible: stages.length > 0
                    FlatTooltip { visible: clrMa.containsMouse; text: "Clear pipeline"; y: 30 }
                    FlatIcon { anchors.centerIn: parent; icon: Icons.trash; size: 12; color: clrMa.containsMouse ? Theme.error : Theme.fgMuted }
                    MouseArea { id: clrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: stages = [] }
                }

                // Run button
                Rectangle {
                    width: runRow.implicitWidth + Theme.s16; height: 28; radius: Theme.r6
                    color: stages.length > 0 ? (runMa.containsMouse ? Theme.accentHover : Theme.accent) : Theme.bgSurface
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    RowLayout { id: runRow; anchors.centerIn: parent; spacing: Theme.s4
                        FlatIcon { icon: Icons.play; size: 11; color: stages.length > 0 ? "#fff" : Theme.fgDim }
                        Text { text: "Run"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.DemiBold; color: stages.length > 0 ? "#fff" : Theme.fgDim }
                    }
                    MouseArea {
                        id: runMa; anchors.fill: parent
                        enabled: stages.length > 0; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            var pipeline = root.buildPipeline()
                            if (pipeline) {
                                var col = collectionName || "collection"
                                var cmd = "db." + col + ".aggregate(" + pipeline + ")"
                                root.runPipeline(cmd)
                            }
                        }
                    }
                }
            }

            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ── Main area: stages OR empty ──────────────────────────
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

            // Stage list
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                contentWidth: stageRow.implicitWidth + Theme.s32
                contentHeight: height; clip: true
                boundsBehavior: Flickable.StopAtBounds

                visible: stages.length > 0

                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitHeight: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }

                Row {
                    id: stageRow
                    x: Theme.s16; y: Theme.s16
                    spacing: Theme.s16

                    Repeater {
                        model: stages

                        Rectangle {
                            id: stageCard
                            required property var modelData
                            required property int index
                            property int stageIdx: index
                            property color stageColor: getStageColor(modelData.stage)

                            width: 280; height: 460; radius: Theme.r8
                            color: Theme.bgElevated
                            border.width: 2; border.color: Qt.rgba(stageColor.r, stageColor.g, stageColor.b, 0.4)

                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: Theme.s8

                                // Card header
                                RowLayout {
                                    Layout.fillWidth: true; spacing: Theme.s8

                                    // Stage number
                                    Rectangle {
                                        width: 24; height: 24; radius: Theme.rFull
                                        color: Qt.rgba(stageCard.stageColor.r, stageCard.stageColor.g, stageCard.stageColor.b, 0.2)
                                        Text { anchors.centerIn: parent; text: (stageCard.stageIdx + 1).toString(); font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono; color: stageCard.stageColor }
                                    }

                                    // Stage name
                                    Text {
                                        text: modelData.stage; font.family: Theme.mono; font.pixelSize: Theme.t13; font.weight: Font.Bold
                                        color: stageCard.stageColor; Layout.fillWidth: true
                                    }

                                    // Enable/disable toggle
                                    Rectangle {
                                        width: 30; height: 16; radius: Theme.rFull
                                        color: modelData.enabled ? Qt.rgba(stageCard.stageColor.r, stageCard.stageColor.g, stageCard.stageColor.b, 0.3) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var arr = stages.slice()
                                                arr[stageCard.stageIdx] = { stage: arr[stageCard.stageIdx].stage, body: arr[stageCard.stageIdx].body, enabled: !arr[stageCard.stageIdx].enabled }
                                                stages = arr
                                            }
                                        }
                                        Rectangle {
                                            width: 12; height: 12; radius: Theme.rFull; anchors.verticalCenter: parent.verticalCenter
                                            color: "#fff"
                                            x: modelData.enabled ? parent.width - width - 2 : 2
                                            Behavior on x { NumberAnimation { duration: Theme.fast } }
                                        }
                                    }

                                    // Remove stage
                                    Rectangle {
                                        width: 22; height: 22; radius: Theme.r4
                                        color: rmMa.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1) : "transparent"
                                        FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 10; color: rmMa.containsMouse ? Theme.error : Theme.fgMuted }
                                        MouseArea { id: rmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.removeStage(stageCard.stageIdx) }
                                    }
                                }

                                // Operator hint
                                Text {
                                    text: getStageHint(modelData.stage)
                                    font.family: Theme.sans; font.pixelSize: Theme.t11; color: Theme.fgMuted
                                    Layout.fillWidth: true
                                }

                                // JSON body editor
                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    radius: Theme.r6; color: Theme.bgSurface
                                    border.width: 1; border.color: stageEditFocus.activeFocus ? Qt.rgba(stageCard.stageColor.r, stageCard.stageColor.g, stageCard.stageColor.b, 0.6) : Theme.border
                                    Behavior on border.color { ColorAnimation { duration: Theme.fast } }
                                    clip: true

                                    Flickable {
                                        anchors.fill: parent; anchors.margins: 1
                                        contentWidth: width; contentHeight: stageEditFocus.implicitHeight + 24
                                        clip: true; boundsBehavior: Flickable.StopAtBounds

                                        TextEdit {
                                            id: stageEditFocus
                                            width: parent.width
                                            topPadding: Theme.s8; leftPadding: Theme.s8; rightPadding: Theme.s8; bottomPadding: Theme.s8
                                            font.family: Theme.mono; font.pixelSize: Theme.t12; color: Theme.fg
                                            wrapMode: TextEdit.Wrap; selectByMouse: true
                                            text: modelData.body || ""
                                            onTextChanged: {
                                                if (stageCard.stageIdx < stages.length) {
                                                    var arr = stages.slice()
                                                    arr[stageCard.stageIdx] = { stage: arr[stageCard.stageIdx].stage, body: text, enabled: arr[stageCard.stageIdx].enabled }
                                                    stages = arr
                                                }
                                            }
                                        }
                                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }
                                    }
                                }

                                // JSON validation indicator
                                RowLayout {
                                    spacing: Theme.s4
                                    property bool valid: {
                                        try { JSON.parse(modelData.body || ""); return true } catch(e) { return false }
                                    }
                                    Rectangle {
                                        width: 6; height: 6; radius: Theme.rFull
                                        color: parent.valid ? Theme.success : Theme.error
                                    }
                                    Text {
                                        text: parent.valid ? "Valid JSON" : "Invalid JSON"
                                        font.family: Theme.sans; font.pixelSize: Theme.t11
                                        color: parent.valid ? Theme.success : Theme.error
                                    }
                                }
                            }

                            // Disabled overlay
                            Rectangle {
                                anchors.fill: parent; radius: Theme.r8
                                color: Qt.rgba(0, 0, 0, 0.4)
                                visible: !modelData.enabled
                                Text {
                                    anchors.centerIn: parent; text: "DISABLED"
                                    font.family: Theme.sans; font.pixelSize: Theme.t13; font.weight: Font.Bold
                                    color: "white"; opacity: 0.6; rotation: -20
                                }
                            }

                            // Arrow between stages (except last)
                            FlatIcon {
                                anchors.right: parent.right; anchors.rightMargin: -(Theme.s16 / 2) - 6
                                anchors.verticalCenter: parent.verticalCenter
                                icon: Icons.right; size: 12; color: stageCard.stageColor; opacity: 0.6
                                visible: stageCard.stageIdx < stages.length - 1
                            }
                        }
                    }
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: stages.length === 0

                ColumnLayout {
                    anchors.centerIn: parent; spacing: Theme.s16

                    FlatIcon { Layout.alignment: Qt.AlignHCenter; icon: Icons.filter; size: 40; color: Theme.fgMuted; opacity: 0.3 }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Build an Aggregation Pipeline"
                        font.family: Theme.sans; font.pixelSize: Theme.t16; font.weight: Font.DemiBold; color: Theme.fg
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Click a stage button above to add your first stage"
                        font.family: Theme.sans; font.pixelSize: Theme.t13; color: Theme.fgMuted
                    }

                    // Quick start buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter; spacing: Theme.s8
                        FlatButton { text: "+ $match"; variant: "outline"; size: "sm"; onClicked: root.addStage("$match") }
                        FlatButton { text: "+ $group"; variant: "outline"; size: "sm"; onClicked: root.addStage("$group") }
                        FlatButton { text: "+ $sort";  variant: "outline"; size: "sm"; onClicked: root.addStage("$sort") }
                    }
                }
            }
        }
    }

    function getStageColor(stage) {
        for (var i = 0; i < stageTypes.length; i++) {
            if (stageTypes[i].label === stage) return stageTypes[i].color
        }
        return "#6b7280"
    }

    function getStageHint(stage) {
        for (var i = 0; i < stageTypes.length; i++) {
            if (stageTypes[i].label === stage) return stageTypes[i].hint
        }
        return ""
    }
}
