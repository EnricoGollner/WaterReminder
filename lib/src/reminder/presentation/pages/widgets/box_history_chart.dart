import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/ui_helpers/ui_text.dart';
import '../../../domain/entities/hydration_history.dart';

/// Gráfico de barras do consumo diário com a linha da meta.
class BoxHistoryChart extends StatelessWidget {
  const BoxHistoryChart({super.key, required this.days, required this.goalMl, this.height = 180});

  final List<DailyIntake> days;
  final int goalMl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxMl = math.max(goalMl, days.fold<int>(0, (m, d) => math.max(m, d.ml))) * 1.15;
    final labelEvery = days.length <= 7 ? 1 : 5;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(size: Size.infinite, painter: _BarsPainter(days: days, goalMl: goalMl, maxMl: maxMl, bar: scheme.primary, reached: AppColors.success, track: scheme.surfaceContainerHighest)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(child: UIText.chartLabel(i % labelEvery == 0 || i == days.length - 1 ? '${days[i].day.day}/${days[i].day.month}' : '', textAlign: .center, maxLines: 1)),
          ],
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({required this.days, required this.goalMl, required this.maxMl, required this.bar, required this.reached, required this.track});

  final List<DailyIntake> days;
  final int goalMl;
  final double maxMl;
  final Color bar, reached, track;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty || maxMl <= 0) return;
    final slot = size.width / days.length, width = math.max(2.0, slot * .6);
    for (var i = 0; i < days.length; i++) {
      final ml = days[i].ml, h = size.height * ml / maxMl, x = slot * i + (slot - width) / 2;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, width, size.height), const Radius.circular(4)), Paint()..color = track.withValues(alpha: .35));
      if (ml > 0) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, width, h), const Radius.circular(4)), Paint()..color = ml >= goalMl ? reached : bar);
    }
    final y = size.height - size.height * goalMl / maxMl, dash = Paint()..color = reached..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), dash);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.days != days || old.goalMl != goalMl || old.bar != bar;
}
