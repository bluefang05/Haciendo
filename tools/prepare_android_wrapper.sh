#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter no está en PATH." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
flutter create --platforms=android --org com.enmanuelapp "$TMP/wrapper_seed" >/dev/null
cp "$TMP/wrapper_seed/android/gradlew" "$ROOT/android/gradlew"
cp "$TMP/wrapper_seed/android/gradlew.bat" "$ROOT/android/gradlew.bat"
cp "$TMP/wrapper_seed/android/gradle/wrapper/gradle-wrapper.jar" \
  "$ROOT/android/gradle/wrapper/gradle-wrapper.jar"
chmod +x "$ROOT/android/gradlew"
echo "Gradle wrapper preparado."
