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

for index in 0..<30 {
    let y = CGFloat(index) * 34 + 12
    let alpha = index.isMultiple(of: 3) ? 0.16 : 0.07
    color(0.0, 0.92, 0.82, alpha).setFill()
    NSBezierPath(roundedRect: CGRect(x: 96 + CGFloat(index % 5) * 12, y: y, width: 250, height: 4), xRadius: 2, yRadius: 2).fill()
}

let orbitSpecs: [(CGFloat, CGFloat, CGFloat, NSColor)] = [
    (650, 230, -18, color(0.0, 0.92, 0.82, 0.74)),
    (770, 292, 42, color(1.0, 0.2, 0.54, 0.62)),
    (880, 352, -62, color(1.0, 0.82, 0.2, 0.45))
]

for spec in orbitSpecs {
    let orbit = ellipsePath(center: center, width: spec.0, height: spec.1, rotationDegrees: spec.2)
    spec.3.setStroke()
    orbit.lineWidth = 12
    orbit.stroke()
}

let glow = NSGradient(colors: [
    color(1.0, 0.86, 0.24, 0.95),
    color(0.0, 0.86, 0.82, 0.72),
    color(0.0, 0.86, 0.82, 0.0)
])!
NSGraphicsContext.saveGraphicsState()
NSBezierPath(ovalIn: CGRect(x: 286, y: 286, width: 452, height: 452)).addClip()
glow.draw(in: CGRect(x: 286, y: 286, width: 452, height: 452), relativeCenterPosition: .zero)
NSGraphicsContext.restoreGraphicsState()

let core = NSBezierPath(ovalIn: CGRect(x: 392, y: 392, width: 240, height: 240))
color(1.0, 0.83, 0.18).setFill()
core.fill()
color(1.0, 1.0, 0.88, 0.95).setStroke()
core.lineWidth = 10
core.stroke()

color(1.0, 1.0, 1.0, 0.92).setFill()
NSBezierPath(ovalIn: CGRect(x: 474, y: 474, width: 76, height: 76)).fill()

let shard = starPath(center: CGPoint(x: 720, y: 690), outer: 112, inner: 56, points: 6, rotation: -.pi / 2.4)
color(1.0, 0.12, 0.46).setFill()
shard.fill()
color(0.08, 0.0, 0.04, 0.72).setStroke()
shard.lineWidth = 12
shard.stroke()

let slash = NSBezierPath()
slash.move(to: CGPoint(x: 666, y: 636))
slash.line(to: CGPoint(x: 774, y: 744))
slash.move(to: CGPoint(x: 774, y: 636))
slash.line(to: CGPoint(x: 666, y: 744))
color(0.04, 0.0, 0.03, 0.82).setStroke()
slash.lineWidth = 18
slash.lineCapStyle = .round
slash.stroke()

for point in [CGPoint(x: 270, y: 676), CGPoint(x: 764, y: 344), CGPoint(x: 300, y: 330)] {
    let spark = starPath(center: point, outer: 34, inner: 15, points: 5)
    color(1.0, 0.86, 0.24, 0.92).setFill()
    spark.fill()
}

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon")
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
