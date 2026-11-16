# DiAppBetes

App móvil para personas con diabetes que ayuda a **calcular la dosis orientativa de insulina de cada comida**, registrar glucemias y seguir el tiempo en rango. Desarrollada con Flutter y Firebase.

> **Aviso médico:** DiAppBetes es una herramienta de apoyo y no sustituye el criterio de un profesional sanitario. Las dosis calculadas son orientativas: consulta siempre con tu equipo médico antes de decidir tu tratamiento.

## Qué problema resuelve

Calcular la insulina de una comida exige contar hidratos, recordar ratios que cambian según la hora y hacer cuentas con la glucemia actual. Es lento y propenso a errores. DiAppBetes lo automatiza de forma transparente y con avisos de seguridad.

## Funcionalidades

- **Cálculo de dosis:** `HC ÷ ratio + (glucemia − 110) ÷ FSI`, redondeado a 0,1 U y nunca negativo. Muestra el desglose paso a paso (comida + corrección) y permite ajustar el resultado antes de confirmar.
- **Sin valores por defecto:** si faltan el ratio de hidratos o el factor de sensibilidad, la app pide configurarlos mediante un asistente. Admite varios tramos horarios de ratio.
- **Avisos de seguridad:** hipoglucemia (< 70 mg/dL), valores imposibles y dosis altas.
- **Comidas y alimentos:** base de alimentos, alimentos personalizados, recientes, visualización en raciones (1 ración = 10 g de HC) y escáner de códigos de barras.
- **Glucemias:** registro rápido, historial por fechas y estadísticas de **tiempo en rango (TIR)** con bajas, altas y media.
- **Modo celíaco** que indica los alimentos con gluten.
- **Cuenta y seguridad:** registro con verificación de correo, acceso con usuario o correo, huella dactilar opcional, borrado de cuenta.
- **Personalización:** tema claro y oscuro, texto escalable y etiquetas de accesibilidad.
- **Panel de administración** para gestionar usuarios, configuración y estadísticas.

## Tecnología

| Área | Herramientas |
| --- | --- |
| App | Flutter / Dart (Material 3), `provider`, `fl_chart`, `mobile_scanner`, `local_auth`, `flutter_secure_storage` |
| Backend | Firebase Authentication y Cloud Firestore (plan gratuito Spark, sin Cloud Functions) |
| Seguridad | Reglas de Firestore en [`diappbetes/firestore.rules`](diappbetes/firestore.rules): cada usuario solo accede a sus datos y los topes de valores se validan en el servidor |
| Datos externos | [Open Food Facts](https://world.openfoodfacts.org/) para el escáner de códigos de barras |

## Estructura del repositorio

```
diappbetes/          App Flutter (lib/, test/, android/, firestore.rules)
  lib/screens/       Pantallas
  lib/services/      Lógica: cálculo de dosis, glucemias, TIR, cuenta, etc.
  lib/widgets/       Componentes reutilizables
  functions/         Cloud Functions (requieren plan Blaze; no se usan en producción)
  diapp-email-worker/ Worker de Cloudflare auxiliar
PRIVACY_POLICY.md    Política de privacidad
```

## Puesta en marcha

Requisitos: Flutter (SDK ^3.7), un proyecto de Firebase y, para Android, el SDK de Android.

```bash
git clone https://github.com/GuillermoBR24/DiAppBetes-Flutter.git
cd DiAppBetes-Flutter/diappbetes
flutter pub get
flutter run
```

Configura tu propio proyecto de Firebase (`flutterfire configure`) y despliega las reglas:

```bash
firebase deploy --only firestore:rules
```

## Pruebas

```bash
flutter analyze
flutter test
```

Las pruebas unitarias cubren el cálculo de dosis, los límites de glucemia, el tiempo en rango y las utilidades de usuario.

## Publicación en Android

La firma de release se lee de `android/key.properties` (usa `android/key.properties.example` como plantilla). Nunca subas el keystore ni ese archivo al repositorio.

```bash
flutter build appbundle --release
```

## Estado del proyecto

Prototipo funcional (MVP) en fase de validación. No es un producto sanitario certificado ni se ha validado clínicamente.

## Privacidad

Consulta la [política de privacidad](PRIVACY_POLICY.md). Los datos de salud se guardan en Firebase y no se usan para publicidad ni se ceden a terceros.

## Créditos

- Datos de productos: © colaboradores de [Open Food Facts](https://world.openfoodfacts.org/), bajo licencia ODbL.

## Licencia

Pendiente de definir. Mientras no se añada un archivo `LICENSE`, todos los derechos están reservados.
