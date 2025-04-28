// lib/widgets/representatives/email_template_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailTemplateDialog extends StatefulWidget {
  final RepresentativeDetails representative;

  const EmailTemplateDialog({
    Key? key,
    required this.representative,
  }) : super(key: key);

  @override
  State<EmailTemplateDialog> createState() => _EmailTemplateDialogState();
}

class _EmailTemplateDialogState extends State<EmailTemplateDialog> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderAddressController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();

  bool _includeContactInfo = true;

  @override
  void initState() {
    super.initState();
    // Initialize with default template
    _subjectController.text = 'Constituent Feedback: [YOUR ISSUE]';
    
    // Create default body template
    String defaultBody = 'Dear ${_getProperTitle()},\n\n'
        'My name is [YOUR NAME] and I am a constituent from [YOUR CITY/NEIGHBORHOOD]. '
        'I am writing to express my [SUPPORT/OPPOSITION/CONCERN] regarding [ISSUE].\n\n'
        '[EXPLAIN WHY THIS ISSUE IS IMPORTANT TO YOU PERSONALLY. CONSIDER ADDING A BRIEF STORY ABOUT HOW THIS AFFECTS YOU, YOUR FAMILY, OR YOUR COMMUNITY.]\n\n'
        '[MENTION ANY RELEVANT DATA OR FACTS THAT SUPPORT YOUR POSITION. OPTIONAL BUT RECCOMENDED]\n\n'
        'I respectfully urge you to [SPECIFIC ACTION YOU\'D LIKE THEM TO TAKE: SUPPORT/OPPOSE A BILL, ADDRESS AN ISSUE, ETC.].\n\n'
        'Thank you for your time and consideration on this important matter.\n\n'
        'Sincerely,\n\n'
        '[YOUR NAME]\n';
    
    if (_includeContactInfo) {
      defaultBody += '[YOUR ADDRESS]\n'
          '[YOUR PHONE NUMBER]\n'
          '[YOUR EMAIL]';
    }
    
    _bodyController.text = defaultBody;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _senderNameController.dispose();
    _senderAddressController.dispose();
    _senderPhoneController.dispose();
    super.dispose();
  }

  String _getProperTitle() {
    final role = widget.representative.role?.toLowerCase() ?? '';
    final chamber = widget.representative.chamber.toUpperCase();
    
    if (role.contains('senator') || chamber.contains('SENATE') || chamber == 'NATIONAL_UPPER') {
      return 'Senator ${widget.representative.name.split(' ').last}';
    } else if (role.contains('representative') || chamber == 'NATIONAL_LOWER' || chamber.contains('HOUSE')) {
      return 'Representative ${widget.representative.name.split(' ').last}';
    } else if (role.contains('mayor') || chamber.contains('MAYOR') || chamber == 'LOCAL_EXEC') {
      return 'Mayor ${widget.representative.name.split(' ').last}';
    } else if (chamber.contains('GOVERNOR')) {
      return 'Governor ${widget.representative.name.split(' ').last}';
    } else if (role.contains('council') || chamber == 'LOCAL' || chamber.contains('CITY')) {
      return 'Council Member ${widget.representative.name.split(' ').last}';
    } else if (chamber.contains('COUNTY')) {
      return 'Commissioner ${widget.representative.name.split(' ').last}';
    } else {
      // Default to Honorable for other positions
      return 'The Honorable ${widget.representative.name}';
    }
  }

  void _sendEmail() async {
    final email = widget.representative.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address available for this representative')),
      );
      return;
    }

    // Construct email URI
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': _subjectController.text,
        'body': _bodyController.text,
      },
    );

    // Try to launch email client
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client')),
        );
      }
    }
  }

  void _copyToClipboard() {
    final fullEmail = 'Subject: ${_subjectController.text}\n\n${_bodyController.text}';
    Clipboard.setData(ClipboardData(text: fullEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email template copied to clipboard')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Email ${widget.representative.name}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Content - Scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Helper text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tips for Effective Communication',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Personalize this template with your own information. Replace the bracketed text [LIKE THIS] with your specific details. Be clear, concise, and respectful.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subject field
                    Text(
                      'Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        hintText: 'Email subject',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email body
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.refresh, size: 16),
                          label: Text('Reset template'),
                          onPressed: () {
                            setState(() {
                              initState();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _bodyController,
                      decoration: InputDecoration(
                        hintText: 'Email body',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 15,
                      minLines: 10,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Include contact info option
                    Row(
                      children: [
                        Checkbox(
                          value: _includeContactInfo,
                          onChanged: (value) {
                            setState(() {
                              _includeContactInfo = value ?? true;
                              // Refresh template
                              initState();
                            });
                          },
                        ),
                        const Text('Include contact information'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(Icons.copy),
                    label: Text('Copy'),
                    onPressed: _copyToClipboard,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.email),
                    label: Text('Send'),
                    onPressed: widget.representative.email != null 
                        ? _sendEmail 
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}