#!/usr/bin/env bash
set -Eeuo pipefail

readonly apk_path="${1:-artifacts/app-release.apk}"
readonly test_apk_path="${2:-artifacts/app-release-androidTest.apk}"
readonly expected_api="${3:-37}"
readonly package_name="com.arabsguard.arabs_guard"
readonly test_package_name="$package_name.test"
readonly instrumentation_name="$test_package_name/androidx.test.runner.AndroidJUnitRunner"
readonly local_network_permission="android.permission.ACCESS_LOCAL_NETWORK"
readonly permission_test="$package_name.PlatformContractTest#localNetworkPermissionMatchesRunnerExpectation"
readonly gateway_test="$package_name.PhysicalLocalNetworkContractTest"

command -v adb >/dev/null 2>&1 || {
  echo "adb is required. This script never downloads an SDK, emulator, or AVD." >&2
  exit 1
}
command -v timeout >/dev/null 2>&1 || {
  echo "GNU timeout is required for bounded physical-device ADB operations." >&2
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
[[ "${ANDROID_PHYSICAL_RESET_CONFIRMED:-}" == "RESET-ARABS-GUARD" ]] || {
  echo "Physical certification removes existing Arabs Guard app data. Select RESET-ARABS-GUARD explicitly." >&2
  exit 1
}
[[ "${ANDROID_PHYSICAL_ROUTER_PROBE_CONFIRMED:-}" == "READ-ONLY-ROUTER-PROBE" ]] || {
  echo "Select READ-ONLY-ROUTER-PROBE to authorize credential-free TCP reachability checks to the private gateway." >&2
  exit 1
}

adb_bounded() {
  timeout --foreground 30s adb "$@"
}

instrument_bounded() {
  timeout --foreground 300s adb "$@"
}

mapfile -t connected_serials < <(adb_bounded devices | awk 'NR > 1 && $2 == "device" { print $1 }')
if [[ "${#connected_serials[@]}" -ne 1 ]]; then
  echo "Connect exactly one authorized physical Android device; found ${#connected_serials[@]}." >&2
  exit 1
fi

export ANDROID_SERIAL="${connected_serials[0]}"
readonly qemu_marker="$(adb_bounded shell getprop ro.kernel.qemu | tr -d '\r')"
readonly actual_api="$(adb_bounded shell getprop ro.build.version.sdk | tr -d '\r')"
if [[ "$ANDROID_SERIAL" == emulator-* || "$qemu_marker" == "1" ]]; then
  echo "Refusing an emulator: this gate is reserved for physical-device evidence." >&2
  exit 1
fi
if [[ "$actual_api" != "$expected_api" ]]; then
  echo "Expected physical API $expected_api, but the connected device reports $actual_api." >&2
  exit 1
fi

readonly results_dir="test-results/api-$expected_api"
readonly transitions_file="$results_dir/permission-transitions.txt"
mkdir -p "$results_dir"
: > "$transitions_file"

cleanup_permission() {
  adb_bounded shell pm revoke "$package_name" "$local_network_permission" >/dev/null 2>&1 || true
}
trap cleanup_permission EXIT

record_transition() {
  printf '%s\n' "$1" >> "$transitions_file"
}

run_permission_assertion() {
  local phase="$1"
  local expected="$2"
  local output="$results_dir/permission-$phase.txt"

  if ! instrument_bounded shell am instrument -w -r \
    -e expectedApi "$expected_api" \
    -e expectedLocalNetworkPermission "$expected" \
    -e class "$permission_test" "$instrumentation_name" \
    | tee "$output"; then
    echo "Local-network permission assertion failed during $phase." >&2
    return 1
  fi
  grep -Eq '^[[:space:]]*OK \(1 test\)[[:space:]]*$' "$output" || {
    echo "Permission assertion did not report exactly one passing test during $phase." >&2
    return 1
  }
  record_transition "$phase=$expected"
}

run_gateway_probe() {
  local phase="$1"
  local output="$results_dir/gateway-$phase.txt"

  if ! instrument_bounded shell am instrument -w -r \
    -e expectedApi "$expected_api" \
    -e class "$gateway_test" "$instrumentation_name" \
    | tee "$output"; then
    echo "Credential-free private-gateway probe failed during $phase." >&2
    return 1
  fi
  grep -Eq '^[[:space:]]*OK \(1 test\)[[:space:]]*$' "$output" || {
    echo "Gateway probe did not report exactly one passing test during $phase." >&2
    return 1
  }
  record_transition "$phase=private_gateway_reachable"
}

adb_bounded uninstall "$test_package_name" >/dev/null 2>&1 || true
adb_bounded uninstall "$package_name" >/dev/null 2>&1 || true
record_transition "fresh_install_reset=complete"

{
  printf 'transport=physical\n'
  printf 'manufacturer=%s\n' "$(adb_bounded shell getprop ro.product.manufacturer | tr -d '\r')"
  printf 'model=%s\n' "$(adb_bounded shell getprop ro.product.model | tr -d '\r')"
  printf 'build=%s\n' "$(adb_bounded shell getprop ro.build.fingerprint | tr -d '\r')"
  printf 'api=%s\n' "$actual_api"
} > "$results_dir/physical-device.txt"

ANDROID_SMOKE_REQUIRE_PHYSICAL=1 \
  bash .github/scripts/android-smoke.sh "$apk_path" "$test_apk_path" "$expected_api"
record_transition "fresh_install_denial_suite=passed"

adb_bounded shell pm grant "$package_name" "$local_network_permission"
adb_bounded shell am force-stop "$package_name"
run_permission_assertion "grant" "granted"
run_gateway_probe "grant"

adb_bounded shell pm revoke "$package_name" "$local_network_permission"
adb_bounded shell am force-stop "$package_name"
run_permission_assertion "settings-revocation" "denied"

adb_bounded shell pm grant "$package_name" "$local_network_permission"
adb_bounded shell am force-stop "$package_name"
run_permission_assertion "regrant" "granted"
run_gateway_probe "reconnection"

adb_bounded shell pm revoke "$package_name" "$local_network_permission"
adb_bounded shell am force-stop "$package_name"
run_permission_assertion "cleanup-revocation" "denied"
