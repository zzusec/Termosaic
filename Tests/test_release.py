#!/usr/bin/env python3
"""Verify both release layouts and updater replacement using only temporary app copies."""
import hashlib
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build/TermYes.app'
INFO = plistlib.loads((ROOT / 'Info.plist').read_bytes())
VERSION = INFO['CFBundleShortVersionString']


def run(*args, **kwargs):
    return subprocess.run([str(x) for x in args], check=True, text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, **kwargs).stdout


def bundle_files(bundle):
    return {str(p.relative_to(bundle)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in bundle.rglob('*') if p.is_file()}


expected = bundle_files(BUILD)
assert INFO['CFBundleIdentifier'] == 'io.github.zzusec.termosaic', 'Keep the existing settings identity'
assert INFO['CFBundleName'] == INFO['CFBundleDisplayName'] == INFO['CFBundleExecutable'] == 'TermYes'
assert expected, 'Build the application first'

with tempfile.TemporaryDirectory(prefix='termyes-release-test-') as folder:
    root = Path(folder)
    for brand in ('TermYes', 'Termosaic'):
        filename = f'{brand}-v{VERSION}-macOS.dmg'
        image = ROOT / 'dist' / filename
        checksum = image.with_suffix('.dmg.sha256').read_text().split()
        assert checksum == [hashlib.sha256(image.read_bytes()).hexdigest(), filename], 'Portable SHA-256 mismatch'
        mount = root / f'mount-{brand}'
        mount.mkdir()
        run('/usr/bin/hdiutil', 'attach', image, '-readonly', '-nobrowse', '-mountpoint', mount)
        try:
            app = mount / f'{brand}.app'
            assert app.is_dir(), f'{brand} updater expects this bundle name'
            info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
            assert info == INFO, 'Main and compatibility images must carry the same release metadata'
            assert bundle_files(app) == expected, 'Mounted app differs from the signed build'
            run('/usr/bin/codesign', '--verify', '--deep', '--strict', app)
            architectures = run('/usr/bin/lipo', '-archs', app / 'Contents/MacOS/TermYes').split()
            assert set(architectures) == {'arm64', 'x86_64'}, 'Missing universal architecture'
            assert (mount / 'Applications').is_symlink()
            assert os.readlink(mount / 'Applications') == '/Applications'

            installed = root / f'installed-{brand}' / f'{brand}.app'
            staged = root / f'staged-{brand}.app'
            backup = root / f'backup-{brand}.app'
            run('/usr/bin/ditto', app, installed)
            run('/usr/bin/ditto', app, staged)
            env = dict(os.environ, TERMOSAIC_UPDATE_SKIP_LAUNCH='1')
            run(BUILD / 'Contents/Helpers/TermYesUpdateInstaller', '999999', staged,
                installed, backup, root / f'update-{brand}.log', env=env)
            assert not staged.exists() and not backup.exists(), 'Temporary replacement did not complete'
            assert bundle_files(installed) == expected, 'Update changed bundle contents'
            run('/usr/bin/codesign', '--verify', '--deep', '--strict', installed)
        finally:
            run('/usr/bin/hdiutil', 'detach', mount, '-quiet')
        print(f'{filename}: checksum, bundle identity, universal signature, and temporary update passed')

print(f'TermYes v{VERSION} release checks passed; no installed application was changed or launched.')
