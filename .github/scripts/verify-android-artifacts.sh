#!/usr/bin/env bash
set -Eeuo pipefail

readonly app_apk="${1:-build/app/outputs/flutter-apk/app-release.apk}"
readonly test_apk="${2:-build/app/outputs/apk/androidTest/release/app-release-androidTest.apk}"
readonly scratch_dir="$(mktemp -d)"
readonly sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"

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

if [[ -z "$sdk_root" ]]; then
  echo "ANDROID_SDK_ROOT or ANDROID_HOME is required for DEX verification." >&2
  exit 1
fi
readonly dexdump_bin="$(
  find "$sdk_root/build-tools" -mindepth 2 -maxdepth 2 -type f -name dexdump \
    -print | sort -V | tail -1
)"
readonly aapt_bin="$(
  find "$sdk_root/build-tools" -mindepth 2 -maxdepth 2 -type f -name aapt \
    -print | sort -V | tail -1
)"
readonly zipalign_bin="$(
  find "$sdk_root/build-tools" -mindepth 2 -maxdepth 2 -type f -name zipalign \
    -print | sort -V | tail -1
)"
if [[ ! -x "$dexdump_bin" ]]; then
  echo "Android SDK dexdump was not found." >&2
  exit 1
fi
if [[ ! -x "$zipalign_bin" ]]; then
  echo "Android SDK zipalign was not found." >&2
  exit 1
fi
if [[ ! -x "$aapt_bin" ]]; then
  echo "Android SDK aapt was not found." >&2
  exit 1
fi

"$zipalign_bin" -c -P 16 4 "$app_apk"

"$aapt_bin" dump badging "$app_apk" > "$scratch_dir/app-badging.txt"
grep -Fq "sdkVersion:'24'" "$scratch_dir/app-badging.txt" || {
  echo "Release APK does not declare minSdk 24." >&2
  exit 1
}
grep -Fq "targetSdkVersion:'37'" "$scratch_dir/app-badging.txt" || {
  echo "Release APK does not target Android 17/API 37." >&2
  exit 1
}
grep -Fq "uses-permission: name='android.permission.ACCESS_LOCAL_NETWORK'" \
  "$scratch_dir/app-badging.txt" || {
    echo "Release APK is missing Android 17 local-network permission." >&2
    exit 1
  }

unzip -Z1 "$app_apk" > "$scratch_dir/app-entries.txt"
for abi in armeabi-v7a arm64-v8a x86_64; do
  grep -Fxq "lib/$abi/libapp.so" "$scratch_dir/app-entries.txt" || {
    echo "Release APK is missing Flutter application code for $abi." >&2
    exit 1
  }
done

for artifact in "$app_apk" "$test_apk"; do
  while IFS= read -r dex_entry; do
    dex_file="$scratch_dir/$(basename "$artifact")-$dex_entry"
    unzip -p "$artifact" "$dex_entry" > "$dex_file"
    "$dexdump_bin" "$dex_file" >> "$scratch_dir/dex-definitions.txt"
  done < <(unzip -Z1 "$artifact" | grep -E '^classes([0-9]+)?\.dex$')
done

for required_class in \
  'Landroidx/test/runner/AndroidJUnitRunner;' \
  'Landroidx/test/runner/MonitoringInstrumentation;' \
  'Landroidx/tracing/Trace;' \
  'Landroidx/tracing/TraceApi18Impl;' \
  'Landroidx/tracing/TraceApi29Impl;' \
  'Landroidx/lifecycle/Lifecycle;' \
  'Landroidx/lifecycle/Lifecycle$State;' \
  'Landroidx/test/core/app/ActivityScenario;' \
  'Landroidx/test/platform/app/InstrumentationRegistry;' \
  'Landroidx/test/ext/junit/runners/AndroidJUnit4;' \
  'Lkotlin/io/CloseableKt;' \
  'Lkotlin/collections/ArraysKt;' \
  'Lkotlin/collections/SetsKt;' \
  'Lorg/junit/Assert;' \
  'Lorg/junit/Test;' \
  'Lcom/arabsguard/arabs_guard/PlatformContractTest;'; do
  grep -Fq "Class descriptor  : '$required_class'" \
    "$scratch_dir/dex-definitions.txt" || {
    echo "Packaged APKs are missing required class definition: $required_class" >&2
    exit 1
  }
done

echo "Android release and instrumentation artifacts passed package verification."
