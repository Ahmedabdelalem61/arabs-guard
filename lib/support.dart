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
