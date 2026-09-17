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

let afterClose = GridLayout.frames(count: 3, within: bounds, gap: 10)
expect(afterClose.count == 3, "closing a window should yield a complete three-window layout")
expect(afterClose[2].width > afterClose[0].width, "remaining final-row window should expand after close")

print("GridLayout tests passed (1, 3, 4, and 5 window cases).")
