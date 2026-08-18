import SwiftUI
import AppKit

private let claudeSVGPathString = "M4.709 15.955l4.72-2.647.08-.23-.08-.128H9.2l-.79-.048-2.698-.073-2.339-.097-2.266-.122-.571-.121L0 11.784l.055-.352.48-.321.686.06 1.52.103 2.278.158 1.652.097 2.449.255h.389l.055-.157-.134-.098-.103-.097-2.358-1.596-2.552-1.688-1.336-.972-.724-.491-.364-.462-.158-1.008.656-.722.881.06.225.061.893.686 1.908 1.476 2.491 1.833.365.304.145-.103.019-.073-.164-.274-1.355-2.446-1.446-2.49-.644-1.032-.17-.619a2.97 2.97 0 01-.104-.729L6.283.134 6.696 0l.996.134.42.364.62 1.414 1.002 2.229 1.555 3.03.456.898.243.832.091.255h.158V9.01l.128-1.706.237-2.095.23-2.695.08-.76.376-.91.747-.492.584.28.48.685-.067.444-.286 1.851-.559 2.903-.364 1.942h.212l.243-.242.985-1.306 1.652-2.064.73-.82.85-.904.547-.431h1.033l.76 1.129-.34 1.166-1.064 1.347-.881 1.142-1.264 1.7-.79 1.36.073.11.188-.02 2.856-.606 1.543-.28 1.841-.315.833.388.091.395-.328.807-1.969.486-2.309.462-3.439.813-.042.03.049.061 1.549.146.662.036h1.622l3.02.225.79.522.474.638-.079.485-1.215.62-1.64-.389-3.829-.91-1.312-.329h-.182v.11l1.093 1.068 2.006 1.81 2.509 2.33.127.578-.322.455-.34-.049-2.205-1.657-.851-.747-1.926-1.62h-.128v.17l.444.649 2.345 3.521.122 1.08-.17.353-.608.213-.668-.122-1.374-1.925-1.415-2.167-1.143-1.943-.14.08-.674 7.254-.316.37-.729.28-.607-.461-.322-.747.322-1.476.389-1.924.315-1.53.286-1.9.17-.632-.012-.042-.14.018-1.434 1.967-2.18 2.945-1.726 1.845-.414.164-.717-.37.067-.662.401-.589 2.388-3.036 1.44-1.882.93-1.086-.006-.158h-.055L4.132 18.56l-1.13.146-.487-.456.061-.746.231-.243 1.908-1.312-.006.006z"

