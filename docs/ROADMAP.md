# Arabs Guard prioritized roadmap

This list is ordered by release risk. A lower priority must not displace an unfinished higher-priority compatibility or safety gate.

## P0 — Android compatibility gate (mandatory)

- [x] Support the Flutter SDK floor, Android 7.0/API 24.
- [x] Run the release APK on every stable API from 24 through 36 using GitHub-hosted AOSP x86_64 emulators.
- [x] On APIs 24–36, verify the exact runtime API, install the release and instrumentation APKs, launch/resume `MainActivity`, and run the native component/permission/VPN contract suite.
- [ ] Run the same contract suite on a physical Android 17/API 37 device, or when its hosted emulator transport becomes reliable. The manual physical gate is implemented and rejects emulators.
- [x] Run Flutter tests for router-only, device-only, router+device validation, gateway auto-detection, catalog navigation, and the Arabic-region roadmap.
- [x] Keep KVM acceleration, explicit ADB timeouts/recovery, per-job ceilings, and uploaded per-API diagnostics so no runner can hang indefinitely.
- [x] Target SDK 37 and add prominent `ACCESS_LOCAL_NETWORK` consent, denial handling, defensive native enforcement, and fresh-install permission contracts.
- [ ] Certify the Android 17 permission grant, denial, settings revocation, and successful router reconnection paths on physical API 37 hardware.

## P0 — Egyptian router safety and coverage gate

- [x] Cover fixed DSL/VDSL, fiber ONT, 4G/MiFi, 5G CPE, mesh, and Egyptian retail-router categories.
- [x] Represent WE, Vodafone, Orange, and e& Egypt provider markets using current provider evidence.
- [x] Fingerprint Huawei, ZTE, TP-Link, D-Link, Nokia, Tenda, ASUS, NETGEAR, and Technicolor/Thomson families.
- [x] Keep the Dart compatibility catalog and native detector aligned through one canonical regression fixture matrix with representative fingerprints for every workflow.
- [x] Add a credential-free, read-only public-login-page compatibility check after gateway detection. It requests Android local-network consent first, sends only the private gateway address to native code, and reports unknown when the page exposes no exact supported marker.
- [x] Fail closed on unknown models, firmware, page structure, WAN selection, or verification results.
- [x] Keep automatic writes restricted to the exact Huawei DN8245V-56 adapter already validated and regression-tested.
- [ ] Hardware-validation queue: ZTE H188A/H188A V2, Huawei HG8245W5-6T, Huawei B535-932A, ZTE K10/MF971R, Huawei H153, ZTE F670/F680, TP-Link TD-W8961N/VR/MR, and D-Link DSL-245GE. Each item needs a sanitized firmware/page capture and read-back test before automation can be enabled.
- [x] Publish a secret-free capture protocol and machine-readable validation queue so new evidence can be regression-tested without collecting router credentials, cookies, addresses, SSIDs, or raw page dumps.
- [ ] Add newly supplied ISP models only after model/firmware evidence is obtained; provider inventories change and cannot be safely inferred from branding.

## P1 — Arabic-world expansion

- [x] Add a modern, bilingual “Coming soon” experience covering all 22 Arab League countries in four validation regions, with Arabic/English country names and validation steps.
- [x] Clearly distinguish roadmap scope from verified compatibility.
- [ ] Recruit firmware-capture testers market by market, beginning with Gulf and Levant providers, then Maghreb and Horn of Africa markets.
- [ ] Publish a provider/model/firmware evidence table per country before enabling any automatic adapter.

## P2 — Production distribution

- [x] Publish architecture-aware APKs, a universal APK, an AAB, checksums, and a demo video as a prerelease.
- [x] Provide WhatsApp support without contacts, phone, SMS, location, or storage permissions.
- [ ] Replace debug release signing with an offline production upload key.
- [ ] Complete Play Console VPN declarations, privacy disclosure, review video, store listing, and closed testing.

## P3 — Local data foundation (last)

- [x] Define the future local-only data contract in `LOCAL_DATA_ARCHITECTURE.md`.
- [ ] Add a local database only when a shipped feature needs durable structured state.
- [ ] Introduce versioned migrations and database regression tests before storing the first record.
- [ ] Never store router passwords, administrator usernames, domain queries, browsing history, or raw VPN traffic.
