import 'package:flutter/material.dart';

/// Estado vacío: icono, título, explicación y (opcional) una acción.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final textSmall = Theme.of(context).textTheme.bodySmall?.color;

    return Semantics(
      container: true,
      label: message == null ? title : '$title. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: primary),
                ),
              ),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor)),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4, color: textSmall)),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(actionLabel!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
