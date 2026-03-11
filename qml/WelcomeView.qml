import QtQuick
import QtQuick.Layouts

Rectangle {
    color: Theme.bg

    ColumnLayout {
        anchors.centerIn: parent; spacing: Theme.s24

        // Logo
        Item {
            Layout.alignment: Qt.AlignHCenter; width: 56; height: 56

            Rectangle {
                anchors.fill: parent; radius: 14
                gradient: Gradient { GradientStop { position: 0; color: "#6366f1" }; GradientStop { position: 1; color: "#8b5cf6" } }
                Text { anchors.centerIn: parent; text: "T"; font.pixelSize: 24; font.weight: Font.Bold; color: "#fff" }
            }

            Rectangle { anchors.centerIn: parent; width: 72; height: 72; radius: 18; color: "transparent"; border.width: 1; border.color: Qt.rgba(0.4, 0.4, 1, 0.08) }
        }

        ColumnLayout {
            spacing: Theme.s4; Layout.alignment: Qt.AlignHCenter
            Text { text: "Welcome to TableMax"; font.family: Theme.sans; font.pixelSize: Theme.t24; font.weight: Font.Bold; color: Theme.fg; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Modern database management"; font.family: Theme.sans; font.pixelSize: Theme.t14; color: Theme.fgMuted; Layout.alignment: Qt.AlignHCenter }
        }

        // Actions
        RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: Theme.s12

            Repeater {
                model: [
                    { icon: "+", label: "New Connection", action: "conn" },
                    { icon: "▶", label: "New Query", action: "tab" }
                ]

                Rectangle {
                    width: 160; height: 72; radius: Theme.r8
                    color: cardMa.containsMouse ? Theme.bgHover : "transparent"
                    border.width: 1; border.color: cardMa.containsMouse ? Theme.borderLight : Theme.border
                    Behavior on color { ColorAnimation { duration: Theme.normal } }
                    Behavior on border.color { ColorAnimation { duration: Theme.normal } }

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: Theme.s6
                        Text { text: modelData.icon; font.pixelSize: 18; color: Theme.accent; Layout.alignment: Qt.AlignHCenter }
                        Text { text: modelData.label; font.family: Theme.sans; font.pixelSize: Theme.t12; font.weight: Font.Medium; color: Theme.fg; Layout.alignment: Qt.AlignHCenter }
                    }

                    MouseArea {
                        id: cardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (modelData.action === "conn") connDialog.open(); else tabManager.addTab() }
                    }
                }
            }
        }

        // Shortcuts
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: Theme.s6

            Repeater {
                model: [ { k: "Ctrl+N", d: "New tab" }, { k: "Ctrl+B", d: "Toggle sidebar" }, { k: "Ctrl+Enter", d: "Execute" }, { k: "Ctrl+W", d: "Close tab" } ]

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: Theme.s8
                    Rectangle {
                        height: 18; width: skText.implicitWidth + 10; radius: Theme.r4; color: Theme.bgSurface; border.width: 1; border.color: Theme.border
                        Text { id: skText; anchors.centerIn: parent; text: modelData.k; font.family: Theme.mono; font.pixelSize: 9; color: Theme.fgDim }
                    }
                    Text { text: modelData.d; font.family: Theme.sans; font.pixelSize: Theme.t11; color: Theme.fgDim }
                }
            }
        }
    }
}
