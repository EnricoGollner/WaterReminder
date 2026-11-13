import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/ui_helpers/ui_text.dart';
import '../../../injector_container.dart';
import '../controllers/states/reminder_state.dart';
import 'widgets/reminder_ui.dart';

/// Tela principal com as abas Hoje, Histórico e Ajustes.
class ReminderPage extends ConsumerStatefulWidget {
  const ReminderPage({super.key});

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(injectorContainer.reminderProvider.notifier).load());
  }

  void _snack(String text, {Color? color}) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: UIText.body(text), backgroundColor: color, duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(injectorContainer.reminderProvider, (ReminderState? previous, ReminderState next) {
      if (previous == null || previous.status != .loaded) return;
      if (next.notice != null && next.notice != previous.notice) _snack(next.notice!.text, color: next.notice!.error ? AppColors.error : null);
      if (!previous.goalReached && next.goalReached && previous.history != next.history) _snack(next.strings.goalReached, color: AppColors.success);
    });
    final state = ref.watch(injectorContainer.reminderProvider), s = state.strings;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const .fromLTRB(22, 18, 22, 14),
              child: Row(
                children: [
                  Container(
                    padding: const .all(8),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
                    child: Image.asset('assets/app_icon.png', width: 30, height: 30),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: .start, children: [UIText.appTitle('WaterReminder'), UIText.caption(s.subtitle)]),
                ],
              ),
            ),
            Expanded(
              child: state.status != .loaded
                  ? const Center(child: CircularProgressIndicator())
                  : switch (_tab) {
                      0 => const TodayTab(),
                      1 => const HistoryTab(),
                      _ => const SettingsTab(),
                    },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.water_drop_outlined), selectedIcon: const Icon(Icons.water_drop_rounded), label: s.tabToday),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart_rounded), label: s.tabHistory),
          NavigationDestination(icon: const Icon(Icons.tune_outlined), selectedIcon: const Icon(Icons.tune_rounded), label: s.tabSettings),
        ],
      ),
    );
  }
}
