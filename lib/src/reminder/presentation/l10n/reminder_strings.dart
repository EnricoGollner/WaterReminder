import '../../domain/entities/app_enums.dart';
import '../../domain/repositories/inative_repository.dart';

part 'reminder_strings_data.dart';

/// Textos traduzidos da interface, notificações e menu da bandeja.
///
/// Modelos com `{0}`, `{1}` são preenchidos por [format].
class ReminderStrings {
  const ReminderStrings({
    required this.subtitle,
    required this.tabToday,
    required this.tabHistory,
    required this.tabSettings,
    required this.untilNext,
    required this.paused,
    required this.outsideActive,
    required this.pause,
    required this.resume,
    required this.drink,
    required this.snooze,
    required this.undo,
    required this.goalProgress,
    required this.goalReached,
    required this.glassesToday,
    required this.last7,
    required this.last30,
    required this.streak,
    required this.average,
    required this.daysOnGoal,
    required this.interval,
    required this.customMinutes,
    required this.set,
    required this.adaptive,
    required this.adaptiveHint,
    required this.messageTitle,
    required this.messageHint,
    required this.randomTips,
    required this.randomTipsHint,
    required this.test,
    required this.goalTitle,
    required this.goalLabel,
    required this.glassSize,
    required this.weight,
    required this.activity,
    required this.activityLow,
    required this.activityModerate,
    required this.activityHigh,
    required this.useSuggested,
    required this.activeHours,
    required this.activeHoursHint,
    required this.from,
    required this.to,
    required this.notifications,
    required this.sound,
    required this.focusMode,
    required this.focusModeHint,
    required this.system,
    required this.autostart,
    required this.autostartHint,
    required this.hotkey,
    required this.hotkeyHint,
    required this.appearance,
    required this.language,
    required this.systemLanguage,
    required this.theme,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.noticeReadError,
    required this.noticeSaveError,
    required this.noticeNotifyError,
    required this.noticeLogged,
    required this.noticeRange,
    required this.noticeUpdated,
    required this.noticeAutostartError,
    required this.noticeHotkeyError,
    required this.noticeSnoozed,
    required this.noticeUndone,
    required this.trayOpen,
    required this.trayDrink,
    required this.traySnooze,
    required this.trayPause,
    required this.trayResume,
    required this.trayQuit,
    required this.toastDrank,
    required this.toastSnooze,
    required this.tooltip,
    required this.tooltipPaused,
    required this.defaultMessage,
    required this.tips,
  });

  final String subtitle, tabToday, tabHistory, tabSettings, untilNext, paused, outsideActive, pause, resume, drink, snooze, undo;
  final String goalProgress, goalReached, glassesToday, last7, last30, streak, average, daysOnGoal;
  final String interval, customMinutes, set, adaptive, adaptiveHint, messageTitle, messageHint, randomTips, randomTipsHint, test;
  final String goalTitle, goalLabel, glassSize, weight, activity, activityLow, activityModerate, activityHigh, useSuggested;
  final String activeHours, activeHoursHint, from, to, notifications, sound, focusMode, focusModeHint;
  final String system, autostart, autostartHint, hotkey, hotkeyHint, appearance, language, systemLanguage, theme, themeSystem, themeLight, themeDark;
  final String noticeReadError, noticeSaveError, noticeNotifyError, noticeLogged, noticeRange, noticeUpdated, noticeAutostartError, noticeHotkeyError, noticeSnoozed, noticeUndone;
  final String trayOpen, trayDrink, traySnooze, trayPause, trayResume, trayQuit, toastDrank, toastSnooze, tooltip, tooltipPaused;

  /// Mensagem padrão da notificação.
  final String defaultMessage;

  /// Dicas sorteadas quando as dicas aleatórias estão ligadas.
  final List<String> tips;

  /// Textos do idioma [lang].
  static ReminderStrings of(AppLang lang) => switch (lang) {
    .pt => _pt,
    .en => _en,
    .es => _es,
  };

  /// Preenche os marcadores `{0}`, `{1}`… de [template] com [args].
  static String format(String template, List<Object> args) {
    var result = template;
    for (var i = 0; i < args.length; i++) {
      result = result.replaceAll('{$i}', '${args[i]}');
    }
    return result;
  }

  /// Nome traduzido do nível de atividade.
  String activityName(ActivityLevel level) => switch (level) {
    .low => activityLow,
    .moderate => activityModerate,
    .high => activityHigh,
  };

  /// Nome traduzido do tema.
  String themeName(AppThemeMode mode) => switch (mode) {
    .system => themeSystem,
    .light => themeLight,
    .dark => themeDark,
  };

  /// Textos enviados ao runner nativo.
  NativeLabels get nativeLabels => (open: trayOpen, drink: trayDrink, snooze: traySnooze, pause: trayPause, resume: trayResume, quit: trayQuit, drankAction: toastDrank, snoozeAction: toastSnooze);
}
