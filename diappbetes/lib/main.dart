import 'package:diappbetes/screens/add_meal_screen.dart';
import 'package:diappbetes/screens/auth_screen.dart';
import 'package:diappbetes/screens/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:diappbetes/screens/historial_screen.dart';
import 'package:diappbetes/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: '/auth',

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
        // '/register':       (context) => const RegisterScreen(),
        '/historial':      (context) => const HistorialScreen(),
        '/add-meal':       (context) => const AddMealScreen(),
        '/settings':       (context) => const SettingsScreen(),
        // '/code-verify':    (context) => const CodeVerificationScreen(),
        // '/password-changed':(context) => const PasswordChangedScreen(),
        // '/remember-password':(context) => const RememberPasswordScreen(),
      },
    );
  }
}