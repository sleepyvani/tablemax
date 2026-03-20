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
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fast }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: Theme.fast; easing.type: Easing.OutQuad }
        }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.fast }
    }

    background: Rectangle {
        color: Theme.bgSurface
        border.width: 1
        border.color: Theme.border
        radius: Theme.r8
        layer.enabled: true
        layer.effect: null

        // Shadow simulation via extra border
        Rectangle {
            anchors.fill: parent; anchors.margins: -1
            radius: Theme.r8 + 1
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.15)
            z: -1
        }
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
                            radius: Theme.r4
                            color: itemMouse.containsMouse ? Theme.bgHover : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.fast } }

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.s8
                                verticalAlignment: Text.AlignVCenter
                                text: modelData
                                font.family: Theme.sans
                                font.pixelSize: Theme.t12
                                color: Theme.fg
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
