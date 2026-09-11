#!/usr/bin/env bash
# NetControl - Offline Build Setup (Linux / macOS)
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="${1:-}"

echo "============================================================"
echo "  NetControl - Offline Build Setup (Linux/macOS)"
echo "============================================================"

[ -d "$KIT/pub-cache" ] || { echo "[ERROR] $KIT/pub-cache not found - run from the extracted offline-kit folder."; exit 1; }

# 1) Project directory
if [ -z "$PROJECT" ]; then
  read -rp "Path to the WiFi project folder (contains pubspec.yaml): " PROJECT
fi
[ -f "$PROJECT/pubspec.yaml" ] || { echo "[ERROR] pubspec.yaml not found in $PROJECT"; exit 1; }
PROJECT="$(cd "$PROJECT" && pwd)"
echo "[OK] Project: $PROJECT"

# 2) Flutter SDK
FLUTTER_CMD="$(command -v flutter || true)"
if [ -z "$FLUTTER_CMD" ]; then
  read -rp "Full path to the flutter executable of the Flutter SDK: " FLUTTER_CMD
fi
[ -x "$FLUTTER_CMD" ] || { echo "[ERROR] flutter not found at $FLUTTER_CMD"; exit 1; }
FLUTTER_SDK="$(cd "$(dirname "$FLUTTER_CMD")/.." && pwd)"
echo "[OK] Flutter SDK: $FLUTTER_SDK"
"$FLUTTER_CMD" --version | grep -qi '3\.24\.5' || echo "[WARN] Kit was built with Flutter 3.24.5 - other versions may mismatch."

# 3) Dart packages cache
PUBDIR="${PUB_CACHE:-$HOME/.pub-cache}"
echo "[..] Copying Dart packages cache to: $PUBDIR"
mkdir -p "$PUBDIR"
cp -R "$KIT/pub-cache/." "$PUBDIR/"
echo "[OK] Dart packages cache installed."

# 4) Lock + offline pub get + codegen
cp "$KIT/pubspec.lock" "$PROJECT/pubspec.lock"
cd "$PROJECT"
"$FLUTTER_CMD" pub get --offline
"$FLUTTER_SDK/bin/dart" run build_runner build --delete-conflicting-outputs

# 5) Gradle dist + Maven artifacts
GH="$HOME/.gradle"
mkdir -p "$GH/wrapper" "$GH/caches"
echo "[..] Copying Gradle 8.4 distribution..."
cp -R "$KIT/gradle/wrapper-dists" "$GH/wrapper/dists"
echo "[..] Copying Maven artifacts (a few minutes)..."
mkdir -p "$GH/caches/modules-2"
cp -R "$KIT/gradle/modules-2/." "$GH/caches/modules-2/"
echo "[OK] Gradle caches installed."

# 6) Offline mode (project-local)
GP="$PROJECT/android/gradle.properties"
grep -q 'org.gradle.offline=true' "$GP" 2>/dev/null || {
  printf '\n# Added by offline setup - remove to build online\norg.gradle.offline=true\n' >> "$GP"
}
echo "[OK] Gradle offline mode enabled for this project."

# 7) SDK licenses
ANDROID_SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$ANDROID_SDK" ]; then
  for CAND in "$HOME/Android/Sdk" "$HOME/Library/Android/sdk"; do
    [ -d "$CAND" ] && ANDROID_SDK="$CAND" && break
  done
fi
if [ -n "$ANDROID_SDK" ] && [ -d "$KIT/licenses" ]; then
  mkdir -p "$ANDROID_SDK/licenses"
  cp -R "$KIT/licenses/." "$ANDROID_SDK/licenses/"
  echo "[OK] SDK licenses installed."
fi

# 8) local.properties
if [ -z "$ANDROID_SDK" ]; then
  read -rp "Android SDK path: " ANDROID_SDK
fi
[ -d "$ANDROID_SDK" ] || { echo "[ERROR] Android SDK not found at $ANDROID_SDK"; exit 1; }
{
  echo "sdk.dir=$ANDROID_SDK"
  echo "flutter.sdk=$FLUTTER_SDK"
} > "$PROJECT/android/local.properties"
echo "[OK] Wrote android/local.properties"

# 9) Verify with a full offline build
echo "[..] Running a full offline build to verify (5-15 minutes)..."
"$FLUTTER_CMD" build apk --release
echo "============================================================"
echo "  SUCCESS - APK built fully offline at:"
echo "  build/app/outputs/flutter-apk/app-release.apk"
echo "============================================================"
