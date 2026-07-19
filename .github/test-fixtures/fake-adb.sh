#!/usr/bin/env bash
set -Eeuo pipefail

: "${FAKE_ADB_LOG:?FAKE_ADB_LOG is required}"
: "${FAKE_ADB_STATE_DIR:?FAKE_ADB_STATE_DIR is required}"

mkdir -p "$FAKE_ADB_STATE_DIR"
printf '%q ' "$@" >> "$FAKE_ADB_LOG"
printf '\n' >> "$FAKE_ADB_LOG"

readonly permission_state="$FAKE_ADB_STATE_DIR/local-network-permission"

permission_value() {
  if [[ -f "$permission_state" ]]; then
    tr -d '\r\n' < "$permission_state"
  else
    printf 'denied'
  fi
}

write_permission() {
  printf '%s\n' "$1" > "$permission_state"
}

readonly command_name="${1:-}"
if [[ -z "$command_name" ]]; then
  exit 2
fi
shift

case "$command_name" in
  devices)
    printf 'List of devices attached\nphysical-api37\tdevice\n'
    ;;
  wait-for-device)
    ;;
  get-state)
    printf 'device\n'
    ;;
  get-serialno)
    printf 'physical-api37\n'
    ;;
  kill-server | start-server | install)
    ;;
  uninstall)
    write_permission denied
    ;;
  logcat)
    printf 'mock logcat: no device data\n'
    ;;
  shell)
    readonly shell_command="${1:-}"
    shift || true
    case "$shell_command" in
      getprop)
        case "${1:-}" in
          ro.kernel.qemu) printf '0\n' ;;
          ro.build.version.sdk) printf '%s\n' "${FAKE_ADB_API:-37}" ;;
          ro.product.manufacturer) printf 'MockVendor\n' ;;
          ro.product.model) printf 'MockPhysicalDevice\n' ;;
          ro.build.fingerprint) printf 'mock/api37/physical\n' ;;
          sys.boot_completed) printf '1\n' ;;
          '') printf '[ro.build.version.sdk]: [%s]\n' "${FAKE_ADB_API:-37}" ;;
          *) printf '\n' ;;
        esac
        ;;
      service)
        [[ "${1:-}" == "check" ]]
        printf 'Service %s: found\n' "${2:-unknown}"
        ;;
      pm)
        readonly pm_command="${1:-}"
        shift || true
        case "$pm_command" in
          path) printf 'package:/data/app/mock/base.apk\n' ;;
          grant) write_permission granted ;;
          revoke) write_permission denied ;;
          *) exit 3 ;;
        esac
        ;;
      am)
        readonly am_command="${1:-}"
        shift || true
        case "$am_command" in
          start) printf 'Starting: Intent mock\n' ;;
          force-stop) ;;
          instrument)
            expected_permission=""
            selected_class=""
            while [[ "$#" -gt 0 ]]; do
              if [[ "$1" == "-e" && "$#" -ge 3 ]]; then
                key="$2"
                value="$3"
                shift 3
                case "$key" in
                  expectedLocalNetworkPermission) expected_permission="$value" ;;
                  class) selected_class="$value" ;;
                esac
              else
                shift
              fi
            done

            current_permission="$(permission_value)"
            if [[ -n "$expected_permission" && "$expected_permission" != "$current_permission" ]]; then
              printf 'INSTRUMENTATION_FAILED: expected %s, found %s\n' \
                "$expected_permission" "$current_permission" >&2
              exit 4
            fi
            if [[ "$selected_class" == *PhysicalLocalNetworkContractTest* && \
              "$current_permission" != "granted" ]]; then
              printf 'INSTRUMENTATION_FAILED: gateway probe requires granted permission\n' >&2
              exit 5
            fi
            if [[ "$selected_class" == *'#'* || \
              "$selected_class" == *PhysicalLocalNetworkContractTest* ]]; then
              printf 'OK (1 test)\n'
            else
              [[ "$current_permission" == "denied" ]]
              printf 'OK (6 tests)\n'
            fi
            ;;
          *) exit 6 ;;
        esac
        ;;
      dumpsys)
        case "${1:-}" in
          activity) printf 'mResumedActivity com.arabsguard.arabs_guard/.MainActivity\n' ;;
          package) printf 'Package mock diagnostics\n' ;;
          *) exit 7 ;;
        esac
        ;;
      *) exit 8 ;;
    esac
    ;;
  *)
    exit 9
    ;;
esac
