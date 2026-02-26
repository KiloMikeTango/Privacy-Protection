import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class LoadingAppsScreen extends StatefulWidget {
  const LoadingAppsScreen({super.key});

  @override
  State<LoadingAppsScreen> createState() => _LoadingAppsScreenState();
}

class _LoadingAppsScreenState extends State<LoadingAppsScreen>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _channel = MethodChannel('privacy_protection');

  double _progress = 0.0;
  double _target = 0.0;
  bool _protectedDone = false;
  bool _appsDone = false;
  bool _minDelayDone = false;
  AnimationController? _progressController;
  List<dynamic> _protected = const [];
  List<dynamic> _apps = const [];

  @override
  void initState() {
    super.initState();
    _initProgressController();
    _startMinDelay();
    _loadData();
  }

  void _initProgressController() {
    _progressController =
        AnimationController(
          vsync: this,
          value: 0.0,
          duration: const Duration(milliseconds: 400),
        )..addListener(() {
          if (!mounted) return;
          setState(() {
            _progress = _progressController!.value;
          });
          _tryNavigate();
        });
  }

  void _animateToTarget(double t) {
    _target = t.clamp(0.0, 1.0);
    final delta = (_target - (_progressController?.value ?? 0.0)).abs();
    final ms = (200 + (400 * delta)).toInt();
    _progressController?.animateTo(
      _target,
      duration: Duration(milliseconds: ms),
      curve: Curves.easeInOutCubic,
    );
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
    _animateToTarget(_appsDone ? 1.0 : 0.4);
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
    _animateToTarget(1.0);
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!_minDelayDone) return;
    if (!_protectedDone || !_appsDone) return;
    if (_progress < 1.0) return;
    // Progress controller drives navigation; no timer to cancel
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/protected',
      arguments: {'apps': _apps, 'protected': _protected},
    );
  }

  @override
  void dispose() {
    _progressController?.dispose();
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
