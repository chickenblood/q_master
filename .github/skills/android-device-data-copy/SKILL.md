---
name: android-device-data-copy
description: "Use when copying Android app user data directly from one device/emulator to another with adb run-as tar streaming. Keywords: android data migration, copy app sandbox, adb run-as tar, emulator to device, q master data transfer."
---

# Android Device Data Copy

Use this skill to copy app user data from one Android device/emulator to another using only a direct `adb` stream between app sandboxes.

This workflow is the validated approach for Q Master and avoids intermediate `/sdcard` copy steps.

## Inputs To Gather

- Source device serial (from `adb devices -l`)
- Destination device serial (from `adb devices -l`)
- Android package name (for Q Master: `com.f3nation.q_master`)
- Host `adb` path (for this machine: `$HOME/Library/Android/sdk/platform-tools/adb`)

## Preconditions

- App is installed on both source and destination.
- `run-as` access works on both devices (debuggable build and matching signature).
- Source and destination are both listed as `device`.

## Workflow

### 1) Verify connectivity and sandbox access

```bash
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
SRC="<SOURCE_SERIAL>"
DST="<DEST_SERIAL>"
PKG="<PACKAGE_NAME>"

"$ADB" devices -l
"$ADB" -s "$SRC" get-state
"$ADB" -s "$DST" get-state
"$ADB" -s "$SRC" shell run-as "$PKG" pwd
"$ADB" -s "$DST" shell run-as "$PKG" pwd
```

### 2) Stop destination app before restore

```bash
"$ADB" -s "$DST" shell am force-stop "$PKG"
```

### 3) Stream-copy app data directories source -> destination

```bash
DIRS=(app_flutter app_textures app_webview cache code_cache files no_backup shared_prefs)

for d in "${DIRS[@]}"; do
  echo "Copying $d"
  "$ADB" -s "$SRC" exec-out run-as "$PKG" tar -cf - "$d" 2>/dev/null \
    | "$ADB" -s "$DST" shell run-as "$PKG" tar -xf - 2>/dev/null || true
done
```

This performs a merge restore: source data is copied onto destination without deleting destination-only files.

### 4) Verify no source files are missing on destination

```bash
TMPDIR="/tmp/android_data_verify_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TMPDIR"

"$ADB" -s "$SRC" shell run-as "$PKG" sh -c \
  'find app_flutter app_textures app_webview cache code_cache files no_backup shared_prefs -type f 2>/dev/null | sort' \
  | tr -d '\r' > "$TMPDIR/src.txt"

"$ADB" -s "$DST" shell run-as "$PKG" sh -c \
  'find app_flutter app_textures app_webview cache code_cache files no_backup shared_prefs -type f 2>/dev/null | sort' \
  | tr -d '\r' > "$TMPDIR/dst.txt"

MISSING=$(comm -23 "$TMPDIR/src.txt" "$TMPDIR/dst.txt" | wc -l | tr -d ' ')
echo "Missing-on-destination count: $MISSING"

if [ "$MISSING" -gt 0 ]; then
  echo "First missing paths:"
  comm -23 "$TMPDIR/src.txt" "$TMPDIR/dst.txt" | head -n 20
fi
```

Success criteria:
- `Missing-on-destination count: 0`

## Q Master Defaults

```bash
SRC="emulator-5554"
DST="2B291FDH2001GT"
PKG="com.f3nation.q_master"
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
```
