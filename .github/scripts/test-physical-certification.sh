#!/usr/bin/env bash
set -Eeuo pipefail

readonly repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly scratch_dir="$(mktemp -d)"
readonly work_dir="$scratch_dir/work"
readonly fake_bin="$scratch_dir/bin"
readonly fake_state="$scratch_dir/state"
readonly fake_log="$scratch_dir/adb-calls.txt"

cleanup() {
  rm -rf -- "$scratch_dir"
}
trap cleanup EXIT

mkdir -p "$work_dir/.github/scripts" "$work_dir/artifacts" "$fake_bin" "$fake_state"
cp "$repo_root/.github/scripts/android-physical-smoke.sh" "$work_dir/.github/scripts/"
cp "$repo_root/.github/scripts/android-smoke.sh" "$work_dir/.github/scripts/"
cp "$repo_root/.github/test-fixtures/fake-adb.sh" "$fake_bin/adb"
chmod 700 "$fake_bin/adb"
: > "$work_dir/artifacts/app-release.apk"
: > "$work_dir/artifacts/app-release-androidTest.apk"
: > "$fake_log"

export PATH="$fake_bin:$PATH"
export FAKE_ADB_LOG="$fake_log"
export FAKE_ADB_STATE_DIR="$fake_state"

set +e
(
  cd "$work_dir"
  bash .github/scripts/android-physical-smoke.sh \
    artifacts/app-release.apk artifacts/app-release-androidTest.apk 37
) > "$scratch_dir/unconfirmed.txt" 2>&1
readonly unconfirmed_status="$?"
set -e

if [[ "$unconfirmed_status" -eq 0 ]]; then
  echo "Physical runner accepted missing destructive/network confirmations." >&2
  exit 1
fi
if [[ -s "$fake_log" ]]; then
  echo "Physical runner contacted ADB before validating confirmations." >&2
  exit 1
fi

(
  cd "$work_dir"
  ANDROID_PHYSICAL_RESET_CONFIRMED=RESET-ARABS-GUARD \
    ANDROID_PHYSICAL_ROUTER_PROBE_CONFIRMED=READ-ONLY-ROUTER-PROBE \
    bash .github/scripts/android-physical-smoke.sh \
      artifacts/app-release.apk artifacts/app-release-androidTest.apk 37
) > "$scratch_dir/confirmed.txt" 2>&1

readonly transitions="$work_dir/test-results/api-37/permission-transitions.txt"
[[ -f "$transitions" ]] || {
  echo "Physical runner did not produce transition evidence." >&2
  exit 1
}

readonly expected_transitions=(
  "fresh_install_reset=complete"
  "fresh_install_denial_suite=passed"
  "grant=granted"
  "grant=private_gateway_reachable"
  "settings-revocation=denied"
  "regrant=granted"
  "reconnection=private_gateway_reachable"
  "cleanup-revocation=denied"
)
mapfile -t actual_transitions < "$transitions"
if [[ "${#actual_transitions[@]}" -ne "${#expected_transitions[@]}" ]]; then
  echo "Physical runner produced an unexpected transition count." >&2
  exit 1
fi
for index in "${!expected_transitions[@]}"; do
  if [[ "${actual_transitions[$index]}" != "${expected_transitions[$index]}" ]]; then
    echo "Unexpected physical transition at index $index." >&2
    exit 1
  fi
done

if [[ "$(tr -d '\r\n' < "$fake_state/local-network-permission")" != "denied" ]]; then
  echo "Physical runner did not leave the local-network permission revoked." >&2
  exit 1
fi
grep -Fq 'pm grant' "$fake_log"
grep -Fq 'pm revoke' "$fake_log"
grep -Fq 'PhysicalLocalNetworkContractTest' "$fake_log"

echo "Physical certification runner passed deterministic no-download regression tests."
