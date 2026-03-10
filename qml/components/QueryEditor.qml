import QtQuick
import QtQuick.Layouts

Rectangle {
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Toolbar
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.margins: 8
            spacing: 8

            FlatButton {
                text: "▶ Run"
                onClicked: {
                    // TODO: execute query via databaseService
                    var idx = tabManager.currentIndex
                    var tab = tabManager.getTab(idx)
                    console.log("Execute:", tab.content)
                }
            }

            FlatKbd { text: "Ctrl+Enter" }

            Item { Layout.fillWidth: true }

            FlatBadge {
                text: databaseService.connected ? "Connected" : "Disconnected"
                variant: databaseService.connected ? "success" : "outline"
            }
        }

        FlatSeparator { orientation: Qt.Horizontal }

        // Editor
        FlatTextArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: "SELECT * FROM ..."
            font.family: Theme.monoFamily
            font.pixelSize: Theme.fontSize

            onTextChanged: {
                tabManager.updateContent(tabManager.currentIndex, text)
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
                    // Execute query
                    event.accepted = true
                }
            }
        }
    }
}
