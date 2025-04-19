// lib/widgets/debug/debug_access_button.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:govvy/screens/debug_navigation_screen.dart';

/// A button that provides access to debug tools in development builds
class DebugAccessButton extends StatelessWidget {
  /// Whether to show the button as an icon (true) or a text button (false)
  final bool useIconButton;
  
  /// Custom color for the button
  final Color? color;
  
  /// Text to show if using text button
  final String buttonText;
  
  const DebugAccessButton({
    Key? key,
    this.useIconButton = true,
    this.color,
    this.buttonText = 'Debug Tools',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
    
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;
    
    if (useIconButton) {
      return IconButton(
        icon: const Icon(Icons.bug_report),
        tooltip: 'Debug Tools',
        color: buttonColor,
        onPressed: () => _openDebugScreen(context),
      );
    } else {
      return TextButton.icon(
        icon: const Icon(Icons.bug_report),
        label: Text(buttonText),
        style: TextButton.styleFrom(
          foregroundColor: buttonColor,
        ),
        onPressed: () => _openDebugScreen(context),
      );
    }
  }
  
  void _openDebugScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebugNavigationScreen(),
      ),
    );
  }
}