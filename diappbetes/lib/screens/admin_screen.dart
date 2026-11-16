import 'package:diappbetes/screens/admin_config_screen.dart';
import 'package:diappbetes/screens/admin_stats_screen.dart';
import 'package:diappbetes/screens/admin_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:diappbetes/utils/admin_nav_helper.dart';
import 'package:diappbetes/widgets/app_feedback.dart';
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
        _isAuthorized = AdminNavHelper.isAdminRole(role);
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
          _errorMessage = 'No se pudieron verificar tus permisos. ${friendlyError(e)}';
        });
        _redirect();
      }
    }
  }

  void _redirect() {
    if (!mounted) return;
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/settings');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          title: Text('Admin',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor, 
                fontWeight: FontWeight.bold,
              )),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, 
                color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          title: Text('Acceso Denegado',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor, 
                fontWeight: FontWeight.bold,
              )),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, 
                color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: AppColors.rojoSuave),
                const SizedBox(height: 24),
                Text(
                  '🔒 Acceso Restringido',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage.isNotEmpty 
                      ? _errorMessage 
                      : 'Esta área está reservada para administradores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver a Mi Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: onPrimaryColor,
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: Text('Administración',
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor, 
              fontWeight: FontWeight.bold,
            )),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor, 
                      fontSize: 14,
                    )),
              );
            },
          ),
        ],
      ),
      body: _buildAdminContent(primaryColor, onPrimaryColor, textColor, textSmallColor, isDark),
    );
  }

  Widget _buildAdminContent(
    Color primaryColor, 
    Color onPrimaryColor, 
    Color? textColor, 
    Color? textSmallColor,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.azulFondo, const Color(0xFF2E5C8A)]
                    : [AppColors.azulFondo, const Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bienvenido, Administrador',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                      SizedBox(height: 4),
                      Text('Gestiona usuarios, contenido y configuración',
                          style: TextStyle(
                            color: Colors.white70,
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

          Text('Funcionalidades',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              )),
          const SizedBox(height: 16),

          _buildPlaceholderCard(
            icon: Icons.people_outline,
            title: 'Gestión de Usuarios',
            subtitle: 'Próximamente: Ver, editar y eliminar usuarios',
            primaryColor: primaryColor,
            textColor: textColor,
            textSmallColor: textSmallColor,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminUsersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.analytics_outlined,
            title: 'Estadísticas',
            subtitle: 'Métricas y reportes de uso',
            primaryColor: primaryColor,
            textColor: textColor,
            textSmallColor: textSmallColor,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminStatsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildPlaceholderCard(
            icon: Icons.settings_outlined,
            title: 'Configuración Global',
            subtitle: 'Próximamente: Ajustes de la aplicación',
            primaryColor: primaryColor,
            textColor: textColor,
            textSmallColor: textSmallColor,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminConfigScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Este panel está en desarrollo. Las funcionalidades estarán disponibles próximamente.',
                    style: TextStyle(
                      color: primaryColor,
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

  Widget _buildPlaceholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required Color? textColor,
    required Color? textSmallColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3) 
                  : Colors.black.withValues(alpha: 0.05),
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
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSmallColor,
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, 
                color: textSmallColor?.withValues(alpha: 0.5), size: 16),
          ],
        ),
      )
    );
  }
}