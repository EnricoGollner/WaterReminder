import 'dart:math' as math;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminder/data/repositories/native_repository.dart';
import 'reminder/data/repositories/settings_repository.dart';
import 'reminder/domain/repositories/inative_repository.dart';
import 'reminder/domain/repositories/isettings_repository.dart';
import 'reminder/presentation/controllers/reminder_controller.dart';
import 'reminder/presentation/controllers/states/reminder_state.dart';

/// Instância global dos providers da aplicação.
final injectorContainer = InjectorContainer();

/// Registro dos providers. Todos são permanentes: o app tem uma única tela que vive durante todo o processo.
class InjectorContainer {
  /// Relógio usado pelo temporizador; substituível nos testes.
  final Provider<DateTime Function()> clockProvider = .new((ref) => DateTime.now, name: 'Clock Provider');

  /// Gerador aleatório das dicas; substituível nos testes.
  final Provider<math.Random> randomProvider = .new((ref) => math.Random(), name: 'Random Provider');

  /// Idioma do sistema operacional (ex.: `pt-BR`).
  final Provider<String> systemLocaleProvider = .new((ref) => PlatformDispatcher.instance.locale.toLanguageTag(), name: 'System Locale Provider');

  final Provider<ISettingsRepository> settingsRepository = .new((ref) => SettingsRepository.appData(), name: 'Settings Repository');

  final Provider<INativeRepository> nativeRepository = .new((ref) {
    final repository = NativeRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }, name: 'Native Repository');

  final NotifierProvider<ReminderController, ReminderState> reminderProvider = .new(ReminderController.new, name: 'Reminder Notifier Provider');
}
