import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

Item {
    id: root

    property alias triggerText: triggerBtn.text
    property alias menuModel: menuRepeater.model
    signal menuItemClicked(int index, string text)

    implicitWidth: triggerBtn.implicitWidth
    implicitHeight: triggerBtn.implicitHeight

    FlatButton {
        id: triggerBtn
        variant: "outline"
        anchors.fill: parent
        onClicked: popup.open()

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "▾"
            font.pixelSize: 10
            color: Theme.mutedForeground
        }
    }

    T.Popup {
        id: popup
        y: triggerBtn.height + 4
        width: Math.max(triggerBtn.width, 160)
        implicitHeight: menuColumn.implicitHeight + 8
        padding: 4

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationFast }
                NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: Theme.durationFast; easing.type: Easing.OutQuad }
            }
        }

        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationFast }
        }

        background: Rectangle {
            color: Theme.popover
            border.width: 1
            border.color: Theme.border
            radius: Theme.radiusMd
        }

        contentItem: ColumnLayout {
            id: menuColumn
            spacing: 2

            Repeater {
                id: menuRepeater

                delegate: Item {
                    Layout.fillWidth: true
                    implicitHeight: modelData === "-" ? 9 : 30

                    Loader {
                        anchors.fill: parent
                        sourceComponent: modelData === "-" ? sepComp : itemComp

                        Component {
                            id: sepComp
                            DashedLine {
                                height: 1
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 4; anchors.rightMargin: 4
                                color: Theme.border
                            }
                        }

                        Component {
                            id: itemComp
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: Theme.radiusSm
                                color: dropMouse.containsMouse ? Theme.accent : "transparent"

                                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.foreground
                                }

                                MouseArea {
                                    id: dropMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.menuItemClicked(index, modelData)
                                        popup.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
