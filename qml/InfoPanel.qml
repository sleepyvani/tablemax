import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

// ── Info Panel (Right Sidebar) ───────────────────────────────
// Shows column details, indexes, primary keys, metadata

Rectangle {
    id: infoPanel
    color: Theme.bgSidebar
    border.width: 1; border.color: Theme.border

    property string tableName: ""
    property var schema: []
    property string dbType: ""
    property int rowCount: 0
    property double queryTime: 0

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Header ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 48
            color: "transparent"

            RowLayout {
                anchors.fill: parent; anchors.margins: Theme.s12; spacing: Theme.s8

                Rectangle {
                    width: 28; height: 28; radius: Theme.r6
                    color: Theme.accentDim
                    FlatIcon {
                        anchors.centerIn: parent; icon: Icons.table; size: 14; color: Theme.accent
                    }
                }

                ColumnLayout {
                    spacing: 0; Layout.fillWidth: true
                    Text {
                        text: tableName || "No table selected"
                        font.family: Theme.mono; font.pixelSize: Theme.t13; font.weight: Font.DemiBold
                        color: Theme.fg; elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    Text {
                        text: schema.length + " columns"
                        font.pixelSize: Theme.t11; color: Theme.fgMuted
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        // ── Stats Cards ──
        RowLayout {
            Layout.fillWidth: true; Layout.margins: Theme.s12; spacing: Theme.s8

            Repeater {
                model: [
                    { label: "Rows",  value: rowCount.toLocaleString(), iconCode: Icons.chart },
                    { label: "Time",  value: queryTime.toFixed(1) + "ms", iconCode: Icons.clock },
                    { label: "Cols",  value: schema.length.toString(), iconCode: Icons.column }
                ]

                Rectangle {
                    Layout.fillWidth: true; height: 52; radius: Theme.r6
                    color: Theme.bgSurface; border.width: 1; border.color: Theme.border

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: Theme.s2
                        Text {
                            text: modelData.value; font.family: Theme.mono; font.pixelSize: Theme.t14
                            font.weight: Font.DemiBold; color: Theme.fg
                            Layout.alignment: Qt.AlignHCenter
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter; spacing: Theme.s4
                            FlatIcon { icon: modelData.iconCode; size: 10; color: Theme.fgMuted }
                            Text {
                                text: modelData.label; font.pixelSize: Theme.t11; color: Theme.fgMuted
                            }
                        }
                    }
                }
            }
        }

        // ── Column List Header ──
        Rectangle {
            Layout.fillWidth: true; Layout.margins: 12; Layout.topMargin: 0
            Layout.preferredHeight: 28; color: "transparent"
            RowLayout {
                anchors.verticalCenter: parent.verticalCenter; x: 4; spacing: Theme.s6
                FlatIcon { icon: Icons.column; size: 11; color: Theme.fgMuted }
                Text {
                    text: "COLUMNS"; font.family: Theme.sans; font.pixelSize: Theme.t11
                    font.weight: Font.DemiBold; color: Theme.fgMuted; font.letterSpacing: 1
                }
            }
        }

        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.leftMargin: 12; Layout.rightMargin: 12
            clip: true; spacing: Theme.s2
            model: schema

            delegate: Rectangle {
                width: parent ? parent.width : 0; height: 42; radius: Theme.r4
                color: mouseArea.containsMouse ? Theme.bgHover : "transparent"

                MouseArea { id: mouseArea; anchors.fill: parent; hoverEnabled: true }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.s8; anchors.rightMargin: Theme.s8; spacing: Theme.s6

                    // PK indicator
                    Rectangle {
                        width: 18; height: 18; radius: Theme.rFull
                        color: modelData.primaryKey ? Theme.accent : "transparent"
                        border.width: modelData.primaryKey ? 0 : 1
                        border.color: Theme.border
                        FlatIcon {
                            anchors.centerIn: parent
                            icon: modelData.primaryKey ? Icons.key : ""
                            size: 9; color: "#fff"
                            visible: modelData.primaryKey
                        }
                    }

                    // Column info
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        Text {
                            text: modelData.name; font.family: Theme.mono; font.pixelSize: Theme.t12
                            color: Theme.fg; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                        RowLayout {
                            spacing: Theme.s4
                            Text {
                                text: modelData.type; font.pixelSize: Theme.t11; color: Theme.accent
                                font.family: Theme.mono
                            }
                            Text {
                                visible: modelData.nullable
                                text: "nullable"; font.pixelSize: Theme.t11; color: Theme.fgDim
                            }
                        }
                    }

                    // Default value badge
                    Rectangle {
                        visible: modelData.defaultValue && modelData.defaultValue !== ""
                        width: defText.implicitWidth + Theme.s8; height: 16; radius: Theme.r4
                        color: Theme.bgSurface; border.width: 1; border.color: Theme.border
                        Text {
                            id: defText; anchors.centerIn: parent
                            text: "= " + (modelData.defaultValue || "")
                            font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fgMuted
                        }
                    }
                }
            }
        }

        // ── Empty state ──
        ColumnLayout {
            visible: schema.length === 0
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter; spacing: Theme.s8

            FlatIcon { icon: Icons.table; size: 32; color: Theme.fgDim; Layout.alignment: Qt.AlignHCenter }
            Text {
                text: "Select a table to view its structure"
                font.pixelSize: Theme.t13; color: Theme.fgMuted; Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
