import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Color de texto/icono (blanco o casi negro) con mayor contraste sobre `bg`.
/// Los tonos suaves de la marca (verde, ámbar, rojo, azul claro del modo
/// oscuro) no llegan a contraste legible con texto blanco.
Color onColor(Color bg) {
  final l = bg.computeLuminance();
  final white = 1.05 / (l + 0.05);
  final dark = (l + 0.05) / 0.06; // contra #1B1B1B (luminancia ≈ 0.01)
  return white >= dark ? Colors.white : const Color(0xFF1B1B1B);
}

/// Mensajes breves y no bloqueantes con el estilo de la app
/// (flotantes, bordes redondeados, icono y colores de marca).
///
/// Úsalos para confirmaciones y avisos leves. Para errores que implican que
/// algo NO se guardó o que el usuario debe actuar, usa [AppDialog].
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.verdesuave, Icons.check_circle_rounded);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.rojoSuave, Icons.error_rounded);

  static void info(BuildContext context, String message) =>
      _show(context, message, Theme.of(context).colorScheme.primary, Icons.info_rounded);

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          elevation: 4,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: onColor(color), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: onColor(color),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Diálogos con la misma cabecera de color que el resto de modales de la app.
class AppDialog {
  AppDialog._();

  static Future<void> error(
    BuildContext context, {
    String title = 'Ha ocurrido un error',
    required String message,
  }) =>
      _show(context, title, message, AppColors.rojoSuave, Icons.error_rounded);

  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
  }) =>
      _show(context, title, message, Theme.of(context).colorScheme.primary, Icons.info_rounded);

  /// Aviso importante que pide una decisión. Devuelve true si el usuario
  /// elige continuar (`confirmLabel`), false si elige `cancelLabel` o cierra.
  static Future<bool> warnConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Continuar',
    String cancelLabel = 'Corregir',
  }) async {
    final card = Theme.of(context).cardColor;
    final text = Theme.of(context).textTheme.bodyLarge?.color;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.ambarSuave,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: onColor(AppColors.ambarSuave), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: TextStyle(
                            color: onColor(AppColors.ambarSuave),
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(message, style: TextStyle(fontSize: 15, height: 1.4, color: text)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(ctx).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(cancelLabel,
                          style: TextStyle(
                              color: Theme.of(ctx).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(ctx).dividerColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(confirmLabel, style: TextStyle(color: text)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// Aviso informativo de seguridad (color ámbar), p. ej. tras una glucemia baja.
  static Future<void> warn(
    BuildContext context, {
    required String title,
    required String message,
  }) =>
      _show(context, title, message, AppColors.ambarSuave, Icons.warning_amber_rounded);

  static Future<void> _show(
    BuildContext context,
    String title,
    String message,
    Color color,
    IconData icon,
  ) {
    final card = Theme.of(context).cardColor;
    final text = Theme.of(context).textTheme.bodyLarge?.color;

    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: onColor(color), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: onColor(color),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(message, style: TextStyle(fontSize: 15, height: 1.4, color: text)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Entendido',
                    style: TextStyle(color: onColor(color), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convierte cualquier excepción en un mensaje comprensible para el usuario.
/// Nunca se debe mostrar `e.toString()` en pantalla.
String friendlyError(Object error) {
  if (error is FirebaseAuthException) return AuthService.translateError(error);
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'No tienes permiso para realizar esta acción.';
      case 'unavailable':
      case 'network-request-failed':
        return 'No se pudo conectar con el servidor. Comprueba tu conexión.';
      case 'deadline-exceeded':
        return 'El servidor tarda demasiado en responder. Inténtalo de nuevo.';
      case 'not-found':
        return 'No se encontró el dato solicitado.';
    }
  }
  return 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
}
