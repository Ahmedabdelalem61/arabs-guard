import 'dart:io';

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
        'B535-932A',
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

  test('catalog names all four national Egyptian provider markets', () {
    final carriers = egyptRouterCatalog
        .map((profile) => profile.carrier)
        .join(' ');

    expect(carriers, contains('WE'));
    expect(carriers, contains('Vodafone'));
    expect(carriers, contains('Orange'));
    expect(carriers, contains('e& Egypt'));
  });

  test('Dart catalog and native fingerprint matrix stay in sync', () {
    final fixtureLines =
        File('android/app/src/test/resources/egypt_router_fixtures.txt')
            .readAsLinesSync()
            .where((line) => line.trim().isNotEmpty && !line.startsWith('#'));
    final fixtures = fixtureLines.map((line) {
      final columns = line.split('|');
      expect(columns, hasLength(3), reason: 'malformed fixture: $line');
      return (workflowId: columns[0], automatic: columns[1] == 'true');
    }).toList();

    final catalogIds = egyptRouterCatalog
        .map((profile) => profile.workflowId)
        .toSet();
    final fixtureIds = fixtures.map((fixture) => fixture.workflowId).toSet();

    expect(
      egyptRouterCatalog.map((profile) => profile.workflowId),
      hasLength(catalogIds.length),
    );
    expect(fixtureIds, catalogIds);
    expect(
      fixtures
          .where((fixture) => fixture.automatic)
          .map((fixture) => fixture.workflowId)
          .toSet(),
      {'huawei_dn8245v56'},
    );
  });
}
