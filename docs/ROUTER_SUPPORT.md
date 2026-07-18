# Egyptian router support

Router firmware is identified before any configuration request. Arabs Guard uses a dedicated workflow per vendor/model/firmware family and stops when the fingerprint is unknown.

| Egyptian provider/use | Model family | Workflow | Release status |
|---|---|---|---|
| WE fixed broadband | Huawei DN8245V-56 | Internet WAN DNS override, then hybrid IP filter rule for outbound TCP/UDP ports 53 and 853, then read-back verification | Automatic only while the tested runtime page contract matches |
| WE / Vodafone fixed broadband | ZTE ZXHN H188A and H188A V2 | ZTE Internet WAN DNS and access-control workflow | Model-specific guided profile; automatic writes disabled until firmware validation |
| Vodafone fiber | Huawei HG8245W5-6T family | Huawei ONT WAN/DHCP DNS workflow | Model-specific guided profile |
| Egyptian fiber | Huawei EG8145/EG8245 and ZTE ZXHN F660/F670/F680/F673 families | Vendor-specific ONT WAN/DHCP DNS workflow | Model-specific guided profile |
| WE Air 5G | Huawei H153 family | Huawei CPE network DNS workflow | Model-specific guided profile |
| WE 4G/MiFi | ZTE K10, MF937, MF971R, MF927U | Mobile-router LAN/DHCP DNS workflow | Model-specific guided profile |
| WE/Vodafone/Orange/e& Egypt mobile broadband | Huawei B310/B315/B525/B535 (including Orange-documented B535-932A)/B612/B818 and H112/H122/H155 families | Huawei CPE LAN/DHCP DNS workflow | Model-specific guided profile |
| WE / Orange legacy | ZTE ZXHN H168N and H108N families | ZTE legacy WAN/DHCP DNS workflow by firmware revision | Model-specific guided profile |
| Egyptian legacy ISP | Huawei DG8045, HG633, HG630, HG531/HG532 families | Huawei legacy WAN/DHCP DNS and URL-filter workflow | Model-specific guided profile |
| Egyptian retail and e& Egypt business mobile broadband | TP-Link TD-W9950/W9960/W9970, Archer VR300/400/600/2100, Deco X20/X50-DSL and Archer/TL-MR mobile families | TP-Link Internet/DHCP DNS and parental-control workflow | Detection/guided fallback |
| Egyptian retail | D-Link DSL-224, Egypt-firmware DSL-245GE, DSL-2877/2888 families | D-Link WAN DNS and parental-control workflow | Detection/guided fallback |
| WE mesh / Egyptian fiber | Nokia Beacon B1.1 and G-240 families | Nokia upstream-gateway or ONT DNS workflow | Detection/guided fallback |
| Egyptian retail/legacy | Tenda V12/D301/D305, ASUS DSL, NETGEAR D6220/D6400/D7000 and Technicolor/Thomson gateways | Vendor-specific WAN or DHCP DNS workflow | Detection/guided fallback |

“Guided” is intentional: model names alone do not prove that page paths, CSRF handling, firewall semantics, or validation rules match. Sending a generic admin request could disconnect the household or weaken an existing firewall.

## Huawei DN8245V-56 adapter

The verified adapter:

1. Connects only to the numeric private router address supplied by the user.
2. Fingerprints the exact `DN8245V-56` model before signing in, then verifies the tested login/WAN/firewall page functions at every phase.
3. Uses the router's own login JavaScript and browser session; credentials are not persisted.
4. Selects the routed WAN whose service list contains `INTERNET`.
5. Applies CleanBrowsing Family Filter IPv4 DNS endpoints.
6. Requires the existing hybrid firewall policy and adds an idempotent upstream drop rule for external DNS ports 53 and 853.
7. Reloads the firewall page and verifies the exact rule before reporting success.

The model string alone never proves page compatibility. If the required login function, WAN, page functions, editable DNS controls, hybrid policy, or read-back result differs, the adapter stops and reports an unsupported firmware state. The UI calls this a verified automatic *adapter*, not a guarantee for every firmware carrying that model name.

## Regression coverage

- A shared canonical fixture matrix contains representative, noisy router-page fingerprints for every dedicated Egyptian workflow. Pure JVM tests exercise every fixture and ensure only the exact model assigned to the fail-closed adapter can enter its automatic path.
- Flutter catalog tests require a one-to-one workflow-ID match with that native fixture matrix, preventing the UI catalog and Android detector from silently drifting apart.
- The Huawei adapter is idempotent and verifies WAN DNS and firewall state after each write before reporting success.
- A machine-readable validation queue must contain exactly one entry for every catalog workflow, and every automatic entry must have a sanitized structural contract fixture. See [ROUTER_CAPTURE_PROTOCOL.md](ROUTER_CAPTURE_PROTOCOL.md).
- Hosted AOSP Android jobs cover every proven runtime API from 24 through 36. Each runs package/activity smoke checks plus native permission, component, lifecycle, VPN-consent, and Android 17 manifest contracts. API 37 remains an explicit physical-hardware certification gate because the hosted image transport is unreliable. Heavy AVD images are not downloaded on the development machine. See [TESTING.md](TESTING.md).

These tests prevent workflow-selection regressions; they do not turn an unobserved ISP firmware revision into a verified automatic adapter. A hardware/firmware capture is still required before enabling writes for that revision.

## Research basis

Provider catalog pages used to establish current Egyptian model families:

- [WE Premium Router — ZTE ZXHN H188A](https://te.eg/en/web/guest/w/premium-router)
- [Vodafone Dual Band Router — ZTE ZXHN H188A V2](https://web.vodafone.com.eg/en/dualband-router)
- [Vodafone home compound/fiber support — Huawei HG8245W5-6T](https://web.vodafone.com.eg/ar/home-compound-support-details)
- [WE Air H153 device](https://te.eg/en/web/guest/w/weairh153device)
- [WE confirms current Home 5G expansion and router/MiFi support](https://te.eg/en/web/guest/personal/home-5g)
- [WE 4G routers](https://www.te.eg/web/guest/personal/devices/4g-routers)
- [WE router/mesh catalog](https://www.te.eg/en/personal/devices/routers)
- [TP-Link Egypt modem-router catalog](https://www.tp-link.com/eg/home-networking/all-gateways/)
- [TP-Link Egypt DSL models and official emulators](https://www.tp-link.com/eg/support/emulator/)
- [D-Link DSL-245GE Egypt-specific firmware and manual](https://www.dlinkmea.com/index.php/product/details?det=K0RsQzFkQldYNnkxQnhUbjN6SkwwQT09)
- [Orange Egypt Home 4G router interface guidance](https://www.orange.eg/en/help/faq-details?category=35&q=421)
- [Vodafone Egypt Home Wireless router guidance](https://web.vodafone.com.eg/en/wireless-net)
- [e& Egypt Office 4G lists Huawei, ZTE, and TP-Link supplied-router families](https://www.etisalat.eg/StaticFiles/portal/etisalat/pages/corporate/home-4g_en.html)
- [Orange Egypt documentation identifies the Huawei B535-932A Home Wireless router](https://www.orange.eg/ar/Documents/Samsung-Smart-TV-Ramadan-offer-prices-en.pdf)

This catalog is not a claim that these are every router ever sold in Egypt. Provider inventory and ISP firmware change, so new adapters require a firmware capture and non-destructive verification before automatic support is enabled.
