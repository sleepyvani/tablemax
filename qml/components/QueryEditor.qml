import QtQuick
import QtQuick.Layouts

Rectangle {
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Toolbar ───
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                // Run button
                Rectangle {
                    Layout.preferredWidth: runRow.implicitWidth + 20
                    Layout.preferredHeight: 28
                    radius: Theme.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: runMouse.containsMouse ? "#4f46e5" : "#6366f1" }
                        GradientStop { position: 1.0; color: runMouse.containsMouse ? "#7c3aed" : "#8b5cf6" }
                    }

                    RowLayout {
                        id: runRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "▶"
                            font.pixelSize: 10
                            color: "#ffffff"
                        }
                        Text {
                            text: "Run"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.DemiBold
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        id: runMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var idx = tabManager.currentIndex
                            var tab = tabManager.getTab(idx)
                            if (tab.content) console.log("Execute:", tab.content)
                        }
                    }

                    scale: runMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutCubic } }
                }

                FlatKbd { text: "Ctrl+Enter" }

                Item { Layout.fillWidth: true }

                // Format button
                Rectangle {
                    width: 28; height: 28
                    radius: Theme.radiusSm
                    color: fmtMouse.containsMouse ? Theme.muted : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "{ }"
                        font.family: Theme.monoFamily
                        font.pixelSize: 10
                        color: Theme.mutedForeground
                    }

                    MouseArea {
                        id: fmtMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // Clear button
                Rectangle {
                    width: 28; height: 28
                    radius: Theme.radiusSm
                    color: clrMouse.containsMouse ? Theme.muted : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⌫"
                        font.pixelSize: 13
                        color: Theme.mutedForeground
                    }

                    MouseArea {
                        id: clrMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editorArea.text = ""
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: Theme.border
            }
        }

        // ─── Editor with line numbers ───
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Line numbers
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 44
                color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.3)

                ListView {
                    anchors.fill: parent
                    anchors.topMargin: 12
                    model: Math.max(1, editorArea.text.split("\n").length)
                    interactive: false
                    contentY: editorFlick.contentY

                    delegate: Item {
                        width: 44
                        height: editorArea.font.pixelSize + 7

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: index + 1
                            font.family: Theme.monoFamily
                            font.pixelSize: 11
                            color: Theme.mutedForeground
                            opacity: 0.5
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Theme.border
                opacity: 0.5
            }

            // Editor
            Flickable {
                id: editorFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: editorArea.implicitHeight + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                TextEdit {
                    id: editorArea
                    width: parent.width
                    topPadding: 12
                    leftPadding: 12
                    rightPadding: 12
                    bottomPadding: 12
                    font.family: Theme.monoFamily
                    font.pixelSize: 13
                    color: Theme.foreground
                    selectionColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                    selectedTextColor: Theme.foreground
                    wrapMode: TextEdit.NoWrap
                    selectByMouse: true
                    focus: true

                    onTextChanged: {
                        tabManager.updateContent(tabManager.currentIndex, text)
                    }

                    // Placeholder
                    Text {
                        anchors.fill: parent
                        anchors.topMargin: 12
                        anchors.leftMargin: 12
                        text: "-- Write your SQL query here...\n-- Press Ctrl+Enter to execute"
                        font: parent.font
                        color: Theme.mutedForeground
                        opacity: 0.4
                        visible: !parent.text && !parent.focus
                    }

                    // Blinking cursor color
                    cursorDelegate: Rectangle {
                        width: 2
                        color: "#8b5cf6"
                        visible: parent.activeFocus

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0; duration: 500 }
                            NumberAnimation { to: 1; duration: 500 }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4; radius: 2; color: Theme.border
                    }
                }
            }
        }
    }

    // Ctrl+Enter handler
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return && (event.modifiers & Qt.ControlModifier)) {
            runMouse.clicked(undefined)
            event.accepted = true
        }
    }
}
