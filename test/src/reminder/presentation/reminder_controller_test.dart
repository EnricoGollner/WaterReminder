import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_reminder/src/injector_container.dart';
import 'package:water_reminder/src/reminder/domain/entities/app_enums.dart';
import 'package:water_reminder/src/reminder/domain/entities/reminder_data.dart';
import 'package:water_reminder/src/reminder/domain/entities/reminder_settings.dart';
import 'package:water_reminder/src/reminder/presentation/controllers/reminder_controller.dart';
import 'package:water_reminder/src/reminder/presentation/controllers/states/reminder_state.dart';
import 'package:water_reminder/src/reminder/presentation/l10n/reminder_strings.dart';

import '../fakes.dart';

void main() {
  late FakeClock clock;
  late FakeSettingsRepository settings;
  late FakeNativeRepository native;
  late ProviderContainer container;

  ReminderController controller() => container.read(injectorContainer.reminderProvider.notifier);
  ReminderState state() => container.read(injectorContainer.reminderProvider);

  Future<void> start({ReminderData? data, String locale = 'en-US'}) async {
    settings = FakeSettingsRepository(data: data);
    container = ProviderContainer.test(
      overrides: [
        injectorContainer.clockProvider.overrideWithValue(clock.call),
        injectorContainer.randomProvider.overrideWithValue(math.Random(1)),
        injectorContainer.systemLocaleProvider.overrideWithValue(locale),
        injectorContainer.settingsRepository.overrideWithValue(settings),
        injectorContainer.nativeRepository.overrideWithValue(native),
      ],
    );
    await controller().load();
  }

  setUp(() {
    clock = FakeClock(DateTime(2026, 3, 10, 12));
    native = FakeNativeRepository();
  });

  group('ReminderController.load', () {
    test('sem dados salvos carrega padrões, idioma do sistema e agenda em 30 minutos', () async {
      await start(locale: 'pt-BR');
      expect(state().status, LoadStatus.loaded);
      expect(state().lang, AppLang.pt);
      expect(state().deadline, clock.now.add(const Duration(minutes: 30)));
      expect(native.labels?.open, 'Abrir WaterReminder');
    });

    test('reagenda quando o prazo salvo já passou', () async {
      await start(data: ReminderData(deadline: clock.now.subtract(const Duration(hours: 2))));
      expect(state().deadline, clock.now.add(const Duration(minutes: 30)));
    });

    test('avisa quando o atalho global já está em uso', () async {
      native.hotkeyAvailable = false;
      await start();
      expect(state().notice?.text, ReminderStrings.of(AppLang.en).noticeHotkeyError);
      expect(state().notice?.error, isTrue);
    });
  });

  group('ReminderController.tick', () {
    test('mostra a notificação no prazo e agenda o próximo ciclo', () async {
      await start();
      clock.advance(const Duration(minutes: 30));
      await controller().tick();
      expect(native.notifications, [ReminderStrings.of(AppLang.en).defaultMessage]);
      expect(state().deadline, clock.now.add(const Duration(minutes: 30)));
    });

    test('não notifica antes do prazo', () async {
      await start();
      clock.advance(const Duration(minutes: 29));
      await controller().tick();
      expect(native.notifications, isEmpty);
    });

    test('pula o lembrete fora do horário ativo', () async {
      clock = FakeClock(DateTime(2026, 3, 10, 23));
      await start(data: const ReminderData(settings: ReminderSettings(activeHoursEnabled: true)));
      clock.advance(const Duration(minutes: 30));
      await controller().tick();
      expect(native.notifications, isEmpty);
      expect(state().deadline, clock.now.add(const Duration(minutes: 30)));
    });

    test('modo foco adia por 1 minuto enquanto o usuário está ocupado', () async {
      await start();
      native.busy = true;
      clock.advance(const Duration(minutes: 30));
      await controller().tick();
      expect(native.notifications, isEmpty);
      expect(state().deadline, clock.now.add(ReminderController.focusRetry));
    });

    test('usa a mensagem personalizada e dicas quando configuradas', () async {
      await start(data: const ReminderData(settings: ReminderSettings(customMessage: 'Beba!')));
      expect(controller().notificationMessage, 'Beba!');
      controller().updateSettings((s) => s.copyWith(randomTips: true));
      expect(ReminderStrings.of(AppLang.en).tips, contains(controller().notificationMessage));
    });

    test('avisa quando o Windows não mostra a notificação', () async {
      await start();
      native.notificationFails = true;
      await controller().testNotification();
      expect(state().notice?.text, ReminderStrings.of(AppLang.en).noticeNotifyError);
    });
  });

  group('ReminderController ações', () {
    test('drink soma o copo, reinicia o temporizador e salva', () async {
      await start();
      clock.advance(const Duration(minutes: 10));
      controller().drink();
      expect(state().todayMl, 250);
      expect(state().deadline, clock.now.add(const Duration(minutes: 30)));
      expect(settings.data?.history.totalOn(clock.now), 250);
    });

    test('undoDrink remove o último copo sem ficar negativo', () async {
      await start();
      controller()
        ..drink()
        ..undoDrink()
        ..undoDrink();
      expect(state().todayMl, 0);
    });

    test('togglePause congela e retoma o tempo restante', () async {
      await start();
      clock.advance(const Duration(minutes: 10));
      controller().togglePause();
      expect(state().paused, isTrue);
      expect(state().remaining, const Duration(minutes: 20));
      clock.advance(const Duration(hours: 1));
      await controller().tick();
      expect(native.notifications, isEmpty);
      controller().togglePause();
      expect(state().deadline, clock.now.add(const Duration(minutes: 20)));
      await Future<void>.delayed(Duration.zero);
      expect(native.trayPaused, isFalse);
    });

    test('snooze adia 5 minutos e retoma se pausado', () async {
      await start();
      controller()
        ..togglePause()
        ..snooze();
      expect(state().paused, isFalse);
      expect(state().deadline, clock.now.add(ReminderController.snoozeDuration));
    });

    test('setInterval rejeita valores fora do limite', () async {
      await start();
      expect(controller().setInterval(0), isFalse);
      expect(state().notice?.error, isTrue);
      expect(controller().setInterval(45), isTrue);
      expect(state().settings.intervalMinutes, 45);
      expect(state().deadline, clock.now.add(const Duration(minutes: 45)));
    });

    test('useSuggestedGoal aplica a meta calculada pelo peso', () async {
      await start();
      controller()
        ..setWeight(80)
        ..useSuggestedGoal();
      expect(state().settings.goalMl, 3150);
    });

    test('setLang troca os textos nativos', () async {
      await start();
      controller().setLang(AppLang.es);
      await Future<void>.delayed(Duration.zero);
      expect(native.labels?.quit, 'Salir');
      expect(settings.data?.settings.lang, AppLang.es);
    });

    test('ações da bandeja e do atalho chegam ao controller', () async {
      await start();
      native.actionsController.add(NativeAction.drinkWater);
      await Future<void>.delayed(Duration.zero);
      expect(state().todayMl, 250);
    });

    test('setAutostart liga a inicialização com o Windows', () async {
      await start();
      await controller().setAutostart(true);
      expect(state().autostart, isTrue);
    });
  });
}
