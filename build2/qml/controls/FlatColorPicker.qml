import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property color selectedColor: "#7c3aed"

    signal colorSelected(color c)

    implicitWidth: 220
    implicitHeight: colorLayout.implicitHeight + 24
    radius: Theme.radius
    color: "transparent"

    property var presetColors: [
        "#ef4444", "#f97316", "#f59e0b", "#eab308",
        "#84cc16", "#22c55e", "#10b981", "#14b8a6",
        "#06b6d4", "#0ea5e9", "#3b82f6", "#6366f1",
        "#8b5cf6", "#a855f7", "#d946ef", "#ec4899",
    ]

    ColumnLayout {
        id: colorLayout
        anchors.fill: parent
        anchors.margins: 0
        spacing: 8

        Text {
            text: root.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: Theme.foreground
            visible: text.length > 0
        }

        GridLayout {
            columns: 8
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: root.presetColors

                Rectangle {
                    width: 20
                    height: 20
                    radius: Theme.radiusFull
                    color: modelData
                    border.width: root.selectedColor === modelData ? 2 : 0
                    border.color: Theme.foreground

                    scale: colorMouse.containsMouse ? 1.2 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutBack }
                    }
                    Behavior on border.width {
                        NumberAnimation { duration: Theme.durationFast }
                    }

                    MouseArea {
                        id: colorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedColor = modelData
                            root.colorSelected(modelData)
                        }
                    }
                }
            }
        }

        // Preview
        RowLayout {
            spacing: 8

            Rectangle {
                width: 32
                height: 32
                radius: Theme.radius
                color: root.selectedColor
            }

            Text {
                text: root.selectedColor
                font.family: Theme.monoFamily
                font.pixelSize: Theme.fontSizeSm
                color: Theme.mutedForeground
            }
        }
    }
}
