import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/nav_card.dart';
import '../widgets/shield_pulse_button.dart';
import '../utils/responsive.dart';

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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final isTablet = size.shortestSide > 600;
          final contentWidth = isTablet ? 500.0 : size.width;
          final circle = isTablet ? 200.0 : size.shortestSide * 0.45;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Container(
            color: colorScheme.background,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Padding(
                    padding: EdgeInsets.all(Responsive.w(6)),
                    child: AnimationLimiter(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 600),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Shield',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                        color: colorScheme.onSurface,
                                        fontSize: isTablet ? 48 : null,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(height: size.height * 0.05),
                            Center(
                              child: ShieldPulseButton(
                                isRunning: _running,
                                isBusy: _busy,
                                onTap: _toggle,
                                size: circle,
                              ),
                            ),
                            SizedBox(height: size.height * 0.05),
                            Center(
                              child: Column(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      _running
                                          ? 'ON'
                                          : 'OFF',
                                      key: ValueKey(_running),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: _running
                                                ? colorScheme.primary
                                                : colorScheme.secondary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  if (_message.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _message,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Hero(
                              tag: 'nav_card',
                              child: Material(
                                type: MaterialType.transparency,
                                child: NavCard(
                                  title: 'Apps',
                                  subtitle: 'Manage your apps',
                                  icon: Icons.apps_rounded,
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed('/protected'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            NavCard(
                              title: 'Secret Unlock',
                              subtitle: 'Configure tap pattern',
                              icon: Icons.security_rounded,
                              onTap: () => Navigator.of(context).pushNamed('/secret_setup'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
