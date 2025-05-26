// lib/screens/representatives/representative_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard functionality
import 'package:govvy/utils/district_type_formatter.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:govvy/widgets/representatives/role_info_widget.dart';
import 'package:govvy/widgets/representatives/email_template_dialog.dart';
import 'package:govvy/widgets/representatives/ai_representative_analysis_widget.dart';
import 'package:govvy/widgets/campaign_finance/campaign_finance_summary_card.dart';
// Removed: import 'package:govvy/providers/csv_representative_provider.dart';

// Extension methods for RepresentativeDetails to add additional functionality
extension RepresentativeDetailsExtension on RepresentativeDetails {
  // Check if this representative is a local or state representative (not federal)
  bool isLocalOrStateRepresentative() {
    final chamberUpper = chamber.toUpperCase();
    
    // Check if NOT a federal representative
    return !(
      chamberUpper.contains('NATIONAL') ||
      chamberUpper == 'SENATE' ||
      chamberUpper == 'HOUSE' ||
      chamberUpper == 'CONGRESS' ||
      chamberUpper == 'REPRESENTATIVE' ||
      chamberUpper == 'SENATOR'
    );
  }
}

class RepresentativeDetailsScreen extends StatefulWidget {
  final String bioGuideId;

  const RepresentativeDetailsScreen({
    Key? key,
    required this.bioGuideId,
  }) : super(key: key);

  @override
  State<RepresentativeDetailsScreen> createState() =>
      _RepresentativeDetailsScreenState();
}

