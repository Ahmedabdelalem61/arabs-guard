import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arabs_guard/guard_platform.dart';
import 'package:arabs_guard/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.arabsguard.guard/control');
  late List<String> nativeCalls;

  setUp(() {
    GuardPlatform.debugAndroidOverride = true;
    nativeCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          nativeCalls.add(call.method);
          return switch (call.method) {
            'vpnStatus' => false,
            'detectRouterGateway' => '192.168.8.1',
            'configureRouter' => <String, Object?>{
              'ok': true,
              'model': 'Huawei DN8245V-56 (test fixture)',
              'message': 'DNS and bypass rules verified.',
              'workflow': 'huawei_dn8245v56',
            },
            'prepareVpn' || 'startVpn' => true,
            'openVpnSettings' => null,
            _ => throw PlatformException(code: 'unexpected_method'),
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    GuardPlatform.debugAndroidOverride = null;
  });

  testWidgets('shows protection entry points', (WidgetTester tester) async {
    await tester.pumpWidget(const ArabsGuardApp());
    await tester.pump();

    expect(find.text('Arabs Guard'), findsWidgets);
    expect(find.text('Set up protection'), findsOneWidget);
    expect(find.text('A calmer internet starts here'), findsOneWidget);
  });

  testWidgets('offers permission-light router auto detection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ArabsGuardApp());
    await tester.pump();
    await tester.tap(find.text('Set up protection'));
    await tester.pumpAndSettle();

    expect(find.text('Auto-detect Wi-Fi router'), findsOneWidget);
    await tester.tap(find.text('Auto-detect Wi-Fi router'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('router-detection-hint')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Router found at 192.168.8.1'), findsOneWidget);
    expect(nativeCalls, contains('detectRouterGateway'));
  });

  testWidgets('completes router-only protection with explicit consent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ArabsGuardApp());
    await tester.pump();
    await tester.tap(find.text('Set up protection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guard-mode-router')));
    await tester.pumpAndSettle();

    final username = find.byKey(const Key('router-username-field'));
    await tester.scrollUntilVisible(
      username,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(username, 'fixture-admin');
    final password = find.byKey(const Key('router-password-field'));
    await tester.scrollUntilVisible(
      password,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(password, 'fixture-password');
    final consent = find.byKey(const Key('router-consent'));
    await tester.scrollUntilVisible(
      consent,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(consent);
    final apply = find.byKey(const Key('apply-protection'));
    await tester.scrollUntilVisible(
      apply,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(apply);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Protection enabled'), findsOneWidget);
    expect(find.textContaining('Huawei DN8245V-56'), findsOneWidget);
    expect(nativeCalls, contains('configureRouter'));
    expect(nativeCalls, isNot(contains('prepareVpn')));
  });

  testWidgets('completes device-only VPN flow without router credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ArabsGuardApp());
    await tester.pump();
    await tester.tap(find.text('Set up protection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guard-mode-device')));
    await tester.pumpAndSettle();

    expect(find.text('Router username'), findsNothing);
    final consent = find.byKey(const Key('vpn-consent'));
    await tester.scrollUntilVisible(
      consent,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(consent);
    final apply = find.byKey(const Key('apply-protection'));
    await tester.scrollUntilVisible(
      apply,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(apply);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Protection enabled'), findsOneWidget);
    expect(
      find.textContaining('Phone: encrypted family DNS guard'),
      findsOneWidget,
    );
    expect(nativeCalls, containsAllInOrder(<String>['prepareVpn', 'startVpn']));
    expect(nativeCalls, isNot(contains('configureRouter')));
  });

  testWidgets('blocks setup until the selected layer disclosure is accepted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ArabsGuardApp());
    await tester.pump();
    await tester.tap(find.text('Set up protection'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guard-mode-device')));
    await tester.pumpAndSettle();

    final apply = find.byKey(const Key('apply-protection'));
    await tester.scrollUntilVisible(
      apply,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(apply);
    await tester.pump();

    expect(
      find.text('Please confirm the required disclosures.'),
      findsOneWidget,
    );
    expect(nativeCalls, isNot(contains('prepareVpn')));
  });

  testWidgets('completes the recommended router and phone flow together', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ArabsGuardApp());
    await tester.pump();
    await tester.tap(find.text('Set up protection'));
    await tester.pumpAndSettle();

    final username = find.byKey(const Key('router-username-field'));
    await tester.scrollUntilVisible(
      username,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(username, 'fixture-admin');
    final password = find.byKey(const Key('router-password-field'));
    await tester.scrollUntilVisible(
      password,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(password, 'fixture-password');
    final routerConsent = find.byKey(const Key('router-consent'));
    await tester.scrollUntilVisible(
      routerConsent,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(routerConsent);
    final vpnConsent = find.byKey(const Key('vpn-consent'));
    await tester.scrollUntilVisible(
      vpnConsent,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(vpnConsent);
    final apply = find.byKey(const Key('apply-protection'));
    await tester.scrollUntilVisible(
      apply,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(apply);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Protection enabled'), findsOneWidget);
    expect(find.textContaining('Router: Huawei DN8245V-56'), findsOneWidget);
    expect(
      find.textContaining('Phone: encrypted family DNS guard'),
      findsOneWidget,
    );
    expect(
      nativeCalls,
      containsAllInOrder(<String>['configureRouter', 'prepareVpn', 'startVpn']),
    );
  });

  testWidgets('opens the Egyptian router compatibility catalog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ArabsGuardApp());
    await tester.pump();
    final catalog = find.byKey(const Key('egypt-router-catalog'));
    await tester.scrollUntilVisible(
      catalog,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(catalog);
    await tester.pumpAndSettle();

    expect(find.text('Egypt router compatibility'), findsOneWidget);
    expect(find.textContaining('DN8245V-56'), findsOneWidget);
    expect(find.textContaining('H188A'), findsOneWidget);
    expect(find.text('Verified automatic'), findsOneWidget);

    final lastWorkflow = find.byKey(
      const Key('router-profile-technicolor_gateway'),
    );
    await tester.scrollUntilVisible(
      lastWorkflow,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(lastWorkflow, findsOneWidget);
    expect(find.textContaining('Technicolor / Thomson'), findsOneWidget);
    expect(find.text('Detection only'), findsWidgets);
  });

  testWidgets('opens transparent Arabic-world coming-soon roadmap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ArabsGuardApp());
    await tester.pump();
    final roadmapCard = find.byKey(const Key('arabic-regions-coming-soon'));
    await tester.scrollUntilVisible(
      roadmapCard,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(roadmapCard);
    await tester.pumpAndSettle();

    expect(find.text('Arabic-world roadmap'), findsOneWidget);
    expect(find.text('مصر هي نقطة البداية'), findsOneWidget);
    expect(find.text('SOON'), findsWidgets);
  });
}