private func parseSVGPath(_ d: String) -> CGPath {
    let path = CGMutablePath()
    let scanner = Scanner(string: d)
    var currentPoint = CGPoint.zero
    var subpathStart = CGPoint.zero

    func parseValues(_ count: Int) -> [CGFloat]? {
        var values: [CGFloat] = []
        for _ in 0..<count {
            _ = scanner.scanCharacters(from: CharacterSet(charactersIn: ",\n\r\t "))
            if let val = scanner.scanDouble() {
                values.append(CGFloat(val))
            } else {
                return nil
            }
        }
        return values
    }

    while !scanner.isAtEnd {
        _ = scanner.scanCharacters(from: CharacterSet(charactersIn: ",\n\r\t "))
        guard let commandChar = scanner.scanCharacter() else { break }

        switch commandChar {
        case "m":
            while let pt = parseValues(2) {
                let p = CGPoint(x: currentPoint.x + pt[0], y: currentPoint.y + pt[1])
                if path.isEmpty {
                    path.move(to: p)
                    subpathStart = p
                } else {
                    path.addLine(to: p)
                }
                currentPoint = p
            }
        case "M":
            while let pt = parseValues(2) {
                let p = CGPoint(x: pt[0], y: pt[1])
                path.move(to: p)
                subpathStart = p
                currentPoint = p
            }
        case "l":
            while let pt = parseValues(2) {
                let p = CGPoint(x: currentPoint.x + pt[0], y: currentPoint.y + pt[1])
                path.addLine(to: p)
                currentPoint = p
            }
        case "L":
            while let pt = parseValues(2) {
                let p = CGPoint(x: pt[0], y: pt[1])
                path.addLine(to: p)
                currentPoint = p
            }
        case "h":
            while let val = parseValues(1) {
                let p = CGPoint(x: currentPoint.x + val[0], y: currentPoint.y)
                path.addLine(to: p)
                currentPoint = p
            }
        case "H":
            while let val = parseValues(1) {
                let p = CGPoint(x: val[0], y: currentPoint.y)
                path.addLine(to: p)
                currentPoint = p
            }
        case "v":
            while let val = parseValues(1) {
                let p = CGPoint(x: currentPoint.x, y: currentPoint.y + val[0])
                path.addLine(to: p)
                currentPoint = p
            }
        case "V":
            while let val = parseValues(1) {
                let p = CGPoint(x: val[0], y: currentPoint.y)
                path.addLine(to: p)
                currentPoint = p
            }
        case "c":
            while let pts = parseValues(6) {
                let c1 = CGPoint(x: currentPoint.x + pts[0], y: currentPoint.y + pts[1])
                let c2 = CGPoint(x: currentPoint.x + pts[2], y: currentPoint.y + pts[3])
                let end = CGPoint(x: currentPoint.x + pts[4], y: currentPoint.y + pts[5])
                path.addCurve(to: end, control1: c1, control2: c2)
                currentPoint = end
            }
        case "C":
            while let pts = parseValues(6) {
                let c1 = CGPoint(x: pts[0], y: pts[1])
                let c2 = CGPoint(x: pts[2], y: pts[3])
                let end = CGPoint(x: pts[4], y: pts[5])
                path.addCurve(to: end, control1: c1, control2: c2)
                currentPoint = end
            }
        case "a":
            while let pts = parseValues(7) {
                let end = CGPoint(x: currentPoint.x + pts[5], y: currentPoint.y + pts[6])
                path.addLine(to: end)
                currentPoint = end
            }
        case "A":
            while let pts = parseValues(7) {
                let end = CGPoint(x: pts[5], y: pts[6])
                path.addLine(to: end)
                currentPoint = end
            }
        case "z", "Z":
            path.closeSubpath()
            currentPoint = subpathStart
        default:
            break
        }
    }
    return path
}

nonisolated(unsafe) private let cachedClaudeSVGPath: CGPath = parseSVGPath(claudeSVGPathString)

public func claudeStatusIcon(status: StatusIndicator, size: NSSize = NSSize(width: 18, height: 18)) -> NSImage {
    let image = NSImage(size: size, flipped: false) { rect in
        guard let context = NSGraphicsContext.current?.cgContext else { return false }

        let inset: CGFloat = 0.5
        let badgeRect = rect.insetBy(dx: inset, dy: inset)

        // 1. Draw circular status background badge
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

        context.setFillColor(bgNSColor.cgColor)
        context.fillEllipse(in: badgeRect)

        // 2. Draw official black Claude SVG logo inside
        let innerTargetRect = badgeRect.insetBy(dx: badgeRect.width * 0.20, dy: badgeRect.height * 0.20)
        let viewBoxSize: CGFloat = 24.0

        let scaleX = innerTargetRect.width / viewBoxSize
        let scaleY = innerTargetRect.height / viewBoxSize
        let scale = min(scaleX, scaleY)

        context.saveGState()

        context.translateBy(x: innerTargetRect.midX, y: innerTargetRect.midY)
        context.scaleBy(x: scale, y: -scale)
        context.translateBy(x: -viewBoxSize / 2.0, y: -viewBoxSize / 2.0)

        context.addPath(cachedClaudeSVGPath)
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1.0))
        context.fillPath()

        context.restoreGState()

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
