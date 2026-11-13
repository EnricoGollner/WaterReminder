import 'dart:async';

import 'package:water_reminder/src/reminder/domain/entities/app_enums.dart';
import 'package:water_reminder/src/reminder/domain/entities/reminder_data.dart';
import 'package:water_reminder/src/reminder/domain/repositories/inative_repository.dart';
import 'package:water_reminder/src/reminder/domain/repositories/isettings_repository.dart';

/// Repositório de configurações em memória.
class FakeSettingsRepository implements ISettingsRepository {
  FakeSettingsRepository({this.data, this.failSave = false});

  ReminderData? data;
  final bool failSave;
  int saves = 0;

  @override
  Future<ReminderData?> load() async => data;

  @override
  Future<bool> save(ReminderData data) async {
    saves++;
    if (failSave) return false;
    this.data = data;
    return true;
  }
}

/// Integração nativa falsa que registra as chamadas.
class FakeNativeRepository implements INativeRepository {
  final actionsController = StreamController<NativeAction>.broadcast();
  final notifications = <String>[];
  NativeLabels? labels;
  String tooltip = '';
  bool trayPaused = false;
  bool busy = false;
  bool autostart = false;
  bool hotkeyAvailable = true;
  bool notificationFails = false;

  @override
  Stream<NativeAction> get actions => actionsController.stream;

  @override
  Future<bool> showNotification({required String title, required String message, required bool sound}) async {
    if (notificationFails) return false;
    notifications.add(message);
    return true;
  }

  @override
  Future<void> configure({required NativeLabels labels, required bool paused}) async => this.labels = labels;

  @override
  Future<void> updateTray({required String tooltip, required bool paused}) async {
    this.tooltip = tooltip;
    trayPaused = paused;
  }

  @override
  Future<bool> isUserBusy() async => busy;

  @override
  Future<bool> getAutostart() async => autostart;

  @override
  Future<bool> setAutostart(bool enabled) async {
    autostart = enabled;
    return true;
  }

  @override
  Future<bool> setHotkey(bool enabled) async => !enabled || hotkeyAvailable;
}

/// Relógio controlável.
class FakeClock {
  FakeClock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}
