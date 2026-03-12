import QtQuick
import QtQuick.Layouts
import "DbHelper.js" as DB
import "FormatHelper.js" as Fmt

Rectangle {
    Layout.fillWidth: true; Layout.preferredHeight: 24; color: Theme.bgElevated

    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }

    RowLayout {
        anchors.fill: parent; anchors.leftMargin: Theme.s12; anchors.rightMargin: Theme.s12; spacing: Theme.s8

        // Connection info
        RowLayout {
            spacing: 4
            Rectangle {
                width: 5; height: 5; radius: 3
                color: databaseService && databaseService.connected ? Theme.success : Theme.fgDim
                opacity: databaseService && databaseService.connected ? 1 : 0.3
            }
            Text {
                text: {
                    if (!databaseService || !databaseService.connected) return "No connection"
                    var c = connectionManager.get(connectionManager.activeIndex)
                    return DB.displayName(c ? c.dbType : "") + " · " + (c && c.name ? c.name : "")
                }
                font.family: Theme.sans; font.pixelSize: 10; color: Theme.fgDim
            }
        }

        Rectangle { width: 1; height: 10; color: Theme.border; opacity: 0.5 }

        // Result info
        Text {
            text: resultModel && resultModel.totalRows > 0
                ? resultModel.totalRows + " rows × " + resultModel.totalColumns + " cols" : "Ready"
            font.family: Theme.mono; font.pixelSize: 10; color: Theme.fgDim
        }

        Rectangle { width: 1; height: 10; color: Theme.border; opacity: 0.5; visible: _execTime.visible }

        // Last execution time
        Text {
            id: _execTime
            visible: databaseService && databaseService.lastExecTime > 0
            text: databaseService && databaseService.lastExecTime > 0
                ? Fmt.formatExecTime(databaseService.lastExecTime)
                : ""
            font.family: Theme.mono; font.pixelSize: 10; color: Theme.fgDim
        }

        // Query mode badge
        Rectangle {
            width: 1; height: 10; color: Theme.border; opacity: 0.5
            visible: databaseService && databaseService.connected
        }
        Rectangle {
            height: 14; width: _qmText.implicitWidth + 8; radius: Theme.r4
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06)
            visible: databaseService && databaseService.connected
            Text {
                id: _qmText; anchors.centerIn: parent
                text: {
                    if (!connectionManager) return ""
                    var c = connectionManager.get(connectionManager.activeIndex)
                    return DB.queryMode(c ? c.dbType : "")
                }
                font.family: Theme.mono; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.accent
            }
        }

        Item { Layout.fillWidth: true }

        // Error indicator
        Text {
            text: "●"; font.pixelSize: 7
            color: databaseService && databaseService.error !== "" ? Theme.error : "transparent"
            visible: databaseService && databaseService.error !== ""
        }

        // Theme toggle
        Rectangle {
            Layout.preferredWidth: 18; Layout.preferredHeight: 16
            radius: Theme.r4
            color: themeMa.containsMouse ? Theme.bgHover : "transparent"
            Behavior on color { ColorAnimation { duration: 80 } }

            Text {
                anchors.centerIn: parent
                text: Theme.darkMode ? "☾" : "☀"
                font.pixelSize: 9; color: Theme.fgMuted
            }

            MouseArea {
                id: themeMa; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Theme.toggleTheme()
            }
        }

        Rectangle { width: 1; height: 10; color: Theme.border; opacity: 0.5 }

        Text { text: "v0.2.0"; font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim; opacity: 0.4 }
    }
}
