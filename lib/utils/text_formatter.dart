import 'package:flutter/material.dart';

class TextFormatter {
  static Widget formatStructuredText(String text, {TextStyle? baseStyle, BuildContext? context}) {
    final List<Widget> widgets = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      
      // Section headers (ALL CAPS followed by colon)
      if (line.contains(':') && line == line.toUpperCase() && !line.startsWith('•')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            line,
            style: (baseStyle ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: (baseStyle?.fontSize ?? 14) + 2,
              color: Colors.blue.shade700,
            ),
          ),
        ));
        continue;
      }
      
      // Bullet points
      if (line.startsWith('•')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: (baseStyle ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
              Expanded(
                child: Text(
                  line.substring(1).trim(),
                  style: baseStyle,
                ),
              ),
            ],
          ),
        ));
        continue;
      }
      
      // TLDR section (highlight it)
      if (line.startsWith('TLDR:')) {
        final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
        widgets.add(Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.amber.shade900.withOpacity(0.2) : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.amber.shade700 : Colors.amber.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: isDark ? Colors.amber.shade400 : Colors.amber.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line,
                  style: (baseStyle ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
        ));
        continue;
      }
      
      // Regular text
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          line,
          style: baseStyle,
        ),
      ));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // Keep the old method for backward compatibility
  static Widget formatMarkdownText(String text, {TextStyle? style, BuildContext? context}) {
    return formatStructuredText(text, baseStyle: style, context: context);
  }
}