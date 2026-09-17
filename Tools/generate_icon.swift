import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "Resources/TermosaicIcon-1024.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let canvas = NSRect(origin: .zero, size: size)
NSColor.clear.setFill()
canvas.fill()

let shell = NSBezierPath(roundedRect: canvas.insetBy(dx: 58, dy: 58), xRadius: 208, yRadius: 208)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.055, green: 0.105, blue: 0.145, alpha: 1),
    NSColor(calibratedRed: 0.035, green: 0.220, blue: 0.235, alpha: 1)
])!
gradient.draw(in: shell, angle: -52)

let panelColor = NSColor(calibratedWhite: 1, alpha: 0.94)
let lineColor = NSColor(calibratedRed: 0.09, green: 0.49, blue: 0.48, alpha: 1)
let paneSize = NSSize(width: 350, height: 350)
let origins = [
    NSPoint(x: 148, y: 526), NSPoint(x: 526, y: 526),
    NSPoint(x: 148, y: 148), NSPoint(x: 526, y: 148)
]

for (index, origin) in origins.enumerated() {
    let rect = NSRect(origin: origin, size: paneSize)
    panelColor.setFill()
    NSBezierPath(roundedRect: rect, xRadius: 62, yRadius: 62).fill()

    let prompt = NSBezierPath()
    prompt.lineWidth = 30
    prompt.lineCapStyle = .round
    lineColor.setStroke()
    let y = rect.midY + 20
    prompt.move(to: NSPoint(x: rect.minX + 78, y: y + 34))
    prompt.line(to: NSPoint(x: rect.minX + 126, y: y))
    prompt.line(to: NSPoint(x: rect.minX + 78, y: y - 34))
    prompt.stroke()

    let cursor = NSBezierPath()
    cursor.lineWidth = 28
    cursor.lineCapStyle = .round
    cursor.move(to: NSPoint(x: rect.minX + 154, y: y - 34))
    cursor.line(to: NSPoint(x: rect.minX + (index == 3 ? 246 : 220), y: y - 34))
    cursor.stroke()
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not create icon PNG\n", stderr)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: output))
