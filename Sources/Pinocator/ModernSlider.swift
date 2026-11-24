import SwiftUI

/// 標準 Slider の昔ながらの見た目を避けるための自前スライダー。
/// 太めの角丸トラック＋大きめのつまみ。操作感は標準と同じ
/// （ドラッグ、クリック位置へのジャンプ、step 刻みの吸着）。
/// つまみだけ macOS 26 以降で本物の Liquid Glass になる
/// （トラックもガラスにした版は 2026-11-24 に試して不採用）。
struct ModernSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0

    private let thumbSize: CGFloat = 20
    private let trackHeight: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let trackWidth = max(0, geo.size.width - thumbSize)
            let fraction = fraction(for: value)
            let thumbX = thumbSize / 2 + fraction * trackWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: trackHeight)
                    .padding(.horizontal, thumbSize / 2)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: thumbX, height: trackHeight)
                thumb
                    .offset(x: thumbX - thumbSize / 2)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        guard trackWidth > 0 else { return }
                        let f = min(1, max(0, (drag.location.x - thumbSize / 2) / trackWidth))
                        setValue(fromFraction: f)
                    }
            )
        }
        .frame(height: thumbSize)
        .accessibilityElement()
        .accessibilityValue(Text(String(format: "%.2f", value)))
        .accessibilityAdjustableAction { direction in
            let delta = (step > 0 ? step : range.upperBound - range.lowerBound)
                * (direction == .increment ? 0.1 : -0.1)
            let raw = min(range.upperBound, max(range.lowerBound, value + delta))
            value = snapped(raw)
        }
    }

    /// つまみ。macOS 26 以降は本物の Liquid Glass、それ以前は白い円。
    @ViewBuilder
    private var thumb: some View {
        if #available(macOS 26, *) {
            Circle()
                .fill(.clear)
                .frame(width: thumbSize, height: thumbSize)
                .glassEffect(.regular.interactive(), in: .circle)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        } else {
            Circle()
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 0.5))
        }
    }

    private func fraction(for v: Double) -> CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return CGFloat((v - range.lowerBound) / span)
    }

    private func setValue(fromFraction f: CGFloat) {
        let raw = range.lowerBound + Double(f) * (range.upperBound - range.lowerBound)
        value = snapped(raw)
    }

    private func snapped(_ raw: Double) -> Double {
        let clamped = min(range.upperBound, max(range.lowerBound, raw))
        guard step > 0 else { return clamped }
        return min(range.upperBound,
                   max(range.lowerBound, (clamped / step).rounded() * step))
    }
}
