import 'package:shared_preferences/shared_preferences.dart';

class RememberMeService {
  static final RememberMeService _instance = RememberMeService._internal();
  factory RememberMeService() => _instance;
  RememberMeService._internal();

  static const _kRememberMe   = 'remember_me';
  static const _kLastActiveAt = 'last_active_at';

  static const Duration sessionTimeout = Duration(hours: 12);

  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberMe, value);
    await _touch();
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRememberMe) ?? false;
  }

  Future<void> _touch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastActiveAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> touchActivity() => _touch();

  Future<bool> shouldExpireSession() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberMe) ?? false;
    if (remember) return false;

    final lastMillis = prefs.getInt(_kLastActiveAt);
    if (lastMillis == null) return false;

    final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
    return DateTime.now().difference(last) > sessionTimeout;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRememberMe);
    await prefs.remove(_kLastActiveAt);
  }
}