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
    property int lineWidth: 1 // Added lineWidth property

    // Optimization for static views
    renderStrategy: Canvas.Threaded
    antialiasing: false

    onPaint: {
        var ctx = getContext("2d") // Use getContext directly
        ctx.clearRect(0, 0, width, height) // Use width/height directly
        ctx.beginPath()
        
        // QML Canvas supports setLineDash
        ctx.setLineDash([root.dashLength, root.dashSpace]) // Use root.dashLength, root.dashSpace
        ctx.lineWidth = root.lineWidth // Use root.lineWidth
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
