// TableStructureView.qml — Column type/detail view for SQL tables
// Tabs: Columns | Indexes | Triggers (phpMyAdmin-style)

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons
import "DbHelper.js" as DB

Rectangle {
    id: root
    color: Theme.bg

    property var schemaService: null
    property string tableName: ""
    property string dbType: ""   // passed from Main.qml — used for DB-specific DDL
    property var columns: []   // [{ name, type, nullable, defaultVal, pk, extra }]
    property var indexes: []   // [{ name, type, columns, unique }] — populated externally or from SHOW INDEX
    property var triggers: []  // [{ name, timing, event, statement }]

    signal columnClicked(string colName)
    signal dropColumnRequested(string tName, string cName)
    signal closed()

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Header ──────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 40; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                FlatIcon { icon: Icons.grid; size: 14; color: Theme.accent }
                Text {
                    text: tableName || "Table Structure"
                    font.pixelSize: Theme.t13; font.weight: Font.DemiBold; font.family: Theme.sans
                    color: Theme.fg; Layout.fillWidth: true; elide: Text.ElideRight
                }

                // Column count badge
                Rectangle {
                    height: 18; width: colCountLbl.implicitWidth + Theme.s12; radius: Theme.rFull
                    color: Theme.bgSurface
                    Text { id: colCountLbl; anchors.centerIn: parent; text: columns.length + " cols"; font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgDim }
                }

                Rectangle {
                    width: 24; height: 24; radius: Theme.r4
                    color: structCloseMa.containsMouse ? Theme.bgHover : "transparent"
                    FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 12; color: Theme.fgMuted }
                    MouseArea { id: structCloseMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closed() }
                }
            }
            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ── Tab Bar ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 34; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; spacing: 0

                Repeater {
                    model: [
                        { id: "columns",  label: "Columns",  icon: Icons.grid,      count: columns.length },
                        { id: "indexes",  label: "Indexes",  icon: Icons.lightning,  count: indexes.length },
                        { id: "triggers", label: "Triggers", icon: Icons.clock,      count: triggers.length }
                    ]

                    Rectangle {
                        property bool active: tabBar.currentTab === modelData.id
                        width: tabRow.implicitWidth + Theme.s16; height: 34
                        color: "transparent"

                        RowLayout {
                            id: tabRow; anchors.centerIn: parent; spacing: Theme.s4
                            FlatIcon { icon: modelData.icon; size: 11; color: active ? Theme.accent : Theme.fgMuted }
                            Text {
                                text: modelData.label; font.family: Theme.sans; font.pixelSize: Theme.t12
                                font.weight: active ? Font.DemiBold : Font.Normal
                                color: active ? Theme.accent : Theme.fgMuted
                            }
                            Rectangle {
                                visible: modelData.count > 0
                                width: cntLbl.implicitWidth + Theme.s6; height: 16; radius: Theme.rFull
                                color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
                                Text { id: cntLbl; anchors.centerIn: parent; text: modelData.count; font.pixelSize: 9; color: active ? Theme.accent : Theme.fgDim; font.family: Theme.mono }
                            }
                        }

                        // Active underline
                        Rectangle {
                            anchors.bottom: parent.bottom; width: parent.width; height: 2
                            color: Theme.accent; visible: active; radius: 1
                        }

                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tabBar.currentTab = modelData.id }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

            QtObject { id: tabBar; property string currentTab: "columns" }
        }

        // ══ COLUMNS TAB ═══════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: tabBar.currentTab === "columns"; spacing: 0

            // Column headers
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 28; color: Theme.bgElevated

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0
                    Text { text: "#";       font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 32 }
                    Text { text: "COLUMN";  font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.fillWidth: true; Layout.preferredWidth: 180 }
                    Text { text: "TYPE";    font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 120 }
                    Text { text: "NULL";    font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 48 }
                    Text { text: "DEFAULT"; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 100 }
                    Text { text: "EXTRA";   font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 80 }
                    Text { text: "ACTION";  font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                }
                DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
            }

            // Column rows
            ListView {
                id: colListView
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; model: columns; boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
                }

                delegate: Rectangle {
                    id: colRow
                    required property int index
                    required property var modelData
                    property int colIdx: index

                    width: colListView.width; height: 36
                    color: colRowMa.containsMouse ? Theme.bgHover : colIdx % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0

                        Text { text: (colRow.colIdx + 1).toString(); font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgDim; Layout.preferredWidth: 32 }

                        RowLayout {
                            Layout.fillWidth: true; Layout.preferredWidth: 180; spacing: Theme.s4
                            Rectangle {
                                visible: colRow.modelData.pk === true
                                width: 18; height: 14; radius: Theme.r4
                                color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                                Text { anchors.centerIn: parent; text: "PK"; font.pixelSize: 9; font.weight: Font.Bold; color: Theme.warning; font.family: Theme.mono }
                            }
                            Text {
                                text: colRow.modelData.name || ""
                                font.pixelSize: Theme.t12; font.weight: colRow.modelData.pk ? Font.DemiBold : Font.Normal
                                font.family: Theme.sans; color: Theme.fg; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 120; height: 20; radius: Theme.r4
                            color: Qt.rgba(Theme.info.r, Theme.info.g, Theme.info.b, 0.08); Layout.alignment: Qt.AlignVCenter
                            Text { anchors.centerIn: parent; text: colRow.modelData.type || "unknown"; font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.info; elide: Text.ElideRight }
                        }

                        Text { text: colRow.modelData.nullable ? "YES" : "NO"; font.pixelSize: Theme.t11; font.family: Theme.mono; Layout.preferredWidth: 48; color: colRow.modelData.nullable ? Theme.fgDim : Theme.warning; font.weight: colRow.modelData.nullable ? Font.Normal : Font.Bold }
                        Text { text: colRow.modelData.defaultVal !== undefined && colRow.modelData.defaultVal !== null ? String(colRow.modelData.defaultVal) : "—"; font.pixelSize: Theme.t11; font.family: Theme.mono; Layout.preferredWidth: 100; color: colRow.modelData.defaultVal !== undefined && colRow.modelData.defaultVal !== null ? Theme.fg : Theme.fgDim; elide: Text.ElideRight }
                        Text { text: colRow.modelData.extra || "—"; font.pixelSize: Theme.t11; font.family: Theme.mono; Layout.preferredWidth: 80; color: (colRow.modelData.extra || "") !== "" ? Theme.accent : Theme.fgDim; elide: Text.ElideRight }

                        Rectangle {
                            Layout.preferredWidth: 40; height: 36; color: "transparent"
                            Rectangle {
                                anchors.centerIn: parent; width: 24; height: 24; radius: Theme.r4
                                color: _dropMa.containsMouse ? Theme.error : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                                FlatIcon { anchors.centerIn: parent; icon: Icons.trash; size: 12; color: _dropMa.containsMouse ? "#fff" : Theme.fgMuted }
                                MouseArea {
                                    id: _dropMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.dropColumnRequested(root.tableName, colRow.modelData.name)
                                }
                                FlatTooltip { visible: _dropMa.containsMouse; text: "Drop Column"; y: -28 }
                            }
                        }
                    }

                    MouseArea { id: colRowMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.columnClicked(colRow.modelData.name || "") }
                    DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.3 }
                }
            }
        }

        // ══ INDEXES TAB ═══════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: tabBar.currentTab === "indexes"; spacing: 0

            // Header row
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 28; color: Theme.bgElevated
                RowLayout { anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0
                    Text { text: "NAME";    font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.fillWidth: true; Layout.preferredWidth: 160 }
                    Text { text: "TYPE";    font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 90 }
                    Text { text: "COLUMNS"; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.fillWidth: true }
                    Text { text: "UNIQUE";  font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignHCenter }
                    Text { text: "ACTION";  font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                }
                DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
            }

            // Index rows
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; model: indexes; boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: ListView.view.width; height: 36
                    color: idxRowMa.containsMouse ? Theme.bgHover : index % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0

                        // Index name
                        Text { text: modelData.name || ""; font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.fg; Layout.fillWidth: true; Layout.preferredWidth: 160; elide: Text.ElideRight }

                        // Type badge
                        Rectangle {
                            Layout.preferredWidth: 90; Layout.alignment: Qt.AlignVCenter
                            width: idxTypeLbl.implicitWidth + Theme.s8; height: 18; radius: Theme.r4
                            color: {
                                var t = (modelData.type || "").toUpperCase()
                                if (t === "PRIMARY") return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12)
                                if (t === "UNIQUE")  return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.12)
                                return Qt.rgba(Theme.info.r, Theme.info.g, Theme.info.b, 0.1)
                            }
                            Text {
                                id: idxTypeLbl; anchors.centerIn: parent
                                text: (modelData.type || "INDEX").toUpperCase()
                                font.pixelSize: Theme.t11; font.family: Theme.mono; font.weight: Font.Bold
                                color: {
                                    var t = (modelData.type || "").toUpperCase()
                                    if (t === "PRIMARY") return Theme.warning
                                    if (t === "UNIQUE")  return Theme.success
                                    return Theme.info
                                }
                            }
                        }

                        // Columns list
                        Text { text: Array.isArray(modelData.columns) ? modelData.columns.join(", ") : (modelData.columns || ""); font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.fgMuted; Layout.fillWidth: true; elide: Text.ElideRight }

                        // Unique badge
                        Rectangle {
                            Layout.preferredWidth: 60; Layout.alignment: Qt.AlignVCenter
                            visible: modelData.unique === true
                            width: 40; height: 18; radius: Theme.rFull
                            color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1)
                            Text { anchors.centerIn: parent; text: "YES"; font.pixelSize: 9; font.weight: Font.Bold; font.family: Theme.mono; color: Theme.success }
                        }
                        Item { visible: modelData.unique !== true; Layout.preferredWidth: 60 }

                        // Drop action
                        Rectangle {
                            Layout.preferredWidth: 40; height: 36; color: "transparent"
                            visible: (modelData.type || "").toUpperCase() !== "PRIMARY"
                            Rectangle {
                                anchors.centerIn: parent; width: 24; height: 24; radius: Theme.r4
                                color: dropIdxMa.containsMouse ? Theme.error : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.fast } }
                                FlatIcon { anchors.centerIn: parent; icon: Icons.trash; size: 12; color: dropIdxMa.containsMouse ? "#fff" : Theme.fgMuted }
                                MouseArea {
                                    id: dropIdxMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var idxName = modelData.name || ""
                                        if (idxName && databaseService && databaseService.connected) {
                                            var sql = DB.buildDropIndexSql(idxName, root.tableName, root.dbType)
                                            databaseService.executeQuery(sql, null)
                                            root.toast("Index dropped: " + idxName, "success")
                                        }
                                    }
                                }
                                FlatTooltip { visible: dropIdxMa.containsMouse; text: "Drop Index"; y: -28 }
                            }
                        }
                    }

                    MouseArea { id: idxRowMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
                    DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.3 }
                }

                // Empty state for indexes
                Item {
                    visible: indexes.length === 0
                    width: parent.width; height: 120
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: Theme.s6
                        FlatIcon { Layout.alignment: Qt.AlignHCenter; icon: Icons.lightning; size: 24; color: Theme.fgMuted; opacity: 0.4 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "No indexes"; font.family: Theme.sans; font.pixelSize: Theme.t13; color: Theme.fgMuted }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Run SHOW INDEX FROM " + root.tableName; font.family: Theme.mono; font.pixelSize: Theme.t11; color: Theme.fgDim; opacity: 0.6 }
                    }
                }
            }
        }

        // ══ TRIGGERS TAB ════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: tabBar.currentTab === "triggers"; spacing: 0

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 28; color: Theme.bgElevated
                RowLayout { anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0
                    Text { text: "NAME";      font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.fillWidth: true; Layout.preferredWidth: 160 }
                    Text { text: "TIMING";    font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 80 }
                    Text { text: "EVENT";     font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 80 }
                    Text { text: "STATEMENT"; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.fillWidth: true }
                }
                DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
            }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; model: triggers; boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 } }

                delegate: Rectangle {
                    required property var modelData; required property int index
                    width: ListView.view.width; height: 36
                    color: trgRowMa.containsMouse ? Theme.bgHover : index % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0
                        Text { text: modelData.name || ""; font.pixelSize: Theme.t12; font.family: Theme.mono; color: Theme.fg; Layout.fillWidth: true; Layout.preferredWidth: 160; elide: Text.ElideRight }
                        Rectangle {
                            Layout.preferredWidth: 80; Layout.alignment: Qt.AlignVCenter
                            width: timingLbl.implicitWidth + Theme.s8; height: 18; radius: Theme.r4
                            color: Qt.rgba(Theme.info.r, Theme.info.g, Theme.info.b, 0.1)
                            Text { id: timingLbl; anchors.centerIn: parent; text: (modelData.timing || "").toUpperCase(); font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.info; font.weight: Font.Bold }
                        }
                        Rectangle {
                            Layout.preferredWidth: 80; Layout.alignment: Qt.AlignVCenter
                            width: eventLbl.implicitWidth + Theme.s8; height: 18; radius: Theme.r4
                            color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.08)
                            Text { id: eventLbl; anchors.centerIn: parent; text: (modelData.event || "").toUpperCase(); font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.warning; font.weight: Font.Bold }
                        }
                        Text { text: modelData.statement || ""; font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgMuted; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                    MouseArea { id: trgRowMa; anchors.fill: parent; hoverEnabled: true; z: -1 }
                    DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.3 }
                }

                Item {
                    visible: triggers.length === 0
                    width: parent.width; height: 120
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: Theme.s6
                        FlatIcon { Layout.alignment: Qt.AlignHCenter; icon: Icons.clock; size: 24; color: Theme.fgMuted; opacity: 0.4 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "No triggers"; font.family: Theme.sans; font.pixelSize: Theme.t13; color: Theme.fgMuted }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Run SHOW TRIGGERS"; font.family: Theme.mono; font.pixelSize: Theme.t11; color: Theme.fgDim; opacity: 0.6 }
                    }
                }
            }
        }
    }
}
