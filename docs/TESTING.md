# Android and router test strategy

Arabs Guard treats compatibility as a release gate, not a sample-device claim. The matrix is intentionally cloud-only so emulator images and ADB workloads do not consume the development machine.

For catalog, UI, or documentation changes that do not alter the Android runtime, the manual workflow's `verify-only` input runs Flutter analysis/tests, JVM tests, release and instrumentation APK builds, manifest/DEX checks, and 16 KB-alignment verification without starting an emulator. Runtime-affecting releases still require the complete API matrix.

## Fast deterministic layer

`flutter test` covers:

- Home protection entry points and modern roadmap UI.
- Gateway auto-detection followed by a credential-free, read-only compatibility inspection through a mocked Android channel; the test verifies ordered consent, address-only inspection arguments, recognized output, and that denial prevents the page request.
- Router-only setup with credentials and explicit owner consent.
- Device-only setup with VPN disclosure and Android consent/start calls.
- Combined router-and-device setup in the required order.
- Rejection when the selected layer disclosure is not accepted.
- Egyptian compatibility catalog navigation.
- Arabic-world roadmap navigation and exact, unique coverage of all 22 Arab League countries.
- Egyptian router catalog model/provider assertions, one-to-one workflow-ID parity across the native fingerprint matrix and prioritized evidence queue, and the invariant that every automatic adapter has a secret-free structural contract fixture.

Pure JVM tests load the same canonical Egyptian fixture matrix, cover multiple real-world page fingerprints for every native router workflow, normalize common Unicode page punctuation, enforce specific-before-generic matching, reject near-match automatic-write false positives, and fail closed for unknown firmware. They also prove that public-page inspection reports only dedicated model/family workflows as recognized; generic vendor and unknown markers remain unrecognized.

Before any emulator starts, a package gate verifies both APK archives, Flutter application libraries for `armeabi-v7a`, `arm64-v8a`, and `x86_64`, and actual DEX class definitions for the instrumentation runner, tracing runtime, lifecycle, registry, and contract tests. It does not accept a mere class-reference string. A stripped or incomplete runtime therefore fails once in the build job instead of wasting the entire emulator matrix.

## Stable every-API device layer

GitHub Actions builds the release APK and release-targeting instrumentation APK once, then fans them out to every stable runtime API from 24 through 36 using lightweight AOSP x86_64 images. Each API job:

1. Enables KVM on the hosted runner and verifies the emulator reports the exact matrix API.
2. Installs the release APK and Android test APK with bounded retries.
3. Confirms the package exists, launches `MainActivity`, and verifies it becomes active.
4. Runs all six `PlatformContractTest` cases:
   - supported runtime, minSdk, and targetSdk contract;
   - real Flutter activity launch and resumed lifecycle;
   - non-exported credential activity, protected/non-exported VPN service, launcher export, and modern foreground-service type;
   - required-only permission surface with explicit rejection of location, camera, microphone, contacts, phone, SMS, and storage permissions;
   - fresh-install Android 17 local-network permission denial contract;
   - fresh-install Android-owned VPN consent requirement.
5. Requires an `OK (6 tests)` instrumentation result, not merely a zero shell exit.
6. Uploads instrumentation output, runtime identity, package dump, device properties, and logcat as API-specific evidence.

Every ADB operation has a hard timeout, recovery is bounded, the job has a ceiling, and the matrix uses `fail-fast: false` so one failure does not hide results from other versions. Build dependencies are cached, evidence expires after seven days, and documentation-only pushes do not start the expensive emulator matrix. Manual dispatch can select one API for a focused infrastructure rerun without running the complete matrix again.

## Android 17/API 37 certification scope

Android 17 is released and the app targets SDK 37. Its local-network permission path is implemented, but the project does not claim a runtime pass until the same suite completes on API 37. Current GitHub standard runners do not provide a usable emulator combination: the x86_64 image remains ADB-offline on Linux and Intel macOS, Apple Silicon reports that HVF is disabled, and Ubuntu ARM does not expose `/dev/kvm`. The emulator workflow opts out of metrics collection explicitly so a future consent prompt cannot block CI.

The manual `Android physical-device certification` workflow builds on a standard hosted runner, then delegates only installation and the contract suite to a labeled self-hosted machine with one attached device. Its wrapper requires a non-emulator API match and uses an already-installed `adb`; it never installs an SDK, system image, emulator, or AVD. Physical API 37 evidence must cover the permission grant, denial, settings revocation, and successful router reconnection paths before certification is checked off.

Official platform basis: [Android local network permission](https://developer.android.com/privacy-and-security/local-network-permission) and [Android 17 behavior changes](https://developer.android.com/about/versions/17/behavior-changes-17).

## Router hardware boundary

Fingerprint and workflow-selection tests can prove safe routing and fail-closed behavior, but they cannot prove an unobserved ISP firmware page. An automatic adapter becomes eligible only after a sanitized hardware/firmware capture demonstrates login, CSRF/session handling, editable DNS/firewall controls, idempotency, and read-back verification. The hardware queue is maintained in `ROADMAP.md`.

The evidence format and non-sensitive capture procedure are defined in `ROUTER_CAPTURE_PROTOCOL.md`; `router_validation_queue.tsv` is the canonical prioritized queue and is cross-checked against the Dart catalog in every Flutter test run.
