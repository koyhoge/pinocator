import Foundation

// Geometry.swift の単体テスト（Linux / macOS 共通）。
// 実行方法: swiftc Sources/Pinocator/Geometry.swift Tests/GeometryTests/main.swift -o /tmp/geomtest && /tmp/geomtest

var failures = 0

func check(_ condition: Bool, _ message: String) {
    if condition {
        print("PASS: \(message)")
    } else {
        print("FAIL: \(message)")
        failures += 1
    }
}

func checkClose(_ actual: CGFloat, _ expected: CGFloat, tolerance: CGFloat = 1.0, _ message: String) {
    check(abs(actual - expected) < tolerance,
          "\(message) (got \(actual), expected ~\(expected))")
}

// autoRadius: 2画面横並び、カーソル (500,400)
// 外接矩形 (0,0)-(3840,1080) の最遠隅は (3840,1080): sqrt(3340^2 + 680^2) ≒ 3408.5
let frames2 = [
    CGRect(x: 0, y: 0, width: 1920, height: 1080),
    CGRect(x: 1920, y: 0, width: 1920, height: 1080),
]
checkClose(Geometry.autoRadius(mouse: CGPoint(x: 500, y: 400), frames: frames2),
           3408.5, "autoRadius 2 screens")

// autoRadius: 1画面、カーソルが中心なら最遠隅は対角の半分 ≒ 1101.5
checkClose(Geometry.autoRadius(mouse: CGPoint(x: 960, y: 540), frames: [frames2[0]]),
           1101.5, "autoRadius 1 screen centered")

// autoRadius: 画面が空ならフォールバック 800
checkClose(Geometry.autoRadius(mouse: .zero, frames: []), 800, "autoRadius empty")

// ringRadius: p=0 で start、p=1 で end、p=0.1 で start * 0.9^3
checkClose(Geometry.ringRadius(progress: 0, start: 1000, end: 0), 1000, "ringRadius p=0")
checkClose(Geometry.ringRadius(progress: 1, start: 1000, end: 0), 0, "ringRadius p=1")
checkClose(Geometry.ringRadius(progress: 0.1, start: 1000, end: 0), 729, "ringRadius p=0.1")
checkClose(Geometry.ringRadius(progress: 0.5, start: 1000, end: 100), 212.5, "ringRadius with end")

// ringAlpha: 1 - p^2
checkClose(Geometry.ringAlpha(progress: 0), 1, "ringAlpha p=0")
checkClose(Geometry.ringAlpha(progress: 0.5), 0.75, "ringAlpha p=0.5")
checkClose(Geometry.ringAlpha(progress: 1), 0, "ringAlpha p=1")

// directionArrow: 右画面から見てカーソルは左 → "←"
check(Geometry.directionArrow(from: frames2[1], to: CGPoint(x: 500, y: 400)) == "←",
      "directionArrow left")
// directionArrow: 左画面中心から右上 → "↗"
check(Geometry.directionArrow(from: frames2[0], to: CGPoint(x: 3000, y: 1500)) == "↗",
      "directionArrow up-right")
// directionArrow: 真下 → "↓"
check(Geometry.directionArrow(from: frames2[0], to: CGPoint(x: 960, y: -500)) == "↓",
      "directionArrow down")

if failures > 0 {
    print("\(failures) FAILURE(S)")
    exit(1)
}
print("ALL TESTS PASSED")
