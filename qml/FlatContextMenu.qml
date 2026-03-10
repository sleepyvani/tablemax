import QtQuick
import QtQuick.Controls.Basic as T
import QtQuick.Layouts

T.Popup {
    id: root

    property alias menuModel: menuRepeater.model
    signal menuItemClicked(int index, string text)

    padding: 4
    implicitWidth: 180

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
        spacing: 2

        Repeater {
            id: menuRepeater

            delegate: Item {
                Layout.fillWidth: true
                implicitHeight: modelData === "-" ? 9 : 30

                Loader {
                    anchors.fill: parent
                    sourceComponent: modelData === "-" ? separatorComp : menuItemComp

                    Component {
                        id: separatorComp
                        Rectangle {
                            height: 1
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 4
                            color: Theme.border
                        }
                    }

                    Component {
                        id: menuItemComp
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: Theme.radiusSm
                            color: itemMouse.containsMouse ? Theme.accent : "transparent"

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
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.menuItemClicked(index, modelData)
                                    root.close()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
