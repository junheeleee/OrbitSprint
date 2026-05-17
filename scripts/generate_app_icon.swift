import AppKit

let size = CGSize(width: 1024, height: 1024)
let outputPath = "LumenRun/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(red: red, green: green, blue: blue, alpha: alpha)
}

func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat, points: Int, rotation: CGFloat = -.pi / 2) -> NSBezierPath {
    let path = NSBezierPath()
    for index in 0..<(points * 2) {
        let radius = index.isMultiple(of: 2) ? outer : inner
        let angle = CGFloat(index) / CGFloat(points * 2) * 2 * .pi + rotation
        let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        if index == 0 {
            path.move(to: point)
        } else {
            path.line(to: point)
        }
    }
    path.close()
    return path
}

func ellipsePath(center: CGPoint, width: CGFloat, height: CGFloat, rotationDegrees: CGFloat) -> NSBezierPath {
    let path = NSBezierPath(ovalIn: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
    var transform = AffineTransform()
    transform.translate(x: center.x, y: center.y)
    transform.rotate(byDegrees: rotationDegrees)
    path.transform(using: transform)
    return path
}

func signalLinePath(y: CGFloat, offset: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: 104, y: y))
    path.curve(
        to: CGPoint(x: 920, y: y + offset),
        controlPoint1: CGPoint(x: 320, y: y - 36),
        controlPoint2: CGPoint(x: 704, y: y + 36)
    )
    return path
}

let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let rect = CGRect(origin: .zero, size: size)
let background = NSGradient(colors: [
    color(0.015, 0.018, 0.05),
    color(0.018, 0.11, 0.13),
    color(0.045, 0.018, 0.07)
])!
background.draw(in: rect, angle: -90)

let center = CGPoint(x: 512, y: 512)

for index in 0..<8 {
    let y = CGFloat(index) * 112 + 96
    let line = signalLinePath(y: y, offset: index.isMultiple(of: 2) ? 24 : -24)
    color(0.0, 0.92, 0.82, index.isMultiple(of: 2) ? 0.16 : 0.09).setStroke()
    line.lineWidth = index.isMultiple(of: 3) ? 4 : 2
    line.lineCapStyle = .round
    line.stroke()
}

let orbitSpecs: [(CGFloat, CGFloat, CGFloat, NSColor)] = [
    (650, 238, -20, color(0.0, 0.92, 0.82, 0.82)),
    (760, 300, 38, color(1.0, 0.82, 0.2, 0.62)),
    (850, 354, -60, color(1.0, 0.22, 0.55, 0.46))
]

for spec in orbitSpecs {
    let orbit = ellipsePath(center: center, width: spec.0, height: spec.1, rotationDegrees: spec.2)
    spec.3.setStroke()
    orbit.lineWidth = 11
    orbit.stroke()
}

for ringIndex in 0..<5 {
    let diameter = CGFloat(410 + ringIndex * 42)
    let alpha = CGFloat(0.16 - Double(ringIndex) * 0.025)
    let ringRect = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
    let ring = NSBezierPath(ovalIn: ringRect)
    color(0.0, 0.92, 0.82, alpha).setStroke()
    ring.lineWidth = 16
    ring.stroke()
}

let core = NSBezierPath(ovalIn: CGRect(x: 392, y: 392, width: 240, height: 240))
color(1.0, 0.83, 0.18).setFill()
core.fill()
color(1.0, 1.0, 0.88, 0.95).setStroke()
core.lineWidth = 10
core.stroke()

color(1.0, 1.0, 1.0, 0.92).setFill()
NSBezierPath(ovalIn: CGRect(x: 474, y: 474, width: 76, height: 76)).fill()

let nodeSpecs: [(CGPoint, CGFloat, NSColor)] = [
    (CGPoint(x: 728, y: 654), 72, color(1.0, 0.86, 0.24, 0.98)),
    (CGPoint(x: 292, y: 540), 58, color(0.0, 0.92, 0.82, 0.95)),
    (CGPoint(x: 634, y: 274), 54, color(1.0, 0.22, 0.55, 0.9)),
    (CGPoint(x: 400, y: 758), 44, color(1.0, 1.0, 1.0, 0.86))
]

for spec in nodeSpecs {
    spec.2.setFill()
    NSBezierPath(ovalIn: CGRect(x: spec.0.x - spec.1 / 2, y: spec.0.y - spec.1 / 2, width: spec.1, height: spec.1)).fill()
    color(1.0, 1.0, 1.0, 0.56).setStroke()
    let ring = NSBezierPath(ovalIn: CGRect(x: spec.0.x - spec.1 / 2, y: spec.0.y - spec.1 / 2, width: spec.1, height: spec.1))
    ring.lineWidth = 6
    ring.stroke()
}

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon")
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
