import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Status bar
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.margins: 8
            spacing: 8

            Text {
                text: resultModel.totalRows + " rows × " + resultModel.totalColumns + " columns"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                color: Theme.mutedForeground
            }

            Item { Layout.fillWidth: true }

            FlatButton {
                text: "Clear"
                variant: "ghost"
                size: "sm"
                onClicked: resultModel.clear()
            }
        }

        FlatSeparator { orientation: Qt.Horizontal }

        // Table
        TableView {
            id: tableView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: resultModel
            boundsBehavior: Flickable.StopAtBounds

            columnWidthProvider: function(col) {
                return Math.max(120, tableView.width / Math.max(1, resultModel.totalColumns))
            }

            delegate: Rectangle {
                implicitWidth: 120
                implicitHeight: 32
                color: row % 2 === 0 ? "transparent" : Qt.rgba(1, 1, 1, 0.01)

                border.width: 0
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }
                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.border
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    text: display || ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    color: display === null || display === "NULL"
                        ? Theme.mutedForeground : Theme.foreground
                    elide: Text.ElideRight
                    font.italic: display === null || display === "NULL"
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 4
                    radius: 2
                    color: Theme.border
                }
            }

            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitHeight: 4
                    radius: 2
                    color: Theme.border
                }
            }
        }

        // Empty state
        FlatEmpty {
            visible: resultModel.totalRows === 0
            anchors.centerIn: parent
            title: "No results"
            description: "Run a query to see data here"
        }
    }
}
