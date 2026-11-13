import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_reminder/main.dart';
import 'package:water_reminder/src/injector_container.dart';

import '../fakes.dart';

void main() {
  late FakeSettingsRepository settings;
  late FakeNativeRepository native;

  Widget app() => ProviderScope(
    overrides: [
      injectorContainer.clockProvider.overrideWithValue(FakeClock(DateTime(2026, 3, 10, 12)).call),
      injectorContainer.systemLocaleProvider.overrideWithValue('en-US'),
      injectorContainer.settingsRepository.overrideWithValue(settings),
      injectorContainer.nativeRepository.overrideWithValue(native),
    ],
    child: const WaterReminderApp(),
  );

  setUp(() {
    settings = FakeSettingsRepository();
    native = FakeNativeRepository();
  });

  /// Desmonta a árvore para cancelar o temporizador do controller.
  Future<void> unmount(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  testWidgets('mostra a contagem e registra um copo ao tocar em "Drank"', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();
    expect(find.text('30:00'), findsOneWidget);
    expect(find.text('0 of 2000 ml'), findsOneWidget);

    await tester.tap(find.text('Drank +250 ml'));
    await tester.pump();
    expect(find.text('250 of 2000 ml'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('troca o idioma para português nos ajustes', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('language-selector')), 300, scrollable: find.byType(Scrollable).first);
    // Afasta o seletor da barra de navegação inferior antes de tocar.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pump();
    await tester.tap(find.text('PT'));
    await tester.pump();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(native.labels?.open, 'Abrir WaterReminder');
    await unmount(tester);
  });
}
