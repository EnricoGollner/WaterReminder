import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/theme/style.dart';
import 'src/injector_container.dart';
import 'src/reminder/domain/entities/app_enums.dart';
import 'src/reminder/presentation/pages/reminder_page.dart';

void main() => runApp(const ProviderScope(child: WaterReminderApp()));

/// Raiz do aplicativo: aplica o tema escolhido e abre a tela de lembretes.
class WaterReminderApp extends ConsumerWidget {
  const WaterReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(injectorContainer.reminderProvider.select((s) => s.settings.themeMode));
    return MaterialApp(
      title: 'WaterReminder',
      debugShowCheckedModeBanner: false,
      theme: Style.light,
      darkTheme: Style.dark,
      themeMode: switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      home: const ReminderPage(),
    );
  }
}
