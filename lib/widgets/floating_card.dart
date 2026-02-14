import 'package:flutter/material.dart';

class FloatingCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  final VoidCallback onTap;

  const FloatingCard({
    super.key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(seconds: 3),
    this.offset = 8.0,
  });

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -widget.offset,
      end: widget.offset,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: GestureDetector(
            onTap: widget.onTap,
            child: widget.child,
          ),
        );
      },
    );
  }
}
