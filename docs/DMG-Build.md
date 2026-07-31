# Building the AutoClicker Pro DMG

This document describes how to package an existing Release build of
`AutoClicker Pro.app` without rebuilding or re-signing it.

## Required tools

- macOS with Xcode Command Line Tools
- `/usr/bin/hdiutil`
- `/usr/bin/ditto`
- Python 3
- [`ds-store`](https://pypi.org/project/ds-store/) 1.3.3, installed into a
  temporary directory for writing Finder layout metadata

No background artwork is required. The release image uses a white Finder
background.

## Inputs and output

- Input: an existing Release build of `AutoClicker Pro.app`
- Output: `dist/AutoClicker-Pro-v1.0.0.dmg`
- Volume name: `AutoClicker Pro`

The input application must already have the intended bundle identifier, version,
icon, entitlements, and signature. The packaging process does not alter them.

## Build commands

Run the following commands from the repository root. Replace `APP_PATH` with the
path to the approved Release application.

```sh
APP_PATH="/path/to/Release/AutoClicker Pro.app"
WORK_DIR="$(mktemp -d /private/tmp/autoclicker-pro-dmg.XXXXXX)"
MOUNT_DIR="$WORK_DIR/mount"
RW_IMAGE="$WORK_DIR/AutoClicker-Pro-rw.dmg"
OUTPUT_IMAGE="$PWD/dist/AutoClicker-Pro-v1.0.0.dmg"

mkdir -p "$MOUNT_DIR" "$PWD/dist"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"

hdiutil create \
  -size 32m \
  -fs HFS+ \
  -volname "AutoClicker Pro" \
  -ov \
  "$RW_IMAGE"

hdiutil attach \
  "$RW_IMAGE" \
  -readwrite \
  -noverify \
  -noautoopen \
  -mountpoint "$MOUNT_DIR"

ditto --rsrc --extattr "$APP_PATH" "$MOUNT_DIR/AutoClicker Pro.app"
ln -s /Applications "$MOUNT_DIR/Applications"

python3 -m pip install \
  --disable-pip-version-check \
  --target "$WORK_DIR/python-packages" \
  ds-store==1.3.3
```

Create `$WORK_DIR/write_layout.py` with the following contents:

```python
import sys

sys.path.insert(0, sys.argv[1])

from ds_store import DSStore, DSStoreEntry
from ds_store.store import ILocCodec, PlistCodec

mount_path = sys.argv[2]

window_settings = {
    "ContainerShowSidebar": False,
    "ShowPathbar": False,
    "ShowSidebar": False,
    "ShowStatusBar": False,
    "ShowTabView": False,
    "ShowToolbar": False,
    "WindowBounds": "{{200, 160}, {680, 420}}",
}

icon_settings = {
    "arrangeBy": "none",
    "backgroundColorBlue": 1.0,
    "backgroundColorGreen": 1.0,
    "backgroundColorRed": 1.0,
    "backgroundType": 1,
    "gridOffsetX": 0.0,
    "gridOffsetY": 0.0,
    "gridSpacing": 100.0,
    "iconSize": 128.0,
    "labelOnBottom": True,
    "scrollPositionX": 0.0,
    "scrollPositionY": 0.0,
    "showIconPreview": True,
    "showItemInfo": False,
    "textSize": 14.0,
    "viewOptionsVersion": 1,
}

entries = [
    DSStoreEntry(".", b"bwsp", PlistCodec, window_settings),
    DSStoreEntry(".", b"icvp", PlistCodec, icon_settings),
    DSStoreEntry(".", b"vstl", b"type", b"icnv"),
    DSStoreEntry("AutoClicker Pro.app", b"Iloc", ILocCodec, (180, 210)),
    DSStoreEntry("Applications", b"Iloc", ILocCodec, (500, 210)),
]

DSStore.open(f"{mount_path}/.DS_Store", "w+", initial_entries=entries).close()
```

Complete the image:

```sh
python3 "$WORK_DIR/write_layout.py" \
  "$WORK_DIR/python-packages" \
  "$MOUNT_DIR"

sync
hdiutil detach "$MOUNT_DIR"

hdiutil convert \
  "$RW_IMAGE" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$OUTPUT_IMAGE"

(
  cd "$PWD/dist"
  shasum -a 256 "AutoClicker-Pro-v1.0.0.dmg" \
    > "AutoClicker-Pro-v1.0.0.dmg.sha256"
)
```

## Verification

Verify the disk image itself:

```sh
hdiutil verify "dist/AutoClicker-Pro-v1.0.0.dmg"
(
  cd dist
  shasum -a 256 -c "AutoClicker-Pro-v1.0.0.dmg.sha256"
)
```

Mount it read-only and inspect the contents:

```sh
VERIFY_DIR="$(mktemp -d /private/tmp/autoclicker-pro-verify.XXXXXX)"

hdiutil attach \
  "dist/AutoClicker-Pro-v1.0.0.dmg" \
  -readonly \
  -noverify \
  -noautoopen \
  -mountpoint "$VERIFY_DIR"

test -d "$VERIFY_DIR/AutoClicker Pro.app"
test "$(readlink "$VERIFY_DIR/Applications")" = "/Applications"
codesign --verify --deep --strict --verbose=2 \
  "$VERIFY_DIR/AutoClicker Pro.app"
```

Confirm the Finder metadata records contain:

- icon view (`vstl = icnv`)
- 680 x 420 window bounds
- hidden toolbar and status bar
- 128 px icon size
- white background
- application position `(180, 210)`
- Applications position `(500, 210)`

Finally, copy the app to `/Applications`, launch it, and remove the verification
copy after testing:

```sh
ditto --rsrc --extattr \
  "$VERIFY_DIR/AutoClicker Pro.app" \
  "/Applications/AutoClicker Pro.app"

open -n "/Applications/AutoClicker Pro.app"
```

Do not overwrite an existing installation without explicit confirmation. Runtime
verification should confirm that the process launches; Accessibility permission may
still need to be granted for that exact application identity.

## Release notes

- The DMG creation process preserves the input app's signature and does not sign or
  notarize the DMG.
- Verify that `CFBundleShortVersionString` matches the release filename before
  publishing.
- A locally or ad-hoc signed application is not equivalent to a Developer ID signed
  and notarized public release and may trigger Gatekeeper warnings on another Mac.
