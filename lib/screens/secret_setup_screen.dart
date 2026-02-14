import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

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
  bool _isChanging = false; // false = Setup, true = Change
  List<int> _existingPattern = []; // To display in overview mode
  bool _showOverview = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPattern();
  }

  Future<void> _checkExistingPattern() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getSecretPattern',
      );
      final List<int> current = result.map((e) => e as int).toList();

      if (current.length >= 6) {
        setState(() {
          _isChanging = true;
          _showOverview = true;
          _existingPattern = current;
        });
      }
    } catch (_) {}
  }

  void _startEditing() {
    setState(() {
      _showOverview = false;
      _pattern.clear();
      _confirmedPattern.clear();
      _isConfirming = false;
    });
  }

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

        // Check if we need to redirect to home (if forced setup)
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final bool forceSetup = args?['forceSetup'] ?? false;

        if (forceSetup) {
          Navigator.of(context).pushReplacementNamed(
            '/permissions',
            arguments: {'forceSetup': true},
          );
        } else {
          Navigator.pop(context);
        }
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

  bool get _isPatternMatched {
    if (_confirmedPattern.length != _pattern.length) return false;
    for (int i = 0; i < _pattern.length; i++) {
      if (_pattern[i] != _confirmedPattern[i]) return false;
    }
    return true;
  }

  void _handleCancel() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool forceSetup = args?['forceSetup'] ?? false;

    if (forceSetup) {
      // If user has started entering a pattern, allow clearing it.
      // Otherwise allow exiting.
      if (!_isConfirming && _pattern.isNotEmpty) {
        _reset();
      } else if (_isConfirming) {
        _reset(); // Cancel confirmation and restart
      } else {
        SystemNavigator.pop(); // Exit app
      }
    } else {
      _reset(); // Just clear
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if we are in "Force Setup" mode
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool forceSetup = args?['forceSetup'] ?? false;

    if (_showOverview && !forceSetup) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXl),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    "Current Pattern",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "TAP SEQUENCE",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          _existingPattern
                              .map((q) => (q + 1).toString())
                              .join("-"),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2Xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startEditing,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text("Change Pattern"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentList = _isConfirming ? _confirmedPattern : _pattern;
    final String instruction = _isConfirming
        ? "Confirm Pattern"
        : (_isChanging ? "New Pattern" : "Set Pattern");
    final String subInstruction = _isConfirming
        ? "Re-enter your sequence to confirm"
        : "Tap at least 6 times to create sequence";

    final String visualPattern = currentList
        .map((q) => (q + 1).toString())
        .join("-");

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: WillPopScope(
        onWillPop: () async {
          // Block back button if forced setup
          return !forceSetup;
        },
        child: SafeArea(
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
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      forceSetup
                          ? "You must set a secret unlock pattern to continue."
                          : subInstruction,
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
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Stack(
                            children: [
                              // Clean Grid lines
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
                              // Modern Quadrant Labels
                              _buildQuadrantLabel("1", top: 24, left: 24),
                              _buildQuadrantLabel("2", top: 24, right: 24),
                              _buildQuadrantLabel("3", bottom: 24, left: 24),
                              _buildQuadrantLabel("4", bottom: 24, right: 24),

                              // Feedback Visualization
                              if (currentList.isNotEmpty)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface.withOpacity(
                                        0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      visualPattern,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                        letterSpacing: 2,
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

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _handleCancel,
                      child: Text(
                        _isConfirming
                            ? "Cancel"
                            : (forceSetup
                                  ? (_pattern.isNotEmpty ? "Clear" : "Exit")
                                  : "Clear"),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: _isConfirming
                          ? (_isPatternMatched ? _save : null)
                          : (_pattern.length >= 6 ? _advanceToConfirm : null),
                      child: Text(_isConfirming ? "Confirm" : "Next"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuadrantLabel(
    String text, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: AppTheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
