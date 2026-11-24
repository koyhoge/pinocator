import AppKit

/// 発火ごとにオーバーレイウィンドウを作り、アニメーション終了で破棄する。
final class OverlayController {
    private let settings = SettingsStore.shared
    private var windows: [NSWindow] = []

    func trigger() {
        closeAll()

        let mouse = NSEvent.mouseLocation  // Cocoa グローバル座標（左下原点）
        let screens = NSScreen.screens
        guard let current = screens.first(where: { $0.frame.contains(mouse) })
            ?? screens.first else { return }

        let startRadius: CGFloat = settings.startRadiusAuto
            ? Geometry.autoRadius(mouse: mouse, frames: screens.map(\.frame))
            : CGFloat(settings.startRadius)

        switch settings.mode {
        case .global:
            for screen in screens {
                showRipple(on: screen, globalCenter: mouse, startRadius: startRadius)
            }
        case .none:
            showRipple(on: current, globalCenter: mouse, startRadius: startRadius)
        case .mirror:
            let rel = CGPoint(x: mouse.x - current.frame.minX,
                              y: mouse.y - current.frame.minY)
            for screen in screens {
                let center = CGPoint(x: screen.frame.minX + rel.x,
                                     y: screen.frame.minY + rel.y)
                showRipple(on: screen, globalCenter: center, startRadius: startRadius)
            }
        case .hint:
            showRipple(on: current, globalCenter: mouse, startRadius: startRadius)
            for screen in screens where screen !== current {
                showHint(on: screen, mouse: mouse,
                         cursorScreenName: current.localizedName)
            }
        }
    }

    private func makeOverlayWindow(frame: NSRect) -> NSWindow {
        let win = NSWindow(contentRect: frame, styleMask: .borderless,
                           backing: .buffered, defer: false)
        win.level = .screenSaver
        win.backgroundColor = .clear
        win.isOpaque = false
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        return win
    }

    private func showRipple(on screen: NSScreen, globalCenter: CGPoint, startRadius: CGFloat) {
        let win = makeOverlayWindow(frame: screen.frame)
        let view = RippleView(frame: NSRect(origin: .zero, size: screen.frame.size))
        // 画面ローカル座標 = グローバル座標 − 画面原点（Y反転は不要）
        view.center = CGPoint(x: globalCenter.x - screen.frame.minX,
                              y: globalCenter.y - screen.frame.minY)
        view.startRadius = startRadius
        view.onFinish = { [weak self, weak win] in
            if let win { self?.remove(win) }
        }
        win.contentView = view
        windows.append(win)
        win.orderFrontRegardless()
        view.start()
    }

    private func showHint(on screen: NSScreen, mouse: CGPoint, cursorScreenName: String) {
        let size = CGSize(width: 340, height: 120)
        let sf = screen.frame
        // その画面内でカーソルに一番近い点に、バッジ全体が収まるよう配置
        let px = min(max(mouse.x, sf.minX), sf.maxX)
        let py = min(max(mouse.y, sf.minY), sf.maxY)
        var origin = CGPoint(x: px - 44, y: py - size.height / 2)
        origin.x = min(max(origin.x, sf.minX), sf.maxX - size.width)
        origin.y = min(max(origin.y, sf.minY), sf.maxY - size.height)

        let win = makeOverlayWindow(frame: NSRect(origin: origin, size: size))
        let view = HintView(frame: NSRect(origin: .zero, size: size))
        view.arrow = Geometry.directionArrow(from: sf, to: mouse)
        view.screenName = cursorScreenName
        view.windowRef = win
        view.onFinish = { [weak self, weak win] in
            if let win { self?.remove(win) }
        }
        win.contentView = view
        windows.append(win)
        win.orderFrontRegardless()
        view.start()
    }

    private func remove(_ window: NSWindow) {
        window.orderOut(nil)
        windows.removeAll { $0 === window }
    }

    private func closeAll() {
        for win in windows {
            (win.contentView as? RippleView)?.stop()
            (win.contentView as? HintView)?.stop()
            win.orderOut(nil)
        }
        windows.removeAll()
    }
}
