#!/usr/bin/env bash
set -Eeuo pipefail

readonly apk_path="${1:-artifacts/app-release.apk}"
readonly test_apk_path="${2:-artifacts/app-release-androidTest.apk}"
readonly expected_api="${3:-unknown}"
readonly package_name="com.arabsguard.arabs_guard"
readonly activity_name="$package_name/.MainActivity"
readonly instrumentation_name="$package_name.test/androidx.test.runner.AndroidJUnitRunner"
readonly results_dir="test-results/api-$expected_api"
readonly short_adb_timeout="20s"
readonly install_adb_timeout="240s"

collect_diagnostics() {
  set +e
  mkdir -p "$results_dir"
  adb_short shell getprop > "$results_dir/device-properties.txt" 2>&1
  adb_short shell dumpsys package "$package_name" > "$results_dir/package-dump.txt" 2>&1
  timeout --foreground 30s adb logcat -d > "$results_dir/logcat.txt" 2>&1
}

trap collect_diagnostics EXIT

adb_short() {
  timeout --foreground "$short_adb_timeout" adb "$@"
}

wait_for_device() {
  for attempt in $(seq 1 12); do
    if adb_short wait-for-device && [[ "$(adb_short get-state 2>/dev/null || true)" == "device" ]]; then
      return 0
    fi

    echo "ADB device readiness attempt $attempt failed; restarting the ADB server." >&2
    timeout --foreground 10s adb kill-server 2>/dev/null || true
    timeout --foreground 10s adb start-server 2>/dev/null || true
    sleep 5
  done

  return 1
}

wait_for_android_services() {
  local boot_status=""
  local package_service=""
  local activity_service=""

  for attempt in $(seq 1 60); do
    boot_status="$(adb_short shell getprop sys.boot_completed 2>/dev/null || true)"
    boot_status="${boot_status//$'\r'/}"
    package_service="$(adb_short shell service check package 2>/dev/null || true)"
    activity_service="$(adb_short shell service check activity 2>/dev/null || true)"

    if [[ "$boot_status" == "1" && "$package_service" == *found* && "$activity_service" == *found* ]]; then
      return 0
    fi

    sleep 5
  done

  return 1
}

if ! wait_for_device; then
  echo "Android emulator did not become available through ADB." >&2
  exit 1
fi

if ! wait_for_android_services; then
  echo "Android package/activity services did not become ready." >&2
  exit 1
fi

mkdir -p "$results_dir"
actual_api="$(adb_short shell getprop ro.build.version.sdk 2>/dev/null || true)"
actual_api="${actual_api//$'\r'/}"
printf 'expected_api=%s\nactual_api=%s\n' "$expected_api" "$actual_api" \
  > "$results_dir/runtime.txt"
if [[ "$actual_api" != "$expected_api" ]]; then
  echo "Expected Android API $expected_api but emulator reports $actual_api." >&2
  exit 1
fi

install_ready=false
for attempt in $(seq 1 3); do
  if timeout --foreground "$install_adb_timeout" adb install -r "$apk_path"; then
    install_ready=true
    break
  fi

  echo "Install attempt $attempt failed; waiting for Android services before retrying." >&2
  wait_for_device || true
  wait_for_android_services || true
  sleep 10
done
test "$install_ready" = true

test_install_ready=false
for attempt in $(seq 1 3); do
  if timeout --foreground "$install_adb_timeout" adb install -r "$test_apk_path"; then
    test_install_ready=true
    break
  fi

  echo "Instrumentation APK install attempt $attempt failed; retrying after ADB recovery." >&2
  wait_for_device || true
  sleep 10
done
test "$test_install_ready" = true

package_ready=false
for attempt in $(seq 1 12); do
  package_path="$(adb_short shell pm path "$package_name" 2>/dev/null || true)"
  if [[ "$package_path" == package:* ]]; then
    package_ready=true
    break
  fi
  sleep 5
done
test "$package_ready" = true

launch_requested=false
for attempt in $(seq 1 3); do
  if adb_short shell am start -n "$activity_name"; then
    launch_requested=true
    break
  fi
  sleep 5
done
test "$launch_requested" = true

activity_ready=false
for attempt in $(seq 1 18); do
  activity_dump="$(adb_short shell dumpsys activity activities 2>/dev/null || true)"
  if [[ "$activity_dump" == *"$activity_name"* ]]; then
    activity_ready=true
    break
  fi
  sleep 5
done
test "$activity_ready" = true

if ! timeout --foreground 300s adb shell am instrument -w -r \
  -e class "$package_name.PlatformContractTest" "$instrumentation_name" \
  | tee "$results_dir/instrumentation.txt"; then
  echo "Android instrumentation command failed on API $expected_api." >&2
  exit 1
fi

if ! grep -Eq '^[[:space:]]*OK \([1-9][0-9]* tests?\)[[:space:]]*$' \
  "$results_dir/instrumentation.txt"; then
  echo "Android instrumentation suite did not report a clean pass on API $expected_api." >&2
  exit 1
fi
