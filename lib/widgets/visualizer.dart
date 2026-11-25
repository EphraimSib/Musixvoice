import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated music visualizer (Bars, Wave or Dots). It animates while music
/// plays; it does not analyse the actual sound.
class AudioVisualizer extends StatefulWidget {
  final bool playing;
  final Color color;
  final Color color2;
  final int style;
  final int bars;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.playing,
    required this.color,
    required this.color2,
    this.style = 0,
    this.bars = 24,
    this.height = 56,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  double _energy = 0.1;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          _energy += ((widget.playing ? 1.0 : 0.08) - _energy) * 0.08;
          return CustomPaint(
            painter: _VisualizerPainter(
              t: _c.value,
              energy: _energy,
              style: widget.style,
              bars: widget.bars,
              c1: widget.color,
              c2: widget.color2,
            ),
          );
        },
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double t;
  final double energy;
  final int style;
  final int bars;
  final Color c1;
  final Color c2;

  _VisualizerPainter({
    required this.t,
    required this.energy,
    required this.style,
    required this.bars,
    required this.c1,
    required this.c2,
  });

  double _level(int i) {
    final a = math.sin(2 * math.pi * t * 1 + i * 0.55) * 0.5 + 0.5;
    final b = math.sin(2 * math.pi * t * 3 + i * 1.3) * 0.5 + 0.5;
    final c = math.sin(2 * math.pi * t * 2 + i * 0.21) * 0.5 + 0.5;
    return (0.12 + 0.88 * (a * 0.4 + b * 0.35 + c * 0.25)) * energy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shader = LinearGradient(colors: [c1, c2])
        .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.fill;
    final n = bars.clamp(8, 64);
    final slot = size.width / n;

    if (style == 1) {
      final line = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final path = Path();
      final mid = size.height / 2;
      for (var x = 0; x <= size.width; x += 3) {
        final i = (x / size.width * n).floor();
        final amp = _level(i) * size.height * 0.45;
        final y = mid + math.sin(x / size.width * 6 * math.pi + 2 * math.pi * t * 2) * amp;
        if (x == 0) {
          path.moveTo(0, y);
        } else {
          path.lineTo(x.toDouble(), y);
        }
      }
      canvas.drawPath(path, line);
    } else if (style == 2) {
      for (var i = 0; i < n; i++) {
        final h = _level(i) * size.height;
        final dots = (h / 8).floor().clamp(1, 8);
        for (var d = 0; d < dots; d++) {
          canvas.drawCircle(
            Offset(slot * i + slot / 2, size.height / 2 - d * 7 - 2),
            2.2,
            paint,
          );
          canvas.drawCircle(
            Offset(slot * i + slot / 2, size.height / 2 + d * 7 + 2),
            2.2,
            paint,
          );
        }
      }
    } else {
      for (var i = 0; i < n; i++) {
        final h = math.max(4.0, _level(i) * size.height);
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(slot * i + slot / 2, size.height / 2),
            width: slot * 0.6,
            height: h,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter old) => true;
}
