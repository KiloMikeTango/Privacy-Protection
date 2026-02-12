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
  final List<int> _confirmedPattern = [];
  bool _saving = false;
  bool _isConfirming = false; // false = Recording, true = Confirming

  void _handleTap(TapUpDetails details, Size size) {
    if (_saving) return;

    final x = details.localPosition.dx;
    final y = details.localPosition.dy;
    final w = size.width;
    final h = size.height;

    int col = (x < w / 2) ? 0 : 1;
    int row = (y < h / 2) ? 0 : 1;
    int quadrant = row * 2 + col; // 0=TL, 1=TR, 2=BL, 3=BR

    setState(() {
      if (_isConfirming) {
        _confirmedPattern.add(quadrant);
      } else {
        _pattern.add(quadrant);
      }
    });
  }

  void _reset() {
    setState(() {
      _pattern.clear();
      _confirmedPattern.clear();
      _isConfirming = false;
    });
  }

  void _advanceToConfirm() {
    if (_pattern.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pattern must be at least 6 taps long.')),
      );
      return;
    }
    setState(() {
      _isConfirming = true;
    });
  }

  Future<void> _save() async {
    // Validation
    if (_confirmedPattern.length != _pattern.length) {
      // Wait for user to finish tapping same amount, or we can check on every tap.
      // But typically user hits "Confirm".
      // Let's verify content.
    }

    // Check match
    bool match = true;
    if (_confirmedPattern.length != _pattern.length) {
      match = false;
    } else {
      for (int i = 0; i < _pattern.length; i++) {
        if (_pattern[i] != _confirmedPattern[i]) {
          match = false;
          break;
        }
      }
    }

    if (!match) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patterns do not match. Try again.')),
      );
      _reset(); // Restart from beginning for security
      return;
    }

    setState(() => _saving = true);
    try {
      await _channel.invokeMethod('saveSecretPattern', _pattern);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Secret pattern saved!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _qName(int q) {
    switch (q) {
      case 0:
        return "TL"; // Top-Left
      case 1:
        return "TR"; // Top-Right
      case 2:
        return "BL"; // Bottom-Left
      case 3:
        return "BR"; // Bottom-Right
      default:
        return "?";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentList = _isConfirming ? _confirmedPattern : _pattern;
    final String instruction = _isConfirming
        ? "Confirm your pattern"
        : "Record your pattern";
    final String subInstruction = _isConfirming
        ? "Tap the same sequence again."
        : "Tap at least 6 times.";

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header similar to Android settings
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Column(
                children: [
                  Text(
                    instruction,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subInstruction,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Tap Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapUp: (details) =>
                        _handleTap(details, constraints.biggest),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Subtle Grid lines
                            Center(
                              child: Container(
                                width: 1,
                                height: double.infinity,
                                color: Colors.grey.shade100,
                              ),
                            ),
                            Center(
                              child: Container(
                                width: double.infinity,
                                height: 1,
                                color: Colors.grey.shade100,
                              ),
                            ),
                            // Minimal Quadrant Labels
                            const Positioned(
                              top: 16,
                              left: 16,
                              child: Text(
                                "1",
                                style: TextStyle(
                                  color: Colors.black12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 16,
                              right: 16,
                              child: Text(
                                "2",
                                style: TextStyle(
                                  color: Colors.black12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Positioned(
                              bottom: 16,
                              left: 16,
                              child: Text(
                                "3",
                                style: TextStyle(
                                  color: Colors.black12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Positioned(
                              bottom: 16,
                              right: 16,
                              child: Text(
                                "4",
                                style: TextStyle(
                                  color: Colors.black12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Feedback Visualization (Dots)
                            if (currentList.isNotEmpty)
                              Center(
                                child: Text(
                                  "${currentList.length} Taps",
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary.withOpacity(0.2),
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

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _reset,
                    child: Text(
                      _isConfirming ? "Cancel" : "Clear",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: _isConfirming
                        ? (_confirmedPattern.isNotEmpty ? _save : null)
                        : (_pattern.isNotEmpty ? _advanceToConfirm : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isConfirming ? "Confirm" : "Next",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
