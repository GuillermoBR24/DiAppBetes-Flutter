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
          SnackBar(
            content: const Text('Correo reenviado'),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.blanco,
      body: Stack(
        children: [
          SizedBox.expand(
            child: CustomPaint(
              painter: _BgPainter(
                color: isDark ? const Color(0xFF1A1A2E) : AppColors.azulFondo,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: h),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: h * 0.01),
                      _buildLogo(context, cardColor, isDark),
                      const SizedBox(height: 30),
                      _sent
                          ? _buildSuccessCard(
                              context,
                              primaryColor,
                              onPrimaryColor,
                              textColor,
                              textSmallColor,
                              isDark,
                            )
                          : _buildFormCard(
                              context,
                              primaryColor,
                              onPrimaryColor,
                              textColor,
                              textSmallColor,
                              dividerColor,
                              isDark,
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: Text('Volver al Login',
                            style: TextStyle(
                                color: primaryColor,
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
  Widget _buildLogo(BuildContext context, Color cardColor, bool isDark) {
    return Container(
      width: 160, height: 160,
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
      child: Image.asset('assets/LogoDiAppBetes.png', fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
              Icons.medical_services_rounded, 
              size: 100, 
              color: Theme.of(context).colorScheme.primary)),
    );
  }

  // ── Formulario ───────────────────────────────────────────────────────── //
  Widget _buildFormCard(
    BuildContext context,
    Color primaryColor,
    Color onPrimaryColor,
    Color? textColor,
    Color? textSmallColor,
    Color dividerColor,
    bool isDark,
  ) {
    return _Card(
      isDark: isDark,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Recuperar Contraseña',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: primaryColor,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),

            Text(
              'Introduce tu email y te enviaremos un enlace para crear una nueva contraseña.',
              style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: _inputDeco('Email', primaryColor, textSmallColor, dividerColor),
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
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: onPrimaryColor, strokeWidth: 2))
                    : Text('Enviar enlace',
                        style: TextStyle(
                          color: onPrimaryColor, 
                          fontSize: 15, 
                          fontWeight: FontWeight.w600,
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pantalla de confirmación (después de enviar) ──────────────────────── //
  Widget _buildSuccessCard(
    BuildContext context,
    Color primaryColor,
    Color onPrimaryColor,
    Color? textColor,
    Color? textSmallColor,
    bool isDark,
  ) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icono de email enviado
          const Center(
            child: Icon(Icons.mark_email_read_rounded,
                size: 72, color: AppColors.verdesuave),
          ),
          const SizedBox(height: 16),

          Text('¡Correo enviado!',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: primaryColor,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),

          // Email destacado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _emailController.text.trim(),
              style: TextStyle(
                  color: primaryColor, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Revisa tu bandeja de entrada y haz clic en el enlace para crear una nueva contraseña.\n\nSi no lo ves, revisa la carpeta de spam.',
            style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Botón principal → login
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Ir al Login',
                  style: TextStyle(
                    color: onPrimaryColor, 
                    fontSize: 15, 
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
          const SizedBox(height: 10),

          // Botón secundario → reenviar
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _onResend,
              icon: Icon(Icons.refresh, size: 18, color: primaryColor),
              label: Text('Reenviar correo',
                  style: TextStyle(
                    color: primaryColor, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w500,
                  )),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(
    String label,
    Color primaryColor,
    Color? textSmallColor,
    Color dividerColor,
  ) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textSmallColor, fontSize: 14),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
        errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.rojoSuave)),
        focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.rojoSuave)),
      );
}

// ── Tarjeta reutilizable ──────────────────────────────────────────────────── //
class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
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
      child: child,
    );
  }
}

class _BgPainter extends CustomPainter {
  final Color color;

  _BgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRRect(RRect.fromLTRBAndCorners(
      0, -size.height * 0.30, size.width, size.height * 0.50,
      bottomLeft: const Radius.circular(25), bottomRight: const Radius.circular(25),
    ), paint);
  }
  
  @override 
  bool shouldRepaint(covariant _BgPainter oldDelegate) => 
      oldDelegate.color != color;
}