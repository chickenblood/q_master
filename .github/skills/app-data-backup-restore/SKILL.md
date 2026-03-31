---
name: app-data-backup-restore
description: "Use when backing up or restoring phone app local data (Documents and Caches), simulator/emulator app containers, temp session data recovery, app state migration, or rehydrating test data for iOS and Android. Keywords: backup app data, restore app data, documents directory, caches directory, simctl get_app_container, adb run-as."
---

# App Data Backup And Restore

Use this skill to safely copy an app's local data out of a phone app container and restore it later.

Scope:
- iOS Simulator app containers via `xcrun simctl`
- Android emulator/device app containers via `adb` and `run-as`

This skill focuses on:
- `Documents` directory backup/restore
- `Library/Caches` (iOS) and `cache`/`code_cache` (Android) backup/restore

## Inputs To Gather

Collect these values before running commands:
- Platform: `ios` or `android`
- Device target:
  - iOS: simulator UDID (from `flutter devices` or `xcrun simctl list devices`)
  - Android: device serial (from `adb devices`)
- App id:
  - iOS bundle id, e.g. `com.f3nation.qmaster`
  - Android package name, e.g. `com.f3nation.q_master`
- Backup root directory on host machine

## Safety Rules

- Always terminate the app before restore to avoid partial writes.
- Create a pre-restore snapshot before overwriting current data.
- Prefer restoring only known files first (for example `workouts.json`) if schema compatibility is uncertain.
- Preserve directory structure and file timestamps when possible.
- Never run destructive host commands (`rm -rf`) against unresolved paths.

## iOS Simulator Workflow

### 1) Resolve app data container

```bash
xcrun simctl get_app_container <SIM_UDID> <BUNDLE_ID> data
```

Expected output: absolute path to the app's data container.

### 2) Backup Documents and Caches

```bash
SIM_UDID="<SIM_UDID>"
BUNDLE_ID="<BUNDLE_ID>"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="/tmp/app_backup_${STAMP}"

DATA_DIR="$(xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE_ID" data)"
mkdir -p "$OUT_DIR"
cp -R "$DATA_DIR/Documents" "$OUT_DIR/Documents"
cp -R "$DATA_DIR/Library/Caches" "$OUT_DIR/Caches"

# Optional integrity metadata
find "$OUT_DIR" -type f -maxdepth 3 2>/dev/null | sort > "$OUT_DIR/file_list.txt"
```

### 3) Restore Documents and Caches

```bash
SIM_UDID="<SIM_UDID>"
BUNDLE_ID="<BUNDLE_ID>"
BACKUP_DIR="<BACKUP_DIR>"

xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
DATA_DIR="$(xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE_ID" data)"

# Pre-restore safety snapshot
SNAPSHOT_DIR="/tmp/pre_restore_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$SNAPSHOT_DIR"
cp -R "$DATA_DIR/Documents" "$SNAPSHOT_DIR/Documents" 2>/dev/null || true
cp -R "$DATA_DIR/Library/Caches" "$SNAPSHOT_DIR/Caches" 2>/dev/null || true

mkdir -p "$DATA_DIR/Documents" "$DATA_DIR/Library/Caches"
cp -R "$BACKUP_DIR/Documents/." "$DATA_DIR/Documents/"
cp -R "$BACKUP_DIR/Caches/." "$DATA_DIR/Library/Caches/"

xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID"
```

## Android Workflow

Note: `run-as` works only for debuggable builds and matching app signatures.

### 1) Verify access

```bash
adb -s <DEVICE_SERIAL> shell run-as <PACKAGE_NAME> pwd
```

If this fails with permission errors, use a debug build or rooted workflow.

### 2) Backup files

```bash
SERIAL="<DEVICE_SERIAL>"
PKG="<PACKAGE_NAME>"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="/tmp/app_backup_${STAMP}"

mkdir -p "$OUT_DIR"

# Backup files dir (analogous to Documents/app files)
adb -s "$SERIAL" exec-out run-as "$PKG" tar -cf - files 2>/dev/null | tar -xf - -C "$OUT_DIR"

# Backup cache dirs if present
adb -s "$SERIAL" exec-out run-as "$PKG" tar -cf - cache code_cache 2>/dev/null | tar -xf - -C "$OUT_DIR" || true
```

### 3) Restore files

```bash
SERIAL="<DEVICE_SERIAL>"
PKG="<PACKAGE_NAME>"
BACKUP_DIR="<BACKUP_DIR>"

adb -s "$SERIAL" shell am force-stop "$PKG"

# Optional pre-restore snapshot on host
SNAPSHOT_DIR="/tmp/pre_restore_android_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$SNAPSHOT_DIR"
adb -s "$SERIAL" exec-out run-as "$PKG" tar -cf - files cache code_cache 2>/dev/null | tar -xf - -C "$SNAPSHOT_DIR" || true

# Push and copy with app uid via run-as
adb -s "$SERIAL" push "$BACKUP_DIR" /sdcard/Download/app_restore_tmp
adb -s "$SERIAL" shell run-as "$PKG" sh -c 'cp -R /sdcard/Download/app_restore_tmp/files/. files/ 2>/dev/null || true; cp -R /sdcard/Download/app_restore_tmp/cache/. cache/ 2>/dev/null || true; cp -R /sdcard/Download/app_restore_tmp/code_cache/. code_cache/ 2>/dev/null || true'
adb -s "$SERIAL" shell rm -rf /sdcard/Download/app_restore_tmp

adb -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
```

## Verification Checklist

After restore, verify:
- App launches without crash.
- Expected records are visible in UI.
- Key restored files exist with expected sizes.
- Optional: compare source and destination checksums for critical files.

Useful commands:

```bash
# iOS simulator critical file check
ls -l "$(xcrun simctl get_app_container <SIM_UDID> <BUNDLE_ID> data)/Documents"

# Android critical file check
adb -s <DEVICE_SERIAL> shell run-as <PACKAGE_NAME> ls -la files
```

## Q Master Notes

For this repository:
- Primary workout persistence file is `Documents/workouts.json`.
- Restoring `workouts.json` into the app data container is usually sufficient.
- Watch-side state is synced from app context after app startup.
