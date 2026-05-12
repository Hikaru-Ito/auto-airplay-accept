#!/bin/bash
# .appをDMGにパッケージする（GitHub Releasesでの配布用）。
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
APP_NAME="AirPlay Auto Accept"
APP_PATH="$DIST_DIR/$APP_NAME.app"
VERSION="${VERSION:-1.0.0}"
DMG_PATH="$DIST_DIR/AirPlayAutoAccept-$VERSION.dmg"

if [[ ! -d "$APP_PATH" ]]; then
	echo "Error: $APP_PATH not found. Run scripts/build.sh first." >&2
	exit 1
fi

rm -f "$DMG_PATH"

STAGING="$(mktemp -d)"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "▶ Creating DMG..."
hdiutil create \
	-volname "$APP_NAME" \
	-srcfolder "$STAGING" \
	-ov \
	-format UDZO \
	"$DMG_PATH" >/dev/null

rm -rf "$STAGING"

echo "✅ DMG created: $DMG_PATH"
