import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/tir_progress_ring.dart';
import '../services/profile_service.dart';
import '../services/glucose_service.dart';
import '../services/meal_service.dart';
import '../services/tir_service.dart';
import '../services/tip_service.dart';
import '../services/auth_service.dart';

// ---------------------------------------------------------------------------
// HomeScreen — con lógica real de Firebase/Firestore
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final _profileService = ProfileService();
  final _glucoseService = GlucoseService();
  final _mealService    = MealService();
  final _tirService     = TirService();
  final _tipService     = TipService();
  final _authService    = AuthService();

  // ── Estado ────────────────────────────────────────────────────────────── //
  String _username           = '';
  String _lastGlucoseReading = '—';
  int    _todayMealCount     = 0;
  int    _tirPercentage      = 0;
  String _tipContent         = '';

  bool _loading = true;

  int _selectedTab = 1;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── didChangeDependencies: se llama también al volver a esta pantalla ─── //
  // Equivalente a ionViewWillEnter() de Ionic
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarga los datos cada vez que se vuelve a esta pantalla
    if (!_loading) _loadAll();
  }

  // ── Carga todos los datos en paralelo ─────────────────────────────────── //
  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Lanzamos todas las peticiones en paralelo — equivalente a los
      // múltiples métodos en ionViewWillEnter() del Angular
      final results = await Future.wait([
        _profileService.getMyProfile(),          // [0]
        _glucoseService.getLatestGlucoseFormatted(), // [1]
        _mealService.getTodayMealCount(),         // [2]
        _tirService.getTirPercentage(),           // [3]
        _tipService.getRandomTip(),               // [4]
      ]);

      if (!mounted) return;

      // Perfil — auto-reparación si no existe
      var profile = results[0] as Map<String, dynamic>?;
      if (profile == null) {
        await _profileService.ensureProfileExists();
        profile = await _profileService.getMyProfile();
      }

      // Username siempre desde Firestore, con fallback al email de Auth
      final username = (profile?['username'] as String?)?.isNotEmpty == true
          ? profile!['username'] as String
          : (_authService.currentUser?.email?.split('@').first ?? '');

      setState(() {
        _username           = username;
        _lastGlucoseReading = results[1] as String;
        _todayMealCount     = results[2] as int;
        _tirPercentage      = results[3] as int;
        _tipContent         = results[4] as String;
        _loading            = false;
      });
    } catch (e) {
      debugPrint('❌ HomeScreen._loadAll error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Navegación bottom bar ─────────────────────────────────────────────── //
  void _onTabTapped(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    switch (index) {
      case 0: Navigator.pushNamed(context, '/historial'); break;
      case 2: Navigator.pushNamed(context, '/add-meal'); break;
    }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        backgroundColor: AppColors.azulFondo,
        title: const Text('DiAppBetes',
            style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.blanco),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              // Al volver de settings recarga por si cambió el username
              _loadAll();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.azulFondo))
          : RefreshIndicator(
              color: AppColors.azulFondo,
              onRefresh: _loadAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 14),
                    _buildProfileCard(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.grisDivider, thickness: 2),
                    ),
                    Expanded(flex: 4, child: _buildTirCard()),
                    const SizedBox(height: 10),
                    Expanded(flex: 2, child: _buildGlucosaCard()),
                    const SizedBox(height: 10),
                    Expanded(flex: 2, child: _buildMealsCard()),
                    const SizedBox(height: 10),
                    Expanded(flex: 2, child: _buildTipCard()),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Profile card ─────────────────────────────────────────────────────── //
  Widget _buildProfileCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.azulFondo, width: 3),
          ),
          child: const Icon(Icons.person, size: 26, color: AppColors.azulFondo),
        ),
        const SizedBox(width: 12),
        Text(
          _username.isNotEmpty ? _username : '—',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
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
          const Text('Tiempo en Rango',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TirProgressRing(percentage: _tirPercentage),
          // Indicador de fuente de datos
          if (_tirPercentage == 0)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Sin lecturas registradas',
                  style: TextStyle(fontSize: 11, color: AppColors.grisTexto)),
            ),
        ],
      ),
    );
  }

  // ── Tarjeta Última Lectura ────────────────────────────────────────────── //
  Widget _buildGlucosaCard() {
    return _Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.water_drop_outlined, size: 20, color: AppColors.azulFondo),
            SizedBox(width: 6),
            Text('Última Lectura',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
          ]),
          const SizedBox(height: 6),
          Text(_lastGlucoseReading,
              style: const TextStyle(fontSize: 18, color: AppColors.grisTexto)),
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
          Row(children: const [
            Icon(Icons.restaurant_outlined, size: 20, color: AppColors.azulFondo),
            SizedBox(width: 6),
            Text('Comidas de hoy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
          ]),
          const SizedBox(height: 6),
          Text('$_todayMealCount',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.grisTexto)),
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
          Row(children: const [
            Icon(Icons.lightbulb_outline, size: 20, color: AppColors.azulFondo),
            SizedBox(width: 6),
            Text('Consejo de salud',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
          ]),
          const SizedBox(height: 8),
          Text(
            _tipContent.isNotEmpty ? _tipContent : 'Cargando consejo...',
            style: const TextStyle(fontSize: 13, color: AppColors.grisTexto, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────── //
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.blanco,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.blanco,
        selectedItemColor: AppColors.fondoAzulClaroActivo,
        unselectedItemColor: AppColors.azulFondo,
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.home),    label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Comida'),
        ],
      ),
    );
  }
}

// ── _Card reutilizable ───────────────────────────────────────────────────── //
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}