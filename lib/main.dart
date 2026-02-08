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
      title: 'Privacy Protection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const HomeScreen(),
        '/protected': (_) => const ProtectedAppsScreen(),
      },
      initialRoute: '/',
    );
  }
}
