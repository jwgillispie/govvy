// lib/widgets/info/privacy_policy_dialog.dart
import 'package:flutter/material.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.privacy_tip,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('Privacy Policy'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Effective Date: ${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSection(
                context,
                'Information We Collect',
                'Govvy collects the following types of information to provide you with our civic engagement services:\n\n'
                '• Account Information: Email address, name, and phone number for account creation and authentication\n'
                '• Location Data: Your address or location to find relevant representatives and legislation\n'
                '• Usage Data: Information about how you use the app to improve our services\n'
                '• Device Information: Basic device and app version information for technical support',
              ),
              
              _buildSection(
                context,
                'How We Use Your Information',
                'We use your information to:\n\n'
                '• Provide accurate representative and legislative information for your location\n'
                '• Send you relevant civic updates and notifications (if enabled)\n'
                '• Improve app functionality and user experience\n'
                '• Provide customer support when needed\n'
                '• Ensure the security and integrity of our services',
              ),
              
              _buildSection(
                context,
                'Information Sharing',
                'We do not sell, trade, or rent your personal information to third parties. We may share information only in the following circumstances:\n\n'
                '• With your explicit consent\n'
                '• To comply with legal obligations or court orders\n'
                '• To protect the rights, property, or safety of Govvy, our users, or others\n'
                '• With service providers who help us operate the app (under strict confidentiality agreements)',
              ),
              
              _buildSection(
                context,
                'Data Security',
                'We implement appropriate technical and organizational measures to protect your personal information, including:\n\n'
                '• Encryption of data in transit and at rest\n'
                '• Regular security assessments and updates\n'
                '• Limited access to personal information on a need-to-know basis\n'
                '• Secure authentication and authorization systems',
              ),
              
              _buildSection(
                context,
                'Your Rights',
                'You have the right to:\n\n'
                '• Access and review your personal information\n'
                '• Correct or update your information\n'
                '• Delete your account and associated data\n'
                '• Opt out of non-essential communications\n'
                '• Export your data in a portable format',
              ),
              
              _buildSection(
                context,
                'Third-Party Services',
                'Govvy integrates with legitimate government and civic data sources, including:\n\n'
                '• Government APIs for representative and legislative data\n'
                '• Mapping services for location-based features\n'
                '• Analytics services to improve app performance\n\n'
                'These services may have their own privacy policies, and we encourage you to review them.',
              ),
              
              _buildSection(
                context,
                'Changes to This Policy',
                'We may update this privacy policy from time to time. We will notify you of any material changes through the app or via email. Your continued use of Govvy after such changes constitutes acceptance of the updated policy.',
              ),
              
              _buildSection(
                context,
                'Contact Us',
                'If you have questions about this privacy policy or your personal information, please contact us:\n\n'
                'Email: privacy@govvy.app\n'
                'Subject: Privacy Policy Inquiry',
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your privacy is important to us. We are committed to protecting your personal information.',
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

void showPrivacyPolicyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const PrivacyPolicyDialog(),
  );
}