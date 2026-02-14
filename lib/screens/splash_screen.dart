import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const MethodChannel _channel = MethodChannel('privacy_protection');

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    // Add a small delay for smoother UX
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getSecretPattern',
      );
      final List<int> current = result.map((e) => e as int).toList();

      // If pattern length < 6, it's considered not set (or default/insecure)
      if (current.length < 6) {
        if (mounted) {
          // Force setup - replace splash so they can't go back
          Navigator.of(context).pushReplacementNamed(
            '/secret_setup',
            arguments: {'forceSetup': true},
          );
        }
      } else {
        // Pattern is set, now check permissions
        final Map<dynamic, dynamic>? perms = await _channel.invokeMethod(
          'checkPermissions',
        );
        bool overlay = perms?['overlay'] ?? false;
        bool usage = perms?['usage'] ?? false;

        if (!overlay || !usage) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/permissions',
              arguments: {'forceSetup': true},
            );
          }
        } else {
          if (mounted) {
            // All good, go home
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    } catch (e) {
      // If error (e.g. channel not ready), assume not set to be safe, or retry.
      // For now, let's assume we need setup.
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/secret_setup',
          arguments: {'forceSetup': true},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_rounded, size: 80, color: AppTheme.onPrimary),
            const SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
