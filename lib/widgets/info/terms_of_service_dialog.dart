// lib/widgets/info/terms_of_service_dialog.dart
import 'package:flutter/material.dart';

class TermsOfServiceDialog extends StatelessWidget {
  const TermsOfServiceDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.description,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('Terms of Service'),
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
                'Acceptance of Terms',
                'By downloading, installing, or using the Govvy mobile application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
              ),
              
              _buildSection(
                context,
                'Description of Service',
                'Govvy is a civic engagement platform that provides:\n\n'
                '• Information about your elected representatives\n'
                '• Legislative tracking and bill information\n'
                '• Election and candidate information\n'
                '• Campaign finance data\n'
                '• Tools to contact your representatives\n\n'
                'Our service is provided for informational and civic engagement purposes.',
              ),
              
              _buildSection(
                context,
                'User Accounts and Responsibilities',
                'To use certain features of Govvy, you may need to create an account. You agree to:\n\n'
                '• Provide accurate and complete information\n'
                '• Maintain the security of your account credentials\n'
                '• Notify us immediately of any unauthorized use\n'
                '• Be responsible for all activities under your account\n'
                '• Use the service only for lawful civic engagement purposes',
              ),
              
              _buildSection(
                context,
                'Acceptable Use',
                'You agree NOT to use Govvy to:\n\n'
                '• Harass, threaten, or abuse representatives or other users\n'
                '• Spread false or misleading information\n'
                '• Attempt to disrupt or compromise the service\n'
                '• Use automated tools to access the service without permission\n'
                '• Violate any applicable laws or regulations\n'
                '• Impersonate others or provide false information',
              ),
              
              _buildSection(
                context,
                'Data Accuracy and Disclaimers',
                'While we strive to provide accurate and up-to-date information:\n\n'
                '• Information is sourced from public records and government APIs\n'
                '• We cannot guarantee 100% accuracy or completeness\n'
                '• Users should verify important information through official sources\n'
                '• Govvy is not responsible for decisions made based on the information provided\n'
                '• Legislative and representative information may change frequently',
              ),
              
              _buildSection(
                context,
                'Intellectual Property',
                'The Govvy app, including its design, features, and content (excluding government data), is owned by Govvy and protected by intellectual property laws. You may not:\n\n'
                '• Copy, modify, or distribute the app or its content\n'
                '• Reverse engineer or attempt to extract source code\n'
                '• Use our trademarks or branding without permission',
              ),
              
              _buildSection(
                context,
                'Privacy and Data Protection',
                'Your privacy is important to us. Our collection and use of personal information is governed by our Privacy Policy, which is incorporated into these terms by reference.',
              ),
              
              _buildSection(
                context,
                'Limitation of Liability',
                'To the fullest extent permitted by law, Govvy shall not be liable for:\n\n'
                '• Any indirect, incidental, or consequential damages\n'
                '• Loss of data, profits, or business opportunities\n'
                '• Damages resulting from use or inability to use the service\n'
                '• Actions taken based on information provided in the app\n\n'
                'Our total liability shall not exceed the amount you paid for the service (if any).',
              ),
              
              _buildSection(
                context,
                'Service Availability',
                'We strive to maintain high availability, but:\n\n'
                '• The service may be temporarily unavailable for maintenance\n'
                '• We do not guarantee uninterrupted access\n'
                '• Third-party data sources may affect service availability\n'
                '• We reserve the right to modify or discontinue features',
              ),
              
              _buildSection(
                context,
                'Termination',
                'We may terminate or suspend your account and access to the service at our discretion, including for:\n\n'
                '• Violation of these terms\n'
                '• Fraudulent or abusive behavior\n'
                '• Extended periods of inactivity\n\n'
                'You may terminate your account at any time through the app settings.',
              ),
              
              _buildSection(
                context,
                'Changes to Terms',
                'We may update these Terms of Service from time to time. We will notify users of material changes through the app or email. Continued use after changes constitutes acceptance of the new terms.',
              ),
              
              _buildSection(
                context,
                'Governing Law',
                'These terms are governed by the laws of the United States and applicable state laws. Any disputes will be resolved through binding arbitration or in courts of competent jurisdiction.',
              ),
              
              _buildSection(
                context,
                'Contact Information',
                'For questions about these Terms of Service, contact us:\n\n'
                'Email: legal@govvy.app\n'
                'Subject: Terms of Service Inquiry',
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
                      Icons.gavel,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'By using Govvy, you agree to these terms and our commitment to responsible civic engagement.',
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

void showTermsOfServiceDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const TermsOfServiceDialog(),
  );
}