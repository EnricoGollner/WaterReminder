import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../injector_container.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/reminder_data.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/inative_repository.dart';
import '../l10n/reminder_strings.dart';
import 'states/reminder_state.dart';

/// Coordena o temporizador, o consumo, as preferências e a integração com o Windows.
class ReminderController extends Notifier<ReminderState> {
  /// Tempo do botão "Adiar".
  static const snoozeDuration = Duration(minutes: 5);

  /// Espera antes de tentar de novo quando o modo foco adia o lembrete.
  static const focusRetry = Duration(minutes: 1);

  Timer? _ticker;
  StreamSubscription<NativeAction>? _actions;
  bool _notifying = false;
  int _noticeId = 0;
  String _lastTooltip = '';

  INativeRepository get _native => ref.read(injectorContainer.nativeRepository);
  DateTime _clock() => ref.read(injectorContainer.clockProvider)();

  @override
  ReminderState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _actions?.cancel();
    });
    final now = _clock();
    const settings = ReminderSettings();
    return .new(now: now, deadline: now.add(settings.interval), cycle: settings.interval, systemLang: AppLang.fromLocale(ref.read(injectorContainer.systemLocaleProvider)));
  }

  /// Carrega o estado salvo, sincroniza o Windows e inicia o temporizador. Executar uma única vez.
  Future<void> load() async {
    if (state.status != .initial) return;
    state = state.copyWith(status: .loading);
    final data = await ref.read(injectorContainer.settingsRepository).load();
    final autostart = await _native.getAutostart();
    if (!ref.mounted) return;
    final now = _clock(), saved = data ?? const ReminderData(), settings = saved.settings;
    final deadline = saved.deadline == null || saved.deadline!.isBefore(now) || saved.deadline!.isAfter(now.add(settings.interval)) ? now.add(settings.interval) : saved.deadline!;
    final remaining = saved.pausedRemaining == null || saved.pausedRemaining! > settings.interval ? null : saved.pausedRemaining;
    state = state.copyWith(status: .loaded, settings: settings, paused: saved.paused, deadline: deadline, cycle: settings.interval, pausedRemaining: remaining, history: saved.history, now: now, autostart: autostart);
    _actions = _native.actions.listen(_onNativeAction);
    await _syncNative();
    if (settings.hotkey && !await _native.setHotkey(true) && ref.mounted) _notice(state.strings.noticeHotkeyError, error: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// Avança o temporizador: dispara o lembrete quando o prazo vence, respeitando horário ativo e modo foco.
  Future<void> tick() async {
    if (state.status != .loaded) return;
    final now = _clock();
    state = state.copyWith(now: now);
    if (!state.paused && !now.isBefore(state.deadline) && !_notifying) await _onDeadline(now);
    _updateTray();
  }

  Future<void> _onDeadline(DateTime now) async {
    final settings = state.settings;
    if (!settings.isActiveAt(now)) return _schedule(now, settings.interval);
    _notifying = true;
    try {
      if (settings.focusMode && await _native.isUserBusy()) {
        if (ref.mounted) _schedule(now, focusRetry, keepCycle: true);
        return;
      }
      if (!ref.mounted) return;
      await _notify();
      if (ref.mounted) _schedule(now, settings.effectiveInterval(now, state.todayMl));
    } finally {
      _notifying = false;
    }
  }

  void _schedule(DateTime now, Duration interval, {bool keepCycle = false}) {
    state = state.copyWith(deadline: now.add(interval), cycle: keepCycle ? null : interval, clearPausedRemaining: true);
    _save();
  }

  /// Mensagem da próxima notificação: dica sorteada, mensagem personalizada ou padrão do idioma.
  String get notificationMessage {
    final s = state.strings, custom = state.settings.customMessage.trim();
    if (state.settings.randomTips) return s.tips[ref.read(injectorContainer.randomProvider).nextInt(s.tips.length)];
    return custom.isEmpty ? s.defaultMessage : custom;
  }

  Future<bool> _notify() async {
    final ok = await _native.showNotification(title: 'WaterReminder', message: notificationMessage, sound: state.settings.sound);
    if (!ok && ref.mounted) _notice(state.strings.noticeNotifyError, error: true);
    return ok;
  }

  /// Exibe a notificação imediatamente, sem alterar o temporizador.
  Future<void> testNotification() => _notify();

  /// Registra um copo e reinicia o temporizador.
  void drink() {
    final now = _clock();
    final history = state.history.add(now, state.settings.glassMl);
    final interval = state.settings.effectiveInterval(now, history.totalOn(now));
    state = state.copyWith(now: now, history: history, deadline: now.add(interval), cycle: interval, pausedRemaining: state.paused ? interval : null, clearPausedRemaining: !state.paused);
    _notice(state.strings.noticeLogged);
    _save();
    _updateTray(force: true);
  }

  /// Remove o último copo registrado hoje.
  void undoDrink() {
    if (state.todayMl <= 0) return;
    final now = _clock();
    state = state.copyWith(now: now, history: state.history.add(now, -state.settings.glassMl));
    _notice(state.strings.noticeUndone);
    _save();
    _updateTray(force: true);
  }

  /// Adia o próximo lembrete por [snoozeDuration], retomando se estiver pausado.
  void snooze() {
    final now = _clock();
    state = state.copyWith(now: now, paused: false, deadline: now.add(snoozeDuration), cycle: snoozeDuration, clearPausedRemaining: true);
    _notice(state.strings.noticeSnoozed);
    _syncNative();
    _save();
  }

  /// Pausa ou retoma os lembretes preservando o tempo restante.
  void togglePause() {
    final now = _clock();
    state = state.paused
        ? state.copyWith(now: now, paused: false, deadline: now.add(state.remaining), clearPausedRemaining: true)
        : state.copyWith(now: now, paused: true, pausedRemaining: state.copyWith(now: now).remaining);
    _syncNative();
    _save();
  }

  /// Altera o intervalo base e reinicia o ciclo. Retorna `false` quando [minutes] está fora do limite.
  bool setInterval(int minutes) {
    if (minutes < ReminderSettings.minInterval || minutes > ReminderSettings.maxInterval) {
      _notice(state.strings.noticeRange, error: true);
      return false;
    }
    final now = _clock(), interval = Duration(minutes: minutes);
    state = state.copyWith(now: now, settings: state.settings.copyWith(intervalMinutes: minutes), deadline: now.add(interval), cycle: interval, pausedRemaining: state.paused ? interval : null, clearPausedRemaining: !state.paused);
    _notice(state.strings.noticeUpdated);
    _save();
    return true;
  }

  /// Altera a meta diária (100 a 20000 ml). Retorna `false` quando inválida.
  bool setGoal(int ml) => _setBounded(ml, 100, 20000, (s) => s.copyWith(goalMl: ml));

  /// Altera o tamanho do copo (10 a 5000 ml). Retorna `false` quando inválido.
  bool setGlass(int ml) => _setBounded(ml, 10, 5000, (s) => s.copyWith(glassMl: ml));

  /// Altera o peso usado na meta sugerida (20 a 400 kg). Retorna `false` quando inválido.
  bool setWeight(int kg) => _setBounded(kg, 20, 400, (s) => s.copyWith(weightKg: kg), silent: true);

  bool _setBounded(int value, int min, int max, ReminderSettings Function(ReminderSettings) change, {bool silent = false}) {
    if (value < min || value > max) {
      _notice(state.strings.noticeRange, error: true);
      return false;
    }
    updateSettings(change, notice: !silent);
    return true;
  }

  /// Aplica a meta sugerida pelo peso e atividade.
  void useSuggestedGoal() => setGoal(ReminderSettings.suggestedGoal(state.settings.weightKg, state.settings.activity));

  /// Altera a mensagem personalizada (vazia volta à padrão).
  void setMessage(String message) => updateSettings((s) => s.copyWith(customMessage: message.trim()));

  /// Altera o idioma; `null` volta a seguir o idioma do sistema.
  void setLang(AppLang? lang) {
    updateSettings((s) => s.copyWith(lang: lang, clearLang: lang == null));
    _syncNative();
  }

  /// Aplica [change] às preferências e salva.
  void updateSettings(ReminderSettings Function(ReminderSettings) change, {bool notice = false}) {
    state = state.copyWith(settings: change(state.settings));
    if (notice) _notice(state.strings.noticeUpdated);
    _save();
    _updateTray(force: true);
  }

  /// Liga ou desliga o atalho global Ctrl+Alt+W.
  Future<void> setHotkey(bool enabled) async {
    final ok = await _native.setHotkey(enabled);
    if (!ref.mounted) return;
    if (enabled && !ok) return _notice(state.strings.noticeHotkeyError, error: true);
    updateSettings((s) => s.copyWith(hotkey: enabled));
  }

  /// Liga ou desliga a inicialização com o Windows.
  Future<void> setAutostart(bool enabled) async {
    final ok = await _native.setAutostart(enabled);
    if (!ref.mounted) return;
    if (!ok) return _notice(state.strings.noticeAutostartError, error: true);
    state = state.copyWith(autostart: enabled);
  }

  void _onNativeAction(NativeAction action) => switch (action) {
    .drinkWater => drink(),
    .togglePause => togglePause(),
    .snooze => snooze(),
  };

  void _notice(String text, {bool error = false}) => state = state.copyWith(notice: Notice(++_noticeId, text, error: error));

  Future<void> _syncNative() async {
    await _native.configure(labels: state.strings.nativeLabels, paused: state.paused);
    if (ref.mounted) _updateTray(force: true);
  }

  void _updateTray({bool force = false}) {
    final s = state.strings, goal = state.settings.goalMl, today = state.todayMl;
    final minutes = (state.remaining.inSeconds / 60).ceil();
    final tooltip = state.paused ? ReminderStrings.format(s.tooltipPaused, [today, goal]) : ReminderStrings.format(s.tooltip, ['$minutes min', today, goal]);
    if (!force && tooltip == _lastTooltip) return;
    _lastTooltip = tooltip;
    _native.updateTray(tooltip: tooltip, paused: state.paused);
  }

  Future<void> _save() async {
    final ok = await ref.read(injectorContainer.settingsRepository).save(.new(settings: state.settings, paused: state.paused, deadline: state.deadline, pausedRemaining: state.pausedRemaining, history: state.history));
    if (!ok && ref.mounted) _notice(state.strings.noticeSaveError, error: true);
  }
}
