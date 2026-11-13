import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/hydration_history.dart';
import '../../../domain/entities/reminder_settings.dart';
import '../../l10n/reminder_strings.dart';

/// Etapas da carga inicial.
enum LoadStatus { initial, loading, loaded }

/// Aviso exibido na tela (snackbar). [id] diferencia avisos de mesmo texto.
class Notice extends Equatable {
  const Notice(this.id, this.text, {this.error = false});

  final int id;
  final String text;
  final bool error;

  @override
  List<Object?> get props => [id, text, error];
}

/// Estado da tela de lembretes.
class ReminderState extends Equatable {
  const ReminderState({
    required this.now,
    required this.deadline,
    required this.cycle,
    this.status = .initial,
    this.settings = const ReminderSettings(),
    this.systemLang = .en,
    this.paused = false,
    this.pausedRemaining,
    this.history = const HydrationHistory(),
    this.autostart = false,
    this.notice,
  });

  final LoadStatus status;
  final ReminderSettings settings;

  /// Idioma do Windows, usado enquanto o usuário não escolhe um idioma.
  final AppLang systemLang;
  final bool paused;

  /// Momento do próximo lembrete.
  final DateTime deadline;

  /// Duração do ciclo atual (base do anel de progresso).
  final Duration cycle;

  /// Tempo restante congelado durante a pausa.
  final Duration? pausedRemaining;
  final HydrationHistory history;

  /// Último instante processado pelo temporizador.
  final DateTime now;
  final bool autostart;
  final Notice? notice;

  /// Idioma em uso.
  AppLang get lang => settings.lang ?? systemLang;

  /// Textos do idioma em uso.
  ReminderStrings get strings => ReminderStrings.of(lang);

  /// Consumo de hoje, em ml.
  int get todayMl => history.totalOn(now);

  /// Indica se a meta de hoje foi atingida.
  bool get goalReached => todayMl >= settings.goalMl;

  /// Fração da meta diária atingida (0 a 1).
  double get goalProgress => settings.goalMl <= 0 ? 0 : (todayMl / settings.goalMl).clamp(0.0, 1.0);

  /// Indica se o momento atual está fora do horário ativo.
  bool get outsideActive => !settings.isActiveAt(now);

  /// Tempo até o próximo lembrete.
  Duration get remaining => paused ? (pausedRemaining ?? cycle) : Duration(milliseconds: math.max(0, deadline.difference(now).inMilliseconds));

  /// Fração do ciclo já decorrida (0 a 1).
  double get cycleProgress => cycle.inMilliseconds <= 0 ? 0 : (1 - remaining.inMilliseconds / cycle.inMilliseconds).clamp(0.0, 1.0);

  /// Tempo restante formatado como `mm:ss` ou `hh:mm:ss`.
  String get remainingLabel {
    final r = remaining;
    String two(int v) => v.toString().padLeft(2, '0');
    final mmss = '${two(r.inMinutes % 60)}:${two(r.inSeconds % 60)}';
    return r.inHours > 0 ? '${two(r.inHours)}:$mmss' : mmss;
  }

  ReminderState copyWith({
    LoadStatus? status,
    ReminderSettings? settings,
    AppLang? systemLang,
    bool? paused,
    DateTime? deadline,
    Duration? cycle,
    Duration? pausedRemaining,
    bool clearPausedRemaining = false,
    HydrationHistory? history,
    DateTime? now,
    bool? autostart,
    Notice? notice,
  }) => .new(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    systemLang: systemLang ?? this.systemLang,
    paused: paused ?? this.paused,
    deadline: deadline ?? this.deadline,
    cycle: cycle ?? this.cycle,
    pausedRemaining: clearPausedRemaining ? null : pausedRemaining ?? this.pausedRemaining,
    history: history ?? this.history,
    now: now ?? this.now,
    autostart: autostart ?? this.autostart,
    notice: notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, settings, systemLang, paused, deadline, cycle, pausedRemaining, history, now, autostart, notice];
}
