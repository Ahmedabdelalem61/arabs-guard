enum RouterAutomation { verified, guided, detectOnly }

class RouterProfile {
  const RouterProfile({
    required this.workflowId,
    required this.carrier,
    required this.vendor,
    required this.models,
    required this.workflow,
    required this.automation,
  });

  final String workflowId;
  final String carrier;
  final String vendor;
  final String models;
  final String workflow;
  final RouterAutomation automation;
}

const egyptRouterCatalog = <RouterProfile>[
  RouterProfile(
    workflowId: 'huawei_dn8245v56',
    carrier: 'WE',
    vendor: 'Huawei',
    models: 'DN8245V-56',
    workflow: 'WAN DNS + DNS-bypass firewall verification',
    automation: RouterAutomation.verified,
  ),
  RouterProfile(
    workflowId: 'zte_h188a',
    carrier: 'WE / Vodafone',
    vendor: 'ZTE',
    models: 'ZXHN H188A / H188A V2',
    workflow: 'ZTE Internet WAN DNS + access-control workflow',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    workflowId: 'huawei_fiber_ont',
    carrier: 'Vodafone Fiber',
    vendor: 'Huawei',
    models: 'HG8245W5-6T, HG8245, EG8145 / EG8245 families',
    workflow: 'Huawei ONT WAN/DHCP DNS workflow',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    workflowId: 'zte_fiber_ont',
    carrier: 'Egypt fiber',
    vendor: 'ZTE',
    models: 'ZXHN F660, F670 / F670L, F680, F673 families',
    workflow: 'ZTE ONT WAN/DHCP DNS workflow by firmware revision',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    workflowId: 'huawei_h153',
    carrier: 'WE Air 5G',
    vendor: 'Huawei',
    models: 'H153 family',
    workflow: 'Huawei CPE network DNS workflow',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    workflowId: 'zte_k10',
    carrier: 'WE 4G / Egyptian mobile broadband',
    vendor: 'ZTE',
    models: 'K10 family',
    workflow: 'ZTE K10 LAN/DHCP DNS workflow by firmware revision',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    workflowId: 'zte_mifi',
    carrier: 'WE 4G / e& Egypt business / Egyptian mobile broadband',
    vendor: 'ZTE',
    models: 'MF937, MF971R, MF927U families',
    workflow: 'ZTE MiFi LAN/DHCP DNS workflow by firmware revision',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    workflowId: 'huawei_mobile_cpe',
    carrier: 'WE / Vodafone / Orange / e& Egypt mobile broadband',
    vendor: 'Huawei',
    models:
        'B310, B315, B525, B535 / B535-932A, B612, B818, H112 / H122 / H155',
    workflow: 'Huawei CPE LAN/DHCP DNS workflow by firmware branch',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    workflowId: 'zte_legacy',
    carrier: 'WE / Orange legacy',
    vendor: 'ZTE',
    models: 'ZXHN H168N / H108N families',
    workflow: 'ZTE legacy WAN/DHCP DNS workflow by firmware revision',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    workflowId: 'huawei_legacy',
    carrier: 'Egypt legacy ISP',
    vendor: 'Huawei',
    models: 'DG8045, HG633, HG630, HG531 / HG532 families',
    workflow: 'Huawei legacy WAN/DHCP DNS and URL-filter workflow',
    automation: RouterAutomation.guided,
  ),
  RouterProfile(
    workflowId: 'tplink_dsl',
    carrier: 'Egypt retail',
    vendor: 'TP-Link',
    models:
        'TD-W8961N/W9950/W9960/W9970, Archer VR300/400/600/2100, Archer VX1800v, Deco X20/X50-DSL',
    workflow: 'TP-Link Internet/DHCP DNS and parental-control workflow',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'tplink_mobile',
    carrier: 'Egypt retail / e& Egypt business mobile broadband',
    vendor: 'TP-Link',
    models: 'Archer MR200 / MR400 / MR402 / MR500 / MR600, TL-MR6400',
    workflow: 'TP-Link LTE Internet/DHCP DNS workflow by hardware version',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'tplink_mifi',
    carrier: 'Egypt retail mobile broadband',
    vendor: 'TP-Link',
    models: 'M7005 / M7200 mobile Wi-Fi families',
    workflow: 'TP-Link MiFi LAN/DHCP DNS workflow by hardware version',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'tplink_5g',
    carrier: 'Egypt retail / 5G home wireless',
    vendor: 'TP-Link',
    models: 'Archer NX200 and Deco X50-5G families',
    workflow: 'TP-Link 5G CPE/mesh DNS workflow by hardware version',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'dlink_dsl',
    carrier: 'Egypt retail',
    vendor: 'D-Link',
    models:
        'DSL-124, DSL-224, DSL-245GE Egypt firmware, DSL-2877 / DSL-2888 / DSL-2888A families',
    workflow: 'D-Link WAN DNS and parental-control workflow',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'dlink_mobile',
    carrier: 'Egypt / Middle East retail mobile broadband',
    vendor: 'D-Link',
    models:
        'DWR-910M / DWR-921 / DWR-930M / DWR-933 / DWR-933M / DWR-953 families',
    workflow: 'D-Link LTE router/MiFi LAN/DHCP DNS workflow by revision',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'nokia_home',
    carrier: 'WE mesh / Egypt fiber',
    vendor: 'Nokia',
    models: 'Beacon B1.1 and G-240 home gateway families',
    workflow: 'Nokia upstream gateway or ONT DNS workflow',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'tenda_dsl',
    carrier: 'Egypt retail / legacy',
    vendor: 'Tenda',
    models: 'V12, D301 / D305 families',
    workflow: 'Tenda WAN/DHCP DNS workflow by hardware revision',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'asus_dsl',
    carrier: 'Egypt retail',
    vendor: 'ASUS',
    models: 'DSL gateway families',
    workflow: 'ASUS WAN/DHCP DNS workflow by hardware revision',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'netgear_dsl',
    carrier: 'Egypt retail',
    vendor: 'NETGEAR',
    models: 'D6220 / D6400 / D7000 families',
    workflow: 'NETGEAR WAN/DHCP DNS workflow by hardware revision',
    automation: RouterAutomation.detectOnly,
  ),
  RouterProfile(
    workflowId: 'technicolor_gateway',
    carrier: 'Egypt legacy ISP',
    vendor: 'Technicolor / Thomson',
    models: 'TG gateway families',
    workflow: 'Technicolor WAN/DHCP DNS workflow by firmware revision',
    automation: RouterAutomation.detectOnly,
  ),
];
