import 'guard_platform.dart';

const _supportPhone = '2001011459031';

const _shareableFailureCodes = <String>{
  'authentication_failed',
  'cancelled',
  'certificate_error',
  'dns_locked',
  'dns_verification_failed',
  'huawei_unverified',
  'huawei_wan_unverified',
  'invalid_address',
  'network_error',
  'wan_not_found',
};

Uri generalSupportUri() =>
    _whatsAppUri('Hello Arabs Guard support, I need help with my router.');

Uri routerValidationVolunteerUri() => _whatsAppUri(
  'Hello Arabs Guard support. I want to help validate a router safely.\n\n'
  'Fill only these non-unique fields manually:\n'
  'Country / البلد: [type manually]\n'
  'Internet provider / شركة الإنترنت: [type manually]\n'
  'Printed router model / موديل الراوتر: [type manually]\n'
  'Hardware revision (not serial number) / إصدار الجهاز: [type manually]\n'
  'Firmware family/version (remove unique IDs) / إصدار النظام: [type manually]\n\n'
  'Never send router addresses, usernames, passwords, Wi-Fi names, serial or MAC numbers, subscriber/phone IDs, cookies, tokens, screenshots, backups, page source, or packet captures.\n'
  'Arabs Guard attached no router, phone, or network data and stored nothing. Please guide me through the secret-free validation steps.',
);

Uri routerFailureSupportUri(RouterResult result) {
  final code = _shareableFailureCodes.contains(result.workflow)
      ? result.workflow
      : 'unsupported_router';
  return _whatsAppUri(
    'Hello Arabs Guard support.\n'
    'Router diagnostic code: $code\n'
    'The app excluded the router address, username, password, cookies, and page content.',
  );
}

Uri _whatsAppUri(String message) =>
    Uri.https('wa.me', '/$_supportPhone', <String, String>{'text': message});
