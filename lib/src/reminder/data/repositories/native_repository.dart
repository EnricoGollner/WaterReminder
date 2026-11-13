import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/entities/app_enums.dart';
import '../../domain/repositories/inative_repository.dart';

/// Integração com o runner Windows via `MethodChannel('water_reminder/native')`.
class NativeRepository implements INativeRepository {
  NativeRepository([this._channel = const MethodChannel('water_reminder/native')]) {
    _channel.setMethodCallHandler((call) async {
      final action = NativeAction.values.where((a) => a.name == call.method).firstOrNull;
      if (action != null) _actions.add(action);
    });
  }

  final MethodChannel _channel;
  final _actions = StreamController<NativeAction>.broadcast();

  @override
  Stream<NativeAction> get actions => _actions.stream;

  /// Invoca [method] e devolve [fallback] quando o lado nativo falha ou não existe (ex.: testes).
  Future<T> _call<T>(String method, Object? args, T fallback) async {
    try {
      return await _channel.invokeMethod<T>(method, args) ?? fallback;
    } on PlatformException {
      return fallback;
    } on MissingPluginException {
      return fallback;
    }
  }

  @override
  Future<bool> showNotification({required String title, required String message, required bool sound}) async {
    try {
      await _channel.invokeMethod<void>('showNotification', {'title': title, 'message': message, 'sound': sound});
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> configure({required NativeLabels labels, required bool paused}) => _call<void>('configure', {
    'paused': paused,
    'open': labels.open,
    'drink': labels.drink,
    'snooze': labels.snooze,
    'pause': labels.pause,
    'resume': labels.resume,
    'quit': labels.quit,
    'drankAction': labels.drankAction,
    'snoozeAction': labels.snoozeAction,
  }, null);

  @override
  Future<void> updateTray({required String tooltip, required bool paused}) => _call<void>('updateTray', {'tooltip': tooltip, 'paused': paused}, null);

  @override
  Future<bool> isUserBusy() => _call('isUserBusy', null, false);

  @override
  Future<bool> getAutostart() => _call('getAutostart', null, false);

  @override
  Future<bool> setAutostart(bool enabled) => _call('setAutostart', enabled, false);

  @override
  Future<bool> setHotkey(bool enabled) => _call('setHotkey', enabled, false);

  /// Libera o canal e o stream de ações.
  void dispose() {
    _channel.setMethodCallHandler(null);
    _actions.close();
  }
}
