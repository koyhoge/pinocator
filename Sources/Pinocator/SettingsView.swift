import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared

    /// Info.plist のバージョン表記（例: "0.2.0"）
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
            Section {
                HStack {
                    Text(L10n.t("settings.trigger_key"))
                    Spacer()
                    HotkeyRecorderView(settings: settings)
                        .frame(width: 220)
                }
                Text(L10n.t("settings.hotkey_hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(L10n.t("section.hotkey"))
            }

            Section {
                Picker(selection: $settings.mode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                } label: {
                    Text(L10n.t("settings.mode"))
                }
                LabeledContent {
                    HStack {
                        ModernSlider(value: $settings.duration, range: 0.2...2.0, step: 0.05)
                        Text(L10n.t("format.seconds", settings.duration))
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                } label: {
                    Text(L10n.t("settings.ring_duration"))
                }
                LabeledContent {
                    HStack {
                        ModernSlider(value: ringCountBinding, range: 1...10, step: 1)
                        Text("\(settings.ringCount)")
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                } label: {
                    Text(L10n.t("settings.ring_count"))
                }
                LabeledContent {
                    HStack {
                        ModernSlider(value: $settings.ringDelay, range: 0...0.6, step: 0.05)
                        Text(L10n.t("format.seconds", settings.ringDelay))
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                } label: {
                    Text(L10n.t("settings.ring_delay"))
                }
                LabeledContent {
                    HStack {
                        ModernSlider(value: $settings.strokeWidth, range: 1...20, step: 1)
                        Text("\(Int(settings.strokeWidth)) pt")
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                } label: {
                    Text(L10n.t("settings.stroke_width"))
                }
                ColorPicker(selection: colorBinding, supportsOpacity: false) {
                    Text(L10n.t("settings.ring_color"))
                }
                Toggle(isOn: $settings.glassStyle) {
                    Text(L10n.t("settings.glass_style"))
                }
                Text(L10n.t("format.total_length", settings.totalDuration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(L10n.t("section.animation"))
            }

            Section {
                Toggle(isOn: $settings.startRadiusAuto) {
                    Text(L10n.t("settings.radius_auto"))
                }
                if !settings.startRadiusAuto {
                    LabeledContent {
                        HStack {
                            ModernSlider(value: $settings.startRadius, range: 100...3000, step: 50)
                            Text("\(Int(settings.startRadius)) pt")
                                .monospacedDigit()
                                .frame(width: 70, alignment: .trailing)
                        }
                    } label: {
                        Text(L10n.t("settings.radius_fixed"))
                    }
                }
                LabeledContent {
                    HStack {
                        ModernSlider(value: $settings.endRadius, range: 0...50, step: 1)
                        Text("\(Int(settings.endRadius)) pt")
                            .monospacedDigit()
                            .frame(width: 60, alignment: .trailing)
                    }
                } label: {
                    Text(L10n.t("settings.end_radius"))
                }
            } header: {
                Text(L10n.t("section.start_radius"))
            }

            Section {
                HStack {
                    Text(L10n.t("settings.version"))
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
