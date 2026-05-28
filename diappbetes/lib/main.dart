import 'package:diappbetes/firebase_options.dart';
import 'package:diappbetes/screens/add_meal_screen.dart';
import 'package:diappbetes/screens/auth_screen.dart';
import 'package:diappbetes/screens/code_verification_screen.dart';
import 'package:diappbetes/screens/login_screen.dart';
import 'package:diappbetes/screens/password_changed_screen.dart';
import 'package:diappbetes/screens/register_screen.dart';
import 'package:diappbetes/screens/remember_password_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:diappbetes/screens/historial_screen.dart';
import 'package:diappbetes/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DiAppBetes());
}

class DiAppBetes extends StatelessWidget {
  const DiAppBetes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiAppBetes',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const _AuthWrapper(),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (fallback)
      ],
      locale: const Locale('es', 'ES'),
      
      routes: {
        '/auth':      (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/login':          (context) => const LoginScreen(),
        '/register':       (context) => const RegisterScreen(),
        '/historial':      (context) => const HistorialScreen(),
        '/add-meal':       (context) => const AddMealScreen(),
        '/settings':       (context) => const SettingsScreen(),
        '/code-verify':    (context) => const CodeVerificationScreen(),
        '/password-changed':(context) => const PasswordChangedScreen(),
        '/remember-password':(context) => const RememberPasswordScreen(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _AuthWrapper — escucha el estado de sesión de Firebase y redirige
// Equivalente al AuthGuard de Angular/Ionic
// ---------------------------------------------------------------------------
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.azulFondo),
            ),
          );
        }
        // Usuario logueado → Home
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        // No logueado → pantalla de bienvenida
        return const AuthScreen();
      },
    );
  }
}