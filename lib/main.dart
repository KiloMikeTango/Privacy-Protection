import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routes: {
        '/': (_) => const HomeScreen(),
        '/protected': (_) => const ProtectedAppsScreen(),
      },
      initialRoute: '/',
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0B1121), // Deep Tech Navy
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00F0FF), // Cyber Cyan
        secondary: Color(0xFF7000FF), // Electric Violet
        surface: Color(0xFF151E32), // Lighter Navy
        background: Color(0xFF0B1121),
        error: Color(0xFFFF2A6D), // Neon Red
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(
        base.textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
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
          borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIconColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF00F0FF);
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.black),
        side: const BorderSide(color: Colors.white54, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
