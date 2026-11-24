#!/bin/zsh
# リリース用 zip を作る（make_app.sh でビルド → .app を zip 化）
# 使い方: ./scripts/release.sh
# 出来た zip を GitHub Release に添付する:
#   gh release create v<version> build/Pinocator-<version>.zip
# または Releases ページの "Draft a new release" から手動で添付。
set -e
cd "$(dirname "$0")/.."

./scripts/make_app.sh

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
ZIP="build/Pinocator-$VERSION.zip"
rm -f "$ZIP"
# .app バンドルは ditto で zip 化する（リソースフォーク等を保持）
ditto -c -k --sequesterRsrc --keepParent "build/Pinocator.app" "$ZIP"
echo "Release zip: $ZIP"
echo "Upload:      gh release create v$VERSION \"$ZIP\""
