import 'package:flutter/material.dart';

class GlutenIndicator extends StatelessWidget {
  final bool? containsGluten;
  final double size;
  final bool showLabel;

  const GlutenIndicator({
    super.key,
    required this.containsGluten,
    this.size = 18,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    if (containsGluten == true) {
      color = const Color(0xFFD32F2F);
      icon = Icons.warning_amber_rounded;
      label = 'Con gluten';
    } else if (containsGluten == false) {
      color = const Color(0xFF388E3C);
      icon = Icons.check_circle_outline;
      label = 'Sin gluten';
    } else {
      color = Colors.grey;
      icon = Icons.help_outline;
      label = 'Desconocido';
    }

    if (!showLabel) {
      return Tooltip(
        message: label,
        child: Icon(icon, color: color, size: size),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: size * 0.8),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: size * 0.65,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}