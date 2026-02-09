import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/protected_apps_screen.dart';

void main() {
  runApp(const PrivacyProtectionApp());
}

class PrivacyProtectionApp extends StatelessWidget {
  const PrivacyProtectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shield',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2EE59D),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0E1838),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.06),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      routes: {
        '/': (_) => const HomeScreen(),
        '/protected': (_) => const ProtectedAppsScreen(),
      },
      initialRoute: '/',
    );
  }
}
