import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';

/// Círculo com água animada subindo conforme [level] (meta diária) e anel externo com [ring] (ciclo do lembrete).
class BoxWaveProgress extends StatefulWidget {
  const BoxWaveProgress({super.key, required this.level, required this.ring, required this.child, this.size = 200});

  /// Nível da água (0 a 1).
  final double level;

  /// Progresso do anel externo (0 a 1).
  final double ring;
  final double size;
  final Widget child;

  @override
  State<BoxWaveProgress> createState() => _BoxWaveProgressState();
}

class _BoxWaveProgressState extends State<BoxWaveProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: widget.size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.level),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, level, child) => CustomPaint(
          painter: _WavePainter(animation: _wave, level: level, ring: widget.ring, track: scheme.surfaceContainerHighest, primary: scheme.primary, background: scheme.surfaceContainer),
          child: child,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.animation, required this.level, required this.ring, required this.track, required this.primary, required this.background}) : super(repaint: animation);

  final Animation<double> animation;
  final double level, ring;
  final Color track, primary, background;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0, gap = 7.0;
    final center = size.center(Offset.zero), outer = size.shortestSide / 2 - stroke / 2, inner = outer - stroke / 2 - gap;
    final ringPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, outer, ringPaint..color = track);
    if (ring > 0) canvas.drawArc(Rect.fromCircle(center: center, radius: outer), -math.pi / 2, 2 * math.pi * ring, false, ringPaint..color = primary);

    final circle = Path()..addOval(Rect.fromCircle(center: center, radius: inner));
    canvas.save();
    canvas.clipPath(circle);
    canvas.drawCircle(center, inner, Paint()..color = background);
    final top = center.dy + inner - 2 * inner * level.clamp(0.0, 1.0);
    final phase = animation.value * 2 * math.pi;
    if (level > 0) {
      _drawWave(canvas, center, inner, top, phase + math.pi, AppColors.waveDeep.withValues(alpha: .55));
      _drawWave(canvas, center, inner, top, phase, AppColors.wave.withValues(alpha: .65));
    }
    canvas.restore();
  }

  void _drawWave(Canvas canvas, Offset center, double radius, double top, double phase, Color color) {
    final left = center.dx - radius, width = radius * 2, amplitude = math.min(6.0, radius * .05);
    final path = Path()..moveTo(left, center.dy + radius);
    for (var x = 0.0; x <= width; x += 2) {
      path.lineTo(left + x, top + math.sin(x / width * 2 * math.pi + phase) * amplitude);
    }
    path
      ..lineTo(left + width, center.dy + radius)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.level != level || old.ring != ring || old.primary != primary || old.track != track;
}
