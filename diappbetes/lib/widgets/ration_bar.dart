import 'package:flutter/material.dart';

/// Visualiza las raciones (1 ración = 10 g de H.C.) como una fila de segmentos.
/// Cada segmento es una ración; la última se rellena en proporción.
class RationBar extends StatelessWidget {
  final double raciones;
  final double hc;
  final Color color;

  /// Segmentos que se dibujan; más allá se añade un "+".
  static const int maxSegments = 8;

  const RationBar({
    super.key,
    required this.raciones,
    required this.hc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textSmall = Theme.of(context).textTheme.bodySmall?.color;
    final r = raciones < 0 ? 0.0 : raciones;
    final shown = r > maxSegments ? maxSegments : r;
    final label = r == 0
        ? 'Sin hidratos de carbono'
        : '≈ ${_fmt(r)} ${r == 1 ? 'ración' : 'raciones'} (${hc.toStringAsFixed(1)} g de HC)';

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < maxSegments; i++) ...[
                  Expanded(child: _segment(context, (shown - i).clamp(0.0, 1.0).toDouble())),
                  if (i < maxSegments - 1) const SizedBox(width: 4),
                ],
                if (r > maxSegments) ...[
                  const SizedBox(width: 6),
                  Text('+', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: textSmall)),
          ],
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, double fill) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fill,
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
