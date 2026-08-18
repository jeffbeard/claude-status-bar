import SwiftUI
import AppKit

public func claudeStatusIcon(status: StatusIndicator, size: NSSize = NSSize(width: 18, height: 18)) -> NSImage {
    let image = NSImage(size: size, flipped: false) { rect in
        let inset: CGFloat = 1.0
        let badgeRect = rect.insetBy(dx: inset, dy: inset)

        // 1. Draw status background badge (rounded rect)
        let backgroundPath = NSBezierPath(roundedRect: badgeRect, xRadius: 4.0, yRadius: 4.0)
        let bgNSColor: NSColor
        switch status {
        case .operational:
            bgNSColor = NSColor(red: 0.13, green: 0.77, blue: 0.36, alpha: 1.0)
        case .minor:
            bgNSColor = NSColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0)
        case .major, .critical:
            bgNSColor = NSColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1.0)
        case .unknown:
            bgNSColor = NSColor(red: 0.60, green: 0.60, blue: 0.64, alpha: 1.0)
        }
        bgNSColor.setFill()
        backgroundPath.fill()

        // 2. Draw blacked out Claude spark shape inside
        let sparkRect = badgeRect.insetBy(dx: 2.8, dy: 2.8)
        let cx = sparkRect.midX
        let cy = sparkRect.midY
        let maxR = sparkRect.width / 2.0

        let path = NSBezierPath()
        let numPoints = 8
        var points: [CGPoint] = []

        for i in 0..<numPoints {
            let angle = (Double(i) * 2.0 * .pi / Double(numPoints)) - (.pi / 2.0)
            let r: Double = (i % 2 == 0) ? Double(maxR) : Double(maxR) * 0.52
            let x = cx + CGFloat(r * cos(angle))
            let y = cy + CGFloat(r * sin(angle))
            points.append(CGPoint(x: x, y: y))
        }

        if let first = points.first {
            path.move(to: first)
            for i in 0..<numPoints {
                let next = points[(i + 1) % numPoints]

                let midAngle = (Double(i) * 2.0 * .pi / Double(numPoints)) + (.pi / Double(numPoints)) - (.pi / 2.0)
                let innerR = Double(maxR) * 0.22
                let ctrlX = cx + CGFloat(innerR * cos(midAngle))
                let ctrlY = cy + CGFloat(innerR * sin(midAngle))
                let ctrlPt = CGPoint(x: ctrlX, y: ctrlY)

                path.curve(to: next, controlPoint1: ctrlPt, controlPoint2: ctrlPt)
            }
            path.close()
        }

        NSColor.black.setFill()
        path.fill()

        return true
    }
    image.isTemplate = false
    return image
}

public struct ClaudeIconView: View {
    public let status: StatusIndicator
    public let size: CGFloat

    public init(status: StatusIndicator, size: CGFloat = 20) {
        self.status = status
        self.size = size
    }

    public var body: some View {
        Image(nsImage: claudeStatusIcon(status: status, size: NSSize(width: size, height: size)))
            .resizable()
            .frame(width: size, height: size)
    }
}
