#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
BUILD="$ROOT/build"
DIST="$ROOT/dist"
APP="$BUILD/Termosaic.app"
STAGING="$BUILD/dmg-staging"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Info.plist")"
DMG="$DIST/Termosaic-v${VERSION}-macOS.dmg"
CHECKSUM="$DMG.sha256"

if [[ ! -d "$APP" ]]; then
  SKIP_INSTALL=1 "$ROOT/build.sh"
fi

if [[ -e "$STAGING" ]]; then /bin/rm -R "$STAGING"; fi
if [[ -e "$DMG" ]]; then /bin/rm "$DMG"; fi
if [[ -e "$CHECKSUM" ]]; then /bin/rm "$CHECKSUM"; fi
mkdir -p "$STAGING" "$DIST"

ditto "$APP" "$STAGING/Termosaic.app"
ln -s /Applications "$STAGING/Applications"

if diskutil image create from --help >/dev/null 2>&1; then
  diskutil image create from \
    --format UDZO \
    --volumeName "Termosaic" \
    "$STAGING" \
    "$DMG" >/dev/null
else
  hdiutil create \
    -volname "Termosaic" \
    -srcfolder "$STAGING" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$DMG" >/dev/null
fi

hdiutil verify "$DMG" >/dev/null
shasum -a 256 "$DMG" > "$CHECKSUM"

printf 'Created: %s\n' "$DMG"
printf 'SHA-256: '
awk '{print $1}' "$CHECKSUM"
