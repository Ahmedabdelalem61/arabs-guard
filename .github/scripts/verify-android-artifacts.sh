#!/usr/bin/env bash
set -Eeuo pipefail

readonly app_apk="${1:-build/app/outputs/flutter-apk/app-release.apk}"
readonly test_apk="${2:-build/app/outputs/apk/androidTest/release/app-release-androidTest.apk}"
readonly scratch_dir="$(mktemp -d)"

cleanup() {
  rm -rf -- "$scratch_dir"
}
trap cleanup EXIT

for artifact in "$app_apk" "$test_apk"; do
  if [[ ! -s "$artifact" ]]; then
    echo "Missing or empty Android artifact: $artifact" >&2
    exit 1
  fi
  unzip -tqq "$artifact"
done

unzip -Z1 "$app_apk" > "$scratch_dir/app-entries.txt"
for abi in armeabi-v7a arm64-v8a x86_64; do
  grep -Fxq "lib/$abi/libapp.so" "$scratch_dir/app-entries.txt" || {
    echo "Release APK is missing Flutter application code for $abi." >&2
    exit 1
  }
done

unzip -p "$test_apk" 'classes*.dex' | strings \
  > "$scratch_dir/test-dex-strings.txt"
for required_symbol in \
  'androidx/test/runner/AndroidJUnitRunner' \
  'androidx/tracing/Trace' \
  'ActivityScenario' \
  'InstrumentationRegistry' \
  'PlatformContractTest'; do
  grep -Fq "$required_symbol" "$scratch_dir/test-dex-strings.txt" || {
    echo "Instrumentation APK is missing required runtime symbol: $required_symbol" >&2
    exit 1
  }
done

echo "Android release and instrumentation artifacts passed package verification."
