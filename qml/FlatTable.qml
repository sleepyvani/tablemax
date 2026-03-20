import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var columns: []       // ["Name", "Type", "Nullable"]
    property var rows: []          // [["id", "int4", "NO"], ["name", "varchar", "YES"]]
    property int rowHeight: 32
    property int headerHeight: 36

    implicitHeight: headerHeight + rows.length * rowHeight + 2

    // Header
    Rectangle {
        id: header
        width: parent.width
        height: headerHeight
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04)

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: root.columns

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        font.family: Theme.sans
                        font.pixelSize: Theme.t10
                        font.weight: Font.DemiBold
                        color: Theme.fgMuted
                        letterSpacing: 0.5
                    }

                    // Right border
                    DashedLine {
                        anchors.right: parent.right
                        width: 1
                        height: parent.height
                        color: Theme.border
                        visible: index < root.columns.length - 1
                    }
                }
            }
        }
    }

    // Rows
    Column {
        y: headerHeight
        width: parent.width

        Repeater {
            model: root.rows

            Rectangle {
                width: root.width
                height: root.rowHeight
                color: rowMouse.containsMouse ? Theme.bgHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                // Bottom border
                DashedLine {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: modelData

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: modelData
                                font.family: Theme.sans
                                font.pixelSize: Theme.t12
                                color: Theme.fg
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }

    // Border
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Theme.border
        radius: Theme.r6
    }
}
