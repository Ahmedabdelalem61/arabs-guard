# Privacy Policy — Arabs Guard

Last updated: 20 July 2026

Arabs Guard is designed to provide family-safe DNS filtering without collecting personal data.

## Data the app processes

- Router address, username, and password entered by the user are processed locally only while the requested router setup is running.
- If the user starts the optional compatibility check, the app reads a bounded portion of the router's public login-page title and visible text in memory to look for a supported model marker. It sends no router username or password, changes no setting, saves no page content, and clears the router browser session afterward.
- DNS queries from the device are processed by a local Android VPN interface and sent through an encrypted DNS-over-HTTPS connection to the CleanBrowsing Family Filter.
- Basic in-app protection status is held locally while the app runs.
- On Android 17+, local-network access is used only after the user starts the optional compatibility check or chooses router protection and grants Android's Nearby devices permission. The app connects only to the numeric private router address selected in setup.

## Data the app does not collect

- Router credentials are not saved, logged, uploaded, or shared.
- Browsing history and DNS-query history are not stored by the app.
- The app contains no advertising or analytics SDK.
- The app does not request contacts, phone, SMS, location, camera, microphone, or storage access.
- The app does not scan for nearby people or collect local-device identities, SSIDs, or network inventories.

CleanBrowsing operates the upstream Family Filter and applies its own service terms and privacy practices. Review those practices before enabling device protection.

## WhatsApp support

Choosing support opens an external `wa.me` link. From a router failure dialog, the prefilled message contains only an allowlisted diagnostic code; it deliberately excludes the router address, model text, username, password, cookies, page content, and native error text.

The optional router-validation volunteer action opens a separate fixed checklist. The app supplies no detected model, gateway, credentials, firmware text, device identifier, or network data and stores no checklist response. The template asks the user to type only country, provider, printed model, non-unique hardware revision, and a sanitized firmware family, and prominently warns against sending addresses, credentials, SSIDs, serial/MAC/subscriber identifiers, cookies/tokens, screenshots, backups, page source, or packet captures. The user can review or edit either message before sending it. WhatsApp and the device browser then operate under their own privacy policies. Arabs Guard does not read the user's contacts or WhatsApp data.

## Security

Router inspection and administration are restricted to a numeric private IPv4 address supplied by the user. Public-host access and navigation away from that private router are rejected. Some home routers use a self-signed HTTPS certificate; Arabs Guard accepts that certificate only for the exact validated private router host during the visible check or setup session. Cookies, cache, history, and credentials are not retained as app data after the router session.

## Contact

Use the WhatsApp support action inside the app for privacy questions.
