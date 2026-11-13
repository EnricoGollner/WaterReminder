import 'package:equatable/equatable.dart';

import 'hydration_history.dart';
import 'reminder_settings.dart';

/// Estado persistido do aplicativo: preferências, temporizador e histórico.
class ReminderData extends Equatable {
  const ReminderData({this.settings = const ReminderSettings(), this.paused = false, this.deadline, this.pausedRemaining, this.history = const HydrationHistory()});

  /// Preferências do usuário.
  final ReminderSettings settings;

  /// Indica se os lembretes estão pausados.
  final bool paused;

  /// Momento do próximo lembrete; `null` quando nunca foi agendado.
  final DateTime? deadline;

  /// Tempo restante congelado durante a pausa.
  final Duration? pausedRemaining;

  /// Histórico de consumo.
  final HydrationHistory history;

  @override
  List<Object?> get props => [settings, paused, deadline, pausedRemaining, history];
}
