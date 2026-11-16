import 'package:flutter/material.dart';

/// Aviso médico breve y reutilizable.
class MedicalDisclaimer extends StatelessWidget {
  final bool compact;
  const MedicalDisclaimer({super.key, this.compact = false});

  static const String text =
      'DiAppBetes es una herramienta de apoyo y no sustituye el criterio de un '
      'profesional sanitario. Las dosis calculadas son orientativas: consulta '
      'siempre con tu equipo médico antes de decidir tu tratamiento.';

  static const String short =
      'Dosis orientativa. No sustituye el criterio de tu equipo médico.';

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodySmall?.color;
    return Semantics(
      label: compact ? short : text,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.medical_information_outlined, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(compact ? short : text,
                  style: TextStyle(fontSize: 12, height: 1.35, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
