import AppKit

final class HeatmapStatusView: NSView {
    private var sessionPercent: Double = 0
    private var weeklyPercent: Double = 0

    private let gridSize = 3
    private let cellSize: CGFloat = 5
    private let cellGap: CGFloat = 1
    private let groupGap: CGFloat = 4

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let gridWidth = CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * cellGap
        let totalWidth = gridWidth * 2 + groupGap
        let totalHeight = gridWidth

        let originX = (bounds.width - totalWidth) / 2
        let originY = (bounds.height - totalHeight) / 2

        drawGrid(percent: sessionPercent, color: .systemGreen, origin: CGPoint(x: originX, y: originY))
        drawGrid(percent: weeklyPercent, color: .systemOrange, origin: CGPoint(x: originX + gridWidth + groupGap, y: originY))
    }

    private func drawGrid(percent: Double, color: NSColor, origin: CGPoint) {
        let filledCount = Int((percent / 100.0) * Double(gridSize * gridSize) + 0.5)

        // Fill order: column by column (left→right), bottom→top within each column
        for cellIndex in 0..<(gridSize * gridSize) {
            let col = cellIndex / gridSize
            let row = cellIndex % gridSize

            let x = origin.x + CGFloat(col) * (cellSize + cellGap)
            let y = origin.y + CGFloat(row) * (cellSize + cellGap)
            let rect = NSRect(x: x, y: y, width: cellSize, height: cellSize)

            if cellIndex < filledCount {
                color.setFill()
            } else {
                color.withAlphaComponent(0.15).setFill()
            }

            let path = NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1)
            path.fill()
        }
    }

    func update(sessionPercent: Double, weeklyPercent: Double) {
        self.sessionPercent = sessionPercent
        self.weeklyPercent = weeklyPercent
        needsDisplay = true
    }
}
