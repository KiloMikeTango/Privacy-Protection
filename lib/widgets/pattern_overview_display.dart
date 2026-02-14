import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatternOverviewDisplay extends StatelessWidget {
  final List<int> pattern;

  const PatternOverviewDisplay({
    super.key,
    required this.pattern,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8, // gap between items
        runSpacing: 8, // gap between lines
        children: List.generate(pattern.length * 2 - 1, (index) {
          // Interleave arrows and items
          if (index.isOdd) {
            return Container(
              height: 40,
              width: 16,
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
            );
          }

          final q = pattern[index ~/ 2];
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              (q + 1).toString(),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: 18,
              ),
            ),
          );
        }),
      ),
    );
  }
}
