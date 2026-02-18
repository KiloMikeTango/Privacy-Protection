import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('privacy_protection');

  bool _overlayGranted = false;
  bool _usageGranted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'checkPermissions',
      );
      if (result != null && mounted) {
        setState(() {
          _overlayGranted = result['overlay'] ?? false;
          _usageGranted = result['usage'] ?? false;
          _checking = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() => _checking = false);
    }
  }

  Future<void> _requestOverlay() async {
    try {
      // This will open settings
      await _channel.invokeMethod('enableOverlay');
      // We rely on lifecycle resume or manual check
    } catch (e) {
      debugPrint('Error requesting overlay: $e');
    }
  }

  Future<void> _requestUsage() async {
    try {
      // Logic in MainActivity handles this if we call enableOverlay,
      // but maybe we should expose direct calls?
      // Current implementation of 'enableOverlay' checks overlay first, then usage.
      // So calling 'enableOverlay' works for both sequentially.
      // But for better UX, we might want to target specific settings.
      // However, the native code is:
      // if (!overlay) -> open overlay settings
      // else if (!usage) -> open usage settings
      // So calling enableOverlay is fine, it handles the next missing permission.
      await _channel.invokeMethod('enableOverlay');
    } catch (e) {
      debugPrint('Error requesting usage: $e');
    }
  }

  void _continue() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool forceSetup = args?['forceSetup'] ?? false;

    final bool allGranted =
        _overlayGranted && _usageGranted; // Notification not needed

    return WillPopScope(
      onWillPop: () async {
        if (forceSetup) {
          SystemNavigator.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: Text(
            'Permissions',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: !forceSetup,
        ),
        body: SafeArea(
          child: _checking
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Required Permissions",
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "To protect your apps, Shield needs the following permissions to run in the background and display over other apps.",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: colorScheme.onSurface.withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            _buildPermissionItem(
                              context,
                              title: "Display over other apps",
                              description:
                                  "Required to show the lock screen over protected apps.",
                              icon: Icons.layers_outlined,
                              isGranted: _overlayGranted,
                              onTap: _overlayGranted ? null : _requestOverlay,
                            ),

                            const SizedBox(height: 16),

                            _buildPermissionItem(
                              context,
                              title: "Usage Access",
                              description:
                                  "Required to detect when you open a protected app.",
                              icon: Icons.data_usage_outlined,
                              isGranted: _usageGranted,
                              onTap: _usageGranted ? null : _requestUsage,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: allGranted ? _continue : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            "Continue",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.border,
          width: isGranted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? AppTheme.success.withOpacity(0.1)
                        : colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isGranted ? AppTheme.success : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isGranted)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 28,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Grant",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
}
