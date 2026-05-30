import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String _error = '';
  bool _obscurePassword = true;
  bool _loading = false;
  bool _registered = false; // true → mostrar pantalla "verifica tu email"

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _clearError() => setState(() => _error = '');

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = ''; _loading = true; });

    try {
      await _authService.register(
        email:      _emailController.text.trim(),
        password:   _passwordController.text,
        birthDate:  _birthDateController.text.trim(),
      );
      if (mounted) setState(() => _registered = true);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.translateError(e));
    } catch (_) {
      setState(() => _error = 'Error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final minDate = DateTime(1900, 1, 1);
    final maxDate = now.subtract(const Duration(days: 365 * 12)); // Mínimo 12 años

    final picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      locale: const Locale('es', 'ES'), // ← Para mostrar en español
      helpText: 'Selecciona tu fecha de nacimiento',
    );

    if (picked != null && mounted) {
      // Formato YYYY-MM-DD (compatible con Firestore)
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  // Reenviar email de verificación si el usuario no lo recibió
  Future<void> _resendVerification() async {
    setState(() { _error = ''; _loading = true; });
    try {
      await _authService.resendVerificationEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo de verificación reenviado'),
            backgroundColor: AppColors.verdesuave,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.translateError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Stack(
        children: [
          SizedBox.expand(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: h * 0.01),
                      _buildLogo(),
                      const SizedBox(height: 30),
                      // Cambia entre formulario y pantalla de verificación
                      _registered ? _buildVerifyCard() : _buildRegisterCard(),
                      const SizedBox(height: 16),
                      if (!_registered)
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/auth'),
                          child: const Text('Volver',
                              style: TextStyle(
                                  color: AppColors.azulFondo,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
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

  Widget _buildLogo() {
    return Container(
      width: 160, height: 160,
      decoration: BoxDecoration(
        color: AppColors.blanco, borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset('assets/LogoDiAppBetes.png', fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.medical_services_rounded, size: 100, color: AppColors.azulFondo)),
    );
  }

  // ── Formulario de registro ────────────────────────────────────────────── //
  Widget _buildRegisterCard() {
    return _Card(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Registro',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
              onChanged: (_) => _clearError(),
              decoration: _inputDeco('Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                if (!v.contains('@')) return 'Formato del email incorrecto';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
              onChanged: (_) => _clearError(),
              decoration: _inputDeco('Contraseña').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.grisTexto, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obligatorio';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _birthDateController,
              readOnly: true, // ← Solo se puede seleccionar con el picker
              style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
              decoration: _inputDeco('Fecha de nacimiento').copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today, color: AppColors.grisTexto, size: 20),
                  onPressed: _selectBirthDate,
                ),
                hintText: 'YYYY-MM-DD',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                // Validar formato básico YYYY-MM-DD
                if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
                  return 'Formato: YYYY-MM-DD';
                }
                return null;
              },
              onTap: _selectBirthDate, // ← Abrir picker al tocar el campo
            ),

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error,
                  style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _onRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulFondo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: AppColors.blanco, strokeWidth: 2))
                    : const Text('Registrarse',
                        style: TextStyle(color: AppColors.blanco, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pantalla post-registro: "verifica tu email" ───────────────────────── //
  Widget _buildVerifyCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icono de email
          const Center(
            child: Icon(Icons.mark_email_unread_rounded,
                size: 72, color: AppColors.azulFondo),
          ),
          const SizedBox(height: 16),

          const Text('¡Verifica tu correo!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),

          // Email destacado en chip azul
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _emailController.text.trim(),
              style: const TextStyle(
                  color: AppColors.azulFondo,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Hemos enviado un correo de verificación.\nHaz clic en el enlace del correo para activar tu cuenta.\n\nSi no lo ves, revisa la carpeta de spam.',
            style: TextStyle(fontSize: 13, color: AppColors.grisTexto, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Botón principal → ir al login
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulFondo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Ir al Login',
                  style: TextStyle(color: AppColors.blanco, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),

          // Botón secundario → reenviar
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _resendVerification,
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.azulFondo),
              label: const Text('Reenviar correo',
                  style: TextStyle(color: AppColors.azulFondo, fontSize: 14, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.azulFondo),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error,
                style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 14),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
        errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.rojoSuave)),
        focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.rojoSuave)),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.blanco, borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.azulFondo;
    canvas.drawRRect(RRect.fromLTRBAndCorners(
      0, -size.height * 0.35, size.width, size.height * 0.45,
      bottomLeft: const Radius.circular(25), bottomRight: const Radius.circular(25),
    ), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}