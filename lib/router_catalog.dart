enum RouterAutomation { verified, guided, detectOnly }

class RouterProfile {
  const RouterProfile({
    required this.carrier,
    required this.vendor,
    required this.models,
    required this.workflow,
    required this.automation,
  });

  final String carrier;
  final String vendor;
  final String models;
  final String workflow;
  final RouterAutomation automation;
}

const egyptRouterCatalog = <RouterProfile>[
  RouterProfile(
    carrier: 'WE',
    vendor: 'Huawei',
    models: 'DN8245V-56',
    workflow: 'WAN DNS + DNS-bypass firewall verification',
    automation: RouterAutomation.verified,
  ),
  RouterProfile(
    carrier: 'WE / Vodafone',
    vendor: 'ZTE',
    models: 'ZXHN H188A / H188A V2',
    workflow: 'ZTE Internet WAN DNS + access-control workflow',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    carrier: 'Vodafone Fiber',
    vendor: 'Huawei',
    models: 'HG8245W5-6T, HG8245, EG8145 / EG8245 families',
    workflow: 'Huawei ONT WAN/DHCP DNS workflow',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    carrier: 'Egypt fiber',
    vendor: 'ZTE',
    models: 'ZXHN F660, F670 / F670L, F680, F673 families',
    workflow: 'ZTE ONT WAN/DHCP DNS workflow by firmware revision',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    carrier: 'WE Air 5G',
    vendor: 'Huawei',
    models: 'H153 family',
    workflow: 'Huawei CPE network DNS workflow',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    carrier: 'WE 4G / Egyptian mobile broadband',
    vendor: 'ZTE',
    models: 'K10, MF937, MF971R, MF927U',
    workflow: 'Mobile-router LAN/DHCP DNS workflow',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    carrier: 'WE / Vodafone / Orange mobile broadband',
    vendor: 'Huawei',
    models: 'B310, B315, B525, B535, B612, B818, H112 / H122 / H155',
    workflow: 'Huawei CPE LAN/DHCP DNS workflow by firmware branch',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    carrier: 'WE / Orange legacy',
    vendor: 'ZTE',
    models: 'ZXHN H168N / H108N families',
    workflow: 'ZTE legacy WAN/DHCP DNS workflow by firmware revision',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    carrier: 'Egypt legacy ISP',
    vendor: 'Huawei',
    models: 'DG8045, HG633, HG630, HG531 / HG532 families',
    workflow: 'Huawei legacy WAN/DHCP DNS and URL-filter workflow',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    carrier: 'Egypt retail',
    vendor: 'TP-Link',
    models: 'TD-W9950/W9960/W9970, Archer VR300/400/600/2100, Deco X20/X50-DSL',
    workflow: 'TP-Link Internet/DHCP DNS and parental-control workflow',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    carrier: 'Egypt retail mobile broadband',
    vendor: 'TP-Link',
    models: 'Archer MR200 / MR400 / MR500 / MR600, TL-MR6400',
    workflow: 'TP-Link LTE Internet/DHCP DNS workflow by hardware version',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    carrier: 'Egypt retail',
    vendor: 'D-Link',
    models: 'DSL-224, DSL-245GE Egypt firmware, DSL-2877 / DSL-2888 families',
    workflow: 'D-Link WAN DNS and parental-control workflow',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    carrier: 'WE mesh / Egypt fiber',
    vendor: 'Nokia',
    models: 'Beacon B1.1 and G-240 home gateway families',
    workflow: 'Nokia upstream gateway or ONT DNS workflow',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    carrier: 'Egypt retail / legacy',
    vendor: 'Tenda / ASUS / NETGEAR / Technicolor',
    models: 'V12, D301/D305, ASUS DSL, D6220/D6400/D7000, TG gateway families',
    workflow: 'Vendor-specific WAN or DHCP DNS workflow',
    automation: RouterAutomation.detectOnly,
  ),
];
