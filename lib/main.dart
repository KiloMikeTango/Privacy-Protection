import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/protected_apps_screen.dart';
import 'screens/secret_setup_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PrivacyProtectionApp());
}

class PrivacyProtectionApp extends StatelessWidget {
  const PrivacyProtectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/': (_) => const HomeScreen(),
        '/protected': (_) => const ProtectedAppsScreen(),
        '/secret_setup': (_) => const SecretSetupScreen(),
      },
      initialRoute: '/',
    );
  }
}
