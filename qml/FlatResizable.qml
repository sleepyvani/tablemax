import QtQuick

Item {
    id: root

    property real splitPosition: 0.5     // 0.0 to 1.0
    property int orientation: Qt.Vertical // Qt.Vertical = top/bottom, Qt.Horizontal = left/right
    property int handleSize: 6
    property int minSize: 60

    property alias first: firstLoader.sourceComponent
    property alias second: secondLoader.sourceComponent

    property bool firstVisible: true
    property bool secondVisible: true

    // First panel
    Loader {
        id: firstLoader
        visible: root.firstVisible
        x: 0
        y: 0
        width: !root.firstVisible ? 0 : (!root.secondVisible ? root.width : (root.orientation === Qt.Vertical ? root.width : root.width * root.splitPosition - root.handleSize / 2))
        height: !root.firstVisible ? 0 : (!root.secondVisible ? root.height : (root.orientation === Qt.Vertical ? root.height * root.splitPosition - root.handleSize / 2 : root.height))
    }

    // Handle
    Rectangle {
        id: handle
        visible: root.firstVisible && root.secondVisible
        color: dragArea.containsMouse || dragArea.drag.active ? Qt.lighter(Theme.border, 1.5) : Theme.border

        x: root.orientation === Qt.Vertical ? 0 : firstLoader.width
        y: root.orientation === Qt.Vertical ? firstLoader.height : 0
        width: root.orientation === Qt.Vertical ? root.width : root.handleSize
        height: root.orientation === Qt.Vertical ? root.handleSize : root.height

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

        // Center dot
        Rectangle {
            anchors.centerIn: parent
            width: root.orientation === Qt.Vertical ? 32 : 3
            height: root.orientation === Qt.Vertical ? 3 : 32
            radius: Theme.radiusFull
            color: parent.color
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: root.orientation === Qt.Vertical ? Qt.SplitVCursor : Qt.SplitHCursor

            drag.target: null

            property real startPos: 0

            onPressed: (mouse) => {
                startPos = root.orientation === Qt.Vertical ? mouse.y : mouse.x
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return
                let delta = root.orientation === Qt.Vertical
                    ? (mouse.y - startPos) / root.height
                    : (mouse.x - startPos) / root.width
                let newPos = root.splitPosition + delta
                let minRatio = root.minSize / (root.orientation === Qt.Vertical ? root.height : root.width)
                root.splitPosition = Math.max(minRatio, Math.min(1.0 - minRatio, newPos))
            }
        }
    }

    // Second panel
    Loader {
        id: secondLoader
        visible: root.secondVisible
        x: !root.firstVisible ? 0 : (root.orientation === Qt.Vertical ? 0 : handle.x + root.handleSize)
        y: !root.firstVisible ? 0 : (root.orientation === Qt.Vertical ? handle.y + root.handleSize : 0)
        width: root.orientation === Qt.Vertical ? root.width : root.width - x
        height: root.orientation === Qt.Vertical ? root.height - y : root.height
    }
}
