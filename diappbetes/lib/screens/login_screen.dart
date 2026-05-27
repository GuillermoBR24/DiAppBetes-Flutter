import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// LoginScreen — equivalente a LoginPage de Angular/Ionic
// ---------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController   = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _error = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() => setState(() => _error = '');

  // ── onLogin() ─────────────────────────────────────────────────────────── //
  Future<void> _onLogin() async {
    setState(() => _error = '');

    final identifier = _identifierController.text.trim();
    final password   = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _error = 'Todos los campos son obligatorios');
      return;
    }

    // TODO: reemplazar con AuthService.login({identifier, password})
    // Simulación hardcodeada: cualquier credencial válida pasa
    if (identifier.isNotEmpty && password.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _error = 'Credenciales incorrectas');
    }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Stack(
        children: [
          // ── Fondo azul con forma redondeada (mismo que AuthScreen) ─── //
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

                      // ── Tarjeta login ─────────────────────────────── //
                      _buildLoginCard(),
                      const SizedBox(height: 16),

                      // ── Botón Volver (.back-container) ────────────── //
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                        child: const Text(
                          'Volver',
                          style: TextStyle(
                            color: AppColors.azulFondo,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  // ── Logo (igual que AuthScreen) ────────────────────────────────────────── //
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

  // ── Tarjeta de login (.welcome-card) ──────────────────────────────────── //
  Widget _buildLoginCard() {
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.azulFondo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Campo Email / Usuario
            TextFormField(
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
              onChanged: (_) => _clearError(),
              decoration: _inputDecoration('Email o Usuario'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),

            // Campo Contraseña
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
              onChanged: (_) => _clearError(),
              decoration: _inputDecoration('Contraseña').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.grisTexto,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
            ),

            // Mensaje de error (.error-message)
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _error,
                style: const TextStyle(
                    color: AppColors.rojoSuave, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),

            // Botón Login (.btn-primary)
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _onLogin,
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

            // ¿Olvidaste tu contraseña? (.forgot-password)
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/remember-password'),
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: AppColors.azulFondo,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Decoración reutilizable para los campos ───────────────────────────── //
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 14),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.grisDivider)),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.azulFondo)),
      errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.rojoSuave)),
      focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.rojoSuave)),
    );
  }
}

// ---------------------------------------------------------------------------
// Fondo — mismo CustomPainter que AuthScreen
// ---------------------------------------------------------------------------
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.azulFondo;
    final rect = RRect.fromLTRBAndCorners(
      0, -size.height * 0.30, size.width, size.height * 0.50,
      bottomLeft: const Radius.circular(25),
      bottomRight: const Radius.circular(25),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}