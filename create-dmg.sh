#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
BUILD="$ROOT/build"
DIST="$ROOT/dist"
APP="$BUILD/TermYes.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Info.plist")"

if [[ ! -d "$APP" ]]; then
  SKIP_INSTALL=1 "$ROOT/build.sh"
fi
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")" == "$VERSION" ]] || {
  echo "Built app version differs from Info.plist; rebuild first." >&2
  exit 1
}
codesign --verify --deep --strict "$APP"
mkdir -p "$DIST"

# ponytail: one extra compatibility image keeps existing Termosaic updaters working.
# Both carry the identical signed TermYes app; only the outer bundle/image names differ.
for brand in TermYes Termosaic; do
  STAGING="$BUILD/dmg-staging-$brand"
  NAME="$brand-v${VERSION}-macOS.dmg"
  DMG="$DIST/$NAME"
  if [[ -e "$STAGING" ]]; then /bin/rm -R "$STAGING"; fi
  if [[ -e "$DMG" ]]; then /bin/rm "$DMG"; fi
  mkdir -p "$STAGING"
  ditto "$APP" "$STAGING/$brand.app"
  ln -s /Applications "$STAGING/Applications"

  if diskutil image create from --help 2>&1 | grep -q -- '--volumeName'; then
    diskutil image create from --format UDZO --volumeName "$brand" "$STAGING" "$DMG" >/dev/null
  else
    hdiutil create -volname "$brand" -srcfolder "$STAGING" -format UDZO \
      -imagekey zlib-level=9 -ov "$DMG" >/dev/null
  fi

  hdiutil verify "$DMG" >/dev/null
  (cd "$DIST" && shasum -a 256 "$NAME" > "$NAME.sha256")
  printf 'Created: %s\n' "$DMG"
done
