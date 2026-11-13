import 'package:flutter_test/flutter_test.dart';
import 'package:water_reminder/src/reminder/data/dtos/reminder_data_dto.dart';
import 'package:water_reminder/src/reminder/domain/entities/app_enums.dart';
import 'package:water_reminder/src/reminder/domain/entities/hydration_history.dart';
import 'package:water_reminder/src/reminder/domain/entities/reminder_data.dart';
import 'package:water_reminder/src/reminder/domain/entities/reminder_settings.dart';

void main() {
  group('ReminderDataDto', () {
    test('fromEntity seguido de toEntity preserva o estado', () {
      final data = ReminderData(
        settings: const ReminderSettings(intervalMinutes: 45, customMessage: 'Água!', lang: AppLang.es, themeMode: AppThemeMode.dark, goalMl: 2500, glassMl: 300, adaptive: true, activeHoursEnabled: true, hotkey: false),
        paused: true,
        deadline: DateTime(2026, 3, 10, 12, 30),
        pausedRemaining: const Duration(minutes: 7),
        history: const HydrationHistory({'2026-03-10': 600}),
      );
      expect(ReminderDataDto(ReminderDataDto.fromEntity(data).json).toEntity(), data);
    });

    test('migra o formato da versão 0.1 (mensagem padrão, copos do dia)', () {
      final entity = const ReminderDataDto({
        'interval': 15,
        'message': 'Time to drink water! Take a quick break and stay hydrated.',
        'lang': 'pt',
        'paused': false,
        'glasses': 3,
        'day': '2026-03-10',
      }).toEntity();
      expect(entity.settings.intervalMinutes, 15);
      expect(entity.settings.customMessage, isEmpty);
      expect(entity.settings.lang, AppLang.pt);
      expect(entity.history.entries, {'2026-03-10': 750});
    });

    test('mantém a mensagem personalizada da versão 0.1', () {
      expect(const ReminderDataDto({'message': 'Beba!'}).toEntity().settings.customMessage, 'Beba!');
    });

    test('aplica limites e padrões para valores inválidos', () {
      final entity = const ReminderDataDto({'interval': 0, 'goalMl': -5, 'lang': 'xx', 'theme': 1, 'sound': 'yes', 'history': 'bad'}).toEntity();
      expect(entity.settings.intervalMinutes, ReminderSettings.minInterval);
      expect(entity.settings.goalMl, 100);
      expect(entity.settings.lang, isNull);
      expect(entity.settings.themeMode, AppThemeMode.system);
      expect(entity.settings.sound, isTrue);
      expect(entity.history.entries, isEmpty);
    });
  });
}
