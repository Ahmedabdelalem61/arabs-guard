import 'dart:io';
import 'dart:convert';

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
        'W8961N',
        'VR300/400/600',
        'MR600',
        'MR402',
        'M7005',
        'NX200',
        'DSL-245GE',
        'DSL-124',
        'DWR-933M',
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

  test('prioritized hardware queue covers every Egyptian workflow once', () {
    final queueLines = File('docs/router_validation_queue.tsv')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
        .toList();
    final rows = queueLines.map((line) {
      final columns = line.split('|');
      expect(columns, hasLength(6), reason: 'malformed queue row: $line');
      return (priority: columns[0], workflowId: columns[1], status: columns[4]);
    }).toList();

    final catalogIds = egyptRouterCatalog
        .map((profile) => profile.workflowId)
        .toSet();
    expect(rows.map((row) => row.workflowId).toSet(), catalogIds);
    expect(rows, hasLength(catalogIds.length));
    expect(rows.map((row) => row.priority).toSet(), hasLength(rows.length));
    expect(
      rows
          .where((row) => row.status == 'structural_contract_verified')
          .map((row) => row.workflowId)
          .toSet(),
      {'huawei_dn8245v56'},
    );
  });

  test('every automatic adapter has a secret-free structural contract', () {
    final verified = egyptRouterCatalog.where(
      (profile) => profile.automation == RouterAutomation.verified,
    );
    final addressPattern = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');
    final macPattern = RegExp(r'\b(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}\b');
    const forbiddenKeys = <String>{
      'username',
      'password',
      'cookie',
      'token',
      'ssid',
      'mac',
      'serial',
      'address',
    };

    void inspect(Object? value) {
      if (value is Map<String, Object?>) {
        for (final entry in value.entries) {
          expect(
            forbiddenKeys,
            isNot(contains(entry.key.toLowerCase())),
            reason: 'sensitive contract key: ${entry.key}',
          );
          inspect(entry.value);
        }
      } else if (value is List<Object?>) {
        value.forEach(inspect);
      } else if (value is String) {
        expect(addressPattern.hasMatch(value), isFalse);
        expect(macPattern.hasMatch(value), isFalse);
      }
    }

    for (final profile in verified) {
      final file = File(
        'test/fixtures/router_contracts/${profile.workflowId}.json',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'missing ${profile.workflowId}',
      );
      final contract =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      expect(contract['schemaVersion'], 1);
      expect(contract['workflowId'], profile.workflowId);
      expect(contract['automaticEligible'], isTrue);
      expect(contract['stages'], isA<Map<String, Object?>>());
      expect(contract['safety'], isA<Map<String, Object?>>());
      inspect(contract);
    }
  });
}
