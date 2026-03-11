import QtQuick
import QtQuick.Layouts

Rectangle {
    Layout.fillWidth: true; Layout.preferredHeight: 24; color: Theme.bgElevated

    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }

    RowLayout {
        anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s12

        Text {
            text: {
                if (!databaseService || !databaseService.connected) return "No connection"
                var c = connectionManager.get(connectionManager.activeIndex)
                return (c && c.dbType ? c.dbType.toUpperCase() : "") + " · " + (c && c.name ? c.name : "")
            }
            font.family: Theme.sans; font.pixelSize: 10; color: Theme.fgDim
        }

        Rectangle { width: 1; height: 10; color: Theme.border }

        Text {
            text: resultModel && resultModel.totalRows > 0 ? resultModel.totalRows + " rows × " + resultModel.totalColumns + " cols" : "Ready"
            font.family: Theme.mono; font.pixelSize: 10; color: Theme.fgDim
        }

        Item { Layout.fillWidth: true }

        // Theme toggle
        Rectangle {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 16
            radius: Theme.r4
            color: themeMa.containsMouse ? Theme.bgHover : "transparent"

            Text {
                anchors.centerIn: parent
                text: Theme.darkMode ? "☾" : "☀"
                font.pixelSize: 10
                color: Theme.fgMuted
            }

            MouseArea {
                id: themeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Theme.toggleTheme()
            }
        }

        Rectangle { width: 1; height: 10; color: Theme.border }

        Text {
            text: "●"; font.pixelSize: 7
            color: databaseService && databaseService.error !== "" ? Theme.error : "transparent"
        }

        Text { text: "v0.2.0"; font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim; opacity: 0.4 }
    }
}
