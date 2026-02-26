import 'dart:async';
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

  double _progress = 0.0;
  double _target = 0.0;
  bool _protectedDone = false;
  bool _appsDone = false;
  bool _minDelayDone = false;
  Timer? _ticker;
  List<dynamic> _protected = const [];
  List<dynamic> _apps = const [];

  @override
  void initState() {
    super.initState();
    _startTicker();
    _startMinDelay();
    _loadData();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      if (_progress < _target) {
        final next = (_progress + 0.02).clamp(0.0, 1.0);
        setState(() {
          _progress = next;
        });
      }
      _tryNavigate();
    });
  }

  void _startMinDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _minDelayDone = true;
    _tryNavigate();
  }

  void _loadData() async {
    unawaited(_loadProtected());
    unawaited(_loadApps());
  }

  Future<void> _loadProtected() async {
    try {
      final res = await _channel.invokeMethod('getProtectedApps');
      if (res is List) {
        _protected = res;
      }
    } catch (_) {}
    _protectedDone = true;
    _target = _appsDone ? 1.0 : 0.4;
    _tryNavigate();
  }

  Future<void> _loadApps() async {
    try {
      final res = await _channel.invokeMethod('getInstalledLaunchableApps');
      if (res is List) {
        _apps = res;
      }
    } catch (_) {}
    _appsDone = true;
    _target = 1.0;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!_minDelayDone) return;
    if (!_protectedDone || !_appsDone) return;
    if (_progress < 1.0) return;
    _ticker?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/protected',
      arguments: {'apps': _apps, 'protected': _protected},
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = (_progress * 100).toInt();
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceVariant,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Preparing apps… $pct%',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
