import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final circle = size.shortestSide * 0.45;
          final ring = circle + 40;
          final colorScheme = Theme.of(context).colorScheme;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.background, colorScheme.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shield',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.shield_outlined),
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/protected'),
                            tooltip: 'Protected Apps',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Glow Ring
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: ring,
                              height: ring,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: _running
                                      ? [
                                          colorScheme.primary.withOpacity(0.0),
                                          colorScheme.primary.withOpacity(0.2),
                                          colorScheme.primary.withOpacity(0.6),
                                          colorScheme.primary.withOpacity(0.2),
                                          colorScheme.primary.withOpacity(0.0),
                                        ]
                                      : [
                                          Colors.white.withOpacity(0.02),
                                          Colors.white.withOpacity(0.05),
                                          Colors.white.withOpacity(0.02),
                                        ],
                                ),
                              ),
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
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _running
                                        ? [
                                            colorScheme.primary,
                                            Color.lerp(
                                              colorScheme.primary,
                                              Colors.black,
                                              0.2,
                                            )!,
                                          ]
                                        : [
                                            colorScheme.surface,
                                            Color.lerp(
                                              colorScheme.surface,
                                              Colors.black,
                                              0.4,
                                            )!,
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _running
                                          ? colorScheme.primary.withOpacity(0.4)
                                          : Colors.black.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 10),
                                    ),
                                    if (_running)
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(
                                          0.6,
                                        ),
                                        blurRadius: 60,
                                        spreadRadius: -10,
                                      ),
                                  ],
                                  border: Border.all(
                                    color: _running
                                        ? Colors.white.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.05),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.power_settings_new_rounded,
                                    color: Colors.white,
                                    size: circle * 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _running ? 'SYSTEM PROTECTED' : 'PROTECTION OFF',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: _running
                                      ? colorScheme.primary
                                      : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
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
                    _buildNavCard(
                      context,
                      title: 'Protected Apps',
                      subtitle: 'Manage overlay permissions',
                      icon: Icons.apps_rounded,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/protected'),
                    ),
                  ],
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
    return Card(
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
