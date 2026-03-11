import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    color: Theme.bg

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ─── Header ───
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 32; color: Theme.bgElevated

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                Text { text: "Results"; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.DemiBold; color: Theme.fgMuted }

                Rectangle {
                    height: 16; width: rcText.implicitWidth + 10; radius: Theme.rFull; color: Theme.bgSurface; visible: resultModel && resultModel.totalRows > 0
                    Text { id: rcText; anchors.centerIn: parent; text: (resultModel ? resultModel.totalRows : 0) + " rows"; font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 24; height: 24; radius: Theme.r4; color: exportMa.containsMouse ? Theme.bgHover : "transparent"; visible: resultModel && resultModel.totalRows > 0
                    Text { anchors.centerIn: parent; text: "↓"; font.pixelSize: 13; color: Theme.fgMuted }
                    MouseArea { id: exportMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                }
            }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
        }

        // ─── Table ───
        TableView {
            id: tv; Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; model: resultModel; visible: resultModel && resultModel.totalRows > 0
            boundsBehavior: Flickable.StopAtBounds; columnSpacing: 0; rowSpacing: 0

            columnWidthProvider: function(c) { return Math.max(100, tv.width / Math.max(1, resultModel ? resultModel.totalColumns : 1)) }
            rowHeightProvider: function() { return 28 }

            delegate: Rectangle {
                implicitWidth: 100; implicitHeight: 28
                color: row === 0 ? Theme.bgElevated : row % 2 === 0 ? "transparent" : Qt.rgba(1, 1, 1, 0.008)

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border; opacity: 0.4 }
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border; opacity: 0.3 }

                Text {
                    anchors.fill: parent; anchors.leftMargin: Theme.s8; verticalAlignment: Text.AlignVCenter
                    text: display !== undefined ? String(display) : ""
                    font.family: Theme.mono; font.pixelSize: Theme.t12
                    color: {
                        if (display === null || display === "NULL") return Theme.fgDim
                        if (display === "true" || display === "false") return Theme.success
                        if (!isNaN(display) && display !== "") return Theme.info
                        return Theme.fg
                    }
                    font.italic: display === null || display === "NULL"
                    elide: Text.ElideRight; opacity: (display === null || display === "NULL") ? 0.5 : 1
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
            }
            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { implicitHeight: 4; radius: 2; color: Theme.borderLight; opacity: 0.6 }
            }
        }

        // ─── Empty ───
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true; visible: !resultModel || resultModel.totalRows === 0

            ColumnLayout {
                anchors.centerIn: parent; spacing: Theme.s12

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter; width: 40; height: 40; radius: Theme.r8; color: Theme.bgSurface
                    Text { anchors.centerIn: parent; text: "⊞"; font.pixelSize: 18; color: Theme.fgDim }
                }
                Text { text: "No results"; font.family: Theme.sans; font.pixelSize: Theme.t14; font.weight: Font.DemiBold; color: Theme.fgMuted; Layout.alignment: Qt.AlignHCenter }
                Text { text: "Run a query to see data here"; font.family: Theme.sans; font.pixelSize: Theme.t12; color: Theme.fgDim; Layout.alignment: Qt.AlignHCenter }
            }
        }
    }
}
