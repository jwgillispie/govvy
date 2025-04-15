// lib/widgets/welcome/signup_success_dialog.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupSuccessDialog extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback? onContinue;
  final String? name;
  
  const SignupSuccessDialog({
    Key? key,
    required this.onDismiss,
    this.onContinue,
    this.name,
  }) : super(key: key);

  Future<void> _shareApp() async {
    const String appUrl = 'https://govvy--dev.web.app/';
    final String message = 'I just joined govvy - an app that helps connect with local representatives and stay informed about government activities! Join me: $appUrl';

    try {
      await Share.share(message);
    } catch (e) {
      debugPrint('Error sharing app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = name != null && name!.isNotEmpty 
        ? 'Welcome, $name!' 
        : 'Welcome to govvy!';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Welcome icon
            Container(
              height: 80,
              width: 80,
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 40,
              ),
            ),
            
            // Welcome title
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Welcome message
            const Text(
              'Thank you for joining the movement! Help us grow the community by sharing govvy with your friends and family.',
              style: TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Share button
            OutlinedButton.icon(
              onPressed: _shareApp,
              icon: const Icon(Icons.share),
              label: const Text('Share govvy'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Buttons for navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinue ?? onDismiss,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Continue'),
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