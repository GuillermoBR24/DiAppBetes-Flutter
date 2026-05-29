import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TipService {
  static final TipService _instance = TipService._internal();
  factory TipService() => _instance;
  TipService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Tips hardcodeados como fallback si la colección daily_tips está vacía
  static const _fallbackTips = [
    'Mantén un horario regular de comidas para ayudar a estabilizar tus niveles de glucosa a lo largo del día.',
    'Beber suficiente agua ayuda a los riñones a eliminar el exceso de glucosa en la sangre.',
    'El ejercicio moderado después de las comidas puede ayudar a reducir los picos de glucosa postprandiales.',
    'Llevar un registro diario de tus lecturas te ayuda a identificar patrones y mejorar tu control glucémico.',
    'Dormir bien es fundamental: la falta de sueño puede aumentar la resistencia a la insulina.',
    'Las fibras solubles de frutas, legumbres y avena ralentizan la absorción de azúcar en sangre.',
    'Revisa tus pies a diario para detectar heridas o cambios de color, ya que la diabetes puede afectar la circulación.',
  ];

  // Equivalente a TipService.getRandomTip() de Angular
  Future<String> getRandomTip() async {
    try {
      // Intentar obtener un tip activo de Firestore
      final snap = await _db
          .collection('daily_tips')
          .where('is_active', isEqualTo: true)
          .get();

      if (snap.docs.isNotEmpty) {
        snap.docs.shuffle();
        final content = snap.docs.first.data()['content'] as String?;
        if (content != null && content.isNotEmpty) return content;
      }

      // Fallback: tip local aleatorio
      _fallbackTips.shuffle();
      return _fallbackTips.first;
    } catch (_) {
      _fallbackTips.shuffle();
      return _fallbackTips.first;
    }
  }

  // Marcar tip como visto en user_tips
  Future<void> markTipSeen(String tipId) async {
    if (_uid == null) return;
    try {
      await _db.collection('user_tips').add({
        'user_id':    _uid,
        'tip_id':     tipId,
        'viewed_at':  FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}