class _RepresentativeDetailsScreenState
    extends State<RepresentativeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 6 tabs

    // Fix: Use addPostFrameCallback to defer API call until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRepresentativeDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRepresentativeDetails() async {
    final provider = Provider.of<CombinedRepresentativeProvider>(context, listen: false);
    await provider.fetchRepresentativeDetails(widget.bioGuideId);
    
    // Load campaign finance data if representative is found
    final rep = provider.selectedRepresentative;
    if (rep != null) {
      final financeProvider = Provider.of<CampaignFinanceProvider>(context, listen: false);
      await financeProvider.loadCandidateByName(rep.name);
    }
    
    // Removed: CSV bills loading
    // final rep = provider.selectedRepresentative;
    // if (rep != null && rep.isLocalOrStateRepresentative()) {
    //   // Use Provider.of to get the CSVRepresentativeProvider
    //   final csvProvider = Provider.of<CSVRepresentativeProvider>(context, listen: false);
    //   await csvProvider.initialize();
    //   await csvProvider.addCSVBillsToRepresentative(rep);
    // }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    // Handle different URL formats
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }

    final Uri uri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return;
    }

    // Clean the phone number
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri(scheme: 'tel', path: cleanedNumber);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not call $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String? email) async {
    if (email == null || email.isEmpty) {
      return;
    }

    // Check if it's a contact form URL instead of email
    if (email.startsWith('http')) {
      return _launchUrl(email);
    }

    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to copy text to clipboard
  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Method to show email template dialog
  void _showEmailTemplate(RepresentativeDetails rep) {
    showDialog(
      context: context,
      builder: (context) => EmailTemplateDialog(
        representative: rep,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CombinedRepresentativeProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isLoadingDetails;
        final rep = provider.selectedRepresentative;
        final isLoadingLegiscan = provider.isLoadingLegiscan;

        return Scaffold(
          appBar: AppBar(
            title: Text(rep?.name ?? 'Representative Details'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : rep == null
                  ? Center(
                      child: Text(
                        provider.errorMessage ?? 'Representative not found',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(  // Make entire page scrollable
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Representative header section
                          _buildRepresentativeHeader(rep),

                          // Contact information section
                          _buildContactInfoSection(rep),

                          // Tab bar
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabs: const [
                              Tab(text: 'Profile'),
                              Tab(text: 'AI Analysis'),
                              Tab(text: 'Role Info'),
                              Tab(text: 'Finance'),
                              Tab(text: 'Sponsored'),
                              Tab(text: 'Co-Sponsored'),
                            ],
                            labelColor: Theme.of(context).colorScheme.primary,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Theme.of(context).colorScheme.primary,
                          ),

                          // Tab content with fixed height to ensure it's visible
                          SizedBox(
                            height: 600, // Fixed height for the tab content
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildProfileTab(rep),
                                SingleChildScrollView(
                                  child: AIRepresentativeAnalysisWidget(
                                    representative: rep,
                                    votingHistory: rep.sponsoredBills?.map((bill) => {
                                      'bill_title': bill.title,
                                      'position': 'Sponsored',
                                      'date': 'Sponsored Bill'
                                    }).toList(),
                                  ),
                                ),
                                RoleInfoWidget(
                                  role: rep.chamber,
                                  officeName: rep.office ?? '',
                                  district: rep.district,
                                ),
                                _buildFinanceTab(),
                                _buildBillsTab(
                                  rep.sponsoredBills, 
                                  'No sponsored bills found',
                                  isLoadingLegiscan,
                                ),
                                _buildBillsTab(
                                  rep.cosponsoredBills,
                                  'No co-sponsored bills found',
                                  false, // We don't load LegiScan bills for cosponsored tab
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildRepresentativeHeader(RepresentativeDetails rep) {
    Color partyColor;
    String partyName;

    // Determine party color and full name
    switch (rep.party.toLowerCase()) {
      case 'r':
      case 'republican':
        partyColor = const Color(0xFFE91D0E);
        partyName = 'Republican';
        break;
      case 'd':
      case 'democrat':
      case 'democratic':
        partyColor = const Color(0xFF232066);
        partyName = 'Democrat';
        break;
      case 'i':
      case 'independent':
        partyColor = const Color(0xFF39BA4C);
        partyName = 'Independent';
        break;
      default:
        partyColor = Colors.grey;
        partyName = rep.party.isEmpty ? 'Unknown' : rep.party;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Representative image
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                rep.imageUrl != null ? NetworkImage(rep.imageUrl!) : null,
            child: rep.imageUrl == null
                ? Icon(Icons.person, size: 40, color: Colors.grey.shade400)
                : null,
          ),
          const SizedBox(width: 16),

          // Representative info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rep.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: partyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      partyName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedRoleTitle(rep),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedRoleTitle(RepresentativeDetails rep) {
    // Use the role field if available
    if (rep.role != null && rep.role!.isNotEmpty) {
      return '${rep.role}, ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}';
    }

    // Otherwise, determine position from chamber
    final String chamberUpper = rep.chamber.toUpperCase();

    if (chamberUpper == 'NATIONAL_UPPER' || chamberUpper == 'SENATE') {
      return 'U.S. Senator, ${rep.state}';
    } else if (chamberUpper == 'NATIONAL_LOWER' ||
        chamberUpper == 'HOUSE' ||
        chamberUpper == 'HOUSE OF REPRESENTATIVES') {
      return 'U.S. Representative, ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}';
    } else if (chamberUpper == 'STATE_UPPER') {
      return 'State Senator, ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}';
    } else if (chamberUpper == 'STATE_LOWER') {
      return 'State Representative, ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}';
    } else if (chamberUpper == 'STATE_EXEC') {
      return 'State Executive Official, ${rep.state}';
    }

    // Don't use displayTitle or office at all - these may contain the address
    // Instead, use the district type formatter but pass null for the office parameter
    return DistrictTypeFormatter.formatRoleWithLocation(
        rep.chamber, null, rep.state, rep.district);
  }

  Widget _buildContactInfoSection(RepresentativeDetails rep) {
    // Check if we have direct contact info
    final bool hasDirectContact = rep.phone != null || rep.email != null || rep.website != null;
    final bool hasSocialMedia = rep.socialMedia != null && rep.socialMedia!.isNotEmpty;
    
    // State variables for the expansion panels
    final ValueNotifier<bool> contactExpanded = ValueNotifier<bool>(true);
    final ValueNotifier<bool> socialExpanded = ValueNotifier<bool>(true);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,  // Use min to prevent expansion
        children: [
          // Direct contact information section
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: contactExpanded,
              builder: (context, isExpanded, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,  // Use min to prevent expansion
                  children: [
                    // Header with expansion toggle
                    InkWell(
                      onTap: () {
                        contactExpanded.value = !isExpanded;
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.contact_phone,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Contact Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Expandable content
                    if (isExpanded)  // Use conditional rendering instead of AnimatedCrossFade
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16.0,
                        ),
                        child: _buildContactContent(rep, hasDirectContact),
                      ),
                  ],
                );
              },
            ),
          ),
          
          // Only show social media section if there's social media
          if (hasSocialMedia) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: socialExpanded,
                builder: (context, isExpanded, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,  // Use min to prevent expansion
                    children: [
                      // Social media header with expansion toggle
                      InkWell(
                        onTap: () {
                          socialExpanded.value = !isExpanded;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.share,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Social Media',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                '${rep.socialMedia?.length ?? 0} accounts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Expandable social media content
                      if (isExpanded)  // Use conditional rendering instead of AnimatedCrossFade
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 16.0,
                          ),
                          child: _buildSocialMediaContent(rep),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build the contact information content
  Widget _buildContactContent(RepresentativeDetails rep, bool hasDirectContact) {
    if (!hasDirectContact) {
      // No contact info available
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No direct contact information available for this representative.',
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ],
        ),
      );
    }
    
    // Build a list of contact items
    List<Widget> contactItems = [];
    
    if (rep.phone != null) {
      contactItems.add(
        _buildContactItem(
          icon: Icons.phone,
          title: 'Phone',
          value: rep.phone!,
          onTap: () => _makePhoneCall(rep.phone),
          onLongPress: () => _copyToClipboard(rep.phone!, 'Phone number'),
        ),
      );
    }
    
    if (rep.email != null) {
      contactItems.add(
        _buildContactItem(
          // If the email is actually a web form, use a different icon
          icon: rep.email!.startsWith('http') ? Icons.web : Icons.email,
          title: rep.email!.startsWith('http') ? 'Contact Form' : 'Email',
          value: rep.email!,
          onTap: () => _sendEmail(rep.email),
          onLongPress: () => _copyToClipboard(rep.email!, 
            rep.email!.startsWith('http') ? 'Contact form URL' : 'Email address'),
        ),
      );
    }
    
    if (rep.office != null) {
      contactItems.add(
        _buildContactItem(
          icon: Icons.location_on,
          title: 'Office',
          value: rep.office!,
          onTap: null,
          onLongPress: () => _copyToClipboard(rep.office!, 'Office address'),
        ),
      );
    }
    
    if (rep.website != null) {
      contactItems.add(
        _buildContactItem(
          icon: Icons.language,
          title: 'Website',
          value: rep.website!,
          onTap: () => _launchUrl(rep.website),
          onLongPress: () => _copyToClipboard(rep.website!, 'Website URL'),
        ),
      );
    }
    
    // Add Email Template button if there's an email
    if (rep.email != null) {
      contactItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.email_outlined),
            label: const Text('Compose Email'),
            onPressed: () => _showEmailTemplate(rep),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contactItems,
    );
  }

  // Helper method to build the social media content
  Widget _buildSocialMediaContent(RepresentativeDetails rep) {
    if (rep.socialMedia == null || rep.socialMedia!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Group social media by platform
    final Map<String, List<String>> groupedSocial = {};
    
    for (var account in rep.socialMedia!) {
      final parts = account.split(':');
      if (parts.length < 2) continue;
      
      String platform = parts[0].trim().toLowerCase();
      String accountInfo = parts.sublist(1).join(':').trim();
      
      // Normalize platform names
      if (platform.startsWith('facebook')) {
        platform = 'facebook';
      }
      
      // Add to appropriate group
      if (!groupedSocial.containsKey(platform)) {
        groupedSocial[platform] = [];
      }
      groupedSocial[platform]!.add(accountInfo);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,  // Use min to prevent expansion
      children: groupedSocial.entries.map((entry) {
        final platform = entry.key;
        final accounts = entry.value;
        
        IconData icon;
        Color color;
        
        // Determine icon and color based on platform
        switch (platform) {
          case 'twitter':
            icon = Icons.flutter_dash; // Use as Twitter icon
            color = Colors.blue;
            break;
          case 'facebook':
            icon = Icons.facebook;
            color = Colors.indigo;
            break;
          case 'instagram':
            icon = Icons.camera_alt;
            color = Colors.pink;
            break;
          case 'youtube':
            icon = Icons.play_circle_fill;
            color = Colors.red;
            break;
          case 'linkedin':
            icon = Icons.work;
            color = Colors.blue.shade800;
            break;
          case 'flickr':
            icon = Icons.photo_camera;
            color = Colors.purple;
            break;
          default:
            icon = Icons.link;
            color = Colors.grey;
        }
        
        // Format platform name for display
        String displayPlatform = platform.split('-')[0];
        displayPlatform = displayPlatform.capitalize();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,  // Use min to prevent expansion
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    displayPlatform,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...accounts.map((account) {
                // Build URL based on platform and account
                String? url;
                
                if (account.startsWith('http')) {
                  // Already a URL
                  url = account;
                } else {
                  // Try to build URL
                  switch (platform) {
                    case 'twitter':
                      url = 'https://twitter.com/$account';
                      break;
                    case 'facebook':
                      url = 'https://facebook.com/$account';
                      break;
                    case 'instagram':
                      url = 'https://instagram.com/$account';
                      break;
                    case 'youtube':
                      if (account.startsWith('@')) {
                        url = 'https://youtube.com/${account.substring(1)}';
                      } else {
                        url = 'https://youtube.com/$account';
                      }
                      break;
                    case 'linkedin':
                      if (account.contains('linkedin.com')) {
                        url = account;
                      } else {
                        url = 'https://linkedin.com/in/$account';
                      }
                      break;
                    case 'flickr':
                      url = 'https://flickr.com/photos/$account';
                      break;
                  }
                }
                
                // Create tappable list item for each account
                return InkWell(
                  onTap: url != null ? () => _launchUrl(url!) : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 26), // Indent for alignment
                        Expanded(
                          child: Text(
                            account,
                            style: TextStyle(
                              color: url != null ? Theme.of(context).colorScheme.primary : Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (url != null)
                          Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper widget for contact items
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required Function()? onTap,
    required Function()? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: onTap != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                icon == Icons.phone
                    ? Icons.call
                    : icon == Icons.email
                        ? Icons.send
                        : Icons.open_in_new,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            if (onLongPress != null)
              const Tooltip(
                message: 'Long press to copy',
                child: Icon(
                  Icons.copy,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(RepresentativeDetails rep) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section with better spacing and styling
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Enhanced about text with more comprehensive description
          _buildAboutText(rep),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Additional profile details
          if (rep.dateOfBirth != null)
            _buildInfoSection('Date of Birth', rep.dateOfBirth),
          if (rep.gender != null) _buildInfoSection('Gender', rep.gender),

          // Add position information
          _buildInfoSection('Position', _getPositionTitle(rep)),

          // Add jurisdiction information
          _buildInfoSection('Jurisdiction', _getJurisdiction(rep)),
        ],
      ),
    );
  }

  // Helper to build a more descriptive About text
  Widget _buildAboutText(RepresentativeDetails rep) {
    // For state executive officials like Manny Diaz
    if (rep.chamber.toUpperCase() == 'STATE_EXEC' && rep.state == 'FL') {
      // Specific content for Manny Diaz
      if (rep.name.contains('Diaz')) {
        return Text(
          'Manny Diaz serves as the Commissioner of Education in Florida\'s executive branch. In this role, he oversees the state\'s public education system, including policies related to K-12 schools, vocational training, and higher education institutions across Florida.',
          style: Theme.of(context).textTheme.bodyLarge,
        );
      }

      // Generic state executive
      return Text(
        '${rep.name} serves in the executive branch of ${rep.state} state government as ${rep.office ?? "a state official"}. Executive branch officials are responsible for implementing and enforcing state laws and overseeing state agencies and departments.',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    // Generate appropriate description based on the role
    String formattedLevel =
        DistrictTypeFormatter.formatDistrictType(rep.chamber);
    String aboutText;

    // Federal representatives
    if (rep.chamber.toUpperCase() == 'NATIONAL_UPPER' ||
        rep.chamber.toLowerCase() == 'senate') {
      aboutText =
          '${rep.name} is a United States Senator representing ${rep.state}. Senators serve 6-year terms and represent the entire state in the upper chamber of Congress.';
    } else if (rep.chamber.toUpperCase() == 'NATIONAL_LOWER' ||
        rep.chamber.toLowerCase() == 'house') {
      aboutText =
          '${rep.name} is a member of the U.S. House of Representatives representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}. Representatives serve 2-year terms and represent specific geographic districts within their state.';
    }
    // State representatives
    else if (rep.chamber.toUpperCase().startsWith('STATE_')) {
      if (rep.chamber.toUpperCase() == 'STATE_UPPER') {
        aboutText =
            '${rep.name} is a State Senator representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}. State Senators create laws and policies at the state level and typically serve 4-year terms.';
      } else if (rep.chamber.toUpperCase() == 'STATE_LOWER') {
        aboutText =
            '${rep.name} is a State Representative serving in the ${rep.state} House of Representatives${rep.district != null ? ' for District ${rep.district}' : ''}. State Representatives draft and vote on state legislation and typically serve 2-year terms.';
      } else if (rep.chamber.toUpperCase() == 'STATE_EXEC') {
        aboutText =
            '${rep.name} serves in the executive branch of ${rep.state} state government${rep.office != null ? ' as ${rep.office}' : ''}. State executive officials implement state laws and oversee various state departments and programs.';
      } else {
        aboutText =
            '${rep.name} is a member of the $formattedLevel representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.';
      }
    }
    // Local representatives
    else if (rep.chamber.toUpperCase() == 'LOCAL_EXEC' ||
        rep.chamber.toUpperCase() == 'MAYOR') {
      aboutText =
          '${rep.name} is the Mayor of ${rep.district ?? rep.state}. As Mayor, ${rep.name.split(' ')[0]} oversees city operations, proposes budgets, and represents the city in official capacities.';
    } else if (rep.chamber.toUpperCase() == 'LOCAL' ||
        rep.chamber.toUpperCase() == 'CITY') {
      aboutText =
          '${rep.name} is a member of the City Council for ${rep.district ?? rep.state}. City Council members create local ordinances, approve city budgets, and address constituent needs at the local level.';
    } else if (rep.chamber.toUpperCase() == 'COUNTY') {
      aboutText =
          '${rep.name} is a County Commissioner for ${rep.district ?? rep.state}. County Commissioners manage county resources, oversee county departments, and establish policies for unincorporated areas.';
    } else if (rep.chamber.toUpperCase() == 'SCHOOL') {
      aboutText =
          '${rep.name} is a member of the School Board for ${rep.district ?? rep.state}. School Board members set educational policies, approve school district budgets, and oversee district operations.';
    }
    // Fallback for other types
    else {
      aboutText =
          '${rep.name} is a member of the $formattedLevel representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.';
    }

    // Don't add office information anymore - it's causing confusion with the address

    return Text(
      aboutText,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildInfoSection(String title, String? content) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _getPositionTitle(RepresentativeDetails rep) {
    // Don't use office field as it contains the physical address
    // Instead, determine position from chamber information

    final String chamberUpper = rep.chamber.toUpperCase();

    if (chamberUpper == 'NATIONAL_UPPER' || chamberUpper == 'SENATE') {
      return 'U.S. Senator';
    } else if (chamberUpper == 'NATIONAL_LOWER' ||
        chamberUpper == 'HOUSE' ||
        chamberUpper == 'HOUSE OF REPRESENTATIVES') {
      return 'U.S. Representative';
    } else if (chamberUpper == 'STATE_UPPER') {
      return 'State Senator';
    } else if (chamberUpper == 'STATE_LOWER') {
      return 'State Representative';
    } else if (chamberUpper == 'STATE_EXEC') {
      return 'State Executive Official';
    } else if (chamberUpper == 'LOCAL_EXEC' || chamberUpper.contains('MAYOR')) {
      return 'Mayor';
    } else if (chamberUpper == 'LOCAL' || chamberUpper.contains('CITY')) {
      return 'City Council Member';
    } else if (chamberUpper.contains('COUNTY')) {
      return 'County Commissioner';
    } else if (chamberUpper.contains('SCHOOL')) {
      return 'School Board Member';
    }

    // Default to formatted district type
    return DistrictTypeFormatter.formatDistrictType(rep.chamber);
  }

  // Helper to get jurisdiction information
  String _getJurisdiction(RepresentativeDetails rep) {
    final String chamberUpper = rep.chamber.toUpperCase();

    if (chamberUpper.startsWith('NATIONAL_')) {
      return rep.state;
    } else if (chamberUpper.startsWith('STATE_')) {
      if (rep.district != null) {
        return '${rep.state} District ${rep.district}';
      } else {
        return rep.state;
      }
    } else if (chamberUpper == 'LOCAL_EXEC' ||
        chamberUpper == 'LOCAL' ||
        chamberUpper.contains('CITY') ||
        chamberUpper.contains('MAYOR')) {
      return rep.district ?? rep.state;
    } else if (chamberUpper.contains('COUNTY')) {
      return rep.district ?? '${rep.state} County';
    } else if (chamberUpper.contains('SCHOOL')) {
      return rep.district ?? '${rep.state} School District';
    }

    // Default
    return rep.district ?? rep.state;
  }

  // Build the bills tab
  Widget _buildBillsTab(
    List<RepresentativeBill> bills, 
    String emptyMessage,
    bool isLoadingBills,
  ) {
    // Show loading indicator if bills are being loaded
    if (isLoadingBills) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading additional bills...',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (bills.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final bill = bills[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bill.source == 'CSV' || bill.source == 'LegiScan'
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${bill.billType.toUpperCase()} ${bill.billNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (bill.source == 'CSV' || bill.source == 'LegiScan')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      bill.source == 'CSV' ? 'Local' : 'State',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (bill.introducedDate != null)
                  Expanded(
                    child: Text(
                      'Introduced: ${bill.introducedDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bill.title,
              style: const TextStyle(fontSize: 16),
            ),
            if (bill.latestAction != null) ...[
              const SizedBox(height: 4),
              Text(
                'Latest Action: ${bill.latestAction}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Session: ${bill.congress}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFinanceTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: CampaignFinanceSummaryCard(),
    );
  }
}

// Helper extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
  }
}