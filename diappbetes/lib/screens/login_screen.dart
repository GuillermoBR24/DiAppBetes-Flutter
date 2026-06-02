// lib/screens/login_screen.dart
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

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      
      // 1. Login exitoso con Firebase Auth
      print('📡 [LOGIN] Llamando a _authService.login()...');
      await _authService.login(
        identifier: _identifierController.text.trim(),
        password:   _passwordController.text,
      );
      
      print('✅ [LOGIN] Login exitoso con Firebase Auth');
      print('👤 [LOGIN] Usuario autenticado: ${FirebaseAuth.instance.currentUser?.uid}');
      
      // 2. ✅ Login OK - Ahora verificar modo mantenimiento
      print('\n🔧 [LOGIN] Verificando modo mantenimiento...');
      final maintenanceMsg = await _maintenanceService.checkMaintenanceMode();
      
      print('\n🔍 [LOGIN] Resultado de checkMaintenanceMode(): ${maintenanceMsg ?? "null (PERMITIR)"}');
      
      if (maintenanceMsg != null) {
        // ❌ Modo mantenimiento activo y usuario NO es admin
        print('🚫 [LOGIN] BLOQUEADO por modo mantenimiento');
        print('🚫 [LOGIN] Mensaje: $maintenanceMsg');
        print('📡 [LOGIN] Cerrando sesión...');
        
        await FirebaseAuth.instance.signOut(); // Cerrar sesión
        
        print('✅ [LOGIN] Sesión cerrada');
        
        if (!mounted) return;
        setState(() => _loading = false);
        
        print('📱 [LOGIN] Mostrando diálogo de mantenimiento...');
        _showMaintenanceDialog(maintenanceMsg);
        print('═══════════════════════════════════════════════════════\n');
        return;
      }
      
      // ✅ Todo OK - Redirigir al home
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

  // ── Diálogo de modo mantenimiento ─────────────────────────────────────── //
  void _showMaintenanceDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.blanco,
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
                  color: AppColors.azulFondo,
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
                    style: const TextStyle(
                      color: AppColors.grisTexto,
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
                Navigator.pop(ctx); // Cerrar diálogo
                // Se queda en la pantalla de login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulFondo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  color: AppColors.blanco,
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

    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Stack(
        children: [
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
                      _buildLogo(),
                      const SizedBox(height: 30),
                      _buildLoginCard(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                        child: const Text('Volver',
                            style: TextStyle(color: AppColors.azulFondo, fontSize: 14, fontWeight: FontWeight.w500)),
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
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset('assets/LogoDiAppBetes.png', fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.medical_services_rounded, size: 100, color: AppColors.azulFondo)),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Login',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // Email / Usuario
            TextFormField(
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
              onChanged: (_) => _clearError(),
              decoration: _inputDeco('Email o Usuario'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),

            // Contraseña
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
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
            ),

            // Error
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error,
                  style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),

            // Botón Login
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulFondo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: AppColors.blanco, strokeWidth: 2))
                    : const Text('Login',
                        style: TextStyle(color: AppColors.blanco, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),

            // ¿Olvidaste tu contraseña?
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/remember-password'),
              child: const Text('¿Olvidaste tu contraseña?',
                  style: TextStyle(color: AppColors.azulFondo, fontSize: 13, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
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

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.azulFondo;
    canvas.drawRRect(RRect.fromLTRBAndCorners(0, -size.height * 0.30, size.width, size.height * 0.50,
        bottomLeft: const Radius.circular(25), bottomRight: const Radius.circular(25)), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}