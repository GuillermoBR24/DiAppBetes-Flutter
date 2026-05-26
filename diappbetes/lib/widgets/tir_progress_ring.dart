import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class TirProgressRing extends StatelessWidget {
  final int percentage;

  // Tamaño reducido a 130 para que quepa sin scroll en pantallas normales
  const TirProgressRing({super.key, required this.percentage});

  Color get _color {
    if (percentage < 33) return AppColors.rojoSuave;
    if (percentage <= 77) return AppColors.ambarSuave;
    return AppColors.verdesuave;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: _RingPainter(
                percentage: percentage,
                progressColor: _color,
                backgroundColor: AppColors.progressBg,
              ),
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int percentage;
  final Color progressColor;
  final Color backgroundColor;

  _RingPainter({
    required this.percentage,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 1.5;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}