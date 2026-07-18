# Release artifacts

Signed APKs, the Android App Bundle, checksums, and the demo video are attached to the corresponding GitHub Release. They are staged in this directory locally but intentionally kept out of Git history.

- Universal APK: Android 7.0+ on arm64, armv7, and x86_64
- Per-ABI APKs: smaller downloads for each supported CPU family
- AAB: Google Play upload format
- Demo video: simulated router setup; no live credentials

The current prerelease artifacts use Android debug signing for evaluation. Configure a protected production upload key before a Google Play production submission.
