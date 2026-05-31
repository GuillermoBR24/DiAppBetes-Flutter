import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _loading = true;
  bool _isAuthorized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  /// Verifica si el usuario tiene rol de administrador en Firestore
  Future<void> _checkAdminRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        setState(() {
          _loading = false;
          _isAuthorized = false;
          _errorMessage = 'No hay usuario autenticado';
        });
        _redirect();
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        setState(() {
          _loading = false;
          _isAuthorized = false;
          _errorMessage = 'Perfil no encontrado';
        });
        _redirect();
        return;
      }

      final role = doc.data()?['role']?.toString().toLowerCase() ?? '';
      
      setState(() {
        _loading = false;
        _isAuthorized = role == 'administrador' || role == 'admin';
        if (!_isAuthorized) {
          _errorMessage = 'Acceso denegado: Se requieren permisos de administrador';
        }
      });

      if (!_isAuthorized) {
        _redirect();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _isAuthorized = false;
          _errorMessage = 'Error al verificar permisos: ${e.toString()}';
        });
        _redirect();
      }
    }
  }

  /// Redirige al usuario no autorizado
  void _redirect() {
    if (!mounted) return;
    
    // Pequeño delay para mostrar mensaje de error si existe
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/settings');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mientras verifica permisos
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.blanco,
        appBar: AppBar(
          backgroundColor: AppColors.azulFondo,
          title: const Text('Admin',
              style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.azulFondo),
        ),
      );
    }

    // Si no está autorizado, muestra pantalla de acceso denegado
    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: AppColors.blanco,
        appBar: AppBar(
          backgroundColor: AppColors.azulFondo,
          title: const Text('Acceso Denegado',
              style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: AppColors.rojoSuave),
                const SizedBox(height: 24),
                Text(
                  '🔒 Acceso Restringido',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulFondo,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage.isNotEmpty 
                      ? _errorMessage 
                      : 'Esta área está reservada para administradores.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.grisTexto),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver a Mi Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulFondo,
                    foregroundColor: AppColors.blanco,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ Usuario autorizado: muestra el panel de administración (vacío por ahora)
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        backgroundColor: AppColors.azulFondo,
        title: const Text('Administración',
            style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Opcional: mostrar info del admin
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('profiles')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final username = data?['username'] ?? 'Admin';
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('👤 $username',
                    style: const TextStyle(color: AppColors.blanco, fontSize: 14)),
              );
            },
          ),
        ],
      ),
      body: _buildAdminContent(),
    );
  }

  /// Contenido del panel de administración (placeholder para futuras funcionalidades)
  Widget _buildAdminContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.azulFondo, Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.azulFondo.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blanco.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, 
                      color: AppColors.blanco, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bienvenido, Administrador',
                          style: TextStyle(
                            color: AppColors.blanco,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                      SizedBox(height: 4),
                      Text('Gestiona usuarios, contenido y configuración',
                          style: TextStyle(
                            color: AppColors.blanco,
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección: Funcionalidades (placeholder)
          const Text('Funcionalidades',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.azulFondo,
              )),
          const SizedBox(height: 16),

          // Tarjeta placeholder para futuras opciones
          _buildPlaceholderCard(
            icon: Icons.people_outline,
            title: 'Gestión de Usuarios',
            subtitle: 'Próximamente: Ver, editar y eliminar usuarios',
          ),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.analytics_outlined,
            title: 'Estadísticas',
            subtitle: 'Próximamente: Métricas y reportes de uso',
          ),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.settings_outlined,
            title: 'Configuración Global',
            subtitle: 'Próximamente: Ajustes de la aplicación',
          ),

          const SizedBox(height: 32),

          // Nota informativa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.azulFondo.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.azulFondo, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Este panel está en desarrollo. Las funcionalidades estarán disponibles próximamente.',
                    style: TextStyle(
                      color: AppColors.azulFondo,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar para tarjetas placeholder
  Widget _buildPlaceholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grisDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.azulFondo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.azulFondo, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.azulFondo,
                    )),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grisTexto,
                    )),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, 
              color: AppColors.grisTexto.withOpacity(0.5), size: 16),
        ],
      ),
    );
  }
}