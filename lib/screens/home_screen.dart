import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/nav_card.dart';
import '../widgets/shield_pulse_button.dart';
import '../widgets/floating_card.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const MethodChannel _channel = MethodChannel('privacy_protection');
  bool _running = false;
  bool _busy = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final bool active =
          await _channel.invokeMethod<bool>('isOverlayActive') ?? false;
      setState(() => _running = active);
    } catch (e) {
      setState(() => _message = 'Status error: $e');
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      if (!_running) {
        final bool ok =
            await _channel.invokeMethod<bool>('enableOverlay') ?? false;
        if (!ok) {
          setState(() {
            _message =
                'Grant “Draw over other apps”, “Usage Access”, and notifications (Android 13+).';
          });
        }
      } else {
        await _channel.invokeMethod('disableOverlay');
      }
      await _refresh();
    } catch (e) {
      setState(() => _message = 'Operation error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final isTablet = size.shortestSide > 600;
            final contentWidth = isTablet ? 500.0 : size.width;
            final circle = isTablet ? 200.0 : size.shortestSide * 0.45;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: AnimationLimiter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const SizedBox(height: AppTheme.spacing2Xl),

                          // Header Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _running
                                      ? AppTheme.success
                                      : AppTheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _running ? 'PROTECTED' : 'UNPROTECTED',
                                style: AppTheme.typography.labelLarge?.copyWith(
                                  color: _running
                                      ? AppTheme.success
                                      : AppTheme.secondary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppTheme.spacing2Xl),

                          // Main Pulse Button
                          Center(
                            child: ShieldPulseButton(
                              isRunning: _running,
                              isBusy: _busy,
                              onTap: _toggle,
                              size: circle,
                            ),
                          ),

                          if (_message.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingMd),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: colorScheme.error.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: Border.all(
                                  color: colorScheme.error.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                _message,
                                textAlign: TextAlign.center,
                                style: AppTheme.typography.bodyMedium?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ],

                          const Spacer(),

                          // Dashboard Grid
                          Row(
                            children: [
                              Expanded(
                                child: FloatingCard(
                                  duration: const Duration(seconds: 4),
                                  offset: 6.0,
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed('/protected'),
                                  child: _buildDashboardCard(
                                    context,
                                    title: 'Apps',
                                    subtitle: 'Manage',
                                    icon: Icons.apps_rounded,
                                    colorScheme: colorScheme,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: FloatingCard(
                                  duration: const Duration(
                                    seconds: 5,
                                  ), // Different duration for organic feel
                                  offset: -6.0, // Opposite direction
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed('/secret_setup'),
                                  child: _buildDashboardCard(
                                    context,
                                    title: 'Unlock',
                                    subtitle: 'Setup',
                                    icon: Icons.fingerprint_rounded,
                                    colorScheme: colorScheme,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing2Xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    // onTap is now handled by FloatingCard
    required ColorScheme colorScheme,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.typography.titleLarge),
                Text(subtitle, style: AppTheme.typography.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
