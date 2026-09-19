import Foundation
import CoreGraphics

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func overlaps(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
    let intersection = lhs.intersection(rhs)
    return !intersection.isNull && intersection.width > 0.5 && intersection.height > 0.5
}

let bounds = CGRect(x: 0, y: 0, width: 1200, height: 800)

let one = GridLayout.frames(count: 1, within: bounds, gap: 10)
expect(one.count == 1, "one window should produce one frame")
expect(one[0].width > 1100 && one[0].height > 700, "one window should fill the usable screen")

let four = GridLayout.frames(count: 4, within: bounds, gap: 10)
expect(four.count == 4, "four windows should produce four frames")
expect(Set(four.map { Int($0.width) }).count == 1, "four-window layout should use equal widths")
expect(Set(four.map { Int($0.height) }).count == 1, "four-window layout should use equal heights")

for index in four.indices {
    expect(bounds.contains(four[index]), "frame \(index) must remain inside bounds")
    for other in four.indices where other > index {
        expect(!overlaps(four[index], four[other]), "frames \(index) and \(other) must not overlap")
    }
}

let five = GridLayout.frames(count: 5, within: bounds, gap: 10)
expect(five.count == 5, "five windows should produce five frames")
expect(five[3].width > five[0].width, "incomplete final row should use the available width")

let six = GridLayout.frames(count: 6, within: bounds, gap: 10)
expect(six.count == 6, "six windows should produce six frames")
let sixWidths = six.map { Int($0.width) }
let sixHeights = six.map { Int($0.height) }
expect((sixWidths.max() ?? 0) - (sixWidths.min() ?? 0) <= 1, "six-window column widths should differ by at most one pixel")
expect((sixHeights.max() ?? 0) - (sixHeights.min() ?? 0) <= 1, "six-window row heights should differ by at most one pixel")

let macBookVisibleFrame = CGRect(x: 0, y: 80, width: 1470, height: 843)
let sixZeroGap = GridLayout.frames(count: 6, within: macBookVisibleFrame, gap: 0)
expect(sixZeroGap.count == 6, "zero-gap six-window layout should produce six frames")
for index in sixZeroGap.indices {
    expect(macBookVisibleFrame.contains(sixZeroGap[index]), "zero-gap frame \(index) must remain inside the visible screen")
    for other in sixZeroGap.indices where other > index {
        expect(!overlaps(sixZeroGap[index], sixZeroGap[other]), "zero-gap frames \(index) and \(other) must not overlap")
    }
}
expect(sixZeroGap[0].maxX == sixZeroGap[1].minX, "top-row windows should touch exactly")
expect(sixZeroGap[0].minY == sixZeroGap[3].maxY, "top and bottom rows should touch exactly")

let fourClockwise = GridLayout.clockwiseFrames(count: 4, within: bounds, gap: 0)
expect(fourClockwise[0].minX < fourClockwise[1].minX && fourClockwise[0].minY == fourClockwise[1].minY, "clockwise order should begin across the top row")
expect(fourClockwise[2].minX > fourClockwise[3].minX && fourClockwise[2].minY == fourClockwise[3].minY, "clockwise order should return across the bottom row")
expect(fourClockwise[0].minY > fourClockwise[2].minY, "top row should precede bottom row")

let sixClockwise = GridLayout.clockwiseFrames(count: 6, within: macBookVisibleFrame, gap: 0)
expect(sixClockwise[0].minX < sixClockwise[1].minX && sixClockwise[1].minX < sixClockwise[2].minX, "six-window order should move left to right across the top")
expect(sixClockwise[3].minX > sixClockwise[4].minX && sixClockwise[4].minX > sixClockwise[5].minX, "six-window order should move right to left across the bottom")

let afterClose = GridLayout.frames(count: 3, within: bounds, gap: 10)
expect(afterClose.count == 3, "closing a window should yield a complete three-window layout")
expect(afterClose[2].width > afterClose[0].width, "remaining final-row window should expand after close")

print("GridLayout tests passed (1, 3, 4, 5, and 6 window cases).")
