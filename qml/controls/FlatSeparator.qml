import QtQuick

Rectangle {
    id: root

    property int orientation: Qt.Horizontal  // Qt.Horizontal or Qt.Vertical

    implicitWidth: orientation === Qt.Horizontal ? parent.width : 1
    implicitHeight: orientation === Qt.Horizontal ? 1 : parent.height

    color: Theme.border
}
