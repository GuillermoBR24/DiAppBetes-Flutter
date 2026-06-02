// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../utils/admin_nav_helper.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onSettingsPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.onSettingsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminNavHelper.getIsAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;
        
        return AppBar(
          automaticallyImplyLeading: showBackButton,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          titleSpacing: 0,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/favicon.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => 
                        Icon(Icons.image_not_supported, 
                            color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 20,
                  )),
            ],
          ),
          actions: [
            // Icono de escáner (solo si no hay acciones personalizadas)
            if (actions == null)
              IconButton(
                icon: Icon(Icons.qr_code_scanner, 
                    color: Theme.of(context).appBarTheme.foregroundColor),
                onPressed: () => Navigator.pushNamed(context, '/scanner'), // ← CAMBIO: pushNamed
              ),
            
            // Icono de admin (solo si es admin y no hay acciones personalizadas)
            if (isAdmin && actions == null)
              IconButton(
                icon: Icon(Icons.admin_panel_settings, 
                    color: Theme.of(context).appBarTheme.foregroundColor),
                onPressed: () => Navigator.pushNamed(context, '/admin'), // ← CAMBIO: pushNamed
              ),
            
            // Icono de settings (solo si no hay acciones personalizadas)
            if (actions == null)
              IconButton(
                icon: Icon(Icons.settings, 
                    color: Theme.of(context).appBarTheme.foregroundColor),
                onPressed: onSettingsPressed ?? () => Navigator.pushNamed(context, '/settings'),
              ),
            
            // Acciones personalizadas
            if (actions != null) ...actions!,
          ],
        );
      },
    );
  }
}