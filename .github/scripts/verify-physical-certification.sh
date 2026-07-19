#!/usr/bin/env bash
set -Eeuo pipefail

readonly workflow=".github/workflows/android-physical.yml"
readonly runner=".github/scripts/android-physical-smoke.sh"
readonly runner_test=".github/scripts/test-physical-certification.sh"
readonly fake_adb=".github/test-fixtures/fake-adb.sh"
readonly contract="android/app/src/androidTest/kotlin/com/arabsguard/arabs_guard/PlatformContractTest.kt"
readonly gateway_contract="android/app/src/androidTest/kotlin/com/arabsguard/arabs_guard/PhysicalLocalNetworkContractTest.kt"

for file in "$workflow" "$runner" "$runner_test" "$fake_adb" "$contract" "$gateway_contract"; do
  [[ -f "$file" ]] || {
    echo "Physical-certification contract file is missing: $file" >&2
    exit 1
  }
done

bash -n "$runner"
bash -n "$runner_test"
bash -n "$fake_adb"

require_literal() {
  local file="$1"
  local literal="$2"
  grep -Fq -- "$literal" "$file" || {
    echo "Missing physical-certification contract '$literal' in $file" >&2
    exit 1
  }
}

require_literal "$workflow" "runs-on: [self-hosted, linux, android-physical]"
require_literal "$workflow" "RESET-ARABS-GUARD"
require_literal "$workflow" "READ-ONLY-ROUTER-PROBE"
require_literal "$runner" 'ANDROID_PHYSICAL_RESET_CONFIRMED'
require_literal "$runner" 'ANDROID_PHYSICAL_ROUTER_PROBE_CONFIRMED'
require_literal "$runner" 'uninstall "$package_name"'
require_literal "$runner" 'pm grant "$package_name" "$local_network_permission"'
require_literal "$runner" 'pm revoke "$package_name" "$local_network_permission"'
require_literal "$runner" 'expectedLocalNetworkPermission'
require_literal "$runner" 'PhysicalLocalNetworkContractTest'
require_literal "$runner" 'permission-transitions.txt'
require_literal "$contract" 'localNetworkPermissionMatchesRunnerExpectation'
require_literal "$gateway_contract" 'grantedPermissionCanDiscoverAndReachPrivateGateway'
require_literal "$gateway_contract" 'listOf(80, 443)'

if grep -Eq '(^|[;&|[:space:]])(sdkmanager|avdmanager)([;&|[:space:]]|$)' "$runner"; then
  echo "The physical runner must not install an SDK, emulator, or AVD." >&2
  exit 1
fi

bash "$runner_test"
