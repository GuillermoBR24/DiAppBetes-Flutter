import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// AuthScreen — pantalla de bienvenida
// Equivalente a AuthPage de Angular/Ionic
// ---------------------------------------------------------------------------
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Stack(
        children: [
          // Fondo azul
          SizedBox.expand(
            child: CustomPaint(painter: _BackgroundPainter()),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Center( 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      _buildLogo(),
                      const SizedBox(height: 30),
                      _buildWelcomeCard(context),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo ─────────────────────────────────────────────────────────────── //
  Widget _buildLogo() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        'assets/LogoDiAppBetes.png',
        fit: BoxFit.contain, 
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.medical_services_rounded,
            size: 100,
            color: AppColors.azulFondo,
          );
        },
      ),
    );
  }

  // ── Tarjeta de bienvenida ─────────────────────────────────────────────── //
  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Título
          const Text(
            'Bienvenido a DiappBetes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.azulFondo,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Subtítulo
          const Text(
            'Raciona tu Diabetes',
            style: TextStyle(fontSize: 15, color: AppColors.grisTexto),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Botón Login (.btn-primary)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulFondo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  color: AppColors.blanco,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botón Registrarse (.btn-secondary — outline)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.azulFondo, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Registrarse',
                style: TextStyle(
                  color: AppColors.azulFondo,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pintor del fondo: círculo azul en la parte superior
// Equivalente a .background-container > .circulo del SCSS
// ---------------------------------------------------------------------------
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.azulFondo;

    // El círculo ocupa el 80% de alto y empieza desplazado -30% arriba,
    // con esquinas redondeadas en la parte inferior (equiv. border-bottom-*-radius: 25px)
    final rect = RRect.fromLTRBAndCorners(
      0,
      -size.height * 0.30,
      size.width,
      size.height * 0.50,
      bottomLeft: const Radius.circular(25),
      bottomRight: const Radius.circular(25),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}