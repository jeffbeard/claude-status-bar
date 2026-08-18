import SwiftUI
import AppKit

private let claudeSVGPathString = "m4.7144 15.9555 4.7174-2.6471.079-.2307-.079-.1275h-.2307l-.7893-.0486-2.6956-.0729-2.3375-.0971-2.2646-.1214-.5707-.1215-.5343-.7042.0546-.3522.4797-.3218.686.0608 1.5179.1032 2.2767.1578 1.6514.0972 2.4468.255h.3886l.0546-.1579-.1336-.0971-.1032-.0972L6.973 9.8356l-2.55-1.6879-1.3356-.9714-.7225-.4918-.3643-.4614-.1578-1.0078.6557-.7225.8803.0607.2246.0607.8925.686 1.9064 1.4754 2.4893 1.8336.3643.3035.1457-.1032.0182-.0728-.164-.2733-1.3539-2.4467-1.445-2.4893-.6435-1.032-.17-.6194c-.0607-.255-.1032-.4674-.1032-.7285L6.287.1335 6.6997 0l.9957.1336.419.3642.6192 1.4147 1.0018 2.2282 1.5543 3.0296.4553.8985.2429.8318.091.255h.1579v-.1457l.1275-1.706.2368-2.0947.2307-2.6957.0789-.7589.3764-.9107.7468-.4918.5828.2793.4797.686-.0668.4433-.2853 1.8517-.5586 2.9021-.3643 1.9429h.2125l.2429-.2429.9835-1.3053 1.6514-2.0643.7286-.8196.85-.9046.5464-.4311h1.0321l.759 1.1293-.34 1.1657-1.0625 1.3478-.8804 1.1414-1.2628 1.7-.7893 1.36.0729.1093.1882-.0183 2.8535-.607 1.5421-.2794 1.8396-.3157.8318.3886.091.3946-.3278.8075-1.967.4857-2.3072.4614-3.4364.8136-.0425.0304.0486.0607 1.5482.1457.6618.0364h1.621l3.0175.2247.7892.522.4736.6376-.079.4857-1.2142.6193-1.6393-.3886-3.825-.9107-1.3113-.3279h-.1822v.1093l1.0929 1.0686 2.0035 1.8092 2.5075 2.3314.1275.5768-.3218.4554-.34-.0486-2.2039-1.6575-.85-.7468-1.9246-1.621h-.1275v.17l.4432.6496 2.3436 3.5214.1214 1.0807-.17.3521-.6071.2125-.6679-.1214-1.3721-1.9246L14.38 17.959l-1.1414-1.9428-.1397.079-.674 7.2552-.3156.3703-.7286.2793-.6071-.4614-.3218-.7468.3218-1.4753.3886-1.9246.3157-1.53.2853-1.9004.17-.6314-.0121-.0425-.1397.0182-1.4328 1.9672-2.1796 2.9446-1.7243 1.8456-.4128.164-.7164-.3704.0667-.6618.4008-.5889 2.386-3.0357 1.4389-1.882.929-1.0868-.0062-.1579h-.0546l-6.3385 4.1164-1.1293.1457-.4857-.4554.0608-.7467.2307-.2429 1.9064-1.3114Z"

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
                let p = CGPoint(x: currentPoint.x, y: val[0])
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
        let innerTargetRect = badgeRect.insetBy(dx: badgeRect.width * 0.22, dy: badgeRect.height * 0.22)
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
