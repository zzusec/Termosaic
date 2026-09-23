#!/bin/bash
set -euo pipefail

ROOT="$(mktemp -d /tmp/termosaic-updater-test.XXXXXX)"
cleanup() {
  find "$ROOT" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT

APP="build/TermYes.app"
HELPER="$APP/Contents/Helpers/TermYesUpdateInstaller"
ditto "$APP" "$ROOT/Installed.app"
ditto "$APP" "$ROOT/Staged.app"

TERMOSAIC_UPDATE_SKIP_LAUNCH=1 "$HELPER" \
  999999 \
  "$ROOT/Staged.app" \
  "$ROOT/Installed.app" \
  "$ROOT/Backup.app" \
  "$ROOT/update.log"

test -d "$ROOT/Installed.app"
test ! -e "$ROOT/Staged.app"
test ! -e "$ROOT/Backup.app"
codesign --verify --deep --strict "$ROOT/Installed.app"
grep -q "Update installed" "$ROOT/update.log"
echo "Update installer test passed."
