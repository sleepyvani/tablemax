// TableStructureView.qml — Column type/detail view for SQL tables
// Inspired by phpMyAdmin structure tab, Drizzle schema inspector

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    color: Theme.bg

    property var schemaService: null
    property string tableName: ""
    property var columns: []  // [{ name, type, nullable, default, pk, extra }]

    signal columnClicked(string colName)
    signal closed()

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Header ──
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
                    Text { id: colCountLbl; anchors.centerIn: parent; text: columns.length + " columns"; font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgDim }
                }

                Rectangle {
                    width: 24; height: 24; radius: Theme.r4
                    color: structCloseMa.containsMouse ? Theme.bgHover : "transparent"
                    FlatIcon { anchors.centerIn: parent; icon: Icons.close; size: 12; color: Theme.fgMuted }
                    MouseArea { id: structCloseMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closed() }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ── Column headers ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 28; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0
                Text { text: "#"; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 32 }
                Text { text: "COLUMN"; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.fillWidth: true; Layout.preferredWidth: 180 }
                Text { text: "TYPE"; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 120 }
                Text { text: "NULL"; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 48 }
                Text { text: "DEFAULT"; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 100 }
                Text { text: "EXTRA"; font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgDim; font.family: Theme.mono; Layout.preferredWidth: 100 }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
        }

        // ── Column rows ──
        ListView {
            id: colListView
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; model: columns
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: colRow
                required property int index
                required property var modelData
                property int colIdx: index

                width: colListView.width; height: 36
                color: colRowMa.containsMouse ? Theme.bgHover : colIdx % 2 === 0 ? "transparent" : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.015)

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: 0

                    // Row number
                    Text { text: (colRow.colIdx + 1).toString(); font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgDim; Layout.preferredWidth: 32 }

                    // Column name + PK indicator
                    RowLayout {
                        Layout.fillWidth: true; Layout.preferredWidth: 180; spacing: Theme.s4

                        // PK badge
                        Rectangle {
                            visible: colRow.modelData.pk === true
                            width: 18; height: 14; radius: Theme.r4
                            color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.15)
                            Text { anchors.centerIn: parent; text: "PK"; font.pixelSize: 7; font.weight: Font.Bold; color: Theme.warning; font.family: Theme.mono }
                        }

                        Text {
                            text: colRow.modelData.name || ""
                            font.pixelSize: Theme.t12; font.weight: colRow.modelData.pk ? Font.DemiBold : Font.Normal
                            font.family: Theme.sans; color: Theme.fg
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }

                    // Type
                    Rectangle {
                        Layout.preferredWidth: 120; height: 20; radius: Theme.r4
                        color: Qt.rgba(Theme.info.r, Theme.info.g, Theme.info.b, 0.08)
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: colRow.modelData.type || "unknown"
                            font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.info
                            elide: Text.ElideRight
                        }
                    }

                    // Nullable
                    Text {
                        text: colRow.modelData.nullable ? "YES" : "NO"
                        font.pixelSize: Theme.t11; font.family: Theme.mono; Layout.preferredWidth: 48
                        color: colRow.modelData.nullable ? Theme.fgDim : Theme.warning
                        font.weight: colRow.modelData.nullable ? Font.Normal : Font.Bold
                    }

                    // Default
                    Text {
                        text: colRow.modelData.defaultVal !== undefined && colRow.modelData.defaultVal !== null ? String(colRow.modelData.defaultVal) : "—"
                        font.pixelSize: Theme.t11; font.family: Theme.mono; Layout.preferredWidth: 100
                        color: colRow.modelData.defaultVal !== undefined && colRow.modelData.defaultVal !== null ? Theme.fg : Theme.fgDim
                        elide: Text.ElideRight
                    }

                    // Extra (AUTO_INCREMENT, etc.)
                    Text {
                        text: colRow.modelData.extra || "—"
                        font.pixelSize: Theme.t11; font.family: Theme.mono; Layout.preferredWidth: 100
                        color: (colRow.modelData.extra || "") !== "" ? Theme.accent : Theme.fgDim
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: colRowMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.columnClicked(colRow.modelData.name || "")
                }

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.3 }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
            }
        }
    }
}
