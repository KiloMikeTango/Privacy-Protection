import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/protected_apps_screen.dart';
import 'screens/secret_setup_screen.dart';

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
      theme: _buildTheme(),
      routes: {
        '/': (_) => const HomeScreen(),
        '/protected': (_) => const ProtectedAppsScreen(),
        '/secret_setup': (_) => const SecretSetupScreen(),
      },
      initialRoute: '/',
    );
  }

  ThemeData _buildTheme() {
    // Modern Clean Aesthetic (2026)
    // Soft gradients, off-white/grey palette, Inter font, elegant shadows.
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Soft cloud grey
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2563EB), // Royal Blue
        secondary: Color(0xFF64748B), // Slate Grey
        surface: Colors.white,
        background: Color(0xFFF5F7FA),
        error: Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSurface: Color(0xFF1E293B), // Dark Slate
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF1E293B),
        displayColor: const Color(0xFF1E293B),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        hintStyle: TextStyle(color: const Color(0xFF94A3B8)),
        prefixIconColor: const Color(0xFF94A3B8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 2),
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF2563EB);
          }
          return Colors.transparent;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFFE2E8F0),
        thickness: 1,
      ),
    );
  }
}
