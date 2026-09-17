import Foundation
import CoreGraphics

struct GridLayout {
    static func frames(count: Int, within bounds: CGRect, gap: CGFloat = 10) -> [CGRect] {
        guard count > 0, bounds.width > 0, bounds.height > 0 else { return [] }

        let columnCount = Int(ceil(sqrt(Double(count))))
        let rowCount = Int(ceil(Double(count) / Double(columnCount)))
        let clampedGap = max(0, min(gap, min(bounds.width, bounds.height) / 8))
        let outerBounds = bounds.insetBy(dx: clampedGap, dy: clampedGap)
        let rowHeight = max(1, (outerBounds.height - clampedGap * CGFloat(max(0, rowCount - 1))) / CGFloat(rowCount))

        var result: [CGRect] = []
        var remaining = count

        for row in 0..<rowCount {
            let itemsInRow = min(columnCount, remaining)
            guard itemsInRow > 0 else { break }

            let cellWidth = max(1, (outerBounds.width - clampedGap * CGFloat(max(0, itemsInRow - 1))) / CGFloat(itemsInRow))
            let y = outerBounds.maxY - CGFloat(row + 1) * rowHeight - CGFloat(row) * clampedGap

            for column in 0..<itemsInRow {
                let x = outerBounds.minX + CGFloat(column) * (cellWidth + clampedGap)
                result.append(CGRect(x: x.rounded(), y: y.rounded(), width: cellWidth.rounded(), height: rowHeight.rounded()))
            }
            remaining -= itemsInRow
        }
        return result
    }
}
