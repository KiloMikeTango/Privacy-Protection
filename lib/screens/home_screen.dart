import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _channel = MethodChannel('privacy_protection');
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _running = false;
  bool _busy = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _refresh();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final circle = size.shortestSide * 0.45;
          final ring = circle + 40;
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Container(
            color: colorScheme.background,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(30),
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
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.05),
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft Outer Ring
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _running
                                        ? _pulseAnimation.value
                                        : 1.0,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      width: ring,
                                      height: ring,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _running
                                            ? colorScheme.primary.withOpacity(
                                                0.1,
                                              )
                                            : Colors.white,
                                        boxShadow: [
                                          if (_running)
                                            BoxShadow(
                                              color: colorScheme.primary
                                                  .withOpacity(0.2),
                                              blurRadius: 40,
                                              spreadRadius: 10,
                                            )
                                          else
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.03,
                                              ),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Button
                              GestureDetector(
                                onTap: _busy ? null : _toggle,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: circle,
                                  height: circle,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _running
                                        ? colorScheme.primary
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _running
                                            ? colorScheme.primary.withOpacity(
                                                0.4,
                                              )
                                            : Colors.black.withOpacity(0.1),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.power_settings_new_rounded,
                                      color: _running
                                          ? Colors.white
                                          : colorScheme.secondary,
                                      size: circle * 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                                      ? 'Protection On'
                                      : 'Protection Off',
                                  key: ValueKey(_running),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: _running
                                        ? colorScheme.primary
                                        : colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
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
                            child: _buildNavCard(
                              context,
                              title: 'Protected Apps',
                              subtitle: 'Manage overlay permissions',
                              icon: Icons.apps_rounded,
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/protected'),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.secondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
