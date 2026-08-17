import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class TipService {
  static final TipService _instance = TipService._internal();
  factory TipService() => _instance;
  TipService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _rng = Random();

  static final List<String> _fallbackTips = [
    'Mantén un horario regular de comidas para ayudar a estabilizar tus niveles de glucosa a lo largo del día.',
    'Beber suficiente agua ayuda a los riñones a eliminar el exceso de glucosa en la sangre.',
    'El ejercicio moderado después de las comidas puede ayudar a reducir los picos de glucosa postprandiales.',
    'Llevar un registro diario de tus lecturas te ayuda a identificar patrones y mejorar tu control glucémico.',
    'Dormir bien es fundamental: la falta de sueño puede aumentar la resistencia a la insulina.',
    'Las fibras solubles de frutas, legumbres y avena ralentizan la absorción de azúcar en sangre.',
    'Revisa tus pies a diario para detectar heridas o cambios de color, ya que la diabetes puede afectar la circulación.',
  ];

  Future<String> getRandomTip() async {
    try {
      final snap = await _db
          .collection('daily_tips')
          .where('is_active', isEqualTo: true)
          .get();

      if (snap.docs.isNotEmpty) {
        final index = _rng.nextInt(snap.docs.length);
        final content = snap.docs[index].data()['content'] as String?;
        if (content != null && content.isNotEmpty) return content;
      }
    } catch (_) {}
    return _fallbackTips[_rng.nextInt(_fallbackTips.length)];
  }
}