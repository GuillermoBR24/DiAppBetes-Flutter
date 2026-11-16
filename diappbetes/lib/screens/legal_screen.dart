import 'package:flutter/material.dart';
import '../widgets/medical_disclaimer.dart';

/// Aviso médico y política de privacidad (también publicada en
/// PRIVACY_POLICY.md para la ficha de Google Play). Mantener ambos iguales.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  /// Correo de contacto para ejercer derechos RGPD. Sustitúyelo antes de publicar.
  static const String contactEmail = 'diappbetes0@gmail.com';

  static const List<(String, String)> _sections = [
    ('Responsable',
        'DiAppBetes. Contacto: $contactEmail.'),
    ('Datos que tratamos',
        'Cuenta (correo, nombre de usuario), perfil (nombre, foto opcional, '
        'rol), datos de salud que introduces tú (glucemias, comidas, '
        'raciones, dosis de insulina, ratio de hidratos y factor de '
        'sensibilidad) y preferencias de la app.'),
    ('Para qué los usamos',
        'Únicamente para ofrecer las funciones de la app: calcular dosis '
        'orientativas, mostrar tu historial y estadísticas. No usamos tus '
        'datos para publicidad ni los vendemos o cedemos a terceros.'),
    ('Dónde se guardan',
        'En Google Firebase (Authentication y Cloud Firestore), con '
        'comunicaciones cifradas. Cada usuario solo puede leer sus propios '
        'datos; los administradores acceden únicamente a lo necesario para '
        'gestionar la app. Los datos de la huella (si la activas) '
        'permanecen en tu dispositivo, en almacenamiento seguro.'),
    ('Permisos',
        'Cámara: solo para escanear códigos de barras. Biometría: solo para '
        'iniciar sesión con huella si lo activas.'),
    ('Conservación y borrado',
        'Conservamos tus datos mientras tengas cuenta. Puedes eliminarla '
        'desde Ajustes: se borran tu perfil y tus registros.'),
    ('Tus derechos',
        'Puedes acceder, rectificar y suprimir tus datos desde la app, o '
        'escribirnos para ejercer cualquier derecho (acceso, portabilidad, '
        'oposición, limitación).'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppBar(title: const Text('Aviso legal y privacidad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const MedicalDisclaimer(),
            ),
            const SizedBox(height: 20),
            Text('Política de privacidad',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 12),
            for (final s in _sections) ...[
              Text(s.$1,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text(s.$2,
                  style: TextStyle(fontSize: 14, height: 1.4, color: textColor)),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
