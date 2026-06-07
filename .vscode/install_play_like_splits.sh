#!/usr/bin/env bash
set -euo pipefail

ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
if [[ ! -x "$ADB" ]]; then
  echo "adb not found at $ADB. Set ADB env var or install Android platform-tools."
  exit 1
fi

ROOT="${WORKSPACE_FOLDER:-$PWD}"
AAB="$ROOT/build/app/outputs/bundle/release/app-release.aab"
if [[ ! -f "$AAB" ]]; then
  echo "AAB not found at $AAB"
  echo "Run task: Build Android App Bundle (Release)"
  exit 1
fi

if command -v bundletool >/dev/null 2>&1; then
  BUNDLETOOL=(bundletool)
else
  BUNDLETOOL_JAR="${BUNDLETOOL_JAR:-$HOME/Library/Android/sdk/cmdline-tools/latest/lib/bundletool.jar}"
  if [[ ! -f "$BUNDLETOOL_JAR" ]]; then
    echo "bundletool not found in PATH and jar not found at $BUNDLETOOL_JAR"
    echo "Install with: brew install bundletool"
    echo "Or set BUNDLETOOL_JAR to bundletool-all-*.jar"
    exit 1
  fi
  BUNDLETOOL=(java -jar "$BUNDLETOOL_JAR")
fi

DEVICE_SERIAL="${DEVICE_SERIAL:-$($ADB devices | awk "NR>1 && \$2==\"device\" {print \$1; exit}")}"
if [[ -z "$DEVICE_SERIAL" ]]; then
  echo "No connected Android device found."
  exit 1
fi

APKS="$ROOT/build/app/outputs/bundle/release/app-release.apks"
"${BUNDLETOOL[@]}" build-apks \
  --bundle="$AAB" \
  --output="$APKS" \
  --overwrite \
  --connected-device \
  --device-id="$DEVICE_SERIAL"

"${BUNDLETOOL[@]}" install-apks \
  --apks="$APKS" \
  --device-id="$DEVICE_SERIAL"

echo "Installed Play-like splits on device: $DEVICE_SERIAL"
