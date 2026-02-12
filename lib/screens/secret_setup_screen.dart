import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SecretSetupScreen extends StatefulWidget {
  const SecretSetupScreen({super.key});

  @override
  State<SecretSetupScreen> createState() => _SecretSetupScreenState();
}

class _SecretSetupScreenState extends State<SecretSetupScreen> {
  static const MethodChannel _channel = MethodChannel('privacy_protection');
  final List<int> _pattern = [];
  bool _saving = false;

  void _handleTap(TapUpDetails details, Size size) {
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;
    final w = size.width;
    final h = size.height;
    
    int col = (x < w / 2) ? 0 : 1;
    int row = (y < h / 2) ? 0 : 1;
    int quadrant = row * 2 + col; // 0=TL, 1=TR, 2=BL, 3=BR
    
    setState(() {
      _pattern.add(quadrant);
    });
  }

  Future<void> _save() async {
    if (_pattern.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _channel.invokeMethod('saveSecretPattern', _pattern);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secret pattern saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _qName(int q) {
    switch(q) {
      case 0: return "TL"; // Top-Left
      case 1: return "TR"; // Top-Right
      case 2: return "BL"; // Bottom-Left
      case 3: return "BR"; // Bottom-Right
      default: return "?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Unlock Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _pattern.clear()),
            tooltip: 'Reset',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _pattern.isNotEmpty && !_saving ? _save : null,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tap the quadrants in your desired sequence to create a secret unlock pattern.\n'
              'Current Length: ${_pattern.length}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) => _handleTap(details, constraints.biggest),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Grid lines
                          Center(
                            child: Container(
                              width: 2,
                              height: double.infinity,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          Center(
                            child: Container(
                              width: double.infinity,
                              height: 2,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          // Quadrant Labels
                          const Positioned(top: 10, left: 10, child: Text("TL", style: TextStyle(color: Colors.black12))),
                          const Positioned(top: 10, right: 10, child: Text("TR", style: TextStyle(color: Colors.black12))),
                          const Positioned(bottom: 10, left: 10, child: Text("BL", style: TextStyle(color: Colors.black12))),
                          const Positioned(bottom: 10, right: 10, child: Text("BR", style: TextStyle(color: Colors.black12))),
                          
                          // Pattern Display
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                _pattern.isEmpty 
                                  ? 'Tap to start...' 
                                  : _pattern.map(_qName).join(' -> '),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
