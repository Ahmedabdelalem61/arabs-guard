# Arabs Guard

Arabs Guard is a consent-driven Android app for family-safe DNS protection on a phone, a home router, or both. It is built with Flutter and a small native Kotlin layer for Android VPN and router-firmware integration.

## What works in this release

- Three modes: router, this Android phone, or both.
- Auto-detection of the current Wi-Fi/Ethernet gateway plus an optional credential-free, read-only compatibility check of the router's public login page. Exact model markers are reported when exposed; setup re-checks the authenticated page contract before any change.
- Android DNS-only `VpnService` with prominent disclosure and the Android system consent dialog.
- DNS queries are forwarded over DNS-over-HTTPS to the CleanBrowsing Family Filter.
- Huawei DN8245V-56 firmware adapter for WAN DNS plus an outbound TCP/UDP 53 and 853 bypass rule.
- Egyptian router fingerprint catalog covering major ZTE, Huawei DSL/fiber/4G/5G, TP-Link DSL/LTE/MiFi/5G, D-Link DSL/LTE/MiFi, Nokia, Tenda, ASUS, NETGEAR, and Technicolor families.
- Modern bilingual Arabic-world expansion roadmap covering all 22 Arab League countries without presenting unvalidated markets as supported.
- Unsupported or changed firmware fails closed: the app does not guess admin requests.
- WhatsApp support from the app without contact, SMS, phone, storage, or location permission. Router failures can prefill an allowlisted diagnostic code while excluding credentials, router addresses, cookies, page content, and raw error text.
- `DEMO_MODE` for recordings and UI testing without changing a router or starting a VPN.

## Important boundaries

No consumer app can make filtering literally irreversible. A router owner can factory-reset a router, and an Android owner can revoke or uninstall a VPN app. Arabs Guard does not secretly change the router administrator password or acquire device-owner privileges. For voluntary commitment, give router credentials to a trusted guardian and enable Android Always-on VPN.

The current phone tunnel routes only DNS. Do **not** enable Android's “Block connections without VPN” switch for this release; doing so can block non-DNS traffic. Always-on VPN itself is supported and helps Android restart the service.

DNS filtering cannot guarantee that every objectionable page worldwide will be classified immediately. It also cannot inspect encrypted page content. The router bypass rule covers common plaintext DNS and DNS-over-TLS ports, while apps using hard-coded DNS-over-HTTPS endpoints may need additional network controls.

## Router support

See [docs/ROUTER_SUPPORT.md](docs/ROUTER_SUPPORT.md), the auditable [docs/TESTING.md](docs/TESTING.md), and the prioritized [docs/ROADMAP.md](docs/ROADMAP.md). Automatic writes are intentionally limited to exact firmware that has been verified. The model name printed on a router is not enough because Egyptian ISP firmware varies.

## Privacy and security

See [PRIVACY.md](PRIVACY.md). The optional compatibility check sends no credentials and clears its isolated router WebView session. Router credentials remain in memory only during setup, are removed from the Android activity intent immediately, and are never saved, logged, or uploaded. The app has no analytics SDK.

Router automation only accepts numeric RFC1918/link-local/loopback IPv4 addresses. A self-signed certificate is accepted only for the exact private router host supplied by the user; public hosts and cross-host navigation are rejected.

## Development

Requirements:

- Flutter 3.44.6 or compatible stable release
- Android SDK Platform 37.0 (the hosted workflows install it; the development machine does not need an emulator)
- Android Gradle Plugin 9.1.1 and Gradle 9.3.1, matching Android's API 37 toolchain floor
- Java 17+

```bash
flutter pub get
flutter analyze
flutter test
android/gradlew -p android :app:testReleaseUnitTest
flutter build apk --debug
```

Run a safe simulated demo:

```bash
flutter run --dart-define=DEMO_MODE=true
```

Generate the launcher icons again:

```bash
flutter pub run flutter_launcher_icons
```

## Android permissions

- `INTERNET` and `ACCESS_NETWORK_STATE`: router access and encrypted DNS transport.
- `BIND_VPN_SERVICE`: enforced by Android on the DNS VPN service.
- foreground-service permissions: required to keep a user-visible VPN alive on modern Android.
- `POST_NOTIFICATIONS`: protection-status notification on Android 13+.
- `ACCESS_LOCAL_NETWORK`: Android 17+ runtime permission used only when the user chooses the optional router compatibility check or router protection.

The app targets SDK 37. Before the optional compatibility check or router setup on Android 17+, it presents a purpose-specific disclosure and then requests Android's `ACCESS_LOCAL_NETWORK` permission. Denial stops the requested router operation before credentials or router-page requests are sent. Android 7–16 do not show this new prompt.

The minimum supported version is Android 7.0 (API 24), which is the floor of the current Flutter SDK. The hosted compatibility workflow has passed every runtime API from 24 through 36 using lightweight AOSP images. Each job installs both the release app and its instrumentation APK, launches the Flutter activity, validates least-privilege components and permissions, verifies consent contracts, and uploads API-specific evidence. The release archive is also checked for 16 KB page-size alignment. Android 17/API 37 is released, but its published emulator image still does not boot reliably with acceleration on GitHub's standard hosted runners. A manual physical-device workflow uses an already-installed `adb`, explicitly confirms app-data reset and a credential-free router reachability probe, and exercises denied/granted/revoked/re-granted/cleanup permission states plus private-gateway reconnection without logging the gateway address. It downloads no emulator or AVD. No emulator image is downloaded to the development machine.

Future structured local data is intentionally the last priority. The privacy and migration contract is documented in [docs/LOCAL_DATA_ARCHITECTURE.md](docs/LOCAL_DATA_ARCHITECTURE.md); no database dependency is included until a real user-facing feature needs durable state.

## Release signing

Local demo APKs use the Flutter template's debug signing key. Before Play publishing, create and protect a production upload keystore, configure release signing outside Git, build an Android App Bundle, complete the Google Play `VpnService` declaration, and provide the required VPN review video and prominent-disclosure evidence.

The current Android 17 evaluation build is published as the [v1.0.0-alpha.10 prerelease](https://github.com/Ahmedabdelalem61/arabs-guard/releases/tag/v1.0.0-alpha.10).

## Support

Use the headset icon in the app to open WhatsApp support.
