import 'package:flutter/material.dart';

class ShieldPulseButton extends StatefulWidget {
  final bool isRunning;
  final bool isBusy;
  final VoidCallback onTap;
  final double size;

  const ShieldPulseButton({
    super.key,
    required this.isRunning,
    required this.isBusy,
    required this.onTap,
    required this.size,
  });

  @override
  State<ShieldPulseButton> createState() => _ShieldPulseButtonState();
}

class _ShieldPulseButtonState extends State<ShieldPulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final circle = widget.size;
    final ring = circle * 1.25; // Ring is 25% larger than circle

    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft Outer Ring
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isRunning ? _pulseAnimation.value : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: ring,
                height: ring,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isRunning
                      ? colorScheme.primary.withValues(alpha: 0.10)
                      : Colors.white,
                  boxShadow: [
                    if (widget.isRunning)
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.20),
                        blurRadius: ring * 0.16,
                        spreadRadius: ring * 0.05,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: ring * 0.1,
                        spreadRadius: ring * 0.02,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        // Button
        GestureDetector(
          onTap: widget.isBusy ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: circle,
            height: circle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isRunning ? colorScheme.primary : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: widget.isRunning
                      ? colorScheme.primary.withValues(alpha: 0.40)
                      : Colors.black.withValues(alpha: 0.10),
                  blurRadius: circle * 0.15,
                  offset: Offset(0, circle * 0.07),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.power_settings_new_rounded,
                color: widget.isRunning ? Colors.white : colorScheme.secondary,
                size: circle * 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
