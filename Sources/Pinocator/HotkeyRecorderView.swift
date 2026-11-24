import AppKit
import SwiftUI

/// クリックすると次のキー入力をホットキーとして記録するコントロール。
struct HotkeyRecorderView: NSViewRepresentable {
    @ObservedObject var settings: SettingsStore

    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.bezelStyle = .rounded
        button.title = settings.hotkeyLabel
        button.target = button
        button.action = #selector(RecorderButton.beginRecording)
        button.onRecord = { keyCode, modifiers, label in
            settings.hotkeyKeyCode = Int(keyCode)
            settings.hotkeyModifiers = Int(modifiers)
            settings.hotkeyLabel = label
        }
        return button
    }

    func updateNSView(_ nsView: RecorderButton, context: Context) {
        if !nsView.isRecording {
            nsView.title = settings.hotkeyLabel
        }
    }
}

final class RecorderButton: NSButton {
    var onRecord: ((UInt32, UInt32, String) -> Void)?
    private(set) var isRecording = false
    private var monitor: Any?

    @objc func beginRecording() {
        guard !isRecording else { return }
        isRecording = true
        title = "キーを押してください…（Escで取消）"
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
            return nil
        }
    }

    private func handle(_ event: NSEvent) {
        defer { stopRecording() }
        if event.keyCode == 53 { return }  // Esc は取消
        let modifiers = carbonModifiers(from: event.modifierFlags)
        let name = keyDisplayName(keyCode: UInt32(event.keyCode), event: event)
        onRecord?(UInt32(event.keyCode), modifiers, hotkeyLabel(modifiers: modifiers, keyName: name))
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
