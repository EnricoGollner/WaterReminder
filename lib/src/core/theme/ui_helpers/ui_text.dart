import 'package:flutter/material.dart';

import '../fonts.dart';

/// Tom de cor aplicado ao texto a partir do tema atual.
enum UITone { normal, primary, muted, error }

/// Texto padronizado do aplicativo. Cada construtor nomeado usa um estilo de `fonts.dart`.
class UIText extends StatelessWidget {
  const UIText(this.text, {super.key, this.tone = .normal, this.textAlign, this.maxLines}) : style = null;
  UIText.appTitle(this.text, {super.key, this.tone = .normal, this.textAlign, this.maxLines}) : style = appTitle;
  UIText.caption(this.text, {super.key, this.tone = .primary, this.textAlign, this.maxLines}) : style = caption;
  UIText.sectionTitle(this.text, {super.key, this.tone = .primary, this.textAlign, this.maxLines}) : style = sectionTitle;
  UIText.countdown(this.text, {super.key, this.tone = .normal, this.textAlign, this.maxLines}) : style = countdown;
  UIText.countdownLabel(this.text, {super.key, this.tone = .muted, this.textAlign, this.maxLines}) : style = countdownLabel;
  UIText.highlight(this.text, {super.key, this.tone = .primary, this.textAlign, this.maxLines}) : style = highlight;
  UIText.body(this.text, {super.key, this.tone = .normal, this.textAlign, this.maxLines}) : style = body;
  UIText.small(this.text, {super.key, this.tone = .muted, this.textAlign, this.maxLines}) : style = small;
  UIText.chartLabel(this.text, {super.key, this.tone = .muted, this.textAlign, this.maxLines}) : style = chartLabel;
  UIText.badge(this.text, {super.key, this.tone = .normal, this.textAlign, this.maxLines}) : style = badge;

  final String text;
  final TextStyle? style;
  final UITone tone;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      .normal => null,
      .primary => scheme.primary,
      .muted => scheme.onSurfaceVariant,
      .error => scheme.error,
    };
    return Text(text, style: (style ?? const TextStyle()).copyWith(color: color), textAlign: textAlign, maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis);
  }
}
