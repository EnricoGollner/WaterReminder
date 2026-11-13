import 'package:flutter/material.dart';

import '../../../../core/theme/ui_helpers/ui_text.dart';

/// Cartão arredondado usado para agrupar conteúdo.
class BoxPanel extends StatelessWidget {
  const BoxPanel({super.key, required this.child, this.padding = const .all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(20), border: Border.all(color: scheme.primary.withValues(alpha: .12))),
      child: child,
    );
  }
}

/// Seção de configurações com título e conteúdo.
class BoxSection extends StatelessWidget {
  const BoxSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .only(bottom: 18),
    child: Column(crossAxisAlignment: .start, children: [UIText.sectionTitle(title), const SizedBox(height: 10), ...children]),
  );
}

/// Linha com interruptor, título e descrição.
class BoxSwitchTile extends StatelessWidget {
  const BoxSwitchTile({super.key, required this.title, required this.value, required this.onChanged, this.subtitle});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: .zero,
    dense: true,
    title: UIText.body(title),
    subtitle: subtitle == null ? null : UIText.small(subtitle!),
    value: value,
    onChanged: onChanged,
  );
}
