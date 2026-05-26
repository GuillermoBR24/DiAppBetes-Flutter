import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/tir_progress_ring.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Profile profile = const Profile(
    id: '1',
    username: 'Guillermo',
    email: 'guillermo@example.com',
    birthDate: '1990-01-01',
    phone: '600123456',
    role: 'user',
  );

  // TODO: reemplazar con GlucoseService.getLatestGlucose()
  String lastGlucoseReading = '112 mg/dL — 10:30';

  // TODO: reemplazar con MealCountService.getTodayMealCount()
  int todayMealCount = 3;

  // TODO: reemplazar con TirService.getTir()
  int tirPercentage = 72;

  // TODO: reemplazar con TipService.getRandomTip()
  String tipContent =
      'Mantén un horario regular de comidas para ayudar a estabilizar tus niveles de glucosa a lo largo del día.';

  int _selectedTab = 1;

  void _onTabTapped(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/historial');
        break;
      case 2:
        Navigator.pushNamed(context, '/add-meal');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        backgroundColor: AppColors.azulFondo,
        automaticallyImplyLeading: false,
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),

            // ── Profile ───────────────────────────────────────────────── //
            _buildProfileCard(),

            // ── Divider ───────────────────────────────────────────────── //
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.grisDivider, thickness: 2),
            ),

            // ── Tarjeta 1: Tiempo en Rango (solo el anillo) ───────────── //
            SizedBox(height: 340, child: _buildTirCard()),
            const SizedBox(height: 10),

            // ── Tarjeta 2: Última lectura de glucosa ──────────────────── //
            /*Expanded(flex: 2, child: _buildGlucosaCard()),
            const SizedBox(height: 10),*/

            // ── Tarjeta 3: Comidas de hoy ─────────────────────────────── //
            SizedBox(height: 100, child: _buildMealsCard()),
            const SizedBox(height: 10),

            // ── Tarjeta 4: Consejo del día ────────────────────────────── //
            SizedBox(height: 140, child: _buildTipCard()),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Profile ──────────────────────────────────────────────────────────── //
  Widget _buildProfileCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.azulFondo, width: 3),
          ),
          child: const Icon(Icons.person, size: 48, color: AppColors.azulFondo),
        ),
        const SizedBox(width: 12),
        Text(
          profile.username,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.azulFondo,
          ),
        ),
      ],
    );
  }

  // ── Tarjeta 1: solo Tiempo en Rango + anillo ─────────────────────────── //
  Widget _buildTirCard() {
    return _Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Tiempo en Rango',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.azulFondo,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          TirProgressRing(percentage: tirPercentage),
          const SizedBox(height: 30),
          Row(
            children: [
            const Icon(Icons.water_drop_outlined,
                  size: 22, color: AppColors.azulFondo),
              SizedBox(width: 6),
              Text(
                'Última Lectura',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulFondo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(height: 6),
              Text(
                lastGlucoseReading,
                style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.grisTexto,
                ),
              ),
            ],
            )
        ],
      ),
    );
  }

  // ── Tarjeta 2: Última Lectura (separada) ──────────────────────────────── //
  /*Widget _buildGlucosaCard() {
    return _Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.water_drop_outlined,
                  size: 20, color: AppColors.azulFondo),
              SizedBox(width: 6),
              Text(
                'Última Lectura',
                style: TextStyle(
                  fontSize: 16,
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
              fontSize: 18,
              color: AppColors.grisTexto,
            ),
          ),
        ],
      ),
    );
  }*/

  // ── Tarjeta 3: Comidas ────────────────────────────────────────────────── //
  Widget _buildMealsCard() {
    return _Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.restaurant_outlined,
                  size: 22, color: AppColors.azulFondo),
              SizedBox(width: 6),
              Text(
                'Comidas de hoy',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulFondo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$todayMealCount',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.grisTexto,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta 4: Consejo ────────────────────────────────────────────────── //
  Widget _buildTipCard() {
    return _Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline,
                  size: 22, color: AppColors.azulFondo),
              SizedBox(width: 6),
              Text(
                'Consejo de salud',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulFondo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tipContent,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.grisTexto,
              height: 1.4,
            ),
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