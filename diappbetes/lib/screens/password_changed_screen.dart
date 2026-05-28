import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// PasswordChangedScreen — equivalente a PasswordChangedPage de Angular/Ionic
// La pantalla más simple: solo muestra confirmación y botón de vuelta al login
// ---------------------------------------------------------------------------
class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Stack(
        children: [
          // ── Fondo azul (mismo que el resto de pantallas auth) ─────── //
          SizedBox.expand(child: CustomPaint(painter: _BackgroundPainter())),

          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: screenHeight * 0.01),

                      // ── Logo ─────────────────────────────────────── //
                      _buildLogo(),
                      const SizedBox(height: 30),

                      // ── Tarjeta de confirmación ───────────────────── //
                      _buildCard(context),
                      const SizedBox(height: 40),
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
        errorBuilder: (_, __, ___) => const Icon(
          Icons.medical_services_rounded,
          size: 100,
          color: AppColors.azulFondo,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título
          const Text(
            'Contraseña Cambiada',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.azulFondo,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Mensaje de éxito (.success-message)
          const Text(
            'Felicidades, su contraseña ha sido cambiada con éxito.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grisTexto,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.blanco.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/TickContaseñaCambiada.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: AppColors.blanco,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Botón Volver al Login (.btn-primary)
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulFondo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Volver al Login',
                style: TextStyle(
                  color: AppColors.blanco,
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
// Fondo — mismo CustomPainter que el resto de pantallas auth
// ---------------------------------------------------------------------------
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.azulFondo;
    final rect = RRect.fromLTRBAndCorners(
      0, -size.height * 0.35, size.width, size.height * 0.45,
      bottomLeft: const Radius.circular(25),
      bottomRight: const Radius.circular(25),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}