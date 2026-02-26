import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/protected_apps_screen.dart';
import 'screens/secret_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/loading_apps_screen.dart';
import 'theme/app_theme.dart';

//TODO: Improve: Fix needing re-enable after adding app; Show loading before installed apps are loaded and navigate to the screen; Make the navigation bar white; Remove background notification feature
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
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/apps_loading': (_) => const LoadingAppsScreen(),
        '/protected': (_) => const ProtectedAppsScreen(),
        '/secret_setup': (_) => const SecretSetupScreen(),
        '/permissions': (_) => const PermissionScreen(),
      },
      initialRoute: '/',
    );
  }
}
