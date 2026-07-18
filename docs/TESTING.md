# Android and router test strategy

Arabs Guard treats compatibility as a release gate, not a sample-device claim. The matrix is intentionally cloud-only so emulator images and ADB workloads do not consume the development machine.

## Fast deterministic layer

`flutter test` covers:

- Home protection entry points and modern roadmap UI.
- Permission-light gateway auto-detection through a mocked Android channel.
- Router-only setup with credentials and explicit owner consent.
- Device-only setup with VPN disclosure and Android consent/start calls.
- Combined router-and-device setup in the required order.
- Rejection when the selected layer disclosure is not accepted.
- Egyptian compatibility catalog navigation.
- Arabic-world roadmap navigation and exact, unique coverage of all 22 Arab League countries.
- Egyptian router catalog model/provider assertions and the invariant that only validated firmware claims automation.

Pure JVM tests cover every native router-fingerprint family, specific-before-generic matching, and fail-closed handling for unknown firmware.

Before any emulator starts, a package gate verifies both APK archives, Flutter application libraries for `armeabi-v7a`, `arm64-v8a`, and `x86_64`, and actual DEX class definitions for the instrumentation runner, tracing runtime, lifecycle, registry, and contract tests. It does not accept a mere class-reference string. A stripped or incomplete runtime therefore fails once in the build job instead of wasting the entire emulator matrix.

## Stable every-API device layer

GitHub Actions builds the release APK and release-targeting instrumentation APK once, then fans them out to every stable runtime API from 24 through 36 using lightweight AOSP x86_64 images. Each API job:

1. Enables KVM on the hosted runner and verifies the emulator reports the exact matrix API.
2. Installs the release APK and Android test APK with bounded retries.
3. Confirms the package exists, launches `MainActivity`, and verifies it becomes active.
4. Runs all five `PlatformContractTest` cases:
   - supported runtime, minSdk, and targetSdk contract;
   - real Flutter activity launch and resumed lifecycle;
   - non-exported credential activity, protected/non-exported VPN service, launcher export, and modern foreground-service type;
   - required-only permission surface with explicit rejection of location, camera, microphone, contacts, phone, SMS, and storage permissions;
   - fresh-install Android-owned VPN consent requirement.
5. Requires an `OK (5 tests)` instrumentation result, not merely a zero shell exit.
6. Uploads instrumentation output, runtime identity, package dump, device properties, and logcat as API-specific evidence.

Every ADB operation has a hard timeout, recovery is bounded, the job has a ceiling, and the matrix uses `fail-fast: false` so one failure does not hide results from other versions. Build dependencies are cached, evidence expires after seven days, and documentation-only pushes do not start the expensive emulator matrix. Manual dispatch can select one API for a focused infrastructure rerun without running the complete matrix again.

## Android 17/API 37 preview scope

The API 37 manual gate uses the published Google APIs 16 KB-page image and fails fast unless the hosted runner exposes hardware acceleration. Current GitHub standard runners do not provide a usable combination: the x86_64 image remains ADB-offline on Linux and Intel macOS, Apple Silicon reports that HVF is disabled, and Ubuntu ARM does not expose `/dev/kvm`. Consequently, the project does not claim an API 37 runtime pass. The packaged release is still checked for 16 KB ZIP alignment and native libraries for all shipped ABIs.

The current app targets SDK 36. Before increasing `targetSdk` to 37, a separate gate must declare and request `ACCESS_LOCAL_NETWORK` with rationale, denial, revocation, and successful-router-connection tests, then run the contract suite on an accelerated API 37 emulator or physical device. Requesting it before the target change would contradict Android's current compatibility guidance.

## Router hardware boundary

Fingerprint and workflow-selection tests can prove safe routing and fail-closed behavior, but they cannot prove an unobserved ISP firmware page. An automatic adapter becomes eligible only after a sanitized hardware/firmware capture demonstrates login, CSRF/session handling, editable DNS/firewall controls, idempotency, and read-back verification. The hardware queue is maintained in `ROADMAP.md`.
