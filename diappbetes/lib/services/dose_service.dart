import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Parámetros reales del usuario necesarios para calcular una dosis.
class DoseSettings {
  final double ratio; // g de HC por unidad de insulina
  final double fsi; // mg/dL que baja 1 unidad
  const DoseSettings({required this.ratio, required this.fsi});
}

/// Resultado de cargar los parámetros: o hay datos válidos o hay un motivo.
class DoseSettingsResult {
  final DoseSettings? settings;
  final String? error;

  /// true si el fallo se arregla configurando ratio/FSI (se ofrece el asistente).
  final bool needsSetup;

  const DoseSettingsResult.ok(DoseSettings s)
      : settings = s,
        error = null,
        needsSetup = false;
  const DoseSettingsResult.failed(String message, {this.needsSetup = false})
      : settings = null,
        error = message;
  bool get isOk => settings != null;
}

/// Desglose de la dosis para mostrárselo al usuario.
class DoseBreakdown {
  final double mealUnits; // HC / ratio
  final double correctionUnits; // (glucemia - objetivo) / FSI (puede ser negativa)
  final double total; // suma, redondeada y nunca < 0
  const DoseBreakdown({
    required this.mealUnits,
    required this.correctionUnits,
    required this.total,
  });
}

enum GlucoseCheck { ok, low, implausible }

/// Única fuente de verdad para ratio H.C., FSI y fórmula de dosis.
/// NUNCA inventa valores por defecto: si falta o falla algo, devuelve un error
/// para que la UI bloquee el cálculo en vez de mostrar una dosis falsa.
class DoseService {
  static final DoseService _instance = DoseService._internal();
  factory DoseService() => _instance;
  DoseService._internal();

  /// Glucemia objetivo usada en la corrección (mg/dL).
  static const double targetGlucose = 110;

  /// Por encima de esta dosis se avisa al usuario (no se bloquea).
  static const double highDoseWarning = 20;

  /// Por debajo de este valor es hipoglucemia: antes de insulina hay que tratarla.
  static const double hypoThreshold = 70;

  /// Fuera de [minPlausible, maxPlausible] se considera un error de tecleo.
  static const double minPlausible = 20;
  static const double maxPlausible = 600;

  static GlucoseCheck checkGlucose(double mgdl) {
    if (mgdl.isNaN || mgdl < minPlausible || mgdl > maxPlausible) {
      return GlucoseCheck.implausible;
    }
    if (mgdl < hypoThreshold) return GlucoseCheck.low;
    return GlucoseCheck.ok;
  }

  /// ¿Falta configurar el ratio H.C.? (el FSI nace con 50 al registrarse).
  Future<bool> needsSetup() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final snap = await _db
          .collection('hc_ratios')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();
      return snap.docs.isEmpty;
    } catch (_) {
      return false; // sin conexión no se molesta al usuario
    }
  }

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<DoseSettingsResult> load({DateTime? at}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const DoseSettingsResult.failed('Sesión no iniciada.');
    }

    try {
      final profile = await _db.collection('profiles').doc(uid).get();
      final fsi = (profile.data()?['fsi'] as num?)?.toDouble();
      if (fsi == null || fsi <= 0) {
        return const DoseSettingsResult.failed(
            'No tienes configurado el FSI. Configúralo para poder calcular la insulina.',
            needsSetup: true);
      }

      final snap = await _db
          .collection('hc_ratios')
          .where('user_id', isEqualTo: uid)
          .get();
      if (snap.docs.isEmpty) {
        return const DoseSettingsResult.failed(
            'No tienes ningún ratio H.C. configurado. Configúralo para poder calcular la insulina.',
            needsSetup: true);
      }

      final now = at ?? DateTime.now();
      final nowMins = now.hour * 60 + now.minute;

      for (final doc in snap.docs) {
        final d = doc.data();
        final start = parseMinutes(d['start_time']);
        final end = parseMinutes(d['end_time']);
        final value = (d['ratio_value'] as num?)?.toDouble();
        if (start == null || end == null || value == null || value <= 0) {
          continue; // tramo corrupto: se ignora, nunca se adivina
        }
        if (inRange(nowMins, start, end)) {
          return DoseSettingsResult.ok(DoseSettings(ratio: value, fsi: fsi));
        }
      }

      return const DoseSettingsResult.failed(
          'Ningún ratio H.C. cubre la hora actual. Revisa tus tramos en Ajustes.');
    } catch (_) {
      return const DoseSettingsResult.failed(
          'No se pudieron cargar tu ratio y FSI. Comprueba la conexión e inténtalo de nuevo.');
    }
  }

  /// Dosis = HC/ratio + (glucemia - objetivo)/FSI, redondeada a 0.1 y nunca < 0.
  static double calculate({
    required double totalHc,
    required double glucose,
    required DoseSettings settings,
  }) =>
      breakdown(totalHc: totalHc, glucose: glucose, settings: settings).total;

  static DoseBreakdown breakdown({
    required double totalHc,
    required double glucose,
    required DoseSettings settings,
  }) {
    final meal = totalHc / settings.ratio;
    final correction = (glucose - targetGlucose) / settings.fsi;
    final raw = meal + correction;
    final total = (raw.isNaN || raw.isInfinite || raw < 0)
        ? 0.0
        : double.parse(raw.toStringAsFixed(1));
    return DoseBreakdown(
      mealUnits: double.parse(meal.toStringAsFixed(1)),
      correctionUnits: double.parse(correction.toStringAsFixed(1)),
      total: total,
    );
  }

  /// Admite tramos que cruzan la medianoche (p. ej. 22:00 -> 06:00).
  /// El final es exclusivo, salvo 23:59 que se considera fin de día.
  @visibleForTesting
  static bool inRange(int now, int start, int end) {
    if (start == end) return true; // tramo de 24 h
    if (start < end) return now >= start && (now < end || end >= 23 * 60 + 59);
    return now >= start || now < end;
  }

  /// "HH:mm" -> minutos. Ajustes guarda el fin del último tramo como "24:00".
  @visibleForTesting
  static int? parseMinutes(dynamic t) {
    if (t is! String) return null;
    final p = t.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null || m < 0 || m > 59) return null;
    if (h == 24 && m == 0) return 1440;
    if (h < 0 || h > 23) return null;
    return h * 60 + m;
  }
}
