import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareAppWidget extends StatelessWidget {
  final bool isCompact;

  const ShareAppWidget({
    Key? key,
    this.isCompact = false,
  }) : super(key: key);

  Future<void> _shareApp() async {
    const String appUrl =
        'https://govvy--dev.web.app/'; // Replace with your actual URL
    const String message =
        'Check out govvy - an app that helps you connect with your local representatives and stay informed about government activities! Download it here: $appUrl';

    try {
      await Share.share(message);
    } catch (e) {
      debugPrint('Error sharing app: $e');
    }
  }

  Future<void> _copyLink() async {
    const String appUrl =
        'https://govvy--dev.web.app/'; // Replace with your actual URL

    await Clipboard.setData(const ClipboardData(text: appUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactVersion(context);
    }

    return _buildFullVersion(context);
  }

  Widget _buildCompactVersion(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Share govvy',
      onPressed: _shareApp,
    );
  }

  Widget _buildFullVersion(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Help spread the word!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share govvy with friends and family to help everyone stay connected with their local government.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareApp,
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share App'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await _copyLink();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Link'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
