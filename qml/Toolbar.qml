// Toolbar.qml — Main toolbar with connection status + action buttons
// Ported from TablePro TableProToolbarView.swift

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    height: 38
    Layout.preferredHeight: 38
    Layout.minimumHeight: 38
    color: Theme.bgElevated

    property bool connected: false
    property string connectionName: ""
    property string dbType: ""
    property bool executing: false
    property bool hasChanges: false
    property bool canUndo: false
    property bool canRedo: false
    property string tabType: "query"

    signal executeQuery()
    signal formatQuery()
    signal saveChanges()
    signal discardChanges()
    signal undoAction()
    signal redoAction()
    signal toggleHistory()
    signal toggleSettings()
    signal addRow()
    signal deleteRows()
    signal refreshData()

    property bool filterActive: false
    property int filterCount: 0
    signal toggleFilter()
    signal exportData()
    signal importData()
    signal showShortcuts()

    RowLayout {
        anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s6

        // ── Connection status ──
        Rectangle {
            width: connRow.implicitWidth + Theme.s16; height: 28; radius: Theme.rFull
            color: connected ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1)
                             : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)
            RowLayout {
                id: connRow; anchors.centerIn: parent; spacing: Theme.s6
                Rectangle { width: Theme.s6; height: Theme.s6; radius: Theme.rFull; color: connected ? Theme.success : Theme.error }
                Text {
                    text: connected ? connectionName : "Disconnected"
                    font.pixelSize: Theme.t11; font.weight: Font.Medium; font.family: Theme.sans
                    color: connected ? Theme.fg : Theme.fgMuted
                }
                // DB type badge
                Rectangle {
                    visible: dbType !== "" && connected
                    width: dbTypeLbl.implicitWidth + Theme.s8; height: 16; radius: Theme.rFull
                    color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                    Text { id: dbTypeLbl; anchors.centerIn: parent; text: dbType.toUpperCase(); font.pixelSize: Theme.t11; font.weight: Font.Bold; color: Theme.fgMuted; font.family: Theme.sans }
                }
            }
        }

        DashedLine { visible: tabType === "query" || tabType === "table"; Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Theme.border; Layout.alignment: Qt.AlignVCenter }

        // ── Execute (Query Tab) ──
        ToolBtn { visible: tabType === "query"; icon: Icons.play; tip: "Execute (Ctrl+Enter)"; accent: true; spinning: executing; onClicked: executeQuery() }
        ToolBtn { visible: tabType === "query"; icon: Icons.formatText; tip: "Format SQL"; onClicked: formatQuery() }

        DashedLine { visible: tabType === "query"; Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Theme.border; Layout.alignment: Qt.AlignVCenter }

        // ── Row operations (Table Tab) ──
        ToolBtn { visible: tabType === "table"; icon: Icons.add; tip: "Add Row"; onClicked: addRow() }
        ToolBtn { visible: tabType === "table"; icon: Icons.trash; tip: "Delete Selected"; onClicked: deleteRows() }
        ToolBtn { visible: tabType === "table"; icon: Icons.refresh; tip: "Refresh Data"; onClicked: refreshData() }
        
        DashedLine { visible: tabType === "table"; Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Theme.border; Layout.alignment: Qt.AlignVCenter }

        // ── Undo / Redo ──
        ToolBtn { icon: Icons.undo; tip: "Undo (Ctrl+Z)"; enabled: canUndo; onClicked: undoAction() }
        ToolBtn { icon: Icons.redo; tip: "Redo (Ctrl+Y)"; enabled: canRedo; onClicked: redoAction() }

        Item { Layout.fillWidth: true }

        // ── Save changes indicator ──
        Rectangle {
            visible: hasChanges
            width: saveRow.implicitWidth + Theme.s16; height: 28; radius: Theme.rFull
            color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12)

            RowLayout {
                id: saveRow; anchors.centerIn: parent; spacing: Theme.s6
                FlatIcon { icon: Icons.warning; size: 12; color: Theme.warning }
                Text { text: "Unsaved changes"; font.pixelSize: Theme.t11; font.weight: Font.Medium; color: Theme.warning; font.family: Theme.sans }
            }

            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: saveChanges() }
        }

        // Discard
        ToolBtn { visible: hasChanges; icon: Icons.close; tip: "Discard changes"; onClicked: discardChanges() }
        // Save
        ToolBtn { visible: hasChanges; icon: Icons.save; tip: "Save changes (Ctrl+S)"; accent: true; onClicked: saveChanges() }

        DashedLine { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Theme.border; Layout.alignment: Qt.AlignVCenter; visible: !hasChanges }

        // ── Filter active badge ──
        Rectangle {
            visible: filterActive
            width: filterRow.implicitWidth + Theme.s12; height: 22; radius: Theme.rFull
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)
            border.width: 1; border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
            RowLayout {
                id: filterRow; anchors.centerIn: parent; spacing: Theme.s4
                FlatIcon { icon: Icons.filter; size: 10; color: Theme.accent }
                Text {
                    text: filterCount > 0 ? filterCount + " filters" : "Filter active"
                    font.pixelSize: Theme.t10; font.weight: Font.Medium; color: Theme.accent; font.family: Theme.sans
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: toggleFilter() }
            FlatTooltip { visible: parent.containsMouse; text: "Click to clear filters"; y: -30 }
        }

        DashedLine { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Theme.border; Layout.alignment: Qt.AlignVCenter }

        // ── Right side ──
        ToolBtn { icon: Icons.upload; tip: "Import (Ctrl+Shift+I)"; onClicked: importData() }
        ToolBtn { icon: Icons.download; tip: "Export (Ctrl+E)"; onClicked: exportData() }
        DashedLine { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: Theme.border; Layout.alignment: Qt.AlignVCenter }
        ToolBtn { icon: Icons.clock; tip: "Toggle History (Ctrl+H)"; onClicked: toggleHistory() }
        ToolBtn { icon: Icons.keyboard; tip: "Keyboard Shortcuts (Ctrl+/)"; onClicked: showShortcuts() }
        ToolBtn { icon: Icons.settings; tip: "Settings (Ctrl+,)"; onClicked: toggleSettings() }
    }

    DashedLine { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

    BlueprintCrosshair {
        anchors.bottom: parent.bottom; anchors.left: parent.left
        anchors.bottomMargin: -size/2; anchors.leftMargin: -size/2
    }
    BlueprintCrosshair {
        anchors.bottom: parent.bottom; anchors.right: parent.right
        anchors.bottomMargin: -size/2; anchors.rightMargin: -size/2
    }

    // ── Execution indicator animation ──
    Rectangle {
        anchors.bottom: parent.bottom; height: 2; color: Theme.accent; visible: executing
        width: parent.width * 0.3; radius: 1

        SequentialAnimation on x {
            running: executing; loops: Animation.Infinite
            NumberAnimation { from: 0; to: root.width * 0.7; duration: 800; easing.type: Easing.InOutQuad }
            NumberAnimation { from: root.width * 0.7; to: 0; duration: 800; easing.type: Easing.InOutQuad }
        }
    }

    // ── Tool button component ──
    component ToolBtn : Rectangle {
        property string icon: ""
        property string tip: ""
        property bool accent: false
        property bool spinning: false

        signal clicked()

        width: 28; height: 28; radius: Theme.r6
        color: accent ? (tbMa.containsMouse ? Qt.darker(Theme.accent, 1.1) : Theme.accent)
             : tbMa.containsMouse ? Theme.bgHover : "transparent"
        opacity: enabled ? 1 : 0.3

        FlatIcon {
            anchors.centerIn: parent; icon: parent.icon; size: 14
            color: parent.accent ? "#fff" : Theme.fgMuted

            RotationAnimation on rotation {
                running: spinning; loops: Animation.Infinite; from: 0; to: 360; duration: 1000
            }
        }

        MouseArea { id: tbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: if (parent.enabled) parent.clicked() }
        FlatTooltip { visible: tbMa.containsMouse && tip !== ""; text: tip; x: tbMa.mouseX; y: -30 }
    }
}
