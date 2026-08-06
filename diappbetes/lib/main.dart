import 'package:diappbetes/firebase_options.dart';
import 'package:diappbetes/screens/add_meal_screen.dart';
import 'package:diappbetes/screens/admin_screen.dart';
import 'package:diappbetes/screens/auth_screen.dart';
import 'package:diappbetes/screens/glucose_history_screen.dart';
import 'package:diappbetes/screens/login_screen.dart';
import 'package:diappbetes/screens/register_screen.dart';
import 'package:diappbetes/screens/remember_password_screen.dart';
import 'package:diappbetes/screens/scanner_screen.dart';
import 'package:diappbetes/services/remember_me_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:diappbetes/screens/historial_screen.dart';
import 'package:diappbetes/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const DiAppBetes(),
    ),
  );
}

class DiAppBetes extends StatelessWidget {
  const DiAppBetes({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'DiAppBetes',
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  themeProvider.mode,
      debugShowCheckedModeBanner: false,
      home: const _AuthWrapper(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      routes: {
        '/auth':              (context) => const AuthScreen(),
        '/home':              (context) => const HomeScreen(),
        '/login':             (context) => const LoginScreen(),
        '/register':          (context) => const RegisterScreen(),
        '/historial':         (context) => const HistorialScreen(),
        '/add-meal':          (context) => const AddMealScreen(),
        '/settings':          (context) => const SettingsScreen(),
        '/remember-password': (context) => const RememberPasswordScreen(),
        '/scanner':           (context) => const ScannerScreen(),
        '/admin':             (context) => const AdminScreen(),
        '/glucose-history':   (context) => const GlucoseHistoryScreen(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _AuthWrapper — escucha el estado de sesión de Firebase y aplica la
// lógica de "Recuérdame": si el usuario no marcó la opción y ha pasado
// el tiempo límite de inactividad, fuerza el cierre de sesión y manda
// a /auth en lugar de /home, aunque Firebase aún tenga el token guardado.
// ---------------------------------------------------------------------------
class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> with WidgetsBindingObserver {
  final _rememberMeService = RememberMeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Cada vez que la app vuelve a primer plano, refresca la marca de actividad
  // (solo importa si "Recuérdame" no está activo; si lo está, no afecta).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rememberMeService.touchActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.azulFondo),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Hay sesión de Firebase activa — comprobamos si debe expirar
          // por inactividad cuando "Recuérdame" no estaba marcado.
          return FutureBuilder<bool>(
            future: _rememberMeService.shouldExpireSession(),
            builder: (context, expireSnap) {
              if (!expireSnap.hasData) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.azulFondo),
                  ),
                );
              }

              if (expireSnap.data == true) {
                // Sesión expirada por inactividad: cerrar y mandar a /auth
                FirebaseAuth.instance.signOut();
                _rememberMeService.clear();
                return const AuthScreen();
              }

              // Sesión válida: refresca la marca de actividad y entra
              _rememberMeService.touchActivity();
              return const HomeScreen();
            },
          );
        }

        return const AuthScreen();
      },
    );
  }
}