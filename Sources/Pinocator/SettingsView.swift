import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared

    /// Info.plist のバージョン表記（例: "0.1.0"）
    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    /// 円の数は Int なので、Slider 用に Double へ橋渡しする
    private var ringCountBinding: Binding<Double> {
        Binding(
            get: { Double(settings.ringCount) },
            set: { settings.ringCount = Int($0) }
        )
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(red: settings.colorRed, green: settings.colorGreen, blue: settings.colorBlue) },
            set: { newColor in
                if let comps = NSColor(newColor).usingColorSpace(.sRGB) {
                    settings.colorRed = Double(comps.redComponent)
                    settings.colorGreen = Double(comps.greenComponent)
                    settings.colorBlue = Double(comps.blueComponent)
                }
            }
        )
    }

    var body: some View {
        Form {
            Section("ホットキー") {
                HStack {
                    Text("表示キー")
                    Spacer()
                    HotkeyRecorderView(settings: settings)
                        .frame(width: 220)
                }
                Text("クリックしてから使いたいキーを押します。変更は即時反映されます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("アニメーション") {
                Picker("モード", selection: $settings.mode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                LabeledContent("1つの円の時間") {
                    HStack {
                        ModernSlider(value: $settings.duration, range: 0.2...2.0, step: 0.05)
                        Text(String(format: "%.2f 秒", settings.duration))
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                LabeledContent("円の数") {
                    HStack {
                        ModernSlider(value: ringCountBinding, range: 1...10, step: 1)
                        Text("\(settings.ringCount)")
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                LabeledContent("円ごとの遅延") {
                    HStack {
                        ModernSlider(value: $settings.ringDelay, range: 0...0.6, step: 0.05)
                        Text(String(format: "%.2f 秒", settings.ringDelay))
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                LabeledContent("線の太さ") {
                    HStack {
                        ModernSlider(value: $settings.strokeWidth, range: 1...20, step: 1)
                        Text("\(Int(settings.strokeWidth)) pt")
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                ColorPicker("円の色", selection: colorBinding, supportsOpacity: false)
                Toggle("ガラス風の見た目（光沢とハイライト）", isOn: $settings.glassStyle)
                Text(String(format: "全体の長さ: 約 %.1f 秒", settings.totalDuration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("開始半径") {
                Toggle("auto（画面配置全体が入る大きさ）", isOn: $settings.startRadiusAuto)
                if !settings.startRadiusAuto {
                    LabeledContent("固定半径") {
                        HStack {
                            ModernSlider(value: $settings.startRadius, range: 100...3000, step: 50)
                            Text("\(Int(settings.startRadius)) pt")
                                .monospacedDigit()
                                .frame(width: 70, alignment: .trailing)
                        }
                    }
                }
                LabeledContent("収束先の半径") {
                    HStack {
                        ModernSlider(value: $settings.endRadius, range: 0...50, step: 1)
                        Text("\(Int(settings.endRadius)) pt")
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }

            Section {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text(versionString)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 560)
    }
}
