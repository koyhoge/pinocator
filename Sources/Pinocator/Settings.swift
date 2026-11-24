import AppKit
import Combine

enum DisplayMode: String, CaseIterable, Identifiable {
    case global
    case hint
    case mirror
    case none

    var id: String { rawValue }

    var label: String {
        switch self {
        case .global: return "global（全画面に本物の円）"
        case .hint:   return "hint（矢印＋画面名バッジ）"
        case .mirror: return "mirror（相対位置を写す）"
        case .none:   return "none（カーソルの画面だけ）"
        }
    }
}

/// 設定の保持。UserDefaults に保存し、変更は次の発火から反映される
/// （ホットキーだけは AppDelegate が購読して即時再登録する）。
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private let d = UserDefaults.standard
    private static func key(_ name: String) -> String { "pinocator.\(name)" }

    @Published var duration: Double {
        didSet { d.set(duration, forKey: Self.key("duration")) }
    }
    @Published var ringCount: Int {
        didSet { d.set(ringCount, forKey: Self.key("ringCount")) }
    }
    @Published var ringDelay: Double {
        didSet { d.set(ringDelay, forKey: Self.key("ringDelay")) }
    }
    @Published var startRadiusAuto: Bool {
        didSet { d.set(startRadiusAuto, forKey: Self.key("startRadiusAuto")) }
    }
    @Published var startRadius: Double {
        didSet { d.set(startRadius, forKey: Self.key("startRadius")) }
    }
    @Published var endRadius: Double {
        didSet { d.set(endRadius, forKey: Self.key("endRadius")) }
    }
    @Published var strokeWidth: Double {
        didSet { d.set(strokeWidth, forKey: Self.key("strokeWidth")) }
    }
    @Published var glassStyle: Bool {
        didSet { d.set(glassStyle, forKey: Self.key("glassStyle")) }
    }
    @Published var colorRed: Double {
        didSet { d.set(colorRed, forKey: Self.key("colorRed")) }
    }
    @Published var colorGreen: Double {
        didSet { d.set(colorGreen, forKey: Self.key("colorGreen")) }
    }
    @Published var colorBlue: Double {
        didSet { d.set(colorBlue, forKey: Self.key("colorBlue")) }
    }
    @Published var mode: DisplayMode {
        didSet { d.set(mode.rawValue, forKey: Self.key("mode")) }
    }
    @Published var hotkeyKeyCode: Int {
        didSet { d.set(hotkeyKeyCode, forKey: Self.key("hotkeyKeyCode")) }
    }
    @Published var hotkeyModifiers: Int {
        didSet { d.set(hotkeyModifiers, forKey: Self.key("hotkeyModifiers")) }
    }
    @Published var hotkeyLabel: String {
        didSet { d.set(hotkeyLabel, forKey: Self.key("hotkeyLabel")) }
    }

    var ringColor: NSColor {
        NSColor(calibratedRed: colorRed, green: colorGreen, blue: colorBlue, alpha: 1)
    }

    /// 全体のアニメーション時間（最後のリングが終わるまで）
    var totalDuration: Double {
        duration + Double(max(0, ringCount - 1)) * ringDelay
    }

    init() {
        // Hammerspoon 版で確定した値をデフォルトにする
        duration        = d.object(forKey: Self.key("duration")) as? Double ?? 0.8
        ringCount       = d.object(forKey: Self.key("ringCount")) as? Int ?? 5
        ringDelay       = d.object(forKey: Self.key("ringDelay")) as? Double ?? 0.3
        startRadiusAuto = d.object(forKey: Self.key("startRadiusAuto")) as? Bool ?? true
        startRadius     = d.object(forKey: Self.key("startRadius")) as? Double ?? 800
        endRadius       = d.object(forKey: Self.key("endRadius")) as? Double ?? 0
        strokeWidth     = d.object(forKey: Self.key("strokeWidth")) as? Double ?? 8
        glassStyle      = d.object(forKey: Self.key("glassStyle")) as? Bool ?? true
        colorRed        = d.object(forKey: Self.key("colorRed")) as? Double ?? 0.15
        colorGreen      = d.object(forKey: Self.key("colorGreen")) as? Double ?? 0.55
        colorBlue       = d.object(forKey: Self.key("colorBlue")) as? Double ?? 1.0
        mode            = DisplayMode(rawValue: d.string(forKey: Self.key("mode")) ?? "") ?? .global
        hotkeyKeyCode   = d.object(forKey: Self.key("hotkeyKeyCode")) as? Int ?? 111  // F12
        hotkeyModifiers = d.object(forKey: Self.key("hotkeyModifiers")) as? Int ?? 512 // Shift
        hotkeyLabel     = d.string(forKey: Self.key("hotkeyLabel")) ?? "⇧F12"
    }
}
