// PaginationBar.qml — Page navigation for large tables
// Ported from TablePro PaginationControlsView.swift

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

Rectangle {
    id: root
    height: 36
    Layout.preferredHeight: 36
    Layout.minimumHeight: 36
    color: Theme.bgElevated

    property int currentPage: 1
    property int totalPages: 1
    property int pageSize: 100
    property int totalRows: 0
    property var pageSizes: [25, 50, 100, 250, 500, 1000]

    signal pageChanged(int page)
    signal rowsPerPageChanged(int size)

    DashedLine { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12
        spacing: Theme.s8

        // Row count — show visible range
        Text {
            text: {
                if (totalRows <= 0) return "0 rows"
                var from = (currentPage - 1) * pageSize + 1
                var to = Math.min(currentPage * pageSize, totalRows)
                return from + "\u2013" + to + " of " + totalRows.toLocaleString() + " rows"
            }
            font.pixelSize: Theme.t11; color: Theme.fgMuted
            font.family: Theme.sans
        }

        Item { Layout.fillWidth: true }

        // Rows per page
        Text { text: "Rows per page:"; font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.sans }
        FlatSelect {
            id: pageSizeSelect
            Layout.preferredWidth: 70; Layout.preferredHeight: 24
            model: pageSizes
            currentIndex: pageSizes.indexOf(pageSize)
            onCurrentIndexChanged: {
                if (currentIndex >= 0) rowsPerPageChanged(pageSizes[currentIndex])
            }
        }

        // Separator
        DashedLine { Layout.preferredWidth: 1; Layout.preferredHeight: 20; color: Theme.border; Layout.alignment: Qt.AlignVCenter }

        // Page info
        Text {
            text: "Page " + currentPage + " of " + Math.max(1, totalPages)
            font.pixelSize: Theme.t11; color: Theme.fgMuted; font.family: Theme.sans
        }

        // Navigation buttons
        Row {
            spacing: Theme.s2

            // First page
            Rectangle {
                width: 24; height: 24; radius: Theme.r4
                color: firstMa.containsMouse ? Theme.bgHover : "transparent"
                opacity: currentPage > 1 ? 1 : 0.3
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                Text {
                    anchors.centerIn: parent
                    text: "\u00AB"  // «
                    font.pixelSize: Theme.t13; font.weight: Font.Bold
                    color: Theme.fgMuted
                }
                MouseArea {
                    id: firstMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (currentPage > 1) pageChanged(1)
                }
                FlatTooltip { text: "First Page"; visible: firstMa.containsMouse }
            }

            // Previous page
            Rectangle {
                width: 24; height: 24; radius: Theme.r4
                color: prevMa.containsMouse ? Theme.bgHover : "transparent"
                opacity: currentPage > 1 ? 1 : 0.3
                FlatIcon { anchors.centerIn: parent; icon: Icons.left; size: 14; color: Theme.fgMuted }
                MouseArea {
                    id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (currentPage > 1) pageChanged(currentPage - 1)
                }
                FlatTooltip { text: "Previous Page"; visible: prevMa.containsMouse }
            }

            // Page number pills
            Row {
                spacing: Theme.s2
                Repeater {
                    model: computePageNumbers()
                    Rectangle {
                        width: 24; height: 24; radius: Theme.r4
                        color: modelData === currentPage ? Theme.accent
                             : pillMa.containsMouse ? Theme.bgHover : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData === -1 ? "…" : modelData
                            font.pixelSize: Theme.t11; font.family: Theme.sans
                            color: modelData === currentPage ? "#fff" : Theme.fgMuted
                        }
                        MouseArea {
                            id: pillMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: modelData !== -1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (modelData > 0) pageChanged(modelData)
                        }
                    }
                }
            }

            // Next page
            Rectangle {
                width: 24; height: 24; radius: Theme.r4
                color: nextMa.containsMouse ? Theme.bgHover : "transparent"
                opacity: currentPage < totalPages ? 1 : 0.3
                FlatIcon { anchors.centerIn: parent; icon: Icons.right; size: 14; color: Theme.fgMuted }
                MouseArea {
                    id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (currentPage < totalPages) pageChanged(currentPage + 1)
                }
                FlatTooltip { text: "Next Page"; visible: nextMa.containsMouse }
            }

            // Last page
            Rectangle {
                width: 24; height: 24; radius: Theme.r4
                color: lastMa.containsMouse ? Theme.bgHover : "transparent"
                opacity: currentPage < totalPages ? 1 : 0.3
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                Text {
                    anchors.centerIn: parent
                    text: "\u00BB"  // »
                    font.pixelSize: Theme.t13; font.weight: Font.Bold
                    color: Theme.fgMuted
                }
                MouseArea {
                    id: lastMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (currentPage < totalPages) pageChanged(totalPages)
                }
                FlatTooltip { text: "Last Page"; visible: lastMa.containsMouse }
            }
        }
    }

    function computePageNumbers() {
        if (totalPages <= 7) {
            var pages = []
            for (var i = 1; i <= totalPages; i++) pages.push(i)
            return pages
        }
        var result = [1]
        if (currentPage > 3) result.push(-1) // ellipsis
        var start = Math.max(2, currentPage - 1)
        var end = Math.min(totalPages - 1, currentPage + 1)
        for (var j = start; j <= end; j++) result.push(j)
        if (currentPage < totalPages - 2) result.push(-1)
        result.push(totalPages)
        return result
    }
}
