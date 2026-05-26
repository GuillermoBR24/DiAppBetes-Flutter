import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/tir_progress_ring.dart';

// ---------------------------------------------------------------------------
// Modelos de datos (equivalentes a los servicios Angular — hardcodeados por ahora)
// ---------------------------------------------------------------------------
class Profile {
  final String id;
  final String username;
  final String email;
  final String birthDate;
  final String phone;
  final String role;

  const Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.birthDate,
    required this.phone,
    required this.role,
  });
}

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---- Estado (equivalente a las variables del componente Angular) --------
  Profile profile = const Profile(
    id: '1',
    username: 'Guillermo',
    email: 'guillermo@example.com',
    birthDate: '1990-01-01',
    phone: '600123456',
    role: 'user',
  );

  // TODO: reemplazar con llamada a GlucoseService.getLatestGlucose()
  String lastGlucoseReading = '112 mg/dL — 10:30';

  // TODO: reemplazar con llamada a MealCountService.getTodayMealCount()
  int todayMealCount = 3;

  // TODO: reemplazar con llamada a TirService.getTir()
  int tirPercentage = 72;

  // TODO: reemplazar con llamada a TipService.getRandomTip()
  String tipContent =
      'Mantén un horario regular de comidas para ayudar a estabilizar tus niveles de glucosa a lo largo del día.';

  // ---- Índice del tab seleccionado (0=Historial, 1=Home, 2=Comida) -------
  int _selectedTab = 1;

  // ---- Lógica de color TIR (portada 1:1 desde Angular) -------------------
  Color get _tirColor {
    if (tirPercentage < 33) return AppColors.rojoSuave;
    if (tirPercentage <= 77) return AppColors.ambarSuave;
    return AppColors.verdesuave;
  }

  // ---- Navegación del bottom bar -----------------------------------------
  void _onTabTapped(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/historial');
        break;
      case 1:
        // Ya estamos en home
        break;
      case 2:
        Navigator.pushNamed(context, '/add-meal');
        break;
    }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      // ------------------------------------------------------------------ //
      // AppBar  (equivalente al ion-toolbar)
      // ------------------------------------------------------------------ //
      appBar: AppBar(
        backgroundColor: AppColors.azulFondo,
        title: const Text(
          'DiAppBetes',
          style: TextStyle(
            color: AppColors.blanco,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.blanco),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
        elevation: 2,
      ),

      // ------------------------------------------------------------------ //
      // Body  (equivalente al ion-content con .content-container)
      // ------------------------------------------------------------------ //
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Profile card ──────────────────────────────────────────── //
            _buildProfileCard(),

            // ── Divider ───────────────────────────────────────────────── //
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Divider(color: AppColors.grisDivider, thickness: 2),
            ),

            // ── Tarjeta TIR + Última lectura ──────────────────────────── //
            _buildTirCard(),
            const SizedBox(height: 12),

            // ── Tarjeta comidas de hoy ─────────────────────────────────── //
            _buildMealsCard(),
            const SizedBox(height: 12),

            // ── Tarjeta consejo del día ────────────────────────────────── //
            _buildTipCard(),
          ],
        ),
      ),

      // ------------------------------------------------------------------ //
      // BottomNavigationBar  (equivalente al ion-tab-bar)
      // ------------------------------------------------------------------ //
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // =========================================================================
  // Widgets auxiliares
  // =========================================================================

  /// Profile card — equivalente a .profile-card
  Widget _buildProfileCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.azulFondo, width: 3),
          ),
          child: const Icon(
            Icons.person,
            size: 30,
            color: AppColors.azulFondo,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          profile.username,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.azulFondo,
          ),
        ),
      ],
    );
  }

  /// Tarjeta TIR — equivalente a .card con .circular-progress + .titulo-glucemia
  Widget _buildTirCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Tiempo en Rango',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.azulFondo,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Anillo de progreso circular
          TirProgressRing(percentage: tirPercentage),

          const SizedBox(height: 16),

          // Última lectura glucemia
          Row(
            children: [
              const Icon(
                Icons.water_drop_outlined,
                size: 22,
                color: AppColors.azulFondo,
              ),
              const SizedBox(width: 6),
              const Text(
                'Última Lectura',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulFondo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            lastGlucoseReading,
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.grisTexto,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta comidas — equivalente a .card con .titulo-comida + .meals-count
  Widget _buildMealsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.restaurant_outlined,
                size: 22,
                color: AppColors.azulFondo,
              ),
              SizedBox(width: 6),
              Text(
                'Comidas de hoy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulFondo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$todayMealCount',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.grisTexto,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta consejo del día — equivalente a .card con .tip-day
  Widget _buildTipCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_outline,
                size: 22,
                color: AppColors.azulFondo,
              ),
              SizedBox(width: 6),
              Text(
                'Consejo de salud',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulFondo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tipContent,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grisTexto,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// BottomNavigationBar — equivalente al ion-tab-bar
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.blanco,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.blanco,
        selectedItemColor: AppColors.fondoAzulClaroActivo,
        unselectedItemColor: AppColors.azulFondo,
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.refresh),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Comida',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Widget reutilizable _Card  (equivalente a .card en SCSS)
// ============================================================================
class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}