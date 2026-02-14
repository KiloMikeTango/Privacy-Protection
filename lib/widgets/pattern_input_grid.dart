import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatternInputGrid extends StatefulWidget {
  final void Function(int quadrant) onTap;

  const PatternInputGrid({
    super.key,
    required this.onTap,
  });

  @override
  State<PatternInputGrid> createState() => _PatternInputGridState();
}

class _PatternInputGridState extends State<PatternInputGrid> {
  int? _lastTappedQuadrant;

  void _handleTap(TapUpDetails details, Size size) {
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;
    final w = size.width;
    final h = size.height;

    int col = (x < w / 2) ? 0 : 1;
    int row = (y < h / 2) ? 0 : 1;
    int quadrant = row * 2 + col; // 0=TL, 1=TR, 2=BL, 3=BR

    setState(() {
      _lastTappedQuadrant = quadrant;
    });

    widget.onTap(quadrant);

    // Reset highlight after short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _lastTappedQuadrant == quadrant) {
        setState(() => _lastTappedQuadrant = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure square aspect ratio if possible, or fill available space
        final double size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        
        // Center the grid within the available space
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              onTapUp: (details) => _handleTap(details, Size(size, size)),
              child: Container(
                margin: const EdgeInsets.all(12), // Some padding from edges
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
                      // Grid Lines
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
                      
                      // Labels
                      _buildQuadrantLabel("1", 0, top: 24, left: 24),
                      _buildQuadrantLabel("2", 1, top: 24, right: 24),
                      _buildQuadrantLabel("3", 2, bottom: 24, left: 24),
                      _buildQuadrantLabel("4", 3, bottom: 24, right: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuadrantLabel(
    String text,
    int quadrantIndex, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final bool isTapped = _lastTappedQuadrant == quadrantIndex;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Responsive scaling for label size could be added here if needed
    // For now, fixed 48x48 is standard tap target size.

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isTapped ? colorScheme.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isTapped ? colorScheme.primary : theme.dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: isTapped 
                  ? colorScheme.primary.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.05),
              blurRadius: isTapped ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isTapped ? Colors.white : colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
