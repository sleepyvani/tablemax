import QtQuick

/*
    DashedLine: 
    Replaces standard 1px Rectangle borders with technical dashed lines.
*/
Canvas {
    id: root
    property color color: Theme.border
    property int dashLength: 4
    property int dashSpace: 4
    property bool vertical: root.width < root.height

    // Optimization for static views
    renderStrategy: Canvas.Threaded
    antialiasing: false

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.beginPath()
        
        // QML Canvas supports setLineDash
        ctx.setLineDash([root.dashLength, root.dashSpace])
        ctx.lineWidth = 1
        ctx.strokeStyle = root.color
        
        // Ensure crisp lines by rendering on half-pixels
        if (root.vertical) {
            var x = Math.floor(width / 2) + 0.5
            ctx.moveTo(x, 0)
            ctx.lineTo(x, height)
        } else {
            var y = Math.floor(height / 2) + 0.5
            ctx.moveTo(0, y)
            ctx.lineTo(width, y)
        }
        ctx.stroke()
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    Connections {
        target: Theme
        function onThemeChanged() {
            canvas.requestPaint()
        }
    }
}
