import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// RememberMeService — controla si la sesión debe persistir indefinidamente
// o expirar tras un tiempo de inactividad.
//
// Firebase Auth por sí solo SIEMPRE mantiene la sesión persistida en disco
// (no hay "modo no persistente" nativo en móvil como en web). Para lograr
// el comportamiento de "cerrar sesión sola si no marcaste Recuérdame",
// guardamos nosotros mismos una marca de tiempo de la última apertura y,
// si no se marcó "Recuérdame", forzamos signOut() cuando ha pasado el
// tiempo límite (p.ej. 24h) o cuando el usuario cierra y reabre la app
// más tarde de lo permitido.
// ---------------------------------------------------------------------------
class RememberMeService {
  static final RememberMeService _instance = RememberMeService._internal();
  factory RememberMeService() => _instance;
  RememberMeService._internal();

  static const _kRememberMe   = 'remember_me';
  static const _kLastActiveAt = 'last_active_at';

  /// Si no se marca "Recuérdame", la sesión expira tras este tiempo de
  /// inactividad (cierre completo de la app). Ajusta a tu gusto.
  static const Duration sessionTimeout = Duration(hours: 12);

  // ── Guardar preferencia al hacer login ────────────────────────────────── //
  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberMe, value);
    await _touch();
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRememberMe) ?? false;
  }

  // ── Marca la última vez que la app estuvo activa ──────────────────────── //
  Future<void> _touch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastActiveAt, DateTime.now().millisecondsSinceEpoch);
  }

  /// Llamar cuando la app pasa a primer plano o en login exitoso
  Future<void> touchActivity() => _touch();

  // ── Comprueba si la sesión debe expirar ───────────────────────────────── //
  /// Devuelve true si hay que forzar signOut() porque:
  /// - no se marcó "Recuérdame" Y
  /// - ha pasado más de [sessionTimeout] desde la última actividad registrada
  Future<bool> shouldExpireSession() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberMe) ?? false;
    if (remember) return false; // sesión persistente indefinida

    final lastMillis = prefs.getInt(_kLastActiveAt);
    if (lastMillis == null) return false; // primera vez, no expirar aún

    final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
    return DateTime.now().difference(last) > sessionTimeout;
  }

  // ── Limpieza al hacer logout manual ───────────────────────────────────── //
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRememberMe);
    await prefs.remove(_kLastActiveAt);
  }
}