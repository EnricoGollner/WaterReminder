import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'app_enums.dart';

/// Preferências configuráveis pelo usuário.
class ReminderSettings extends Equatable {
  const ReminderSettings({
    this.intervalMinutes = 30,
    this.customMessage = '',
    this.lang,
    this.themeMode = AppThemeMode.system,
    this.goalMl = 2000,
    this.glassMl = 250,
    this.weightKg = 70,
    this.activity = ActivityLevel.moderate,
    this.activeHoursEnabled = false,
    this.activeStartMinute = 8 * 60,
    this.activeEndMinute = 22 * 60,
    this.adaptive = false,
    this.sound = true,
    this.focusMode = true,
    this.randomTips = false,
    this.hotkey = true,
  });

  /// Menor e maior intervalo aceitos, em minutos.
  static const minInterval = 1, maxInterval = 1440;

  /// Intervalo base entre lembretes, em minutos.
  final int intervalMinutes;

  /// Mensagem personalizada da notificação; vazia usa a mensagem padrão do idioma.
  final String customMessage;

  /// Idioma escolhido; `null` enquanto o usuário não escolheu (usa o idioma do sistema).
  final AppLang? lang;

  /// Tema visual.
  final AppThemeMode themeMode;

  /// Meta diária de consumo, em ml.
  final int goalMl;

  /// Volume de um copo, em ml.
  final int glassMl;

  /// Peso do usuário em kg, usado na meta sugerida.
  final int weightKg;

  /// Nível de atividade física, usado na meta sugerida.
  final ActivityLevel activity;

  /// Indica se os lembretes ficam restritos ao horário ativo.
  final bool activeHoursEnabled;

  /// Início e fim do horário ativo, em minutos desde a meia-noite.
  final int activeStartMinute, activeEndMinute;

  /// Indica se o intervalo diminui quando o consumo está abaixo do esperado.
  final bool adaptive;

  /// Indica se a notificação toca som.
  final bool sound;

  /// Indica se as notificações são adiadas enquanto o usuário está em tela cheia ou apresentação.
  final bool focusMode;

  /// Indica se a notificação sorteia dicas de hidratação em vez da mensagem fixa.
  final bool randomTips;

  /// Indica se o atalho global Ctrl+Alt+W registra um copo.
  final bool hotkey;

  /// Intervalo base como [Duration].
  Duration get interval => Duration(minutes: intervalMinutes);

  /// Meta sugerida (ml) para [weightKg] e [activity]: 35 ml/kg mais o extra da atividade, arredondada para 50 ml.
  static int suggestedGoal(int weightKg, ActivityLevel activity) => ((weightKg * 35 + activity.extraMl) / 50).round() * 50;

  /// Indica se [now] está dentro do horário ativo. Sempre `true` quando o horário ativo está desligado.
  bool isActiveAt(DateTime now) {
    if (!activeHoursEnabled || activeStartMinute == activeEndMinute) return true;
    final minute = now.hour * 60 + now.minute;
    if (activeStartMinute < activeEndMinute) return minute >= activeStartMinute && minute < activeEndMinute;
    return minute >= activeStartMinute || minute < activeEndMinute;
  }

  /// Consumo esperado (ml) em [now], proporcional ao trecho já decorrido da janela ativa.
  int expectedIntakeAt(DateTime now) {
    final start = activeStartMinute, end = activeEndMinute > activeStartMinute ? activeEndMinute : activeEndMinute + 1440;
    var minute = now.hour * 60 + now.minute;
    if (minute < start && end > 1440) minute += 1440;
    final fraction = ((minute - start) / (end - start)).clamp(0.0, 1.0);
    return (goalMl * fraction).round();
  }

  /// Intervalo efetivo: com [adaptive] ligado e consumo abaixo de 80% do esperado, reduz para 2/3 (mínimo 5 min).
  Duration effectiveInterval(DateTime now, int consumedMl) {
    if (!adaptive || consumedMl >= expectedIntakeAt(now) * .8) return interval;
    final minutes = math.max(math.min(5, intervalMinutes), (intervalMinutes * 2 / 3).round());
    return Duration(minutes: minutes);
  }

  /// Cria uma cópia com os campos informados alterados. Use [clearLang] para voltar ao idioma do sistema.
  ReminderSettings copyWith({
    int? intervalMinutes,
    String? customMessage,
    AppLang? lang,
    bool clearLang = false,
    AppThemeMode? themeMode,
    int? goalMl,
    int? glassMl,
    int? weightKg,
    ActivityLevel? activity,
    bool? activeHoursEnabled,
    int? activeStartMinute,
    int? activeEndMinute,
    bool? adaptive,
    bool? sound,
    bool? focusMode,
    bool? randomTips,
    bool? hotkey,
  }) => .new(
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    customMessage: customMessage ?? this.customMessage,
    lang: clearLang ? null : lang ?? this.lang,
    themeMode: themeMode ?? this.themeMode,
    goalMl: goalMl ?? this.goalMl,
    glassMl: glassMl ?? this.glassMl,
    weightKg: weightKg ?? this.weightKg,
    activity: activity ?? this.activity,
    activeHoursEnabled: activeHoursEnabled ?? this.activeHoursEnabled,
    activeStartMinute: activeStartMinute ?? this.activeStartMinute,
    activeEndMinute: activeEndMinute ?? this.activeEndMinute,
    adaptive: adaptive ?? this.adaptive,
    sound: sound ?? this.sound,
    focusMode: focusMode ?? this.focusMode,
    randomTips: randomTips ?? this.randomTips,
    hotkey: hotkey ?? this.hotkey,
  );

  @override
  List<Object?> get props => [
    intervalMinutes, customMessage, lang, themeMode, goalMl, glassMl, weightKg, activity, activeHoursEnabled,
    activeStartMinute, activeEndMinute, adaptive, sound, focusMode, randomTips, hotkey,
  ];
}
