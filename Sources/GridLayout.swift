import Foundation
import CoreGraphics

struct GridLayout {
    static func frames(count: Int, within bounds: CGRect, gap: CGFloat = 10) -> [CGRect] {
        guard count > 0, bounds.width > 0, bounds.height > 0 else { return [] }

        let columnCount = Int(ceil(sqrt(Double(count))))
        let rowCount = Int(ceil(Double(count) / Double(columnCount)))
        let clampedGap = max(0, min(gap, min(bounds.width, bounds.height) / 8))
        let outerBounds = bounds.insetBy(dx: clampedGap, dy: clampedGap)
        let usableHeight = max(1, outerBounds.height - clampedGap * CGFloat(max(0, rowCount - 1)))
        let rawRowHeight = usableHeight / CGFloat(rowCount)

        var result: [CGRect] = []
        var remaining = count

        for row in 0..<rowCount {
            let itemsInRow = min(columnCount, remaining)
            guard itemsInRow > 0 else { break }

            let rowTop = outerBounds.maxY - CGFloat(row) * rawRowHeight - CGFloat(row) * clampedGap
            let rowBottom = outerBounds.maxY - CGFloat(row + 1) * rawRowHeight - CGFloat(row) * clampedGap
            let roundedTop = rowTop.rounded()
            let roundedBottom = rowBottom.rounded()
            let rowHeight = max(1, roundedTop - roundedBottom)

            let usableWidth = max(1, outerBounds.width - clampedGap * CGFloat(max(0, itemsInRow - 1)))
            let rawCellWidth = usableWidth / CGFloat(itemsInRow)

            for column in 0..<itemsInRow {
                let cellLeft = outerBounds.minX + CGFloat(column) * rawCellWidth + CGFloat(column) * clampedGap
                let cellRight = outerBounds.minX + CGFloat(column + 1) * rawCellWidth + CGFloat(column) * clampedGap
                let roundedLeft = cellLeft.rounded()
                let roundedRight = cellRight.rounded()

                result.append(
                    CGRect(
                        x: roundedLeft,
                        y: roundedBottom,
                        width: max(1, roundedRight - roundedLeft),
                        height: rowHeight
                    )
                )
            }
            remaining -= itemsInRow
        }
        return result
    }
}
