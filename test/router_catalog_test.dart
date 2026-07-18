import 'package:arabs_guard/router_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Egypt router catalog covers major fixed, fiber, and mobile families',
    () {
      final text = egyptRouterCatalog
          .map((profile) => '${profile.vendor} ${profile.models}')
          .join(' ');

      for (final expected in <String>[
        'DN8245V-56',
        'H188A',
        'HG8245W5',
        'F670',
        'H153',
        'MF971R',
        'B315',
        'H168N',
        'DG8045',
        'VR300/400/600',
        'MR600',
        'DSL-245GE',
        'Beacon B1.1',
        'NETGEAR',
      ]) {
        expect(text, contains(expected), reason: 'missing $expected');
      }
    },
  );

  test('only validated profiles claim automatic router writes', () {
    final verified = egyptRouterCatalog
        .where((profile) => profile.automation == RouterAutomation.verified)
        .toList();

    expect(verified, hasLength(1));
    expect(verified.single.models, 'DN8245V-56');
  });
}
