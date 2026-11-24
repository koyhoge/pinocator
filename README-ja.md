# Pinocator（Swift 版）

ホットキーを押すと、巨大な円（線のみ）がマウスカーソルの点に向かって
収束するアニメーションを全スクリーンに表示する macOS 常駐ユーティリティ。
Hammerspoon 版プロトタイプで確定した仕様の Swift 移植。設計の詳細は
[SPEC.md](SPEC.md) を参照。英語版は [README.md](README.md)。

## ビルドと実行（Mac）

前提: macOS 13 以降、Xcode または Command Line Tools（Swift 5.9+）。

```zsh
cd Pinocator
./scripts/make_app.sh     # build/Pinocator.app ができる
open build/Pinocator.app  # メニューバーに ◎ が出れば起動成功
```

開発中は `swift run` でも起動できる（その場合もメニューバー常駐になる）。

## 使い方

- デフォルトのホットキーは **Shift+F12**。押すとアニメーションが出る
- メニューバーの ◎ から「今すぐ表示」「設定…」「終了」
- 設定は UserDefaults に保存され、次回の表示から反映される
  （ホットキーの変更だけは即時反映）
- 権限は不要（アクセシビリティも画面収録も使わない）

## 注意点

- F12 は Apple 純正キーボードでは音量キーと共用のことがある。
  その場合は「システム設定 → キーボード」で F キーを標準
  ファンクションキーとして使う設定にするか、設定画面で別のキーに変更する
- 署名は ad hoc のみ。自分の Mac で使う前提で、公証はしていない

## 構成

- `Sources/Pinocator/main.swift` — エントリポイント
- `AppDelegate.swift` — メニューバー、設定ウィンドウ、ホットキー配線
- `HotkeyManager.swift` — Carbon RegisterEventHotKey
- `OverlayController.swift` — 画面ごとのオーバーレイ生成とモード分岐
- `RippleView.swift` — 収束円の描画とアニメーション（ガラス風の見た目を含む）
- `HintView.swift` — hint モードのバッジ（矢印＋画面名）
- `Settings.swift` — 設定ストア（UserDefaults）
- `SettingsView.swift` / `HotkeyRecorderView.swift` — 設定 GUI
- `ModernSlider.swift` — 設定 GUI 用の自前スライダー
  （macOS 26 以降ではつまみが Liquid Glass になる）
- `Geometry.swift` — プラットフォーム非依存の計算（auto 半径、収束
  半径・透明度、8方位矢印）。Foundation のみで、Linux でもテスト可能
- `Tests/GeometryTests/main.swift` — Geometry の単体テスト
- `Resources/AppIcon.iconset/` — アプリアイコン
  （生成は `scripts/make_icon.py`、要 Pillow。make_app.sh が
  iconutil で .icns 化してバンドルに入れる）

## テスト

Geometry の単体テストは macOS / Linux どちらでも実行できる:

```zsh
swiftc Sources/Pinocator/Geometry.swift Tests/GeometryTests/main.swift -o /tmp/geomtest
/tmp/geomtest
```

## 既知の制限・TODO

- メニューの「今すぐ表示」に表示されるキー名は起動時点のもの
  （ホットキーを変えても表記が追従しない。実害はなし）
- ログイン時起動なし
- Mac 実機でビルドと動作を確認済み（2026-11-24、SpaceWalker の
  仮想画面を含むマルチスクリーンでも動作）。開発 VM（Linux）では
  Swift 6.4.3 で全ファイルの構文チェック（swiftc -parse）と
  Geometry の単体テスト13件の合格までを確認している
