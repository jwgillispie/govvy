import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class LandingPageShareSection extends StatelessWidget {
  const LandingPageShareSection({Key? key}) : super(key: key);

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

  Future<void> _copyLink(BuildContext context) async {
    const String appUrl =
        'https://govvy--dev.web.app/'; // Replace with your actual URL

    await Clipboard.setData(const ClipboardData(text: appUrl));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 64,
        horizontal: isMobile ? 24 : 32,
      ),
      color: const Color(0xFFD1C4E9), // Deep Purple 100
      child: Column(
        children: [
          Text(
            'Share Democracy',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: isMobile ? double.infinity : 600,
            child: Text(
              'Help spread the word about govvy and empower more citizens to connect with their local government.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Social sharing buttons
          isMobile
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _shareApp,
                        icon: const Icon(Icons.share),
                        label: const Text('Share govvy'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _copyLink(context),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Link'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: _shareApp,
                        icon: const Icon(Icons.share),
                        label: const Text('Share govvy'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton.icon(
                        onPressed: () => _copyLink(context),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Link'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
