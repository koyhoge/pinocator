import AppKit
import Carbon

/// Carbon RegisterEventHotKey によるグローバルホットキー。
/// アクセシビリティ権限は不要。
final class HotkeyManager {
    var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        installHandlerIfNeeded()
        let hotKeyID = EventHotKeyID(signature: OSType(0x5049_4E4F), id: 1) // 'PINO'
        RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            if let userData {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.onTrigger?()
            }
            return noErr
        }, 1, &eventType, userData, &handlerRef)
    }
}

/// NSEvent の修飾フラグを Carbon の修飾キー値に変換する。
func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var result: UInt32 = 0
    if flags.contains(.command) { result |= UInt32(cmdKey) }
    if flags.contains(.shift)   { result |= UInt32(shiftKey) }
    if flags.contains(.option)  { result |= UInt32(optionKey) }
    if flags.contains(.control) { result |= UInt32(controlKey) }
    return result
}

/// キーコードから表示名を作る（Fキーはコード表、その他は文字から）。
func keyDisplayName(keyCode: UInt32, event: NSEvent?) -> String {
    let fKeys: [UInt32: String] = [
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
        105: "F13", 107: "F14", 113: "F15", 106: "F16", 64: "F17",
        79: "F18", 80: "F19", 90: "F20",
    ]
    if let name = fKeys[keyCode] { return name }
    if let chars = event?.charactersIgnoringModifiers, !chars.isEmpty {
        return chars.uppercased()
    }
    return "Key \(keyCode)"
}

/// 修飾キー＋キー名のラベル（例: "⇧F12"、"⌃⌥⌘P"）。
func hotkeyLabel(modifiers: UInt32, keyName: String) -> String {
    var label = ""
    if modifiers & UInt32(controlKey) != 0 { label += "⌃" }
    if modifiers & UInt32(optionKey) != 0  { label += "⌥" }
    if modifiers & UInt32(shiftKey) != 0   { label += "⇧" }
    if modifiers & UInt32(cmdKey) != 0     { label += "⌘" }
    return label + keyName
}
