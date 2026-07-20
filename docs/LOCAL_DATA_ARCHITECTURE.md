# Future local data architecture

Arabs Guard currently needs no database: protection status comes from Android, router credentials are intentionally ephemeral, and the router catalog ships as reviewed application data. Adding storage now would create privacy and migration risk without a user benefit.

The router-validation volunteer checklist also requires no persistence: it is a fixed external URI containing no automatically gathered router, phone, or network values. Any future contribution-tracking feature must pass the same database gate below instead of silently turning this checklist into local telemetry.

When a later feature genuinely needs durable structured state, use a local SQLite-backed repository behind a Dart interface so UI and protection code do not depend directly on a database package. Prefer a maintained Flutter SQLite abstraction with generated, versioned migrations. The selection must be reviewed again at implementation time rather than pinning an unused dependency today.

## Allowed future data

- Non-sensitive preferences such as language, theme, and whether education cards were dismissed.
- A coarse protection event such as “phone guard enabled” with a timestamp, without domains, queries, URLs, or traffic content.
- Sanitized router model/workflow identifiers and firmware-validation status, never credentials or session cookies.
- Downloaded regional catalog versions signed by the project, with no personal network identifiers.

## Prohibited data

- Router username or password.
- Router authentication tokens, cookies, or page captures from a user's device.
- DNS questions, browsing history, URLs, IP traffic, contacts, location, or advertising identifiers.
- Secrets merely “obfuscated” in SQLite. A secret that must exist later requires Android Keystore-backed protection and a separate threat-model review.

## Required implementation gate

1. Define repository interfaces and immutable domain models first.
2. Add schema version 1 plus exported schema snapshots.
3. Test fresh creation, CRUD, constraints, transactions, Unicode/Arabic/emoji, concurrent access, close/reopen persistence, corruption handling, and deletion.
4. For every later schema version, test migration from every supported historical version with retained-data assertions.
5. Run Android-dependent database tests across every supported API in the hosted matrix.
6. Provide a user-visible erase-local-data action and verify uninstall removes all app data.
