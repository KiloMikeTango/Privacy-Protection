import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_info.dart';
import '../utils/responsive.dart';

class AppListItem extends StatelessWidget {
  final AppInfo app;
  final bool isChecked;
  final String query;
  final ValueChanged<bool> onToggle;

  const AppListItem({
    super.key,
    required this.app,
    required this.isChecked,
    required this.query,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isChecked
            ? Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: Responsive.w(4),
          vertical: Responsive.h(0.5),
        ),
        leading: Container(
          width: Responsive.w(12).clamp(40.0, 56.0),
          height: Responsive.w(12).clamp(40.0, 56.0),
          decoration: BoxDecoration(
            color: colorScheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(Responsive.w(2)),
          child: app.icon != null
              ? Image.memory(app.icon!, fit: BoxFit.contain)
              : Icon(Icons.android_rounded, color: colorScheme.secondary),
        ),
        title: _buildHighlightText(
          app.appName,
          query.trim(),
          theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          colorScheme.primary,
        ),
        subtitle: Text(
          app.packageName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        trailing: InkWell(
          onTap: () => onToggle(!isChecked),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isChecked
                  ? colorScheme.error.withOpacity(0.1)
                  : colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              isChecked ? Icons.remove_rounded : Icons.add_rounded,
              color: isChecked ? colorScheme.error : colorScheme.primary,
              size: 20,
            ),
          ),
        ),
        onTap: () => onToggle(!isChecked),
      ),
    );
  }

  Widget _buildHighlightText(
    String text,
    String query,
    TextStyle baseStyle,
    Color highlightColor,
  ) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        matches.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        matches.add(TextSpan(text: text.substring(start, index)));
      }
      matches.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            color: highlightColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = index + query.length;
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: matches),
    );
  }
}
