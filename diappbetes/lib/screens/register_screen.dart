import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// RegisterScreen — equivalente a RegisterPage de Angular/Ionic
// ---------------------------------------------------------------------------
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _error = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() => setState(() => _error = '');

  // ── onRegister() ──────────────────────────────────────────────────────── //
  Future<void> _onRegister() async {
    setState(() => _error = '');

    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Todos los campos son obligatorios');
      return;
    }

    // Validación básica de email
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = 'Formato del email incorrecto');
      return;
    }

    // Validación de contraseña mínima
    if (password.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    // TODO: reemplazar con AuthService.register({username, email, password})
    // Simulación hardcodeada: registro exitoso → navegar a /login
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Stack(
        children: [
          // ── Fondo azul (mismo que Auth y Login) ───────────────────── //
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

                      // ── Tarjeta registro ──────────────────────────── //
                      _buildRegisterCard(),
                      const SizedBox(height: 16),

                      // ── Botón Volver (.back-container) ────────────── //
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/auth'),
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
        errorBuilder: (_, __, ___) => const Icon(
          Icons.medical_services_rounded,
          size: 100,
          color: AppColors.azulFondo,
        ),
      ),
    );
  }

  // ── Tarjeta de registro (.welcome-card) ──────────────────────────────── //
  Widget _buildRegisterCard() {
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
              'Registro',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.azulFondo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Campo Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
              onChanged: (_) => _clearError(),
              decoration: _inputDecoration('Email'),
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

            // Botón Registrarse (.btn-primary)
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _onRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulFondo,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Registrarse',
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
      ),
    );
  }

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
// Fondo — mismo CustomPainter que Auth y Login
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