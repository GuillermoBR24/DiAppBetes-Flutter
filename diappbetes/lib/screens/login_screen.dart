// lib/screens/login_screen.dart
import 'package:diappbetes/services/biometric_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/maintenance_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController   = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _maintenanceService = MaintenanceService();

  String _error = '';
  bool _obscurePassword = true;
  bool _loading = false;
  bool _biometricEnabled = false;
  bool _useBiometric = false;
  bool _rememberMe = false; // ── "Recuérdame" ──────────────────────────── //
  final _biometricService = BiometricService();

  @override 
  void initState() {
    super.initState();
    _checkBiometricLogin();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.rojoSuave : AppColors.verdesuave,
    ));
  }

  void _clearError() => setState(() => _error = '');

  // ── Login con verificación de modo mantenimiento ──────────────────────── //
  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = ''; _loading = true; });

    try {
      print('\n═══════════════════════════════════════════════════════');
      print('🔐 [LOGIN] Iniciando proceso de login');
      print('═══════════════════════════════════════════════════════');
      print('🔍 [LOGIN] Intentando login con: ${_identifierController.text.trim()}');
      print('🔍 [LOGIN] Recuérdame: $_rememberMe');
      
      await _authService.login(
        identifier: _identifierController.text.trim(),
        password:   _passwordController.text,
        rememberMe: _rememberMe,
      );
      
      print('✅ [LOGIN] Login exitoso con Firebase Auth');
      print('👤 [LOGIN] Usuario autenticado: ${FirebaseAuth.instance.currentUser?.uid}');
      
      final maintenanceMsg = await _maintenanceService.checkMaintenanceMode();
      
      print('\n🔍 [LOGIN] Resultado de checkMaintenanceMode(): ${maintenanceMsg ?? "null (PERMITIR)"}');
      
      if (maintenanceMsg != null) {
        print('🚫 [LOGIN] BLOQUEADO por modo mantenimiento');
        print('🚫 [LOGIN] Mensaje: $maintenanceMsg');
        print('📡 [LOGIN] Cerrando sesión...');
        
        await FirebaseAuth.instance.signOut();
        
        print('✅ [LOGIN] Sesión cerrada');
        
        if (!mounted) return;
        setState(() => _loading = false);
        
        print('📱 [LOGIN] Mostrando diálogo de mantenimiento...');
        _showMaintenanceDialog(maintenanceMsg);
        print('═══════════════════════════════════════════════════════\n');
        return;
      }
      
      print('✅ [LOGIN] Todo OK - Redirigiendo al home');
      print('═══════════════════════════════════════════════════════\n');
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
      
    } on FirebaseAuthException catch (e) {
      print('❌ [LOGIN] FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() => _error = AuthService.translateError(e));
      
    } catch (e, stackTrace) {
      print('❌ [LOGIN] ERROR GENERAL: $e');
      print('📋 [LOGIN] STACK TRACE: $stackTrace');
      setState(() => _error = 'Error: ${e.toString()}');
      
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  // ── Verificar si puede usar login biométrico ─────────────────────────── //
  // NOTA: en LoginScreen aún no hay sesión de Firebase activa, así que no
  // comparamos con currentUserId — solo comprobamos si HAY un usuario con
  // biometría activada guardada en este dispositivo (getUserId() != null).
  Future<void> _checkBiometricLogin() async {
    final canUse      = await _biometricService.canCheckBiometrics();
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled    = await _biometricService.isEnabled();
    final savedUserId  = await _biometricService.getUserId();

    if (mounted) {
      setState(() {
        _biometricEnabled = canUse && isAvailable && isEnabled && savedUserId != null;
        _useBiometric = _biometricEnabled;
      });

      // Si hay credenciales guardadas, ofrece login automático con huella
      if (_useBiometric) {
        await _loginWithBiometric();
      }
    }
  }

  // ── Login con huella ─────────────────────────────────────────────────── //
  // Usa las credenciales (email/password) guardadas de forma segura por
  // BiometricService tras verificar la huella, y hace el login normal
  // de Firebase con ellas.
  Future<void> _loginWithBiometric() async {
    setState(() => _loading = true);

    try {
      final authenticated = await _biometricService.authenticate();

      if (!mounted) return;

      if (!authenticated) {
        setState(() => _loading = false);
        _showSnack('Autenticación cancelada', isError: true);
        return;
      }

      final creds = await _biometricService.getCredentials();
      if (creds == null || creds['email'] == null || creds['password'] == null) {
        setState(() => _loading = false);
        _showSnack('No hay credenciales guardadas para huella', isError: true);
        return;
      }

      // Login real con Firebase usando las credenciales guardadas.
      // "rememberMe: true" porque si activó huella, asumimos que quiere
      // sesión persistente en este dispositivo.
      await _authService.login(
        identifier: creds['email']!,
        password:   creds['password']!,
        rememberMe: true,
      );

      if (!mounted) return;

      final maintenanceMsg = await _maintenanceService.checkMaintenanceMode();
      if (maintenanceMsg != null) {
        await FirebaseAuth.instance.signOut();
        setState(() => _loading = false);
        _showMaintenanceDialog(maintenanceMsg);
        return;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(AuthService.translateError(e), isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('Error en autenticación: $e', isError: true);
      }
    }
  }

  // ── Diálogo de modo mantenimiento ─────────────────────────────────────── //
  void _showMaintenanceDialog(String message) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.ambarSuave.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.build, color: AppColors.ambarSuave, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Modo Mantenimiento',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.ambarSuave.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ambarSuave.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 40, color: AppColors.ambarSuave),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: onPrimaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
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
                      _buildLoginCard(
                        context,
                        primaryColor,
                        onPrimaryColor,
                        textColor,
                        textSmallColor,
                        dividerColor,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                        child: Text('Volver',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            )),
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
      padding: const EdgeInsets.all(10),
      child: Image.asset('assets/LogoDiAppBetes.png', fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.medical_services_rounded, 
            size: 100, 
            color: Theme.of(context).colorScheme.primary,
          )),
    );
  }

  Widget _buildLoginCard(
    BuildContext context,
    Color primaryColor,
    Color onPrimaryColor,
    Color? textColor,
    Color? textSmallColor,
    Color dividerColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Login',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: primaryColor,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // Email / Usuario
            TextFormField(
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textColor, fontSize: 15),
              onChanged: (_) => _clearError(),
              decoration: _inputDeco('Email o Usuario', primaryColor, textSmallColor, dividerColor),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),

            // Contraseña
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: textColor, fontSize: 15),
              onChanged: (_) => _clearError(),
              decoration: _inputDeco('Contraseña', primaryColor, textSmallColor, dividerColor).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: textSmallColor, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
            ),

            // ── Checkbox "Recuérdame" ────────────────────────────────── //
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        activeColor: primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recuérdame',
                        style: TextStyle(color: textColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_error,
                  style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),

            // Botón Login con contraseña
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: onPrimaryColor, strokeWidth: 2))
                    : Text('Login',
                        style: TextStyle(
                          color: onPrimaryColor, 
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                        )),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // ✅ Botón de huella dactilar (si está disponible)
            if (_biometricEnabled) ...[
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loginWithBiometric,
                  icon: Icon(Icons.fingerprint, color: primaryColor, size: 24),
                  label: Text('Iniciar con huella',
                      style: TextStyle(
                        color: primaryColor, 
                        fontSize: 16, 
                        fontWeight: FontWeight.w600,
                      )),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('o usa tu huella dactilar',
                  style: TextStyle(color: textSmallColor, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
            
            const SizedBox(height: 16),

            // ¿Olvidaste tu contraseña?
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/remember-password'),
              child: Text('¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: primaryColor, 
                    fontSize: 13, 
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
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

class _BackgroundPainter extends CustomPainter {
  final Color color;

  _BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRRect(RRect.fromLTRBAndCorners(0, -size.height * 0.30, size.width, size.height * 0.50,
        bottomLeft: const Radius.circular(25), bottomRight: const Radius.circular(25)), paint);
  }
  
  @override 
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => 
      oldDelegate.color != color;
}