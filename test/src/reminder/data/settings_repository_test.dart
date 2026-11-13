import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:water_reminder/src/reminder/data/repositories/settings_repository.dart';
import 'package:water_reminder/src/reminder/domain/entities/reminder_data.dart';
import 'package:water_reminder/src/reminder/domain/entities/reminder_settings.dart';

void main() {
  late Directory dir;
  late File file, legacy;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('water_reminder_test');
    file = File('${dir.path}/new/settings.json');
    legacy = File('${dir.path}/old/settings.json');
  });

  tearDown(() => dir.delete(recursive: true));

  group('SettingsRepository', () {
    test('load retorna null quando não há arquivo', () async {
      expect(await SettingsRepository(file: file, legacyFile: legacy).load(), isNull);
    });

    test('save grava e load lê o mesmo estado', () async {
      final repository = SettingsRepository(file: file);
      const data = ReminderData(settings: ReminderSettings(goalMl: 1800));
      expect(await repository.save(data), isTrue);
      expect(await repository.load(), data);
    });

    test('load usa o arquivo legado enquanto o novo não existe', () async {
      await legacy.create(recursive: true);
      await legacy.writeAsString('{"interval": 45}');
      final loaded = await SettingsRepository(file: file, legacyFile: legacy).load();
      expect(loaded?.settings.intervalMinutes, 45);
    });

    test('load retorna null quando o JSON está corrompido', () async {
      await file.create(recursive: true);
      await file.writeAsString('{not json');
      expect(await SettingsRepository(file: file).load(), isNull);
    });
  });
}
