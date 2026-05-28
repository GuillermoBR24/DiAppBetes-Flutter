import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RememberPasswordScreen extends StatefulWidget {
  const RememberPasswordScreen({super.key});

  @override
  State<RememberPasswordScreen> createState() => _RememberPasswordScreenState();
}

class _RememberPasswordScreenState extends State<RememberPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String _error = '';
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = ''; _loading = true; });

    try {
      await _authService.sendPasswordResetEmail(
        _emailController.text.trim(),
      );
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.translateError(e));
    } catch (_) {
      setState(() => _error = 'Error al enviar el correo. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Reenviar (cooldown gestionado por Firebase — máx 1 por minuto) ───── //
  Future<void> _onResend() async {
    setState(() { _error = ''; _loading = true; });
    try {
      await _authService.sendPasswordResetEmail(
        _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo reenviado'),
            backgroundColor: AppColors.azulFondo,
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
                      _sent ? _buildSuccessCard() : _buildFormCard(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text('Volver al Login',
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

  // ── Logo ─────────────────────────────────────────────────────────────── //
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

  // ── Formulario ───────────────────────────────────────────────────────── //
  Widget _buildFormCard() {
    return _Card(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Recuperar Contraseña',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            const Text(
              'Introduce tu email y te enviaremos un enlace para crear una nueva contraseña.',
              style: TextStyle(fontSize: 13, color: AppColors.grisTexto, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
              decoration: _inputDeco('Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                if (!v.contains('@')) return 'Formato de email incorrecto';
                return null;
              },
            ),

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error,
                  style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulFondo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: AppColors.blanco, strokeWidth: 2))
                    : const Text('Enviar enlace',
                        style: TextStyle(color: AppColors.blanco, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pantalla de confirmación (después de enviar) ──────────────────────── //
  Widget _buildSuccessCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icono de email enviado
          const Center(
            child: Icon(Icons.mark_email_read_rounded,
                size: 72, color: AppColors.verdesuave),
          ),
          const SizedBox(height: 16),

          const Text('¡Correo enviado!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),

          // Email destacado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _emailController.text.trim(),
              style: const TextStyle(
                  color: AppColors.azulFondo, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Revisa tu bandeja de entrada y haz clic en el enlace para crear una nueva contraseña.\n\nSi no lo ves, revisa la carpeta de spam.',
            style: TextStyle(fontSize: 13, color: AppColors.grisTexto, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Botón principal → login
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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
              onPressed: _loading ? null : _onResend,
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.azulFondo),
              label: const Text('Reenviar correo',
                  style: TextStyle(color: AppColors.azulFondo, fontSize: 14, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.azulFondo),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
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

// ── Tarjeta reutilizable ──────────────────────────────────────────────────── //
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
      0, -size.height * 0.30, size.width, size.height * 0.50,
      bottomLeft: const Radius.circular(25), bottomRight: const Radius.circular(25),
    ), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}