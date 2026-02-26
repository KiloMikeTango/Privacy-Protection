import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/protected_apps_screen.dart';
import 'screens/secret_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/loading_apps_screen.dart';
import 'theme/app_theme.dart';

//TODO: Improve: Fix needing re-enable after adding app; Remove background notification feature
void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTheme.background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppTheme.background,
      systemNavigationBarContrastEnforced: false,
    ),
  );
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
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppTheme.background,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppTheme.background,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: AppTheme.background,
          systemNavigationBarContrastEnforced: false,
        ),
        child: child!,
      ),
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
