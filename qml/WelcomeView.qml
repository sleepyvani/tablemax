import QtQuick
import QtQuick.Layouts

Rectangle {
    color: Theme.bg

    // Subtle grid pattern — blueprint feel
    Canvas {
        anchors.fill: parent
        opacity: Theme.darkMode ? 0.03 : 0.04
        onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = Theme.darkMode ? "#ffffff" : "#000000"
            ctx.lineWidth = 0.5
            var step = 24
            for (var x = 0; x < width; x += step) {
                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
            }
            for (var y = 0; y < height; y += step) {
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
            }
        }
        Component.onCompleted: requestPaint()
        Connections { target: Theme; function onThemeChanged() { requestPaint() } }
    }

    ColumnLayout {
        anchors.centerIn: parent; spacing: 32

        // Logo
        Item {
            Layout.alignment: Qt.AlignHCenter; width: 64; height: 64

            Rectangle {
                anchors.fill: parent; radius: 16
                gradient: Gradient {
                    GradientStop { position: 0; color: "#6366f1" }
                    GradientStop { position: 1; color: "#8b5cf6" }
                }

                Text {
                    anchors.centerIn: parent; text: "T"
                    font.pixelSize: 28; font.weight: Font.Bold; color: "#fff"
                    font.family: Theme.sans
                }
            }

            // Glow ring
            Rectangle {
                anchors.centerIn: parent; width: 80; height: 80; radius: 20
                color: "transparent"; border.width: 1
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
            }
            Rectangle {
                anchors.centerIn: parent; width: 96; height: 96; radius: 24
                color: "transparent"; border.width: 1
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.05)
            }
        }

        // Title
        ColumnLayout {
            spacing: 6; Layout.alignment: Qt.AlignHCenter

            Text {
                text: "TableMax"
                font.family: Theme.sans; font.pixelSize: 28; font.weight: Font.Bold
                color: Theme.fg; Layout.alignment: Qt.AlignHCenter
                font.letterSpacing: -0.5
            }
            Text {
                text: "Modern database management tool"
                font.family: Theme.sans; font.pixelSize: 14; color: Theme.fgMuted
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Actions
        RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 12

            Repeater {
                model: [
                    { icon: "+", label: "New Connection", desc: "Add a database", action: "conn" },
                    { icon: "▷", label: "New Query", desc: "Write SQL", action: "tab" }
                ]

                Rectangle {
                    width: 180; height: 88; radius: Theme.r8
                    color: cardMa.containsMouse ? Theme.bgHover : "transparent"
                    border.width: 1
                    border.color: cardMa.containsMouse ? Theme.borderLight : Theme.border

                    Behavior on color { ColorAnimation { duration: Theme.normal } }
                    Behavior on border.color { ColorAnimation { duration: Theme.normal } }

                    // Hover glow
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        color: "transparent"; border.width: 1
                        border.color: cardMa.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08) : "transparent"
                        Behavior on border.color { ColorAnimation { duration: Theme.normal } }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 8

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 28; height: 28; radius: Theme.r6
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                            border.width: 1; border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15)

                            Text {
                                anchors.centerIn: parent; text: modelData.icon
                                font.pixelSize: 14; color: Theme.accent
                            }
                        }

                        ColumnLayout {
                            spacing: 2; Layout.alignment: Qt.AlignHCenter

                            Text {
                                text: modelData.label; font.family: Theme.sans
                                font.pixelSize: 13; font.weight: Font.DemiBold
                                color: Theme.fg; Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: modelData.desc; font.family: Theme.sans
                                font.pixelSize: 11; color: Theme.fgDim
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    MouseArea {
                        id: cardMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (modelData.action === "conn") connDialog.open(); else tabManager.addTab() }
                    }
                }
            }
        }

        // Keyboard shortcuts
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 8

            Text {
                text: "KEYBOARD SHORTCUTS"
                font.family: Theme.sans; font.pixelSize: 9; font.weight: Font.DemiBold
                font.letterSpacing: 1.5; color: Theme.fgDim; opacity: 0.6
                Layout.alignment: Qt.AlignHCenter
            }

            Repeater {
                model: [
                    { k: "Ctrl+N", d: "New tab" },
                    { k: "Ctrl+B", d: "Toggle sidebar" },
                    { k: "Ctrl+Enter", d: "Execute query" },
                    { k: "Ctrl+T", d: "Toggle theme" },
                    { k: "Ctrl+W", d: "Close tab" }
                ]

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 10

                    Rectangle {
                        height: 20; width: skText.implicitWidth + 12; radius: Theme.r4
                        color: Theme.bgSurface; border.width: 1; border.color: Theme.border

                        Text {
                            id: skText; anchors.centerIn: parent; text: modelData.k
                            font.family: Theme.mono; font.pixelSize: 10; color: Theme.fgDim
                        }
                    }
                    Text {
                        text: modelData.d; font.family: Theme.sans
                        font.pixelSize: 12; color: Theme.fgDim
                    }
                }
            }
        }
    }
}
