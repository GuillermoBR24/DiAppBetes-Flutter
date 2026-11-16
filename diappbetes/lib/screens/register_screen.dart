import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:diappbetes/widgets/app_feedback.dart';
import '../theme/app_theme.dart';
import 'legal_screen.dart';
import '../services/auth_service.dart';
import '../services/password_validation_service.dart';

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
  final _passwordValidationService = PasswordValidationService();

  String _error = '';
  bool _obscurePassword = true;
  bool _loading = false;
  bool _registered = false;
  
  bool _requireStrongPassword = true;
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadPasswordConfig();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadPasswordConfig() async {
    final requireStrong = await _passwordValidationService.isStrongPasswordRequired();
    if (mounted) {
      setState(() {
        _requireStrongPassword = requireStrong;
        _loadingConfig = false;
      });
    }
  }

  void _clearError() => setState(() => _error = '');

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    final passwordError = await _passwordValidationService.validatePassword(
      _passwordController.text,
    );
    
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }
    
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
    final maxDate = now.subtract(const Duration(days: 365 * 12));

    final picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      locale: const Locale('es', 'ES'),
      helpText: 'Selecciona tu fecha de nacimiento',
    );

    if (picked != null && mounted) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _resendVerification() async {
    setState(() { _error = ''; _loading = true; });
    try {
      await _authService.resendVerificationEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        AppToast.success(context, 'Correo de verificación reenviado');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.translateError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    if (password.isEmpty) return const SizedBox.shrink();
    
    int strength = 0;
    
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]').hasMatch(password)) strength++;

    Color color;
    String label;
    
    switch (strength) {
      case 0:
      case 1:
        color = AppColors.rojoSuave;
        label = 'Muy débil';
        break;
      case 2:
        color = AppColors.rojoSuave;
        label = 'Débil';
        break;
      case 3:
        color = AppColors.ambarSuave;
        label = 'Media';
        break;
      case 4:
        color = AppColors.ambarSuave;
        label = 'Buena';
        break;
      case 5:
        color = AppColors.verdesuave;
        label = 'Fuerte';
        break;
      default:
        color = AppColors.grisTexto;
        label = '';
    }

    final dividerColor = Theme.of(context).dividerColor;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: index < strength ? color : dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (strength < 5)
              Text(
                _getMissingRequirements(password),
                style: TextStyle(color: textSmallColor, fontSize: 12),
              ),
          ],
        ),
      ],
    );
  }

  String _getMissingRequirements(String password) {
    final missing = <String>[];
    
    if (password.length < 8) missing.add('8+ car.');
    if (!RegExp(r'[A-Z]').hasMatch(password)) missing.add('A-Z');
    if (!RegExp(r'[a-z]').hasMatch(password)) missing.add('a-z');
    if (!RegExp(r'[0-9]').hasMatch(password)) missing.add('0-9');
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]').hasMatch(password)) missing.add('!@#');
    
    if (missing.isEmpty) return '';
    return 'Falta: ${missing.join(' ')}';
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
                      _registered 
                          ? _buildVerifyCard(
                              context,
                              primaryColor,
                              onPrimaryColor,
                              textColor,
                              textSmallColor,
                              isDark,
                            ) 
                          : _buildRegisterCard(
                              context,
                              primaryColor,
                              onPrimaryColor,
                              textColor,
                              textSmallColor,
                              dividerColor,
                              isDark,
                            ),
                      const SizedBox(height: 16),
                      if (!_registered)
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/auth'),
                          child: Text('Volver',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LegalScreen()),
                        ),
                        child: Text('Aviso legal y privacidad',
                            style: TextStyle(color: primaryColor, fontSize: 12)),
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
      width: 160, height: 160,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
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

  Widget _buildRegisterCard(
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
            Text('Registro',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: primaryColor,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textColor, fontSize: 15),
              onChanged: (_) => _clearError(),
              decoration: _inputDeco('Email', primaryColor, textSmallColor, dividerColor),
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
              style: TextStyle(color: textColor, fontSize: 15),
              onChanged: (_) {
                _clearError();
                setState(() {});
              },
              decoration: _inputDeco('Contraseña', primaryColor, textSmallColor, dividerColor).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: textSmallColor, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                helperText: _loadingConfig 
                    ? null 
                    : (_requireStrongPassword 
                        ? 'Mín. 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 símbolo'
                        : 'Mínimo 6 caracteres'),
                helperStyle: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obligatorio';
                if (_requireStrongPassword) {
                  if (v.length < 8) return 'Mínimo 8 caracteres';
                } else {
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                }
                return null;
              },
            ),
            
            if (_requireStrongPassword && _passwordController.text.isNotEmpty)
              _buildPasswordStrengthIndicator(_passwordController.text),
            
            const SizedBox(height: 16),

            TextFormField(
              controller: _birthDateController,
              readOnly: true,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: _inputDeco('Fecha de nacimiento', primaryColor, textSmallColor, dividerColor).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today, color: textSmallColor, size: 20),
                  onPressed: _selectBirthDate,
                ),
                hintText: 'YYYY-MM-DD',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
                  return 'Formato: YYYY-MM-DD';
                }
                return null;
              },
              onTap: _selectBirthDate,
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
                onPressed: (_loading || _loadingConfig) ? null : _onRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: (_loading || _loadingConfig)
                    ? SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: onPrimaryColor, strokeWidth: 2))
                    : Text('Registrarse',
                        style: TextStyle(
                          color: onPrimaryColor, 
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyCard(
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
          Center(
            child: Icon(Icons.mark_email_unread_rounded,
                size: 72, color: primaryColor),
          ),
          const SizedBox(height: 16),

          Text('¡Verifica tu correo!',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: primaryColor,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
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
            'Hemos enviado un correo de verificación.\nHaz clic en el enlace del correo para activar tu cuenta.\n\nSi no lo ves, revisa la carpeta de spam.',
            style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Ir al Inicio de Sesión',
                  style: TextStyle(
                    color: onPrimaryColor, 
                    fontSize: 15, 
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _resendVerification,
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
                ? Colors.black.withValues(alpha: 0.3)
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
      0, -size.height * 0.35, size.width, size.height * 0.45,
      bottomLeft: const Radius.circular(25), bottomRight: const Radius.circular(25),
    ), paint);
  }
  
  @override 
  bool shouldRepaint(covariant _BgPainter oldDelegate) => 
      oldDelegate.color != color;
}