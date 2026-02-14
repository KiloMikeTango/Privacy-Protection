import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatternSequenceDisplay extends StatefulWidget {
  final List<int> pattern;
  final bool isConfirming;
  final bool isMatched;

  const PatternSequenceDisplay({
    super.key,
    required this.pattern,
    this.isConfirming = false,
    this.isMatched = true,
  });

  @override
  State<PatternSequenceDisplay> createState() => _PatternSequenceDisplayState();
}

class _PatternSequenceDisplayState extends State<PatternSequenceDisplay> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Design Goals (Senior UX):
        // 1. Remove visual noise (arrows) to save horizontal space.
        // 2. Maintain legibility of numbers.
        // 3. Ensure 8 items fit on small screens without wrapping.

        final availableWidth = constraints.maxWidth;
        final itemCount = widget.pattern.length;

        // Calculate optimal item size
        // We need (itemCount * size) + ((itemCount - 1) * spacing) <= availableWidth
        // Target size: 36.0 (nice touch target size visually)
        // Min spacing: 4.0

        double itemSize = 36.0;
        double spacing = 8.0;

        double requiredWidth =
            (itemCount * itemSize) +
            ((itemCount - 1 > 0 ? itemCount - 1 : 0) * spacing);

        if (requiredWidth > availableWidth) {
          // If overflow, prioritize reducing spacing first
          spacing = 4.0;
          requiredWidth =
              (itemCount * itemSize) +
              ((itemCount - 1 > 0 ? itemCount - 1 : 0) * spacing);

          if (requiredWidth > availableWidth) {
            // If still overflow, scale down items
            // Solve for size: size * count + spacing * (count-1) = width
            // size = (width - spacing * (count-1)) / count
            itemSize =
                (availableWidth - (spacing * (itemCount - 1))) / itemCount;
          }
        }

        // Ensure itemSize is never negative (prevents layout errors)
        if (itemSize < 0) itemSize = 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          // Wrap with FittedBox to guarantee no overflow even with rounding errors
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(itemCount, (index) {
                final q = widget.pattern[index];
                final isLast = index == itemCount - 1;

                // Animation key: Using index ensures existing items stay put,
                // new items animate in.
                return AnimatedContainer(
                  // Use a standard curve to avoid overshooting (which causes negative blurRadius in shadows)
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: index < itemCount - 1
                      ? EdgeInsets.only(right: spacing)
                      : EdgeInsets.zero,
                  width: itemSize,
                  height: itemSize,
                  decoration: BoxDecoration(
                    color: isLast
                        ? colorScheme.primary
                        : colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLast
                          ? colorScheme.primary
                          : colorScheme.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: isLast
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve:
                        Curves.easeOutBack, // Move the bouncy pop effect here
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Text(
                          (q + 1).toString(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isLast
                                ? colorScheme.onPrimary
                                : colorScheme.primary,
                            fontSize: itemSize * 0.5, // Responsive font scaling
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ), // Close FittedBox
        ); // Close Container
      },
    );
  }
}
