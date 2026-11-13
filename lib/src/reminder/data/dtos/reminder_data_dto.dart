import '../../domain/entities/app_enums.dart';
import '../../domain/entities/hydration_history.dart';
import '../../domain/entities/reminder_data.dart';
import '../../domain/entities/reminder_settings.dart';

/// Formato JSON do arquivo de configurações salvo em disco.
class ReminderDataDto {
  const ReminderDataDto(this.json);

  /// Mensagens padrão da versão 0.1, salvas literalmente e que não devem virar mensagem personalizada.
  static const _legacyDefaults = {
    'Time to drink water! Take a quick break and stay hydrated.',
    'Hora de beber água! Faça uma pausa rápida e mantenha-se hidratado.',
    '¡Hora de beber agua! Haz una pausa rápida y mantente hidratado.',
  };

  /// Conteúdo JSON bruto.
  final Map<String, dynamic> json;

  /// Cria o DTO a partir da entidade.
  factory ReminderDataDto.fromEntity(ReminderData data) {
    final s = data.settings;
    return .new({
      'version': 2,
      'interval': s.intervalMinutes,
      'customMessage': s.customMessage,
      'lang': s.lang?.name,
      'theme': s.themeMode.name,
      'goalMl': s.goalMl,
      'glassMl': s.glassMl,
      'weightKg': s.weightKg,
      'activity': s.activity.name,
      'activeHours': s.activeHoursEnabled,
      'activeStart': s.activeStartMinute,
      'activeEnd': s.activeEndMinute,
      'adaptive': s.adaptive,
      'sound': s.sound,
      'focusMode': s.focusMode,
      'randomTips': s.randomTips,
      'hotkey': s.hotkey,
      'paused': data.paused,
      'deadline': data.deadline?.toIso8601String(),
      'remainingSeconds': data.pausedRemaining?.inSeconds,
      'history': data.history.entries,
    });
  }

  /// Converte para a entidade, aplicando valores padrão e migrando o formato da versão 0.1.
  ReminderData toEntity() {
    const d = ReminderSettings();
    int? number(String key) => json[key] is num ? (json[key] as num).toInt() : null;
    int integer(String key, int fallback, int min, int max) => (number(key) ?? fallback).clamp(min, max);
    bool flag(String key, bool fallback) => json[key] is bool ? json[key] as bool : fallback;
    String? text(String key) => json[key] is String ? json[key] as String : null;
    final legacyMessage = text('message')?.trim() ?? '';
    final message = text('customMessage') ?? (_legacyDefaults.contains(legacyMessage) ? '' : legacyMessage);
    final rawHistory = json['history'];
    final history = <String, int>{
      if (rawHistory is Map)
        for (final e in rawHistory.entries)
          if (e.value is num) '${e.key}': (e.value as num).toInt(),
    };
    final legacyGlasses = number('glasses');
    if (rawHistory == null && legacyGlasses != null && text('day') != null) history[text('day')!] = legacyGlasses * d.glassMl;
    final remaining = number('remainingSeconds');
    return .new(
      settings: .new(
        intervalMinutes: integer('interval', d.intervalMinutes, ReminderSettings.minInterval, ReminderSettings.maxInterval),
        customMessage: message,
        lang: AppLang.tryParse(text('lang')),
        themeMode: AppThemeMode.parse(text('theme')),
        goalMl: integer('goalMl', d.goalMl, 100, 20000),
        glassMl: integer('glassMl', d.glassMl, 10, 5000),
        weightKg: integer('weightKg', d.weightKg, 20, 400),
        activity: ActivityLevel.parse(text('activity')),
        activeHoursEnabled: flag('activeHours', d.activeHoursEnabled),
        activeStartMinute: integer('activeStart', d.activeStartMinute, 0, 1439),
        activeEndMinute: integer('activeEnd', d.activeEndMinute, 0, 1439),
        adaptive: flag('adaptive', d.adaptive),
        sound: flag('sound', d.sound),
        focusMode: flag('focusMode', d.focusMode),
        randomTips: flag('randomTips', d.randomTips),
        hotkey: flag('hotkey', d.hotkey),
      ),
      paused: flag('paused', false),
      deadline: DateTime.tryParse(text('deadline') ?? ''),
      pausedRemaining: remaining == null || remaining <= 0 ? null : Duration(seconds: remaining),
      history: HydrationHistory(Map.unmodifiable(history)),
    );
  }
}
