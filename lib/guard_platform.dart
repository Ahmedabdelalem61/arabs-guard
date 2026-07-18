import 'dart:io';

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

class GuardPlatform {
  static const _channel = MethodChannel('com.arabsguard.guard/control');

  static Future<bool> requestVpnConsent() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('prepareVpn') ?? false;
  }

  static Future<bool> startVpn() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('startVpn') ?? false;
  }

  static Future<bool> vpnStatus() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('vpnStatus') ?? false;
  }

  static Future<void> openVpnSettings() async {
    if (Platform.isAndroid) {
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
