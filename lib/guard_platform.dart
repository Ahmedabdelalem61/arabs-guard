import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RouterResult {
  const RouterResult({
    required this.ok,
    required this.model,
    required this.message,
    required this.workflow,
  });

  factory RouterResult.fromMap(Map<Object?, Object?> value) => RouterResult(
    ok: value['ok'] == true,
    model: value['model']?.toString() ?? 'Unknown router',
    message: value['message']?.toString() ?? 'No result was returned.',
    workflow: value['workflow']?.toString() ?? 'unknown',
  );

  final bool ok;
  final String model;
  final String message;
  final String workflow;
}

class RouterInspection {
  const RouterInspection({
    required this.detected,
    required this.model,
    required this.message,
    required this.workflow,
    required this.automaticEligible,
  });

  factory RouterInspection.fromMap(Map<Object?, Object?> value) =>
      RouterInspection(
        detected: value['detected'] == true,
        model: value['model']?.toString() ?? 'Unknown router',
        message:
            value['message']?.toString() ??
            'No inspection result was returned.',
        workflow: value['workflow']?.toString() ?? 'unknown',
        automaticEligible: value['automaticEligible'] == true,
      );

  final bool detected;
  final String model;
  final String message;
  final String workflow;
  final bool automaticEligible;
}

class GuardPlatform {
  static const _channel = MethodChannel('com.arabsguard.guard/control');

  @visibleForTesting
  static bool? debugAndroidOverride;

  static bool get _isAndroid =>
      debugAndroidOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static Future<bool> requestVpnConsent() async {
    if (!_isAndroid) return false;
    return await _channel.invokeMethod<bool>('prepareVpn') ?? false;
  }

  static Future<bool> startVpn() async {
    if (!_isAndroid) return false;
    return await _channel.invokeMethod<bool>('startVpn') ?? false;
  }

  static Future<bool> vpnStatus() async {
    if (!_isAndroid) return false;
    return await _channel.invokeMethod<bool>('vpnStatus') ?? false;
  }

  static Future<bool> requestLocalNetworkConsent() async {
    if (!_isAndroid) return false;
    return await _channel.invokeMethod<bool>('prepareLocalNetwork') ?? false;
  }

  static Future<String?> detectRouterGateway() async {
    if (!_isAndroid) return null;
    return _channel.invokeMethod<String>('detectRouterGateway');
  }

  static Future<RouterInspection> inspectRouter({
    required String address,
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'inspectRouter',
      <String, Object?>{'address': address},
    );
    return RouterInspection.fromMap(result ?? const <Object?, Object?>{});
  }

  static Future<void> openVpnSettings() async {
    if (_isAndroid) {
      await _channel.invokeMethod<void>('openVpnSettings');
    }
  }

  static Future<RouterResult> configureRouter({
    required String address,
    required String username,
    required String password,
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'configureRouter',
      <String, Object?>{
        'address': address,
        'username': username,
        'password': password,
      },
    );
    return RouterResult.fromMap(result ?? const <Object?, Object?>{});
  }
}
