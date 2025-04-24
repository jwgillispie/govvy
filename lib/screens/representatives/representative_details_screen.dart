// lib/screens/representatives/representative_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard functionality
import 'package:govvy/utils/district_type_formatter.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:govvy/widgets/representatives/role_info_widget.dart';
import 'package:govvy/data/government_roles.dart';

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
    _tabController = TabController(length: 4, vsync: this); // Updated to 4 tabs

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
    final provider =
        Provider.of<CombinedRepresentativeProvider>(context, listen: false);
    await provider.fetchRepresentativeDetails(widget.bioGuideId);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<CombinedRepresentativeProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isLoadingDetails;
        final rep = provider.selectedRepresentative;

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
                  : Column(
                      children: [
                        // Representative header section
                        _buildRepresentativeHeader(rep),

                        // Contact information section
                        _buildContactInfoSection(rep),

                        // Tab bar
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Profile'),
                            Tab(text: 'Role Info'),
                            Tab(text: 'Sponsored'),
                            Tab(text: 'Co-Sponsored'),
                          ],
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                        ),

                        // Tab content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildProfileTab(rep),
                              RoleInfoWidget(
                                role: rep.chamber,
                                officeName: rep.office ?? '',
                                district: rep.district,
                              ),
                              _buildBillsTab(rep.sponsoredBills,
                                  'No sponsored bills found'),
                              _buildBillsTab(rep.cosponsoredBills,
                                  'No co-sponsored bills found'),
                            ],
                          ),
                        ),
                      ],
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
    // Check if this is a specific role like Manny Diaz
    if (rep.chamber.toUpperCase() == 'STATE_EXEC' &&
        rep.office != null &&
        rep.office!.isNotEmpty) {
      return '${rep.office}, ${rep.state}';
    }

    // For other cases, use the formatter
    return DistrictTypeFormatter.formatRoleWithLocation(
        rep.chamber, rep.office, rep.state, rep.district);
  }

  // Widget for contact information with improved layout
  Widget _buildContactInfoSection(RepresentativeDetails rep) {
    // Check if we have direct contact info
    final bool hasDirectContact = rep.phone != null || rep.email != null;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // If we have direct contact info, show it
          if (hasDirectContact)
            Column(
              children: [
                if (rep.phone != null)
                  _buildContactItem(
                    icon: Icons.phone,
                    title: 'Phone',
                    value: rep.phone!,
                    onTap: () => _makePhoneCall(rep.phone),
                    onLongPress: () =>
                        _copyToClipboard(rep.phone!, 'Phone number'),
                  ),
                if (rep.email != null)
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email',
                    value: rep.email!,
                    onTap: () => _sendEmail(rep.email),
                    onLongPress: () =>
                        _copyToClipboard(rep.email!, 'Email address'),
                  ),
                if (rep.office != null)
                  _buildContactItem(
                    icon: Icons.location_on,
                    title: 'Office',
                    value: rep.office!,
                    onTap: null,
                    onLongPress: () =>
                        _copyToClipboard(rep.office!, 'Office address'),
                  ),
                if (rep.website != null)
                  _buildContactItem(
                    icon: Icons.language,
                    title: 'Website',
                    value: rep.website!,
                    onTap: () => _launchUrl(rep.website),
                    onLongPress: () =>
                        _copyToClipboard(rep.website!, 'Website URL'),
                  ),
              ],
            )
          else if (rep.website != null)
            // If we only have website, show a message and website button
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Direct contact information not available. Please visit the representative\'s website for contact details.',
                          style: TextStyle(color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildContactItem(
                  icon: Icons.language,
                  title: 'Website',
                  value: rep.website!,
                  onTap: () => _launchUrl(rep.website),
                  onLongPress: () =>
                      _copyToClipboard(rep.website!, 'Website URL'),
                ),
              ],
            )
          else
            // No contact info available
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No contact information available for this representative.',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // If there's social media, show it
          if (rep.socialMedia != null && rep.socialMedia!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Social Media',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rep.socialMedia!.map((socialAccount) {
                IconData icon;
                Color color;

                // Parse platform from social media string
                final parts = socialAccount.split(':');
                if (parts.length < 2) return const SizedBox.shrink();

                final platform = parts[0].trim().toLowerCase();

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
                  default:
                    icon = Icons.link;
                    color = Colors.grey;
                }

                return InkWell(
                  onTap: () {
                    // Try to build a social media URL (simplified)
                    String url = '';
                    final username = parts.sublist(1).join(':').trim();

                    switch (platform) {
                      case 'twitter':
                        url = 'https://twitter.com/$username';
                        break;
                      case 'facebook':
                        url = 'https://facebook.com/$username';
                        break;
                      case 'instagram':
                        url = 'https://instagram.com/$username';
                        break;
                      case 'youtube':
                        if (username.startsWith('@')) {
                          url = 'https://youtube.com/${username.substring(1)}';
                        } else {
                          url = 'https://youtube.com/$username';
                        }
                        break;
                      case 'linkedin':
                        url = 'https://linkedin.com/in/$username';
                        break;
                      default:
                        url = '';
                    }

                    if (url.isNotEmpty) {
                      _launchUrl(url);
                    }
                  },
                  child: Chip(
                    avatar: Icon(icon, color: color, size: 16),
                    label: Text(
                      platform.capitalize(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey.shade100,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
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
      // Specific content for Manny
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
            '${rep.name} is a member of the ${formattedLevel} representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.';
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
          '${rep.name} is a member of the ${formattedLevel} representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.';
    }

    // Add office title if available and not already included
    if (rep.office != null &&
        rep.office!.isNotEmpty &&
        !aboutText.contains(rep.office!)) {
      aboutText += ' ${rep.name.split(' ')[0]} serves as ${rep.office}.';
    }

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
    final String chamberUpper = rep.chamber.toUpperCase();

    // Based on chamber type, determine the position title
    // House/Representatives
    if (chamberUpper == 'NATIONAL_LOWER' || chamberUpper == 'HOUSE') {
      return 'U.S. Representative';
    }
    // Senate
    else if (chamberUpper == 'NATIONAL_UPPER' || chamberUpper == 'SENATE') {
      return 'U.S. Senator';
    }
    // State Legislature - Upper Chamber
    else if (chamberUpper == 'STATE_UPPER') {
      return 'State Senator';
    }
    // State Legislature - Lower Chamber
    else if (chamberUpper == 'STATE_LOWER') {
      return 'State Representative';
    }
    // State Executive Officials
    else if (chamberUpper == 'STATE_EXEC') {
      // Only use office for state executives if it's clearly a title (e.g., "Commissioner of Education")
      if (rep.office != null && rep.office!.isNotEmpty) {
        final lowercaseOffice = rep.office!.toLowerCase();
        if (lowercaseOffice.contains('secretary') ||
            lowercaseOffice.contains('commissioner') ||
            lowercaseOffice.contains('governor') ||
            lowercaseOffice.contains('attorney general') ||
            lowercaseOffice.contains('treasurer') ||
            lowercaseOffice.contains('controller')) {
          return rep.office!;
        }
      }
      return 'State Executive Official';
    }
    // Mayors
    else if (chamberUpper == 'LOCAL_EXEC' || chamberUpper.contains('MAYOR')) {
      return 'Mayor';
    }
    // City Council
    else if (chamberUpper == 'LOCAL' || chamberUpper.contains('CITY')) {
      return 'City Council Member';
    }
    // County Officials
    else if (chamberUpper.contains('COUNTY')) {
      return 'County Commissioner';
    }
    // School Board
    else if (chamberUpper.contains('SCHOOL')) {
      return 'School Board Member';
    }

    // Only use office field if it's likely a role title and not an address/building
    if (rep.office != null && rep.office!.isNotEmpty) {
      final lowercaseOffice = rep.office!.toLowerCase();

      // Skip if it contains address-related keywords
      final addressKeywords = [
        'building',
        'suite',
        'room',
        'rayburn',
        'longworth',
        'cannon',
        'dirksen',
        'hart',
        'russell',
        'street',
        'avenue',
        'boulevard',
        'road',
        'drive',
        'lane',
        'way',
        '1st',
        '2nd',
        '3rd',
        '#',
        'ste',
        'st',
        'ave',
        'blvd',
        'rd',
        'dr'
      ];

      bool isLikelyAddress =
          addressKeywords.any((keyword) => lowercaseOffice.contains(keyword));

      // Skip if it contains digits (likely an address)
      bool containsDigits = RegExp(r'\d').hasMatch(lowercaseOffice);

      if (!isLikelyAddress && !containsDigits) {
        return rep.office!;
      }
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

  Widget _buildBillsTab(List<RepresentativeBill> bills, String emptyMessage) {
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
                    color: Theme.of(context).colorScheme.primary,
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
                if (bill.introducedDate != null)
                  Text(
                    'Introduced: ${bill.introducedDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
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
          ],
        );
      },
    );
  }
}

// Helper extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
  }
}
