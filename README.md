# Arabs Guard

Arabs Guard is a consent-driven Android app for family-safe DNS protection on a phone, a home router, or both. It is built with Flutter and a small native Kotlin layer for Android VPN and router-firmware integration.

## What works in this release

- Three modes: router, this Android phone, or both.
- Auto-detection of the current Wi-Fi/Ethernet gateway, followed by model and firmware fingerprinting before router changes.
- Android DNS-only `VpnService` with prominent disclosure and the Android system consent dialog.
- DNS queries are forwarded over DNS-over-HTTPS to the CleanBrowsing Family Filter.
- Huawei DN8245V-56 firmware adapter for WAN DNS plus an outbound TCP/UDP 53 and 853 bypass rule.
- Egyptian router fingerprint catalog covering major ZTE, Huawei DSL/fiber/4G/5G, TP-Link DSL/LTE, D-Link, Nokia, Tenda, ASUS, NETGEAR, and Technicolor families.
- Modern bilingual Arabic-world expansion roadmap covering all 22 Arab League countries without presenting unvalidated markets as supported.
- Unsupported or changed firmware fails closed: the app does not guess admin requests.
- WhatsApp support from the app without contact, SMS, phone, storage, or location permission.
- `DEMO_MODE` for recordings and UI testing without changing a router or starting a VPN.

## Important boundaries

No consumer app can make filtering literally irreversible. A router owner can factory-reset a router, and an Android owner can revoke or uninstall a VPN app. Arabs Guard does not secretly change the router administrator password or acquire device-owner privileges. For voluntary commitment, give router credentials to a trusted guardian and enable Android Always-on VPN.

The current phone tunnel routes only DNS. Do **not** enable Android's “Block connections without VPN” switch for this release; doing so can block non-DNS traffic. Always-on VPN itself is supported and helps Android restart the service.

DNS filtering cannot guarantee that every objectionable page worldwide will be classified immediately. It also cannot inspect encrypted page content. The router bypass rule covers common plaintext DNS and DNS-over-TLS ports, while apps using hard-coded DNS-over-HTTPS endpoints may need additional network controls.

## Router support

See [docs/ROUTER_SUPPORT.md](docs/ROUTER_SUPPORT.md), the auditable [docs/TESTING.md](docs/TESTING.md), and the prioritized [docs/ROADMAP.md](docs/ROADMAP.md). Automatic writes are intentionally limited to exact firmware that has been verified. The model name printed on a router is not enough because Egyptian ISP firmware varies.

## Privacy and security

See [PRIVACY.md](PRIVACY.md). Router credentials remain in memory only during setup, are removed from the Android activity intent immediately, and are never saved, logged, or uploaded. The app has no analytics SDK.

Router automation only accepts numeric RFC1918/link-local/loopback IPv4 addresses. A self-signed certificate is accepted only for the exact private router host supplied by the user; public hosts and cross-host navigation are rejected.

## Development

Requirements:

- Flutter 3.41.7 or compatible stable release
- Android SDK 36
- Java 17+

```bash
flutter pub get
flutter analyze
flutter test
android/gradlew -p android :app:testDebugUnitTest
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

The app targets SDK 36. Android 17 introduces the `ACCESS_LOCAL_NETWORK` runtime permission for apps targeting SDK 37+, so that permission flow must be implemented and tested when the project moves to target 37. It is deliberately not requested while targeting 36, as required by Android's compatibility guidance.

The minimum supported version is Android 7.0 (API 24), which is the floor of the current Flutter SDK. The hosted compatibility workflow has passed every stable runtime API from 24 through 36 using lightweight AOSP images. Each job installs both the release app and its instrumentation APK, launches the Flutter activity, validates least-privilege components and permissions, verifies the fresh-install VPN-consent contract, and uploads API-specific evidence. The release archive is also checked for 16 KB page-size alignment. API 37 remains a manual preview gate because its currently published 16 KB-page emulator images cannot boot with acceleration on GitHub's standard hosted runners. No emulator image is downloaded to the development machine.

Future structured local data is intentionally the last priority. The privacy and migration contract is documented in [docs/LOCAL_DATA_ARCHITECTURE.md](docs/LOCAL_DATA_ARCHITECTURE.md); no database dependency is included until a real user-facing feature needs durable state.

## Release signing

Local demo APKs use the Flutter template's debug signing key. Before Play publishing, create and protect a production upload keystore, configure release signing outside Git, build an Android App Bundle, complete the Google Play `VpnService` declaration, and provide the required VPN review video and prominent-disclosure evidence.

## Support

Use the headset icon in the app to open WhatsApp support.
