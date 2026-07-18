#!/usr/bin/env bash
set -Eeuo pipefail

readonly apk_path="${1:-artifacts/app-release.apk}"
readonly test_apk_path="${2:-artifacts/app-release-androidTest.apk}"
readonly expected_api="${3:-37}"

command -v adb >/dev/null 2>&1 || {
  echo "adb is required. This script never downloads an SDK, emulator, or AVD." >&2
  exit 1
}
[[ -f "$apk_path" && -f "$test_apk_path" ]] || {
  echo "Release and instrumentation APKs are required." >&2
  exit 1
}
[[ "$expected_api" =~ ^[0-9]+$ ]] || {
  echo "Expected API must be numeric." >&2
  exit 1
}

mapfile -t connected_serials < <(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
if [[ "${#connected_serials[@]}" -ne 1 ]]; then
  echo "Connect exactly one authorized physical Android device; found ${#connected_serials[@]}." >&2
  exit 1
fi

export ANDROID_SERIAL="${connected_serials[0]}"
readonly qemu_marker="$(adb shell getprop ro.kernel.qemu | tr -d '\r')"
readonly actual_api="$(adb shell getprop ro.build.version.sdk | tr -d '\r')"
if [[ "$ANDROID_SERIAL" == emulator-* || "$qemu_marker" == "1" ]]; then
  echo "Refusing an emulator: this gate is reserved for physical-device evidence." >&2
  exit 1
fi
if [[ "$actual_api" != "$expected_api" ]]; then
  echo "Expected physical API $expected_api, but the connected device reports $actual_api." >&2
  exit 1
fi

readonly results_dir="test-results/api-$expected_api"
mkdir -p "$results_dir"
{
  printf 'transport=physical\n'
  printf 'manufacturer=%s\n' "$(adb shell getprop ro.product.manufacturer | tr -d '\r')"
  printf 'model=%s\n' "$(adb shell getprop ro.product.model | tr -d '\r')"
  printf 'build=%s\n' "$(adb shell getprop ro.build.fingerprint | tr -d '\r')"
  printf 'api=%s\n' "$actual_api"
} > "$results_dir/physical-device.txt"

ANDROID_SMOKE_REQUIRE_PHYSICAL=1 \
  bash .github/scripts/android-smoke.sh "$apk_path" "$test_apk_path" "$expected_api"
