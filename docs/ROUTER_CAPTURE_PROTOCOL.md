# Secret-free router validation protocol

This protocol turns hardware observations into regression evidence without collecting a household's router secrets or raw administration pages. A catalog fingerprint is detection evidence only; it cannot enable writes.

## Safety boundary

Use a router you own or are explicitly authorized to administer. Prefer a spare router or a maintenance window, export a recoverable configuration backup, keep another connection available, and do not change WAN credentials, remote administration, Wi-Fi security, firmware, or factory-reset settings.

Never submit:

- Router usernames, passwords, password-manager output, authentication tokens, session identifiers, cookies, or CSRF values.
- Public or private IP addresses, MAC addresses, serial numbers, SSIDs, phone numbers, subscriber identifiers, configuration backups, packet captures, or raw HTML/JavaScript dumps.
- Screenshots containing account, network, device, or household information.

## Evidence stages

1. Record only provider, printed model, hardware revision, and firmware family after removing unique identifiers.
2. Describe the login contract as element and function *names*, never their values.
3. Describe the WAN/DHCP contract as page path, required function names, editable DNS fields, routed-Internet selection semantics, and save result.
4. Describe firewall behavior as policy mode, rule-field names, idempotency result, and whether a second read shows the exact intended rule.
5. Reconnect a client and confirm the intended DNS policy survives; record only pass/fail and elapsed time.
6. Restore the original values and confirm connectivity; record only pass/fail.
7. Build a sanitized JSON contract following `test/fixtures/router_contracts/huawei_dn8245v56.json`. A reviewer must reject unknown keys or any value resembling a secret, address, or unique device identifier.

## Automation eligibility

An adapter stays guided or detection-only until the sanitized contract proves login/session handling, editable controls, safe preconditions, idempotent writes, read-back verification, reconnect persistence, and rollback on real hardware. Runtime code must independently check those structures again and stop before each unsupported operation. A model name, vendor emulator, manual, or successful login alone is insufficient.

The prioritized Egyptian queue is `router_validation_queue.tsv`. New evidence must add regression fixtures and keep the Dart catalog, native detector, queue, documentation, and hardware status aligned in one change.
