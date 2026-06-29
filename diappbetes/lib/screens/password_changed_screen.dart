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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.blanco,
      body: Stack(
        children: [
          // ── Fondo dinámico (mismo que el resto de pantallas auth) ─────── //
          SizedBox.expand(
            child: CustomPaint(
              painter: _BackgroundPainter(
                color: isDark ? const Color(0xFF1A1A2E) : AppColors.azulFondo,
              ),
            ),
          ),

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
                      _buildLogo(context, cardColor, isDark),
                      const SizedBox(height: 30),

                      // ── Tarjeta de confirmación ───────────────────── //
                      _buildCard(
                        context,
                        primaryColor,
                        onPrimaryColor,
                        textColor,
                        isDark,
                      ),
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

  Widget _buildLogo(BuildContext context, Color cardColor, bool isDark) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0x1A000000),
            blurRadius: 6, 
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        'assets/LogoDiAppBetes.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.medical_services_rounded,
          size: 100,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    Color primaryColor,
    Color onPrimaryColor,
    Color? textColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.blanco,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0x1A000000),
            blurRadius: 12, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título
          Text(
            'Contraseña Cambiada',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Mensaje de éxito (.success-message)
          Text(
            'Felicidades, su contraseña ha sido cambiada con éxito.',
            style: TextStyle(
              fontSize: 15,
              color: textColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Center(
            child: Container(
              width: 180,
              height: 180,
              child: Image.asset(
                'assets/TickContaseñaCambiada.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: primaryColor,
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
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Volver al Login',
                style: TextStyle(
                  color: onPrimaryColor,
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
  final Color color;

  _BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rect = RRect.fromLTRBAndCorners(
      0, -size.height * 0.35, size.width, size.height * 0.45,
      bottomLeft: const Radius.circular(25),
      bottomRight: const Radius.circular(25),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => 
      oldDelegate.color != color;
}