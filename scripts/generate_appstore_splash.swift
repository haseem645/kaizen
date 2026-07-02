import AppKit

let width = 1242
let height = 2688
let canvasSize = NSSize(width: width, height: height)

func color(_ hex: Int, alpha: CGFloat = 1.0) -> NSColor {
  NSColor(
    calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
    green: CGFloat((hex >> 8) & 0xFF) / 255.0,
    blue: CGFloat(hex & 0xFF) / 255.0,
    alpha: alpha
  )
}

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
  NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawRadialGlow(
  center: CGPoint,
  radius: CGFloat,
  color: NSColor,
  alpha: CGFloat
) {
  guard
    let gradient = NSGradient(
      starting: color.withAlphaComponent(alpha),
      ending: color.withAlphaComponent(0.0)
    )
  else { return }

  gradient.draw(
    fromCenter: center,
    radius: 0,
    toCenter: center,
    radius: radius,
    options: [.drawsBeforeStartingLocation, .drawsAfterEndingLocation]
  )
}

func drawText(
  _ text: String,
  at point: CGPoint,
  fontName: String,
  size: CGFloat,
  color: NSColor
) {
  let font = NSFont(name: fontName, size: size) ?? NSFont.systemFont(ofSize: size)
  let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: color,
  ]
  NSString(string: text).draw(at: point, withAttributes: attrs)
}

let image = NSImage(size: canvasSize)
image.lockFocus()

NSGraphicsContext.current?.imageInterpolation = .high

let fullRect = NSRect(x: 0, y: 0, width: width, height: height)
color(0x2A2D3D).setFill()
fullRect.fill()

drawRadialGlow(
  center: CGPoint(x: 110, y: height - 90),
  radius: 980,
  color: color(0x9260FE),
  alpha: 0.82
)

drawRadialGlow(
  center: CGPoint(x: width - 40, y: 140),
  radius: 860,
  color: color(0x7F56D9),
  alpha: 0.78
)

drawRadialGlow(
  center: CGPoint(x: CGFloat(width) * 0.5, y: CGFloat(height) * 0.5),
  radius: 1300,
  color: color(0x1B1139),
  alpha: 0.18
)

if let wash = NSGradient(colors: [
  color(0xFFFFFF, alpha: 0.02),
  color(0x000000, alpha: 0.14),
]) {
  wash.draw(in: fullRect, angle: 0)
}

// Status bar
drawText(
  "2:59",
  at: CGPoint(x: 172, y: height - 125),
  fontName: "SF Pro Display Bold",
  size: 55,
  color: .black
)

let islandRect = NSRect(x: 428, y: height - 136, width: 386, height: 78)
color(0x000000).setFill()
roundedRect(islandRect, radius: 39).fill()

for index in 0..<4 {
  let dot = NSRect(x: 894 + CGFloat(index) * 20, y: CGFloat(height - 103), width: 9, height: 9)
  color(0x4F4A67, alpha: 0.75).setFill()
  NSBezierPath(ovalIn: dot).fill()
}

// Wi-Fi
let wifiCenter = CGPoint(x: 1033, y: height - 92)
let wifiPath = NSBezierPath()
wifiPath.lineWidth = 6
color(0x0A0A0A).setStroke()
wifiPath.appendArc(
  withCenter: wifiCenter,
  radius: 22,
  startAngle: 38,
  endAngle: 142,
  clockwise: false
)
wifiPath.stroke()

let wifiInner = NSBezierPath()
wifiInner.lineWidth = 6
wifiInner.appendArc(
  withCenter: wifiCenter,
  radius: 13,
  startAngle: 45,
  endAngle: 135,
  clockwise: false
)
wifiInner.stroke()
NSBezierPath(ovalIn: NSRect(x: wifiCenter.x - 3, y: wifiCenter.y - 4, width: 6, height: 6)).fill()

// Battery
let batteryBody = roundedRect(NSRect(x: 1087, y: height - 101, width: 74, height: 34), radius: 11)
color(0x0A0A0A).setStroke()
batteryBody.lineWidth = 5
batteryBody.stroke()
color(0x0A0A0A).setFill()
roundedRect(NSRect(x: 1097, y: height - 91, width: 50, height: 14), radius: 5).fill()
roundedRect(NSRect(x: 1162, y: height - 89, width: 5, height: 10), radius: 2.5).fill()

// Wordmark
let kaizenFont = NSFont(name: "SF Pro Display Bold", size: 90) ?? NSFont.boldSystemFont(ofSize: 90)
let dividerFont = NSFont(name: "SF Pro Display Thin", size: 118) ?? NSFont.systemFont(ofSize: 118, weight: .thin)
let teamsFont = NSFont(name: "SF Pro Display Bold", size: 90) ?? NSFont.boldSystemFont(ofSize: 90)

let kaizenAttrs: [NSAttributedString.Key: Any] = [
  .font: kaizenFont,
  .foregroundColor: color(0xA67DFF),
]
let dividerAttrs: [NSAttributedString.Key: Any] = [
  .font: dividerFont,
  .foregroundColor: color(0xFFFFFF),
]
let teamsAttrs: [NSAttributedString.Key: Any] = [
  .font: teamsFont,
  .foregroundColor: color(0xFFFFFF),
]

let kaizen = NSString(string: "Kaizen")
let divider = NSString(string: "|")
let teams = NSString(string: "Teams")

let kaizenSize = kaizen.size(withAttributes: kaizenAttrs)
let dividerSize = divider.size(withAttributes: dividerAttrs)
let teamsSize = teams.size(withAttributes: teamsAttrs)
let totalWidth = kaizenSize.width + dividerSize.width + teamsSize.width + 10
let baseX = (CGFloat(width) - totalWidth) / 2
let baselineY = CGFloat(1180)

kaizen.draw(at: CGPoint(x: baseX, y: baselineY), withAttributes: kaizenAttrs)
divider.draw(
  at: CGPoint(x: baseX + kaizenSize.width + 2, y: baselineY - 12),
  withAttributes: dividerAttrs
)
teams.draw(
  at: CGPoint(x: baseX + kaizenSize.width + dividerSize.width + 8, y: baselineY),
  withAttributes: teamsAttrs
)

// Spinner
let spinner = NSBezierPath()
spinner.lineWidth = 12
spinner.lineCapStyle = .round
spinner.appendArc(
  withCenter: CGPoint(x: width / 2, y: 550),
  radius: 30,
  startAngle: 120,
  endAngle: 355,
  clockwise: false
)
color(0xFFFFFF).setStroke()
spinner.stroke()

// Home indicator
color(0x4E4664, alpha: 0.9).setFill()
roundedRect(NSRect(x: 411, y: 24, width: 420, height: 14), radius: 7).fill()

image.unlockFocus()

guard
  let tiff = image.tiffRepresentation,
  let bitmap = NSBitmapImageRep(data: tiff),
  let png = bitmap.representation(using: .png, properties: [:])
else {
  fputs("Failed to create PNG data\n", stderr)
  exit(1)
}

let outputDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  .appendingPathComponent("appstore_screenshots", isDirectory: true)
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let output = outputDir.appendingPathComponent("kaizen_teams_splash_1242x2688.png")
try png.write(to: output)

print(output.path)
