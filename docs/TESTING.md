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

## Every-API device layer

GitHub Actions builds the release APK and release-targeting instrumentation APK once, then fans them out to every runtime API from 24 through 37. APIs 24–36 use lightweight AOSP x86_64 images. The official Android 17 repository currently provides API 37.0 x86_64 as a Google APIs 16 KB-page image while the stable SDK channel does not yet expose `platforms;android-37`. The hosted-only job therefore installs platform 36, matching the app's compile SDK, while selecting system-image API `37.0` and target `google_apis_ps16k`; the script still asserts the emulator itself reports runtime API 37. This also checks native-library compatibility with the newer page size. Each API job:

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

Every ADB operation has a hard timeout, recovery is bounded, the job has a ceiling, and the matrix uses `fail-fast: false` so one failure does not hide results from other versions. Build dependencies are cached, evidence expires after seven days, and documentation-only pushes do not start the expensive emulator matrix. Manual dispatch can select one API for a focused infrastructure rerun without paying for the complete matrix again.

## Android 17 scope

The current app targets SDK 36 and is runtime-tested on Android 17/API 37. Android grants SDK-36 targets compatibility access to the LAN. Before increasing `targetSdk` to 37, a separate gate must declare and request `ACCESS_LOCAL_NETWORK` with rationale, denial, revocation, and successful-router-connection tests. Requesting it before the target change would contradict Android's current guidance.

## Router hardware boundary

Fingerprint and workflow-selection tests can prove safe routing and fail-closed behavior, but they cannot prove an unobserved ISP firmware page. An automatic adapter becomes eligible only after a sanitized hardware/firmware capture demonstrates login, CSRF/session handling, editable DNS/firewall controls, idempotency, and read-back verification. The hardware queue is maintained in `ROADMAP.md`.
