import QtQuick

/*
    BlueprintCrosshair:
    Draws a tiny '+' mark at corners to simulate blueprint drafting aesthetics.
*/
Item {
    id: root
    property int size: 8
    property int thickness: 1
    property color color: Theme.fgDim
    property real opacityRatio: 0.6
    
    width: size
    height: size
    opacity: opacityRatio

    Rectangle {
        anchors.centerIn: parent
        width: root.thickness
        height: root.size
        color: root.color
    }
    
    Rectangle {
        anchors.centerIn: parent
        width: root.size
        height: root.thickness
        color: root.color
    }
}
