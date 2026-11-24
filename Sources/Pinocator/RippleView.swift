import AppKit

/// 収束する円を描くビュー。中心はビュー座標（Cocoa 左下原点）で受け取る。
final class RippleView: NSView {
    var center: CGPoint = .zero
    var startRadius: CGFloat = 0
    var onFinish: (() -> Void)?

    private let settings = SettingsStore.shared
    private var timer: Timer?
    private var startDate: Date?
    private var elapsed: TimeInterval = 0

    func start() {
        startDate = Date()
        elapsed = 0
        timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let startDate else { return }
        elapsed = Date().timeIntervalSince(startDate)
        if elapsed >= settings.totalDuration {
            stop()
            onFinish?()
            return
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let s = settings
        for i in 0..<s.ringCount {
            let p = (elapsed - Double(i) * s.ringDelay) / s.duration
            guard p > 0, p < 1 else { continue }
            let r = Geometry.ringRadius(progress: p, start: startRadius,
                                        end: CGFloat(s.endRadius))
            let alpha = Geometry.ringAlpha(progress: p)
            if s.glassStyle {
                drawGlassRing(radius: r, lineWidth: CGFloat(s.strokeWidth),
                              alpha: alpha, color: s.ringColor)
            } else {
                let rect = NSRect(x: center.x - r, y: center.y - r,
                                  width: 2 * r, height: 2 * r)
                let path = NSBezierPath(ovalIn: rect)
                path.lineWidth = CGFloat(s.strokeWidth)
                s.ringColor.withAlphaComponent(alpha).setStroke()
                path.stroke()
            }
        }
    }

    /// ガラス風のリング。本物の Liquid Glass は「面」の素材なので線には
    /// 使えない。帯＋グロー＋上側のスペキュラハイライト＋下側の反射で
    /// 質感を寄せる。
    private func drawGlassRing(radius r: CGFloat, lineWidth w: CGFloat,
                               alpha: CGFloat, color: NSColor) {
        func circlePath(_ radius: CGFloat) -> NSBezierPath {
            NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius,
                                        width: 2 * radius, height: 2 * radius))
        }

        // 柔らかいグロー
        let glow = circlePath(r)
        glow.lineWidth = w * 2.4
        color.withAlphaComponent(alpha * 0.12).setStroke()
        glow.stroke()

        // 本体の帯（少し透ける）
        let band = circlePath(r)
        band.lineWidth = w
        color.withAlphaComponent(alpha * 0.75).setStroke()
        band.stroke()

        // 上側のスペキュラハイライト
        let highlight = NSBezierPath()
        highlight.appendArc(withCenter: center, radius: r - w * 0.22,
                            startAngle: 25, endAngle: 155, clockwise: false)
        highlight.lineWidth = w * 0.38
        highlight.lineCapStyle = .round
        NSColor.white.withAlphaComponent(alpha * 0.8).setStroke()
        highlight.stroke()

        // 下側の弱い反射
        let reflection = NSBezierPath()
        reflection.appendArc(withCenter: center, radius: r - w * 0.22,
                             startAngle: 205, endAngle: 335, clockwise: false)
        reflection.lineWidth = w * 0.3
        reflection.lineCapStyle = .round
        NSColor.white.withAlphaComponent(alpha * 0.25).setStroke()
        reflection.stroke()

        // 外周の細い明線
        let edge = circlePath(r + w / 2 - 0.75)
        edge.lineWidth = 1.5
        NSColor.white.withAlphaComponent(alpha * 0.35).setStroke()
        edge.stroke()
    }
}
