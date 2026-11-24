import Foundation

/// プラットフォーム非依存の純粋な計算だけを集めたもの。
/// Foundation のみで書かれているので、Linux 上でも単体テストできる
/// （Tests/GeometryTests を swiftc で直接コンパイルして実行）。
enum Geometry {
    /// "auto" 半径: 全画面の外接矩形の4隅のうち、カーソルから
    /// 一番遠い点までの距離。
    static func autoRadius(mouse: CGPoint, frames: [CGRect]) -> CGFloat {
        guard var union = frames.first else { return 800 }
        for frame in frames.dropFirst() {
            union = union.union(frame)
        }
        let corners = [
            CGPoint(x: union.minX, y: union.minY),
            CGPoint(x: union.maxX, y: union.minY),
            CGPoint(x: union.minX, y: union.maxY),
            CGPoint(x: union.maxX, y: union.maxY),
        ]
        return corners.map { hypot($0.x - mouse.x, $0.y - mouse.y) }.max() ?? 800
    }

    /// 収束半径: 最初は速く、点に近づくにつれてゆっくり ((1-p)^3)。
    static func ringRadius(progress p: Double, start: CGFloat, end: CGFloat) -> CGFloat {
        end + (start - end) * CGFloat(pow(1 - p, 3))
    }

    /// リングの不透明度。
    static func ringAlpha(progress p: Double) -> CGFloat {
        CGFloat(1 - p * p)
    }

    /// Cocoa 座標（y 上向き）で、画面中心から見た点の方向を8方位矢印にする。
    static func directionArrow(from screenFrame: CGRect, to point: CGPoint) -> String {
        let angle = atan2(point.y - screenFrame.midY, point.x - screenFrame.midX)
        var idx = Int(floor((angle + .pi / 8) / (.pi / 4)))
        idx = ((idx % 8) + 8) % 8
        let arrows = ["→", "↗", "↑", "↖", "←", "↙", "↓", "↘"]
        return arrows[idx]
    }
}
