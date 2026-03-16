import QtQuick

/*
    BlueprintGrid:
    Draws a technical-style grid background on the canvas.
*/
Item {
    id: root
    property int gridSize: 32
    property color gridColor: Theme.borderLight
    property real gridOpacity: 0.3

    Connections {
        target: Theme
        function onThemeChanged() {
            canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        // Optimize canvas rendering
        renderStrategy: Canvas.Threaded
        antialiasing: false

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            
            ctx.beginPath()
            ctx.lineWidth = 1
            ctx.strokeStyle = root.gridColor
            ctx.globalAlpha = root.gridOpacity
            var step = root.gridSize;

            for (var x = step; x < width; x += step) {
                ctx.moveTo(x, 0)
                ctx.lineTo(x, height)
            }
            for (var y = step; y < height; y += step) {
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
            }
            ctx.stroke()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
}
