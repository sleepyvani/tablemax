import QtQuick
import QtQuick.Layouts

Rectangle {
    Layout.fillWidth: true
    height: 26
    color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.15)

    Rectangle {
        anchors.top: parent.top
        width: parent.width; height: 1
        color: Theme.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Connection info
        Text {
            text: {
                if (!databaseService.connected) return "No connection"
                var c = connectionManager.get(connectionManager.activeIndex)
                return (c.dbType || "").toUpperCase() + " — " + (c.name || "")
            }
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: Theme.mutedForeground
        }

        Rectangle { width: 1; height: 12; color: Theme.border }

        // Row count
        Text {
            text: resultModel.totalRows > 0
                ? resultModel.totalRows + " rows × " + resultModel.totalColumns + " cols"
                : "Ready"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: Theme.mutedForeground
        }

        Item { Layout.fillWidth: true }

        // Loading spinner
        Text {
            text: "⟳"
            font.pixelSize: 11
            color: Theme.mutedForeground
            visible: databaseService.loading

            RotationAnimation on rotation {
                from: 0; to: 360
                duration: 1000
                loops: Animation.Infinite
                running: databaseService.loading
            }
        }

        // Error indicator
        Text {
            text: "● Error"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: "#ef4444"
            visible: databaseService.error !== ""
        }

        // Version
        Text {
            text: "v0.2.0"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: Theme.mutedForeground
            opacity: 0.4
        }
    }
}
