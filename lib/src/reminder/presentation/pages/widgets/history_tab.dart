import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/ui_helpers/ui_text.dart';
import '../../../../injector_container.dart';
import '../../l10n/reminder_strings.dart';
import 'box_history_chart.dart';
import 'box_panel.dart';

/// Aba "Histórico": gráfico de 7/30 dias, sequência e média.
class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(injectorContainer.reminderProvider), s = state.strings, goal = state.settings.goalMl;
    final days = state.history.lastDays(state.now, _days), onGoal = days.where((d) => d.ml >= goal).length;
    return ListView(
      padding: const .fromLTRB(22, 4, 22, 22),
      children: [
        SegmentedButton<int>(
          segments: [ButtonSegment(value: 7, label: UIText(s.last7)), ButtonSegment(value: 30, label: UIText(s.last30))],
          selected: {_days},
          onSelectionChanged: (v) => setState(() => _days = v.first),
        ),
        const SizedBox(height: 14),
        BoxPanel(child: BoxHistoryChart(days: days, goalMl: goal)),
        const SizedBox(height: 14),
        _Stat(icon: Icons.local_fire_department_rounded, color: AppColors.success, text: ReminderStrings.format(s.streak, [state.history.streak(state.now, goal)])),
        _Stat(icon: Icons.insights_rounded, text: ReminderStrings.format(s.average, [state.history.average(state.now, _days)])),
        _Stat(icon: Icons.flag_rounded, text: ReminderStrings.format(s.daysOnGoal, [onGoal, _days])),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .only(bottom: 10),
    child: BoxPanel(
      padding: const .symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 20), const SizedBox(width: 12), Expanded(child: UIText.body(text))]),
    ),
  );
}
