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
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Container(
            color: colorScheme.background,
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
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.shield_outlined),
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/protected'),
                            tooltip: 'Protected Apps',
                            color: colorScheme.onSurface,
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
                            // Soft Outer Ring
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: ring,
                              height: ring,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _running
                                    ? colorScheme.primary.withOpacity(0.1)
                                    : Colors.white,
                                boxShadow: [
                                  if (_running)
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.2),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    )
                                  else
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                ],
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
                                  color: _running
                                      ? colorScheme.primary
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _running
                                          ? colorScheme.primary.withOpacity(0.4)
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
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _running ? 'System Protected' : 'Protection Off',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: _running
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                              fontWeight: FontWeight.w600,
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
