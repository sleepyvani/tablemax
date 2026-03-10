import QtQuick
import QtQuick.Layouts

Rectangle {
    id: sidebar
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Header ───
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            Layout.leftMargin: 14
            Layout.rightMargin: 10
            spacing: 6

            // Logo
            Rectangle {
                width: 24; height: 24
                radius: 6
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#6366f1" }
                    GradientStop { position: 1.0; color: "#8b5cf6" }
                }

                Text {
                    anchors.centerIn: parent
                    text: "T"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: "#ffffff"
                }
            }

            Text {
                text: "TableMax"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeMd
                font.weight: Font.DemiBold
                color: Theme.foreground
                Layout.fillWidth: true
            }

            // Add connection
            Rectangle {
                width: 26; height: 26
                radius: Theme.radiusSm
                color: addMouse.containsMouse ? Theme.muted : "transparent"
                border.width: addMouse.containsMouse ? 1 : 0
                border.color: Theme.border
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: 16
                    font.weight: Font.Light
                    color: Theme.mutedForeground
                }

                MouseArea {
                    id: addMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: connectionDialog.open()
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        // ─── Search ───
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.margins: 8
            radius: Theme.radius
            color: Qt.rgba(Theme.input.r, Theme.input.g, Theme.input.b, 0.3)
            border.width: 1
            border.color: searchFocused ? Theme.ring : Theme.input

            Behavior on border.color { ColorAnimation { duration: Theme.duration } }

            property bool searchFocused: false

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 6

                Text {
                    text: "⌕"
                    font.pixelSize: 13
                    color: Theme.mutedForeground
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.foreground
                    selectByMouse: true
                    clip: true
                    onFocusChanged: parent.parent.searchFocused = focus

                    Text {
                        anchors.fill: parent
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "Search connections..."
                        font: parent.font
                        color: Theme.mutedForeground
                        visible: !parent.text && !parent.focus
                    }
                }
            }
        }

        // ─── Section: Connections ───
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.leftMargin: 14
            color: "transparent"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "CONNECTIONS"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Medium
                font.letterSpacing: 1.2
                color: Theme.mutedForeground
                opacity: 0.6
            }
        }

        // ─── Connection List ───
        FlatScrollArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: parent.height * 0.35

            ColumnLayout {
                width: parent.width
                spacing: 1

                Repeater {
                    model: connectionManager.connections

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        radius: Theme.radiusSm

                        property bool isActive: connectionManager.activeIndex === index
                        property bool isHovered: connMouse.containsMouse

                        color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                             : isHovered ? Qt.rgba(1, 1, 1, 0.02)
                             : "transparent"

                        border.width: isActive ? 1 : 0
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 10

                            // Color dot with glow when connected
                            Rectangle {
                                width: 8; height: 8
                                radius: 4
                                color: modelData.color || "#6366f1"

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width + 4
                                    height: parent.height + 4
                                    radius: width / 2
                                    color: parent.color
                                    opacity: isActive && databaseService.connected ? 0.3 : 0
                                    Behavior on opacity { NumberAnimation { duration: Theme.duration } }
                                }
                            }

                            ColumnLayout {
                                spacing: 1
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.name || "Unnamed"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: isActive ? Font.Medium : Font.Normal
                                    color: isActive ? Theme.foreground : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.85)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: (modelData.dbType || "").toUpperCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    font.letterSpacing: 0.5
                                    color: Theme.mutedForeground
                                    opacity: 0.7
                                }
                            }

                            // Delete button
                            Rectangle {
                                width: 22; height: 22
                                radius: Theme.radiusSm
                                color: delMouse.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.15) : "transparent"
                                visible: isHovered || isActive

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 9
                                    color: delMouse.containsMouse ? "#ef4444" : Theme.mutedForeground
                                }

                                MouseArea {
                                    id: delMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: connectionManager.remove(index)
                                }
                            }
                        }

                        MouseArea {
                            id: connMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: -1
                            onClicked: {
                                connectionManager.activeIndex = index
                                databaseService.connect(modelData.dbType, modelData.connectionString)
                                schemaService.refresh(databaseService)
                            }
                        }
                    }
                }

                // Empty state
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    visible: connectionManager.connections.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "No connections"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.mutedForeground
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Click + to add one"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.mutedForeground
                            opacity: 0.6
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

        // ─── Section: Schema ───
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.leftMargin: 14
            Layout.topMargin: 4
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Text {
                    text: "SCHEMA"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    font.letterSpacing: 1.2
                    color: Theme.mutedForeground
                    opacity: 0.6
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 22; height: 22
                    radius: Theme.radiusSm
                    color: refreshMouse.containsMouse ? Theme.muted : "transparent"
                    Layout.rightMargin: 8

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        font.pixelSize: 12
                        color: Theme.mutedForeground
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: schemaService.refresh(databaseService)
                    }
                }
            }
        }

        // ─── Schema Tree ───
        SchemaTree {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
