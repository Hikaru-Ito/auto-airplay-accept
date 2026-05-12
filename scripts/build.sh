#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$PROJECT_ROOT/src/main.applescript"
DIST_DIR="$PROJECT_ROOT/dist"
APP_NAME="AirPlay Auto Accept"
APP_PATH="$DIST_DIR/$APP_NAME.app"
BUNDLE_ID="com.hikaru-ito.airplay-auto-accept"
VERSION="${VERSION:-1.0.0}"

if [[ ! -f "$SRC" ]]; then
	echo "Error: AppleScript source not found at $SRC" >&2
	exit 1
fi

mkdir -p "$DIST_DIR"
rm -rf "$APP_PATH"

echo "▶ Compiling AppleScript Applet..."
# -s: stay-open applet (idle handlerを使うために必須)
osacompile -s -o "$APP_PATH" "$SRC"

INFO_PLIST="$APP_PATH/Contents/Info.plist"

echo "▶ Patching Info.plist..."

set_or_add_plist() {
	local key="$1"
	local type="$2"
	local value="$3"
	if /usr/libexec/PlistBuddy -c "Print :$key" "$INFO_PLIST" >/dev/null 2>&1; then
		/usr/libexec/PlistBuddy -c "Set :$key $value" "$INFO_PLIST"
	else
		/usr/libexec/PlistBuddy -c "Add :$key $type $value" "$INFO_PLIST"
	fi
}

# Dock/メニューバーに出さない（バックグラウンドUIElement）
set_or_add_plist "LSUIElement" "bool" "true"
# Bundle identifier
set_or_add_plist "CFBundleIdentifier" "string" "$BUNDLE_ID"
# Versions
set_or_add_plist "CFBundleShortVersionString" "string" "$VERSION"
set_or_add_plist "CFBundleVersion" "string" "$VERSION"
# Display name
set_or_add_plist "CFBundleDisplayName" "string" "$APP_NAME"
set_or_add_plist "CFBundleName" "string" "$APP_NAME"
# 最小macOS（控えめに11.0）
set_or_add_plist "LSMinimumSystemVersion" "string" "11.0"
# 権限ダイアログに表示される説明文
set_or_add_plist "NSAppleEventsUsageDescription" "string" "AirPlay Auto Accept は、AirPlay 受信ダイアログの「受け入れる」ボタンを自動でクリックするために、システムのUI操作権限を必要とします。"

# ad-hoc署名（未署名だとGatekeeperで毎回弾かれる対策の最低限）
echo "▶ Ad-hoc signing..."
codesign --force --deep --sign - "$APP_PATH" >/dev/null 2>&1 || true

echo ""
echo "✅ Build complete:"
echo "   $APP_PATH"
echo ""
echo "Test run:"
echo "   open \"$APP_PATH\""
