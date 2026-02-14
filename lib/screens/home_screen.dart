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

                          // Replace Spacer with Flexible or Expanded if needed, but since it's inside
                          // AnimationConfiguration.toStaggeredList which returns a List<Widget>,
                          // we need to be careful. The children list is passed to a Column.
                          // AnimationConfiguration.toStaggeredList wraps each child in an AnimationConfiguration.
                          // So Spacer becomes AnimationConfiguration(child: Spacer()).
                          // Spacer is Expanded(child: SizedBox.shrink()).
                          // Expanded must be a direct child of Column/Row/Flex.
                          // But here it is wrapped by AnimationConfiguration -> FadeInAnimation -> SlideAnimation.
                          // This breaks the Expanded constraint.
                          
                          // Fix: Use SizedBox with weight or just a big SizedBox?
                          // Or remove Spacer and use MainAxisAlignment.spaceBetween on Column?
                          // But the Column is inside SingleChildScrollView (not here but typically).
                          // Here it's just a Column.
                          // Let's replace Spacer with a large flexible gap using MainAxisAlignment
                          // or just a transparent container that takes space if we can't use Spacer.
                          // Better yet, remove Spacer and set mainAxisAlignment to spaceBetween on the Column
                          // if the Column fills height.
                          // However, we can't easily change the Column properties inside the builder without
                          // restructuring.
                          // EASIEST FIX: Use a large SizedBox instead of Spacer, or wrap the bottom elements 
                          // in an Expanded if the list structure allows, but staggred list makes it hard.
                          // Actually, we can just remove Spacer and rely on the layout or
                          // if we really need it to push down, we can try to use a flexible container 
                          // but the wrapper prevents it.
                          
                          // Correct approach for staggered list with spacer:
                          // Don't animate the spacer.
                          // We can split the children list.
                          
                          const SizedBox(height: 40), // Use fixed spacing instead of Spacer to avoid error
                          
                          // Dashboard Grid
                          Row(
                            children: [
                              Expanded(
                                child: FloatingCard(
                                  duration: const Duration(
                                    seconds: 6,
                                  ), // Slower
                                  offset: 4.0, // Smaller movement
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
                                    seconds: 7,
                                  ), // Even slower, async
                                  offset: -4.0, // Smaller movement
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
