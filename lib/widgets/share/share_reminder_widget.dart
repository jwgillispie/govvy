// lib/widgets/share/share_reminder_widget.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShareReminderWidget extends StatefulWidget {
  final VoidCallback? onDismiss;

  const ShareReminderWidget({
    Key? key,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<ShareReminderWidget> createState() => _ShareReminderWidgetState();

  static Future<bool> shouldShowReminder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt('last_share_reminder') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Show reminder if it hasn't been shown in the last 7 days
      return (now - lastShown) > (1000 * 60 * 60 * 24 * 7);
    } catch (e) {
      debugPrint('Error checking share reminder status: $e');
      return false;
    }
  }
}

class _ShareReminderWidgetState extends State<ShareReminderWidget> {
  Future<void> _shareApp() async {
    const String appUrl = 'https://govvy--dev.web.app/';
    const String message =
        'I\'m using govvy to connect with my local representatives and stay informed! Join me: $appUrl';

    try {
      await Share.share(message);
      // Mark reminder as shown to prevent showing again too soon
      await _markReminderAsShown();

      if (widget.onDismiss != null && mounted) {
        widget.onDismiss!();
      }
    } catch (e) {
      debugPrint('Error sharing app: $e');
    }
  }

  Future<void> _markReminderAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('last_share_reminder', now);
    } catch (e) {
      debugPrint('Error marking reminder as shown: $e');
    }
  }

  Future<void> _dismissForLater() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      // Set a shorter period before showing again if dismissed
      await prefs.setInt('last_share_reminder',
          now - (1000 * 60 * 60 * 24 * 3)); // 3 days shorter

      if (widget.onDismiss != null && mounted) {
        widget.onDismiss!();
      }
    } catch (e) {
      debugPrint('Error dismissing reminder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  radius: 20,
                  child: Icon(
                    Icons.people_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Spread civic engagement',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Help friends and family connect with their representatives by sharing govvy!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _dismissForLater,
                  child: const Text('Later'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _shareApp,
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
