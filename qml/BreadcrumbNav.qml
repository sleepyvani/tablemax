// BreadcrumbNav.qml — Navigation breadcrumb for current database/table context
// Inspired by MongoDB Compass breadcrumb + phpMyAdmin path

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    height: 32; color: Theme.bgElevated

    property string serverName: ""
    property string databaseName: ""
    property string tableName: ""
    property string dbType: ""

    signal serverClicked()
    signal databaseClicked()
    signal tableClicked()

    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 0

        // Server
        BreadcrumbItem {
            icon: Icons.server
            label: serverName || "Server"
            active: serverName !== ""
            onClicked: root.serverClicked()
        }

        BreadcrumbSep { visible: databaseName !== "" }

        // Database
        BreadcrumbItem {
            visible: databaseName !== ""
            icon: Icons.database
            label: databaseName
            active: true
            onClicked: root.databaseClicked()
        }

        BreadcrumbSep { visible: tableName !== "" }

        // Table
        BreadcrumbItem {
            visible: tableName !== ""
            icon: Icons.table
            label: tableName
            active: true
            isCurrent: true
            onClicked: root.tableClicked()
        }

        Item { Layout.fillWidth: true }

        // DB type badge
        Rectangle {
            visible: dbType !== ""
            width: dbTypeBreadLbl.implicitWidth + 12; height: 18; radius: 9
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
            Text { id: dbTypeBreadLbl; anchors.centerIn: parent; text: dbType.toUpperCase(); font.pixelSize: 8; font.weight: Font.Bold; color: Theme.accent; font.family: Theme.mono }
        }
    }

    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

    // ── Breadcrumb item component ──
    component BreadcrumbItem : Rectangle {
        property string icon: ""
        property string label: ""
        property bool active: false
        property bool isCurrent: false

        signal clicked()

        width: bcRow.implicitWidth + 12; height: 24; radius: 4
        color: bcItemMa.containsMouse ? Theme.bgHover : "transparent"

        RowLayout {
            id: bcRow; anchors.centerIn: parent; spacing: 4
            FlatIcon { icon: parent.parent.icon; size: 11; color: parent.parent.isCurrent ? Theme.accent : Theme.fgMuted }
            Text {
                text: label; font.pixelSize: 11
                font.weight: isCurrent ? Font.DemiBold : Font.Normal
                font.family: Theme.fontFamily
                color: isCurrent ? Theme.fg : Theme.fgMuted
            }
        }

        MouseArea {
            id: bcItemMa; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    // ── Breadcrumb separator ──
    component BreadcrumbSep : Item {
        width: 20; height: 24
        Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 12; color: Theme.fgDim; opacity: 0.5 }
    }
}
