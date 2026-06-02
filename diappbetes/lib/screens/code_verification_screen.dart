import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// CodeVerificationScreen — equivalente a CodeVerificationPage de Angular/Ionic
// ---------------------------------------------------------------------------
class CodeVerificationScreen extends StatefulWidget {
  const CodeVerificationScreen({super.key});

  @override
  State<CodeVerificationScreen> createState() => _CodeVerificationScreenState();
}

class _CodeVerificationScreenState extends State<CodeVerificationScreen> {
  final _codeController = TextEditingController();

  // Equivalente a lastResend: controla el cooldown de 60s
  DateTime? _lastResend;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ── onCodeInput — solo dígitos, máx 6 ────────────────────────────────── //
  void _onCodeChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits != value) {
      _codeController.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
  }

  // ── verifyCode() ──────────────────────────────────────────────────────── //
  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      _showAlert('Error', 'Por favor ingrese el código de 6 dígitos');
      return;
    }

    // TODO: reemplazar con ResetPasswordService.verifyAndChangePassword(email, code, newPassword)
    // Simulación hardcodeada: cualquier código de 6 dígitos es válido
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Éxito',
            style: TextStyle(
                color: Theme.of(ctx).colorScheme.primary, fontWeight: FontWeight.bold)),
        content: Text(
            'Contraseña cambiada con éxito. Ahora puede iniciar sesión.',
            style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) Navigator.pushReplacementNamed(context, '/password-changed');
            },
            child: Text('OK',
                style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  // ── resendCode() con cooldown de 60s ─────────────────────────────────── //
  Future<void> _resendCode() async {
    final now = DateTime.now();

    if (_lastResend != null &&
        now.difference(_lastResend!).inSeconds < 60) {
      _showAlert('Espere',
          'Solo se puede enviar un código cada 60 segundos, espere por favor');
      return;
    }

    // TODO: reemplazar con ResetPasswordService.sendVerificationCode(email)
    setState(() => _lastResend = now);
    _showAlert('Éxito', 'Código reenviado a su correo');
  }

  Future<void> _showAlert(String title, String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(title,
            style: TextStyle(
                color: Theme.of(ctx).colorScheme.primary, fontWeight: FontWeight.bold)),
        content: Text(message,
            style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.blanco,
      body: Stack(
        children: [
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
                      _buildLogo(context, cardColor, isDark),
                      const SizedBox(height: 30),
                      _buildCard(
                        context,
                        primaryColor,
                        onPrimaryColor,
                        textSmallColor,
                        dividerColor,
                        isDark,
                      ),
                      const SizedBox(height: 16),

                      // Botón Volver → /auth
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/auth'),
                        child: Text(
                          'Volver',
                          style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
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
    Color? textSmallColor,
    Color dividerColor,
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
            'Introduce Código',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Instrucción (.instruction-message)
          Text(
            'Un código fue mandado a su correo.',
            style: TextStyle(fontSize: 14, color: textSmallColor, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Campo código (.code-input) — centrado, grande, solo números
          Center(
            child: SizedBox(
              width: 200,
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',   // oculta el contador de caracteres
                  hintText: '000000',
                  hintStyle: TextStyle(
                      color: dividerColor,
                      fontSize: 26,
                      letterSpacing: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _onCodeChanged,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón Introducir Código (.btn-primary)
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Introducir Código',
                style: TextStyle(
                    color: onPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Botón Reenviar Código (.btn-secondary — outline)
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _resendCode,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Reenviar Código',
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fondo — mismo CustomPainter que el resto de pantallas de auth
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