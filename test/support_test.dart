import 'package:arabs_guard/guard_platform.dart';
import 'package:arabs_guard/support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('router support URI shares only an allowlisted diagnostic code', () {
    const result = RouterResult(
      ok: false,
      model: 'Huawei DN8245V-56',
      message: 'The router did not confirm the DNS policy.',
      workflow: 'dns_verification_failed',
    );

    final uri = routerFailureSupportUri(result);
    final text = uri.queryParameters['text'].orEmpty;

    expect(uri.scheme, 'https');
    expect(uri.host, 'wa.me');
    expect(uri.path, '/2001011459031');
    expect(text, contains('dns_verification_failed'));
    expect(text, contains('excluded the router address'));
    expect(text, isNot(contains(result.model)));
    expect(text, isNot(contains(result.message)));
  });

  test('unexpected native text cannot enter the support payload', () {
    const result = RouterResult(
      ok: false,
      model: '192.168.1.1',
      message: 'password=fixture-secret',
      workflow: 'fixture-secret_192_168_1_1',
    );

    final text = routerFailureSupportUri(
      result,
    ).queryParameters['text'].orEmpty;

    expect(text, contains('unsupported_router'));
    expect(text, isNot(contains('192.168.1.1')));
    expect(text, isNot(contains('fixture-secret')));
    expect(text, isNot(contains('password=')));
  });
}

extension on String? {
  String get orEmpty => this ?? '';
}
