import AppKit

/// hint モードで他の画面に出すバッジ。
/// 矢印（カーソルの方向、8方位）＋カーソルのある画面名を表示する。
final class HintView: NSView {
    var arrow: String = "→"
    var screenName: String = ""
    var onFinish: (() -> Void)?

    private let settings = SettingsStore.shared
    private let hintTime = 0.6
    private var timer: Timer?
    private var startDate: Date?
    private var elapsed: TimeInterval = 0
    weak var windowRef: NSWindow?

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
        let total = settings.totalDuration
        if elapsed >= total + hintTime {
            stop()
            onFinish?()
            return
        }
        if elapsed > total {
            windowRef?.alphaValue = max(0, 1 - (elapsed - total) / hintTime)
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds
        // 背景
        let bg = NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14)
        NSColor.black.withAlphaComponent(0.55).setFill()
        bg.fill()

        // リング（軽く脈動）
        let ringCenter = CGPoint(x: 44, y: bounds.midY)
        let r: CGFloat = 24 + 2 * CGFloat(sin(elapsed * 8))
        let ring = NSBezierPath(ovalIn: NSRect(x: ringCenter.x - r, y: ringCenter.y - r,
                                               width: 2 * r, height: 2 * r))
        ring.lineWidth = 3
        settings.ringColor.setStroke()
        ring.stroke()

        // 矢印
        let arrowAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 28, weight: .medium),
            .foregroundColor: settings.ringColor,
        ]
        let arrowStr = NSAttributedString(string: arrow, attributes: arrowAttr)
        let arrowSize = arrowStr.size()
        arrowStr.draw(at: CGPoint(x: ringCenter.x - arrowSize.width / 2,
                                  y: ringCenter.y - arrowSize.height / 2))

        // 画面名
        let nameAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 20),
            .foregroundColor: NSColor.white,
        ]
        let nameStr = NSAttributedString(string: screenName, attributes: nameAttr)
        let nameSize = nameStr.size()
        nameStr.draw(at: CGPoint(x: 84, y: bounds.midY - nameSize.height / 2))
    }
}
