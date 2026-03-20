// SQLPreviewDialog.qml — Preview generated SQL before applying (phpMyAdmin-style)

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

FlatDialog {
    id: root
    dialogTitle: "SQL Preview"
    dialogDescription: "Review before applying"
    width: 600; height: 460

    property var statements: []
    property var changeTracker: null

    signal confirmed()
    signal cancelled()

    function showPreview(stmts) {
        statements = stmts || []
        open()
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ── Stats header ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 36
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06)
            radius: Theme.r6

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                FlatIcon { icon: Icons.code; size: 14; color: Theme.accent }
                Text {
                    text: statements.length + " statement" + (statements.length !== 1 ? "s" : "") + " to execute"
                    font.pixelSize: Theme.t12; font.weight: Font.Medium; color: Theme.fg; font.family: Theme.sans
                }
                Item { Layout.fillWidth: true }

                // Copy all
                Rectangle {
                    width: 70; height: 24; radius: Theme.rFull
                    color: copyAllMa.containsMouse ? Theme.bgHover : Theme.bgSurface
                    border.width: 1; border.color: Theme.border
                    Text { anchors.centerIn: parent; text: "Copy All"; font.pixelSize: Theme.t11; font.weight: Font.Medium; color: Theme.fg; font.family: Theme.sans }
                    MouseArea {
                        id: copyAllMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            _clip.text = statements.join(";\n") + ";"; _clip.selectAll(); _clip.copy()
                        }
                    }
                }
            }
        }

        Item { height: 8 }

        // ── SQL statements list ──
        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true
            contentHeight: stmtCol.implicitHeight; clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: stmtCol
                anchors.left: parent.left; anchors.right: parent.right
                spacing: Theme.s6

                Repeater {
                    model: statements.length

                    Rectangle {
                        id: stmtItem
                        required property int index
                        property int stmtIdx: index

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(stmtText.implicitHeight + 24, 48)
                        radius: Theme.r6
                        color: Theme.bgSurface
                        border.width: 1; border.color: Theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s8
                            anchors.topMargin: Theme.s6; anchors.bottomMargin: Theme.s6
                            spacing: Theme.s8

                            // Statement type icon
                            Rectangle {
                                width: 24; height: 24; radius: Theme.rFull
                                color: {
                                    var s = stmtIdx < statements.length ? statements[stmtIdx] : ""
                                    if (s.indexOf("INSERT") === 0) return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.12)
                                    if (s.indexOf("UPDATE") === 0) return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12)
                                    if (s.indexOf("DELETE") === 0) return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
                                    return Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                                }
                                Text {
                                    anchors.centerIn: parent; font.pixelSize: Theme.t11; font.weight: Font.Bold; font.family: Theme.mono
                                    color: {
                                        var s = stmtItem.stmtIdx < root.statements.length ? root.statements[stmtItem.stmtIdx] : ""
                                        if (s.indexOf("INSERT") === 0) return Theme.success
                                        if (s.indexOf("UPDATE") === 0) return Theme.warning
                                        if (s.indexOf("DELETE") === 0) return Theme.error
                                        return Theme.fgDim
                                    }
                                    text: {
                                        var s = stmtItem.stmtIdx < root.statements.length ? root.statements[stmtItem.stmtIdx] : ""
                                        if (s.indexOf("INSERT") === 0) return "I"
                                        if (s.indexOf("UPDATE") === 0) return "U"
                                        if (s.indexOf("DELETE") === 0) return "D"
                                        return "?"
                                    }
                                }
                            }

                            // SQL text
                            Text {
                                id: stmtText
                                text: stmtItem.stmtIdx < root.statements.length ? root.statements[stmtItem.stmtIdx] : ""
                                font.pixelSize: Theme.t11; font.family: Theme.mono; color: Theme.fg
                                wrapMode: Text.WrapAnywhere; Layout.fillWidth: true
                            }

                            // Copy individual
                            Rectangle {
                                width: 24; height: 24; radius: Theme.r4
                                color: copySingleMa.containsMouse ? Theme.bgHover : "transparent"
                                FlatIcon { anchors.centerIn: parent; icon: Icons.copy; size: 11; color: Theme.fgMuted }
                                MouseArea {
                                    id: copySingleMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var s = stmtItem.stmtIdx < root.statements.length ? root.statements[stmtItem.stmtIdx] : ""
                                        _clip.text = s + ";"; _clip.selectAll(); _clip.copy()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
            }
        }

        Item { height: 12 }

        // ── Warning ──
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32; radius: Theme.r6
            color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.08)
            visible: statements.length > 0

            RowLayout {
                anchors.centerIn: parent; spacing: Theme.s6
                FlatIcon { icon: Icons.warning; size: 12; color: Theme.warning }
                Text { text: "This will modify data in your database. Proceed with caution."; font.pixelSize: Theme.t11; color: Theme.warning; font.family: Theme.sans }
            }
        }

        Item { height: 12 }

        // ── Action buttons ──
        RowLayout {
            Layout.fillWidth: true; spacing: Theme.s8

            Item { Layout.fillWidth: true }
            FlatButton { text: "Cancel"; variant: "ghost"; onClicked: { cancelled(); root.close() } }
            FlatButton {
                text: "Execute " + statements.length + " Statement" + (statements.length !== 1 ? "s" : "")
                variant: "default"
                onClicked: { confirmed(); root.close() }
            }
        }
    }

    TextEdit { id: _clip; visible: false }
}
