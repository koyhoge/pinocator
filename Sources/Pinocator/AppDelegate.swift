import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore.shared
    private let hotkey = HotkeyManager()
    private let overlay = OverlayController()
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        hotkey.onTrigger = { [weak self] in self?.overlay.trigger() }
        applyHotkey()

        // ホットキー設定が変わったら即時に再登録する
        settings.$hotkeyKeyCode
            .combineLatest(settings.$hotkeyModifiers)
            .dropFirst()
            .sink { [weak self] _, _ in self?.applyHotkey() }
            .store(in: &cancellables)
    }

    private func applyHotkey() {
        hotkey.register(keyCode: UInt32(settings.hotkeyKeyCode),
                        modifiers: UInt32(settings.hotkeyModifiers))
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "◎"
        item.button?.toolTip = "Pinocator"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "今すぐ表示（\(settings.hotkeyLabel)）",
                                action: #selector(triggerFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "設定…",
                                action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Pinocator を終了",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        for menuItem in menu.items { menuItem.target = self }
        menu.items.last?.target = nil  // 終了だけは NSApp 直通に戻す
        item.menu = menu
        statusItem = item
    }

    @objc private func triggerFromMenu() {
        overlay.trigger()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
                styleMask: [.titled, .closable],
                backing: .buffered, defer: false)
            window.title = "Pinocator 設定"
            window.contentViewController = NSHostingController(rootView: SettingsView())
            // ホスティング側の測定サイズが 0 だとタイトルバーだけの
            // ウィンドウになるので、明示的にサイズを戻す
            window.setContentSize(NSSize(width: 480, height: 560))
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
