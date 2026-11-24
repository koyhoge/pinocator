#!/bin/zsh
# Pinocator.app を組み立てる（SPM リリースビルド → .app バンドル → ad hoc 署名）
set -e
cd "$(dirname "$0")/.."

swift build -c release

APP="build/Pinocator.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/Pinocator" "$APP/Contents/MacOS/Pinocator"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"

codesign --force --sign - "$APP"
echo "Built: $APP"
echo "Run:   open $APP"
