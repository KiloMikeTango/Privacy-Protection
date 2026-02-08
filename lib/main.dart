import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PrivacyProtectionApp());
}

class PrivacyProtectionApp extends StatelessWidget {
  const PrivacyProtectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Privacy Protection',
      home: OverlayScreen(),
    );
  }
}

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  static const MethodChannel _channel = MethodChannel('privacy_protection');
  bool _active = false;
  bool _busy = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  Future<void> _refreshState() async {
    try {
      final bool active = await _channel.invokeMethod<bool>('isOverlayActive') ?? false;
      setState(() => _active = active);
    } catch (e) {
      setState(() => _message = 'Status error: $e');
    }
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      if (value) {
        final bool granted = await _channel.invokeMethod<bool>('enableOverlay') ?? false;
        if (!granted) {
          setState(() {
            _message = 'Please grant “Draw over other apps” permission.';
          });
        }
      } else {
        await _channel.invokeMethod('disableOverlay');
      }
      await _refreshState();
    } catch (e) {
      setState(() => _message = 'Operation error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Protection'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enable Overlay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: _active,
                  onChanged: _busy ? null : _toggle,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _active ? 'Overlay Active' : 'Overlay Inactive',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _active ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
