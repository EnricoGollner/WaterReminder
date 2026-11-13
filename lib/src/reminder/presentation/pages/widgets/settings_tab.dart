import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ui_helpers/ui_text.dart';
import '../../../../injector_container.dart';
import '../../../domain/entities/app_enums.dart';
import '../../../domain/entities/reminder_settings.dart';
import '../../l10n/reminder_strings.dart';
import 'box_panel.dart';

/// Aba "Ajustes": intervalo, mensagem, meta, horário ativo, notificações, sistema e aparência.
class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  static const _presets = [15, 30, 45, 60], _glasses = [200, 250, 300, 500];

  late final ReminderSettings _initial = ref.read(injectorContainer.reminderProvider).settings;
  late final _minutes = TextEditingController(text: '${_initial.intervalMinutes}');
  late final _message = TextEditingController(text: _initial.customMessage);
  late final _goal = TextEditingController(text: '${_initial.goalMl}');
  late final _glass = TextEditingController(text: '${_initial.glassMl}');
  late final _weight = TextEditingController(text: '${_initial.weightKg}');

  @override
  void dispose() {
    for (final c in [_minutes, _message, _goal, _glass, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  static int _parse(TextEditingController c) => int.tryParse(c.text) ?? 0;

  String _time(int minute) => '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

  Future<void> _pickTime(int current, ReminderSettings Function(ReminderSettings, int) apply) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60));
    if (picked == null || !mounted) return;
    ref.read(injectorContainer.reminderProvider.notifier).updateSettings((s) => apply(s, picked.hour * 60 + picked.minute), notice: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(injectorContainer.reminderProvider), controller = ref.read(injectorContainer.reminderProvider.notifier);
    final s = state.strings, settings = state.settings;
    final suggested = ReminderSettings.suggestedGoal(settings.weightKg, settings.activity);
    return ListView(
      padding: const .fromLTRB(22, 4, 22, 22),
      children: [
        BoxSection(
          title: s.interval,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in _presets)
                  ChoiceChip(
                    label: UIText('${v}m'),
                    selected: settings.intervalMinutes == v,
                    onSelected: (_) {
                      _minutes.text = '$v';
                      controller.setInterval(v);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _NumberRow(controller: _minutes, hint: s.customMinutes, action: s.set, onSubmit: () => controller.setInterval(_parse(_minutes))),
            BoxSwitchTile(title: s.adaptive, subtitle: s.adaptiveHint, value: settings.adaptive, onChanged: (v) => controller.updateSettings((x) => x.copyWith(adaptive: v))),
          ],
        ),
        BoxSection(
          title: s.messageTitle,
          children: [
            TextField(
              controller: _message,
              maxLines: 2,
              maxLength: 200,
              enabled: !settings.randomTips,
              decoration: InputDecoration(hintText: s.messageHint),
              onChanged: controller.setMessage,
            ),
            BoxSwitchTile(title: s.randomTips, subtitle: s.randomTipsHint, value: settings.randomTips, onChanged: (v) => controller.updateSettings((x) => x.copyWith(randomTips: v))),
            const SizedBox(height: 6),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: controller.testNotification, icon: const Icon(Icons.notifications_outlined), label: UIText(s.test))),
          ],
        ),
        BoxSection(
          title: s.goalTitle,
          children: [
            _NumberRow(controller: _goal, hint: s.goalLabel, action: s.set, onSubmit: () => controller.setGoal(_parse(_goal))),
            const SizedBox(height: 12),
            UIText.small(s.glassSize),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in _glasses)
                  ChoiceChip(
                    label: UIText('$v ml'),
                    selected: settings.glassMl == v,
                    onSelected: (_) {
                      _glass.text = '$v';
                      controller.setGlass(v);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _NumberRow(controller: _glass, hint: 'ml', action: s.set, onSubmit: () => controller.setGlass(_parse(_glass))),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _weight,
                    keyboardType: .number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: s.weight),
                    onSubmitted: (_) => controller.setWeight(_parse(_weight)),
                    onChanged: (v) {
                      final kg = int.tryParse(v);
                      if (kg != null && kg >= 20 && kg <= 400) controller.setWeight(kg);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SegmentedButton<ActivityLevel>(
                    showSelectedIcon: false,
                    segments: [for (final a in ActivityLevel.values) ButtonSegment(value: a, label: UIText(s.activityName(a), maxLines: 1))],
                    selected: {settings.activity},
                    onSelectionChanged: (v) => controller.updateSettings((x) => x.copyWith(activity: v.first)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _goal.text = '$suggested';
                controller.useSuggestedGoal();
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: UIText(ReminderStrings.format(s.useSuggested, [suggested])),
            ),
          ],
        ),
        BoxSection(
          title: s.activeHours.toUpperCase(),
          children: [
            BoxSwitchTile(title: s.activeHours, subtitle: s.activeHoursHint, value: settings.activeHoursEnabled, onChanged: (v) => controller.updateSettings((x) => x.copyWith(activeHoursEnabled: v))),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: settings.activeHoursEnabled ? () => _pickTime(settings.activeStartMinute, (x, m) => x.copyWith(activeStartMinute: m)) : null,
                    child: UIText('${s.from} ${_time(settings.activeStartMinute)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: settings.activeHoursEnabled ? () => _pickTime(settings.activeEndMinute, (x, m) => x.copyWith(activeEndMinute: m)) : null,
                    child: UIText('${s.to} ${_time(settings.activeEndMinute)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
        BoxSection(
          title: s.notifications,
          children: [
            BoxSwitchTile(title: s.sound, value: settings.sound, onChanged: (v) => controller.updateSettings((x) => x.copyWith(sound: v))),
            BoxSwitchTile(title: s.focusMode, subtitle: s.focusModeHint, value: settings.focusMode, onChanged: (v) => controller.updateSettings((x) => x.copyWith(focusMode: v))),
          ],
        ),
        BoxSection(
          title: s.system,
          children: [
            BoxSwitchTile(title: s.autostart, subtitle: s.autostartHint, value: state.autostart, onChanged: controller.setAutostart),
            BoxSwitchTile(title: s.hotkey, subtitle: s.hotkeyHint, value: settings.hotkey, onChanged: controller.setHotkey),
          ],
        ),
        BoxSection(
          title: s.appearance,
          children: [
            UIText.small(s.language),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              key: const Key('language-selector'),
              showSelectedIcon: false,
              segments: [ButtonSegment(value: 'system', label: UIText(s.systemLanguage, maxLines: 1)), for (final l in AppLang.values) ButtonSegment(value: l.name, label: UIText(l.code), tooltip: l.label)],
              selected: {settings.lang?.name ?? 'system'},
              onSelectionChanged: (v) => controller.setLang(AppLang.tryParse(v.first)),
            ),
            const SizedBox(height: 12),
            UIText.small(s.theme),
            const SizedBox(height: 6),
            SegmentedButton<AppThemeMode>(
              showSelectedIcon: false,
              segments: [for (final m in AppThemeMode.values) ButtonSegment(value: m, label: UIText(s.themeName(m), maxLines: 1))],
              selected: {settings.themeMode},
              onSelectionChanged: (v) => controller.updateSettings((x) => x.copyWith(themeMode: v.first)),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.controller, required this.hint, required this.action, required this.onSubmit});

  final TextEditingController controller;
  final String hint, action;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: controller,
          keyboardType: .number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (_) => onSubmit(),
        ),
      ),
      const SizedBox(width: 9),
      FilledButton(onPressed: onSubmit, child: UIText(action)),
    ],
  );
}
