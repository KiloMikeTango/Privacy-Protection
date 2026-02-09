import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
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
      final bool active = await _channel.invokeMethod<bool>('isOverlayActive') ?? false;
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
        final bool ok = await _channel.invokeMethod<bool>('enableOverlay') ?? false;
        if (!ok) {
          setState(() {
            _message = 'Grant “Draw over other apps”, “Usage Access”, and notifications (Android 13+).';
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
          final ring = circle + 24;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E2A78), Color(0xFF0E1838)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shield',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pushNamed('/protected'),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: ring,
                              height: ring,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: _running
                                    ? [
                                        BoxShadow(color: Colors.greenAccent.withOpacity(0.4), blurRadius: 40, spreadRadius: 4),
                                      ]
                                    : [
                                        BoxShadow(color: Colors.white10, blurRadius: 10),
                                      ],
                                gradient: SweepGradient(
                                  colors: _running
                                      ? [Colors.greenAccent, Colors.green, Colors.greenAccent]
                                      : [Colors.white10, Colors.white12, Colors.white10],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _busy ? null : _toggle,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: circle,
                                height: circle,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _running
                                        ? [const Color(0xFF2EE59D), const Color(0xFF19A76A)]
                                        : [const Color(0xFF3B4A9A), const Color(0xFF222C66)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    _running ? Icons.power : Icons.power_settings_new,
                                    color: Colors.white,
                                    size: circle * 0.35,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _running ? 'Monitoring Enabled' : 'Monitoring Disabled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _running ? Colors.greenAccent : Colors.white70,
                        ),
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.shield, color: Colors.white),
                        title: const Text('Protected Apps', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Choose which apps get an overlay', style: TextStyle(color: Colors.white70)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                        onTap: () => Navigator.of(context).pushNamed('/protected'),
                      ),
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
}
