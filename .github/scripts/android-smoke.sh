#!/usr/bin/env bash
set -Eeuo pipefail

readonly apk_path="${1:-artifacts/app-release.apk}"
readonly package_name="com.arabsguard.arabs_guard"
readonly activity_name="$package_name/.MainActivity"

wait_for_android_services() {
  local boot_status=""
  local package_service=""
  local activity_service=""

  for attempt in $(seq 1 60); do
    boot_status="$(adb shell getprop sys.boot_completed 2>/dev/null || true)"
    boot_status="${boot_status//$'\r'/}"
    package_service="$(adb shell service check package 2>/dev/null || true)"
    activity_service="$(adb shell service check activity 2>/dev/null || true)"

    if [[ "$boot_status" == "1" && "$package_service" == *found* && "$activity_service" == *found* ]]; then
      return 0
    fi

    sleep 5
  done

  return 1
}

adb wait-for-device
if ! wait_for_android_services; then
  echo "Android package/activity services did not become ready." >&2
  exit 1
fi

install_ready=false
for attempt in $(seq 1 3); do
  if adb install -r "$apk_path"; then
    install_ready=true
    break
  fi

  echo "Install attempt $attempt failed; waiting for Android services before retrying." >&2
  adb wait-for-device
  wait_for_android_services || true
  sleep 10
done
test "$install_ready" = true

package_ready=false
for attempt in $(seq 1 12); do
  package_path="$(adb shell pm path "$package_name" 2>/dev/null || true)"
  if [[ "$package_path" == package:* ]]; then
    package_ready=true
    break
  fi
  sleep 5
done
test "$package_ready" = true

launch_requested=false
for attempt in $(seq 1 3); do
  if adb shell am start -n "$activity_name"; then
    launch_requested=true
    break
  fi
  sleep 5
done
test "$launch_requested" = true

activity_ready=false
for attempt in $(seq 1 18); do
  activity_dump="$(adb shell dumpsys activity activities 2>/dev/null || true)"
  if [[ "$activity_dump" == *"$activity_name"* ]]; then
    activity_ready=true
    break
  fi
  sleep 5
done
test "$activity_ready" = true
