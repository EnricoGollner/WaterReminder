import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/ui_helpers/ui_text.dart';
import '../../../../injector_container.dart';
import '../../l10n/reminder_strings.dart';
import 'box_panel.dart';
import 'box_wave_progress.dart';

/// Aba "Hoje": contagem regressiva, progresso da meta e ações rápidas.
class TodayTab extends ConsumerWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(injectorContainer.reminderProvider), controller = ref.read(injectorContainer.reminderProvider.notifier);
    final s = state.strings, settings = state.settings;
    final label = state.paused ? s.paused : (state.outsideActive ? s.outsideActive : s.untilNext);
    return ListView(
      padding: const .fromLTRB(22, 4, 22, 22),
      children: [
        BoxPanel(
          padding: const .symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              BoxWaveProgress(
                level: state.goalProgress,
                ring: state.cycleProgress,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Icon(state.paused ? Icons.pause_rounded : Icons.water_drop_rounded, color: Theme.of(context).colorScheme.primary, size: 26),
                    const SizedBox(height: 4),
                    UIText.countdown(state.remainingLabel),
                    Padding(padding: const .symmetric(horizontal: 30), child: UIText.countdownLabel(label, textAlign: .center, maxLines: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              UIText.highlight(ReminderStrings.format(s.goalProgress, [state.todayMl, settings.goalMl])),
              const SizedBox(height: 2),
              UIText.small(ReminderStrings.format(s.glassesToday, [settings.glassMl <= 0 ? 0 : (state.todayMl / settings.glassMl).round()])),
              if (state.goalReached) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: .center,
                  children: [const Icon(Icons.emoji_events_rounded, color: AppColors.success, size: 18), const SizedBox(width: 6), Flexible(child: UIText.small(s.goalReached, tone: .normal))],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _PrimaryAction(icon: state.paused ? Icons.play_arrow_rounded : Icons.pause_rounded, label: state.paused ? s.resume : s.pause, onPressed: controller.togglePause)),
            const SizedBox(width: 10),
            Expanded(child: _PrimaryAction(icon: Icons.local_drink_rounded, label: ReminderStrings.format(s.drink, [settings.glassMl]), onPressed: controller.drink)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(onPressed: controller.snooze, icon: const Icon(Icons.snooze_rounded, size: 18), label: UIText(s.snooze, maxLines: 1))),
            const SizedBox(width: 10),
            Expanded(child: TextButton.icon(onPressed: state.todayMl > 0 ? controller.undoDrink : null, icon: const Icon(Icons.undo_rounded, size: 18), label: UIText(s.undo, maxLines: 1))),
          ],
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(padding: const .symmetric(vertical: 15)),
    icon: Icon(icon, size: 19),
    label: UIText(label, maxLines: 1),
  );
}
