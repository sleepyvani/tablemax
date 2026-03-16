import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Icons.js" as Icons

// ── Database Switcher ────────────────────────────────────────

FlatPopover {
    id: dbSwitcher
    width: 260

    property var databases: []
    property string currentDb: ""

    signal databaseSelected(string dbName)

    contentItem: ColumnLayout {
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 40
            color: "transparent"
            RowLayout {
                anchors.fill: parent; anchors.margins: Theme.s12; spacing: Theme.s8
                FlatIcon { icon: Icons.database; size: 14; color: Theme.accent }
                Text {
                    text: "Databases"; font.family: Theme.sans; font.pixelSize: Theme.t13
                    font.weight: Font.DemiBold; color: Theme.fg
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: databases.length + " total"; font.pixelSize: Theme.t11; color: Theme.fgMuted
                }
            }
        }

        DashedLine { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

        // Search
        FlatInput {
            id: searchInput
            Layout.fillWidth: true; Layout.margins: 8
            placeholderText: "Search databases..."
            onTextChanged: filterList()
        }

        // List
        ListView {
            id: dbList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 300)
            clip: true; spacing: 0

            model: ListModel { id: dbModel }

            delegate: Rectangle {
                width: dbList.width; height: 36
                color: mouseArea.containsMouse ? Theme.bgHover :
                       (name === currentDb ? Theme.accentDim : "transparent")
                radius: Theme.r4

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

                    Rectangle {
                        width: 6; height: 6; radius: Theme.rFull
                        color: name === currentDb ? Theme.accent : "transparent"
                    }

                    Text {
                        text: name; font.family: Theme.mono; font.pixelSize: Theme.t12
                        color: name === currentDb ? Theme.accent : Theme.fg
                        font.weight: name === currentDb ? Font.DemiBold : Font.Normal
                        Layout.fillWidth: true; elide: Text.ElideRight
                    }

                    Text {
                        text: name === currentDb ? "current" : ""
                        font.pixelSize: Theme.t11; color: Theme.fgMuted
                    }
                }

                MouseArea {
                    id: mouseArea; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        databaseSelected(name)
                        dbSwitcher.close()
                    }
                }
            }
        }

        // Empty
        Text {
            visible: dbModel.count === 0
            text: "No databases found"; font.pixelSize: Theme.t12; color: Theme.fgMuted
            Layout.alignment: Qt.AlignHCenter; Layout.margins: 16
        }
    }

    onOpened: {
        searchInput.text = ""
        filterList()
        searchInput.forceActiveFocus()
    }

    function filterList() {
        dbModel.clear()
        var q = searchInput.text.toLowerCase()
        for (var i = 0; i < databases.length; i++) {
            if (q === "" || databases[i].toLowerCase().indexOf(q) >= 0)
                dbModel.append({ name: databases[i] })
        }
    }
}
