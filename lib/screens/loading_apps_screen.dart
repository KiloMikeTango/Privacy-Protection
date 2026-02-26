import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class LoadingAppsScreen extends StatefulWidget {
  const LoadingAppsScreen({super.key});

  @override
  State<LoadingAppsScreen> createState() => _LoadingAppsScreenState();
}

class _LoadingAppsScreenState extends State<LoadingAppsScreen> {
  static const MethodChannel _channel = MethodChannel('privacy_protection');

  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    final minDelay = Future.delayed(const Duration(seconds: 3));
    List<dynamic> apps = const [];
    List<dynamic> protected = const [];
    Object? error;
    try {
      final results = await Future.wait([
        _channel.invokeMethod<List<dynamic>>('getProtectedApps'),
        _channel.invokeMethod<List<dynamic>>('getInstalledLaunchableApps'),
      ]);
      protected = (results[0] as List<dynamic>?) ?? [];
      apps = (results[1] as List<dynamic>?) ?? [];
    } catch (e) {
      error = e;
    }
    await minDelay; // ensure minimum display time

    if (!mounted) return;
    if (error != null) {
      // Fallback: go to screen, let it handle errors/loading itself
      Navigator.of(context).pushReplacementNamed('/protected');
    } else {
      Navigator.of(context).pushReplacementNamed(
        '/protected',
        arguments: {'apps': apps, 'protected': protected},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Loading your apps…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
