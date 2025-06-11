// lib/widgets/info/about_dialog.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutGovvyDialog extends StatefulWidget {
  const AboutGovvyDialog({Key? key}) : super(key: key);

  @override
  State<AboutGovvyDialog> createState() => _AboutGovvyDialogState();
}

class _AboutGovvyDialogState extends State<AboutGovvyDialog> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _version = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text('About Govvy'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your civic engagement companion',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Govvy helps you stay informed and engaged with your local and federal government by providing easy access to:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            
            _buildFeatureItem(
              context,
              Icons.people,
              'Find Your Representatives',
              'Discover who represents you at every level of government',
            ),
            const SizedBox(height: 8),
            
            _buildFeatureItem(
              context,
              Icons.description,
              'Track Legislation',
              'Follow bills and laws that matter to you',
            ),
            const SizedBox(height: 8),
            
            _buildFeatureItem(
              context,
              Icons.how_to_vote,
              'Election Information',
              'Stay informed about upcoming elections and candidates',
            ),
            const SizedBox(height: 8),
            
            _buildFeatureItem(
              context,
              Icons.account_balance_wallet,
              'Campaign Finance',
              'Explore campaign contributions and political funding',
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Version $_version ($_buildNumber)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Icons.copyright,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  '© ${DateTime.now().year} Govvy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Made with ❤️ for civic engagement',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void showAboutGovvyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const AboutGovvyDialog(),
  );
}