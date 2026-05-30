import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/tir_progress_ring.dart';
import '../services/profile_service.dart';
import '../services/glucose_service.dart';
import '../services/meal_service.dart';
import '../services/tir_service.dart';
import '../services/tip_service.dart';
import '../services/auth_service.dart';

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

  // Estado granular: cada tarjeta carga independientemente
  bool _loadingProfile  = true;
  bool _loadingGlucose  = true;
  bool _loadingMeals    = true;
  bool _loadingTir      = true;
  bool _loadingTip      = true;

  int _selectedTab = 1;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // Recarga al volver de otra pantalla
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo recarga si ya terminó la carga inicial
    if (!_loadingProfile && !_loadingMeals) _loadAll();
  }

  // ── Carga en paralelo, cada sección muestra su propio indicador ──────── //
  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loadingProfile = true;
      _loadingGlucose = true;
      _loadingMeals   = true;
      _loadingTir     = true;
      _loadingTip     = true;
    });

    // Cada futuro actualiza la UI en cuanto termina — no bloquean entre sí
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
      if (mounted) setState(() { _username = username; _loadingProfile = false; });
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

  void _onTabTapped(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    switch (index) {
      case 0: Navigator.pushNamed(context, '/historial'); break;
      case 2: Navigator.pushNamed(context, '/add-meal'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.azulFondo,
        titleSpacing: 0, // ← Elimina el margen izquierdo por defecto del AppBar
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16), // ← Margen izquierdo opcional para separar del borde
            // Fondo blanco con bordes redondeados + Logo
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.blanco, // ← Fondo blanco
                borderRadius: BorderRadius.circular(8), // ← Bordes circulares (ajusta el valor)
                // Opcional: sombra sutil para profundidad
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8), // ← Recorta la imagen a los bordes redondeados
                child: Image.asset(
                  'assets/favicon.png',
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.image_not_supported, color: AppColors.azulFondo, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12), // ← Espacio entre logo y texto
            // Título
            const Text('DiAppBetes',
                style: TextStyle(
                  color: AppColors.blanco, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 20
                )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.blanco),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              _loadProfile();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
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
              Expanded(flex: 6, child: _buildTirCard()),
              const SizedBox(height: 10),
              /*Expanded(flex: 2, child: _buildGlucosaCard()),
              const SizedBox(height: 10),*/
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
        _loadingProfile
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azulFondo))
            : Text(
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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _loadingTir
              ? const SizedBox(height: 130, child: Center(
                  child: CircularProgressIndicator(color: AppColors.azulFondo)))
              : TirProgressRing(percentage: _tirPercentage),
          if (!_loadingTir && _tirPercentage == 0)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Sin lecturas aún',
                  style: TextStyle(fontSize: 11, color: AppColors.grisTexto)),
            ),
          const SizedBox(height: 48),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.water_drop_outlined, size: 20, color: AppColors.azulFondo),
                SizedBox(width: 6),
                Text('Última Lectura',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
              ]),
              const SizedBox(height: 6),
              _loadingGlucose
                  ? const SizedBox(height: 20, child: Center(
                      child: LinearProgressIndicator(color: AppColors.azulFondo,
                          backgroundColor: AppColors.grisDivider)))
                  : Text(_lastGlucoseReading,
                      style: const TextStyle(fontSize: 18, color: AppColors.grisTexto)),
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
          Row(children: const [
            Icon(Icons.restaurant_outlined, size: 20, color: AppColors.azulFondo),
            SizedBox(width: 6),
            Text('Comidas de hoy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
          ]),
          const SizedBox(height: 6),
          _loadingMeals
              ? const SizedBox(height: 34, child: Center(
                  child: LinearProgressIndicator(color: AppColors.azulFondo,
                      backgroundColor: AppColors.grisDivider)))
              : Text('$_todayMealCount',
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
          _loadingTip
              ? const LinearProgressIndicator(color: AppColors.azulFondo,
                  backgroundColor: AppColors.grisDivider)
              : Text(
                  _tipContent.isNotEmpty ? _tipContent : '—',
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
          BottomNavigationBarItem(icon: Icon(Icons.refresh),    label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.home),       label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Comida'),
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
      color: AppColors.cardBackground, borderRadius: BorderRadius.circular(24),
      boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
    ),
    child: child,
  );
}