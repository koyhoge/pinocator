# Pinocator 設計メモ（Swift 版）

Hammerspoon 版プロトタイプ（pinocator.lua）で確定した仕様を、Swift 製
常駐アプリへ移植するための設計メモ。仕様の正本は実機で検証済みの
Hammerspoon 版の挙動とする。

## 目的

実画面＋SpaceWalker 仮想画面のようなマルチスクリーン環境でマウス
カーソルを見失ったとき、ホットキー1つでカーソルの在り処を即座に
分かるようにする。

## 確定した挙動（Hammerspoon 版で実機確認済み）

- ホットキーを押すと、**巨大な円（線のみ）がカーソルの点に向かって
  収束する**アニメーションを表示する。拡大する波紋ではない。
- デフォルトモードは **global**：全画面を1つの座標空間として扱い、
  各画面には「本物の円の続き」を描く。カーソルのない画面では円弧が
  画面端から入ってくるため、カーソルの方向と距離感が幾何学的に
  そのまま読める。本人が SpaceWalker 実機で「理想通り」と評価。
- 開始半径は **auto**：全画面の外接矩形の4隅のうちカーソルから
  最も遠い点までの距離を、発火ごとに計算する（画面構成の変化に追従）。
- パラメータ（確定値）:
  - ホットキー: Shift+F12（変更可能であることが必須要件）
  - duration 0.8s / ringCount 5 / ringDelay 0.3s（全体で約2.0s）
  - startRadius "auto" / endRadius 0
  - strokeWidth 8 / 色は青系 (0.15, 0.55, 1.0)
- アニメーションの式:
  - 半径: r(p) = end + (start − end) × (1−p)³
    （最初は速く、点に近づくにつれてゆっくり収束）
  - 透明度: alpha(p) = 1 − p²
  - p はリングごとの開始遅延を差し引いた正規化時刻

## モード（CONFIG.mode の移植）

- `global`（デフォルト）: 上記。全画面に本物の円を描く
- `hint`: カーソルの画面だけ円を描き、他の画面には「その画面内で
  カーソルに一番近い点」へ矢印（8方位）＋カーソルのある画面名の
  バッジを出す。円の終了後 0.6s かけてフェードアウト
- `mirror`: 各画面の同じ相対位置に円を写す
- `none`: カーソルのある画面だけ

## Swift 版の実装方針

- 言語/形態: Swift + AppKit のメニューバー常駐アプリ（LSUIElement）。
  Swift Package Manager でビルドし、シェルスクリプトで .app に包む。
  対象は macOS 13 以降、Apple Silicon。
- 座標系: Cocoa は左下原点のグローバル座標で、`NSEvent.mouseLocation`
  と `NSScreen.frame` が同じ空間にある。Hammerspoon（左上原点）と
  違い Y 反転は不要で、画面ローカル中心は
  `mouseLocation − screen.frame.origin` で得られる。
- 描画: 画面ごとに borderless・透明・クリック透過
  （`ignoresMouseEvents = true`）の NSWindow を置き、
  level は `.screenSaver`、collectionBehavior に
  `canJoinAllSpaces / fullScreenAuxiliary / stationary` を付ける。
  中身の NSView が `draw(_:)` で NSBezierPath の円を stroke する。
  タイマー（60fps）で経過時間を持ち、再描画する素朴な方式で十分。
- ホットキー: Carbon の `RegisterEventHotKey` を使う。
  アクセシビリティ権限が不要で、他アプリにフォーカスがあっても効く。
  設定 GUI ではキー入力をキャプチャして keyCode＋Carbon 修飾キーに
  変換し、UserDefaults に保存する。
- 設定: UserDefaults に保存し、設定ウィンドウ（SwiftUI）から変更。
  変更は次の発火から反映。ホットキーだけは即時に再登録する。
- 権限: 画面収録もアクセシビリティも不要。署名は当面 ad hoc でよい
  （公証・配布は将来課題）。

## v1 の範囲

- global / hint / mirror / none の4モード
- 設定 GUI（ホットキー記録、数値パラメータ、色、モード）
- メニューバーからの手動発火と終了

将来課題: アプリアイコン、ログイン時起動、公証と配布、Spoon 版の扱い。
