// lib/screens/home_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:diappbetes/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import '../widgets/tir_progress_ring.dart';
import '../services/profile_service.dart';
import '../services/glucose_service.dart';
import '../services/meal_service.dart';
import '../services/tir_service.dart';
import '../services/tip_service.dart';
import '../services/auth_service.dart';
import '../utils/admin_nav_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileService = ProfileService();
  final _glucoseService = GlucoseService();
  final _mealService    = MealService();
  final _tirService     = TirService();
  final _tipService     = TipService();
  final _authService    = AuthService();

  String _username           = '';
  String _lastGlucoseReading = '—';
  int    _todayMealCount     = 0;
  int    _tirPercentage      = 0;
  String _tipContent         = '';
  Uint8List? _avatarBytes;  // ← NUEVO: avatar del usuario

  // ── Estado para navegación ───────────────────────────────────────────── //
  bool _isAdmin = false;
  int _selectedTab = 1;

  // Estado granular de carga
  bool _loadingProfile  = true;
  bool _loadingGlucose  = true;
  bool _loadingMeals    = true;
  bool _loadingTir      = true;
  bool _loadingTip      = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _checkAdminRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadingProfile && !_loadingMeals) {
      _loadAll();
      _checkAdminRole();
    }
  }

  // ── Verificar rol de administrador ───────────────────────────────────── //
  Future<void> _checkAdminRole() async {
    final isAdmin = await AdminNavHelper.getIsAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  // ── Carga en paralelo ────────────────────────────────────────────────── //
  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loadingProfile = true;
      _loadingGlucose = true;
      _loadingMeals   = true;
      _loadingTir     = true;
      _loadingTip     = true;
    });

    _loadProfile();
    _loadGlucose();
    _loadMealCount();
    _loadTir();
    _loadTip();
  }

  Future<void> _loadProfile() async {
    try {
      var profile = await _profileService.getMyProfile();
      if (profile == null) {
        await _profileService.ensureProfileExists();
        profile = await _profileService.getMyProfile();
      }
      
      final username = (profile?['username'] as String?)?.isNotEmpty == true
          ? profile!['username'] as String
          : (_authService.currentUser?.email?.split('@').first ?? '');
      
      // ✅ NUEVO: Decodificar avatar si existe
      Uint8List? avatarBytes;
      final avatarBase64 = profile?['avatar_base64'] as String?;
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        try {
          avatarBytes = base64Decode(avatarBase64);
        } catch (e) {
          print('❌ [HOME] Error decodificando avatar: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _username = username;
          _avatarBytes = avatarBytes;  // ← NUEVO
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loadingProfile = false; });
    }
  }

  Future<void> _loadGlucose() async {
    try {
      final val = await _glucoseService.getLatestGlucoseFormatted();
      if (mounted) setState(() { _lastGlucoseReading = val; _loadingGlucose = false; });
    } catch (_) {
      if (mounted) setState(() { _lastGlucoseReading = 'Sin lecturas'; _loadingGlucose = false; });
    }
  }

  Future<void> _loadMealCount() async {
    try {
      final count = await _mealService.getTodayMealCount();
      if (mounted) setState(() { _todayMealCount = count; _loadingMeals = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingMeals = false; });
    }
  }

  Future<void> _loadTir() async {
    try {
      final pct = await _tirService.getTirPercentage();
      if (mounted) setState(() { _tirPercentage = pct; _loadingTir = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingTir = false; });
    }
  }

  Future<void> _loadTip() async {
    try {
      final tip = await _tipService.getRandomTip();
      if (mounted) setState(() { _tipContent = tip; _loadingTip = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingTip = false; });
    }
  }

  // ── Manejo de tabs con AdminNavHelper ────────────────────────────────── //
  void _onTabTapped(int index) {
    AdminNavHelper.handleTabTap(
      context: context,
      index: index,
      isAdmin: _isAdmin,
      onValidTap: (validIndex) {
        setState(() => _selectedTab = validIndex);
        switch (validIndex) {
          case 0: Navigator.pushReplacementNamed(context, '/historial'); break;
          case 2: Navigator.pushReplacementNamed(context, '/add-meal'); break;
          // case 1 (Home) no hace nada
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'DiAppBetes',
        onSettingsPressed: () async {
          await Navigator.pushNamed(context, '/settings');
          _loadProfile();
          _checkAdminRole();
        },
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          await _loadAll();
          await _checkAdminRole();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              _buildProfileCard(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Theme.of(context).dividerColor, thickness: 2),
              ),
              Expanded(flex: 6, child: _buildTirCard()),
              const SizedBox(height: 10),
              Expanded(flex: 2, child: _buildMealsCard()),
              const SizedBox(height: 10),
              Expanded(flex: 2, child: _buildTipCard()),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminNavHelper.buildBottomBar(
        context: context,
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        isAdmin: _isAdmin,
      ),
    );
  }

  // ── Profile card CON AVATAR ──────────────────────────────────────────── //
  Widget _buildProfileCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ✅ AVATAR: muestra imagen si existe, sino icono
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
            image: _avatarBytes != null
                ? DecorationImage(
                    image: MemoryImage(_avatarBytes!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _avatarBytes == null
              ? Icon(Icons.person, size: 26, color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        const SizedBox(width: 12),
        _loadingProfile
            ? SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary))
            : Text(
                _username.isNotEmpty ? _username : '—',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
      ],
    );
  }

  // ── Tarjeta TIR ───────────────────────────────────────────────────────── //
  Widget _buildTirCard() {
    return _Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tiempo en Rango',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _loadingTir
              ? SizedBox(height: 130, child: Center(
                  child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)))
              : TirProgressRing(percentage: _tirPercentage),
          if (!_loadingTir && _tirPercentage == 0)
            
          const SizedBox(height: 48),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.water_drop_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text('Última Lectura',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ]),
              const SizedBox(height: 6),
              _loadingGlucose
                  ? SizedBox(height: 20, child: Center(
                      child: LinearProgressIndicator(color: Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(context).dividerColor)))
                  : Text(_lastGlucoseReading,
                      style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tarjeta Comidas de hoy ────────────────────────────────────────────── //
  Widget _buildMealsCard() {
    return _Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.restaurant_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text('Comidas de hoy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ]),
          const SizedBox(height: 6),
          _loadingMeals
              ? SizedBox(height: 34, child: Center(
                  child: LinearProgressIndicator(color: Theme.of(context).colorScheme.primary,
                      backgroundColor: Theme.of(context).dividerColor)))
              : Text('$_todayMealCount',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  // ── Tarjeta Consejo ───────────────────────────────────────────────────── //
  Widget _buildTipCard() {
    return _Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_outline, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text('Consejo de salud',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ]),
          const SizedBox(height: 8),
          _loadingTip
              ? LinearProgressIndicator(color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).dividerColor)
              : Text(
                  _tipContent.isNotEmpty ? _tipContent : '—',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor, 
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.3)
              : const Color(0x1A000000),
          blurRadius: 12, 
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}