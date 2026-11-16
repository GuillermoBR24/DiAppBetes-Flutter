import 'package:flutter/material.dart';

/// Bloque gris que "respira" mientras se cargan los datos.
/// Si el sistema pide reducir animaciones, se queda fijo.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 8});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _ctrl.stop();
      _started = false;
    } else if (!_started) {
      _ctrl.repeat(reverse: true);
      _started = true;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE6E6E6);
    final light = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFF2F2F2);

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, light, _ctrl.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// Lista de tarjetas esqueleto para pantallas de listado.
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: Column(
        children: List.generate(
          count,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 16),
                  SizedBox(height: 10),
                  SkeletonBox(height: 12),
                  SizedBox(height: 6),
                  SkeletonBox(width: 200, height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
