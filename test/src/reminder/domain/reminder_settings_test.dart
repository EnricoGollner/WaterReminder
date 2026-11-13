import 'package:flutter_test/flutter_test.dart';
import 'package:water_reminder/src/reminder/domain/entities/app_enums.dart';
import 'package:water_reminder/src/reminder/domain/entities/reminder_settings.dart';

void main() {
  group('ReminderSettings.isActiveAt', () {
    test('retorna true a qualquer hora quando o horário ativo está desligado', () {
      expect(const ReminderSettings().isActiveAt(DateTime(2026, 1, 1, 3)), isTrue);
    });

    test('respeita uma janela no mesmo dia (08:00–22:00)', () {
      const settings = ReminderSettings(activeHoursEnabled: true);
      expect(settings.isActiveAt(DateTime(2026, 1, 1, 7, 59)), isFalse);
      expect(settings.isActiveAt(DateTime(2026, 1, 1, 8)), isTrue);
      expect(settings.isActiveAt(DateTime(2026, 1, 1, 21, 59)), isTrue);
      expect(settings.isActiveAt(DateTime(2026, 1, 1, 22)), isFalse);
    });

    test('suporta janela que atravessa a meia-noite (22:00–06:00)', () {
      const settings = ReminderSettings(activeHoursEnabled: true, activeStartMinute: 22 * 60, activeEndMinute: 6 * 60);
      expect(settings.isActiveAt(DateTime(2026, 1, 1, 23)), isTrue);
      expect(settings.isActiveAt(DateTime(2026, 1, 1, 5)), isTrue);
      expect(settings.isActiveAt(DateTime(2026, 1, 1, 12)), isFalse);
    });
  });

  group('ReminderSettings.suggestedGoal', () {
    test('calcula 35 ml/kg mais o extra da atividade, arredondado para 50 ml', () {
      expect(ReminderSettings.suggestedGoal(70, ActivityLevel.low), 2450);
      expect(ReminderSettings.suggestedGoal(70, ActivityLevel.moderate), 2800);
      expect(ReminderSettings.suggestedGoal(61, ActivityLevel.high), 2850);
    });
  });

  group('ReminderSettings.effectiveInterval', () {
    final noon = DateTime(2026, 1, 1, 15);

    test('mantém o intervalo base com o adaptativo desligado', () {
      expect(const ReminderSettings().effectiveInterval(noon, 0), const Duration(minutes: 30));
    });

    test('reduz para 2/3 quando o consumo está abaixo de 80% do esperado', () {
      const settings = ReminderSettings(adaptive: true, intervalMinutes: 45);
      expect(settings.expectedIntakeAt(noon), 1000);
      expect(settings.effectiveInterval(noon, 500), const Duration(minutes: 30));
    });

    test('mantém o intervalo base quando o consumo está em dia', () {
      const settings = ReminderSettings(adaptive: true, intervalMinutes: 45);
      expect(settings.effectiveInterval(noon, 900), const Duration(minutes: 45));
    });

    test('nunca reduz abaixo de 5 minutos', () {
      const settings = ReminderSettings(adaptive: true, intervalMinutes: 6);
      expect(settings.effectiveInterval(noon, 0), const Duration(minutes: 5));
    });
  });

  test('copyWith com clearLang volta a seguir o idioma do sistema', () {
    const settings = ReminderSettings(lang: AppLang.pt);
    expect(settings.copyWith(clearLang: true).lang, isNull);
    expect(settings.copyWith(goalMl: 1500), isNot(settings));
  });

  test('AppLang.fromLocale reconhece português e espanhol e usa inglês como padrão', () {
    expect(AppLang.fromLocale('pt-BR'), AppLang.pt);
    expect(AppLang.fromLocale('es_ES'), AppLang.es);
    expect(AppLang.fromLocale('de-DE'), AppLang.en);
  });
}
