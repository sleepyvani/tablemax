import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

// ── Filter Panel ─────────────────────────────────────────────
// Visual query builder with AND/OR logic

Rectangle {
    id: filterPanel
    color: Theme.bgElevated
    border.width: 1; border.color: Theme.border
    radius: Theme.r8
    clip: true

    property var columns: []
    property alias filterCount: filterModel.count

    signal filtersApplied(string whereClause)
    signal filtersClosed()

    implicitHeight: headerRow.height + filterList.contentHeight + footerRow.height + 32

    ListModel { id: filterModel }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 8

        // ── Header ──
        RowLayout {
            id: headerRow; Layout.fillWidth: true; spacing: 8

            FlatIcon { icon: Icons.filter; size: 14; color: Theme.accent }
            Text {
                text: "Filters"; font.family: Theme.sans; font.pixelSize: 13
                font.weight: Font.DemiBold; color: Theme.fg
            }

            Rectangle {
                visible: filterModel.count > 0
                width: countText.implicitWidth + 12; height: 20; radius: 10
                color: Theme.accent
                Text {
                    id: countText; anchors.centerIn: parent
                    text: filterModel.count; font.pixelSize: 10; font.weight: Font.Bold; color: "#fff"
                }
            }

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Add"; flat: true; font.pixelSize: 11
                onClicked: filterModel.append({
                    column: columns.length > 0 ? columns[0].name : "",
                    operator: "=",
                    value: "",
                    logic: "AND"
                })
            }

            FlatIcon {
                icon: Icons.close; size: 14; color: Theme.fgMuted
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    anchors.margins: -4
                    onClicked: filtersClosed()
                }
            }
        }

        // ── Filter Rows ──
        ListView {
            id: filterList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 200)
            model: filterModel; spacing: 6; clip: true

            delegate: RowLayout {
                width: filterList.width; spacing: 6; height: 36

                FlatSelect {
                    visible: index > 0; implicitWidth: 64
                    model: ["AND", "OR"]
                    currentIndex: logic === "OR" ? 1 : 0
                    onCurrentTextChanged: filterModel.setProperty(index, "logic", currentText)
                }
                Item { visible: index === 0; implicitWidth: 64 }

                FlatSelect {
                    implicitWidth: 140
                    model: columns.map(function(c) { return c.name })
                    currentIndex: Math.max(0, columns.findIndex(function(c) { return c.name === column }))
                    onCurrentTextChanged: filterModel.setProperty(index, "column", currentText)
                }

                FlatSelect {
                    implicitWidth: 80
                    model: ["=", "!=", ">", "<", ">=", "<=", "LIKE", "IN", "IS NULL", "IS NOT NULL"]
                    currentIndex: model.indexOf(operator)
                    onCurrentTextChanged: filterModel.setProperty(index, "operator", currentText)
                }

                FlatInput {
                    Layout.fillWidth: true
                    text: value; placeholderText: "Value..."
                    visible: operator !== "IS NULL" && operator !== "IS NOT NULL"
                    onTextChanged: filterModel.setProperty(index, "value", text)
                }

                FlatIcon {
                    icon: Icons.close; size: 12; color: Theme.error
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        anchors.margins: -4
                        onClicked: filterModel.remove(index)
                    }
                }
            }
        }

        // ── Empty state ──
        Text {
            visible: filterModel.count === 0
            text: "No filters added. Click 'Add' to create one."
            font.family: Theme.sans; font.pixelSize: 12; color: Theme.fgMuted
            Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8
        }

        // ── Footer ──
        RowLayout {
            id: footerRow; Layout.fillWidth: true; spacing: 8

            FlatButton {
                text: "Clear All"; flat: true; visible: filterModel.count > 0
                onClicked: { filterModel.clear(); filtersApplied("") }
            }

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Apply Filters"; highlighted: true
                enabled: filterModel.count > 0
                onClicked: filtersApplied(buildWhereClause())
            }
        }
    }

    function buildWhereClause() {
        if (filterModel.count === 0) return ""
        var parts = []
        for (var i = 0; i < filterModel.count; i++) {
            var f = filterModel.get(i)
            var clause = ""
            if (f.operator === "IS NULL") clause = "\"" + f.column + "\" IS NULL"
            else if (f.operator === "IS NOT NULL") clause = "\"" + f.column + "\" IS NOT NULL"
            else if (f.operator === "IN") clause = "\"" + f.column + "\" IN (" + f.value + ")"
            else if (f.operator === "LIKE") clause = "\"" + f.column + "\" LIKE '" + f.value + "'"
            else clause = "\"" + f.column + "\" " + f.operator + " '" + f.value + "'"

            if (i > 0) clause = " " + f.logic + " " + clause
            parts.push(clause)
        }
        return "WHERE " + parts.join("")
    }
}
