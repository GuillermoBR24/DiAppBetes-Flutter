import 'package:diappbetes/firebase_options.dart';
import 'package:diappbetes/providers/theme_provider.dart';
import 'package:diappbetes/screens/add_meal_screen.dart';
import 'package:diappbetes/screens/admin_config_screen.dart';
import 'package:diappbetes/screens/admin_screen.dart';
import 'package:diappbetes/screens/admin_stats_screen.dart';
import 'package:diappbetes/screens/admin_user_screen.dart';
import 'package:diappbetes/screens/auth_screen.dart';
import 'package:diappbetes/screens/code_verification_screen.dart';
import 'package:diappbetes/screens/glucose_history_screen.dart';
import 'package:diappbetes/screens/login_screen.dart';
import 'package:diappbetes/screens/password_changed_screen.dart';
import 'package:diappbetes/screens/register_screen.dart';
import 'package:diappbetes/screens/remember_password_screen.dart';
import 'package:diappbetes/screens/scanner_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:diappbetes/screens/historial_screen.dart';
import 'package:diappbetes/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
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
    // Escucha cambios de tema sin reconstruir todo el árbol
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
        '/code-verify':       (context) => const CodeVerificationScreen(),
        '/password-changed':  (context) => const PasswordChangedScreen(),
        '/remember-password': (context) => const RememberPasswordScreen(),
        '/scanner':           (context) => const ScannerScreen(),
        '/admin':             (context) => const AdminScreen(),
        '/admin-user':        (context) => const AdminUsersScreen(),
        '/admin-stats':       (context) => const AdminStatsScreen(),
        '/admin-config':      (context) => const AdminConfigScreen(),
        '/glucose-history':   (context) => const GlucoseHistoryScreen(),
      },
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

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
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}