// lib/screens/representatives/representative_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // For clipboard functionality
import 'package:govvy/utils/district_type_formatter.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:url_launcher/url_launcher.dart';

class RepresentativeDetailsScreen extends StatefulWidget {
  final String bioGuideId;
  
  const RepresentativeDetailsScreen({
    Key? key,
    required this.bioGuideId,
  }) : super(key: key);

  @override
  State<RepresentativeDetailsScreen> createState() => _RepresentativeDetailsScreenState();
}

class _RepresentativeDetailsScreenState extends State<RepresentativeDetailsScreen> with SingleTickerProviderStateMixin {
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
    final provider = Provider.of<CombinedRepresentativeProvider>(context, listen: false);
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
                              _buildRoleInfoTab(rep),
                              _buildBillsTab(rep.sponsoredBills, 'No sponsored bills found'),
                              _buildBillsTab(rep.cosponsoredBills, 'No co-sponsored bills found'),
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
    String partyColor;
    String partyName;
    
    // Determine party color and full name
    switch (rep.party.toLowerCase()) {
      case 'r':
      case 'republican':
        partyColor = '#E91D0E';
        partyName = 'Republican';
        break;
      case 'd':
      case 'democrat':
      case 'democratic':
        partyColor = '#232066';
        partyName = 'Democrat';
        break;
      case 'i':
      case 'independent':
        partyColor = '#39BA4C';
        partyName = 'Independent';
        break;
      default:
        partyColor = '#777777';
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
            backgroundImage: rep.imageUrl != null 
                ? NetworkImage(rep.imageUrl!) 
                : null,
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
                        color: Color(int.parse(partyColor.substring(1, 7), radix: 16) + 0xFF000000),
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
                  '${rep.chamber}, ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                    onLongPress: () => _copyToClipboard(rep.phone!, 'Phone number'),
                  ),
                
                if (rep.email != null)
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email',
                    value: rep.email!,
                    onTap: () => _sendEmail(rep.email),
                    onLongPress: () => _copyToClipboard(rep.email!, 'Email address'),
                  ),
                
                if (rep.office != null)
                  _buildContactItem(
                    icon: Icons.location_on,
                    title: 'Office',
                    value: rep.office!,
                    onTap: null,
                    onLongPress: () => _copyToClipboard(rep.office!, 'Office address'),
                  ),

                if (rep.website != null)
                  _buildContactItem(
                    icon: Icons.language,
                    title: 'Website',
                    value: rep.website!,
                    onTap: () => _launchUrl(rep.website),
                    onLongPress: () => _copyToClipboard(rep.website!, 'Website URL'),
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
                      Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
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
                  onLongPress: () => _copyToClipboard(rep.website!, 'Website URL'),
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
                  Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                      color: onTap != null ? Theme.of(context).colorScheme.primary : Colors.black,
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
          if (rep.gender != null)
            _buildInfoSection('Gender', rep.gender),
          
          // Add education details if available
          // if (rep.bioGuideId.contains('dickens') && rep.name.contains('Andre')) {
          //   _buildInfoSection('Education', 'B.S. Chemical Engineering, Georgia Institute of Technology; M.S. Public Administration, Georgia State University'),
          //   _buildInfoSection('Career', 'Chemical Engineer, Assistant Director of the Office of Institute Diversity at Georgia Tech, Chief Development Officer at TechBridge, Former Atlanta City Council Member'),
          // }
        ],
      ),
    );
  }

  // New tab for role information
  Widget _buildRoleInfoTab(RepresentativeDetails rep) {
    // Determine the role type to show the appropriate information
    final String chamberUpper = rep.chamber.toUpperCase();
    String roleType = '';
    
    if (chamberUpper.contains('MAYOR') || chamberUpper.contains('LOCAL_EXEC')) {
      roleType = 'mayor';
    } else if (chamberUpper.contains('CITY') || chamberUpper.contains('LOCAL')) {
      roleType = 'cityCouncil';
    } else if (chamberUpper.contains('COUNTY')) {
      roleType = 'countyCommission';
    } else if (chamberUpper.contains('SENATE') || chamberUpper == 'NATIONAL_UPPER') {
      roleType = 'senator';
    } else if (chamberUpper.contains('HOUSE') || chamberUpper == 'NATIONAL_LOWER') {
      roleType = 'representative';
    } else if (chamberUpper.contains('STATE')) {
      roleType = 'stateOfficial';
    } else {
      roleType = 'other';
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role & Responsibilities',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Role description
          _buildRoleDescription(roleType, rep),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          
          // Key responsibilities section
          Text(
            'Key Responsibilities',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildResponsibilitiesList(roleType),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          
          // Authority & Limitations section
          Text(
            'Authority & Limitations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildAuthorityLimitations(roleType),
        ],
      ),
    );
  }
  
  // Helper to build role description
  Widget _buildRoleDescription(String roleType, RepresentativeDetails rep) {
    String description = '';
    
    switch (roleType) {
      case 'mayor':
        if (rep.name.contains('Dickens') && rep.state == 'GA') {
          description = 'As the Mayor of Atlanta, Andre Dickens serves as the Chief Executive Officer of the city. He is responsible for the general management of Atlanta, enforcing all laws and ordinances, and serving as the official representative of the city. Mayor Dickens oversees the city\'s budget and thousands of employees across numerous departments.';
        } else {
          description = 'Mayors are the chief executive officers of cities, responsible for the general management of city operations, enforcing laws and ordinances, and serving as the official representative of the city. They typically oversee city departments, propose budgets, and implement policies set by the city council.';
        }
        break;
        
      case 'cityCouncil':
        description = 'City Council members serve as the legislative body for the city. They create laws through ordinances and resolutions, approve budgets, establish tax rates, set utility fees, and develop policy. Council members represent specific districts or the city at large, advocating for constituents\' needs and interests.';
        break;
        
      case 'countyCommission':
        description = 'County Commissioners form the legislative and often executive body of county government. They manage county property and funds, establish budgets, set tax rates, oversee public works, and implement policies for unincorporated areas. Commissioners typically represent specific districts within the county.';
        break;
        
      case 'senator':
        description = 'U.S. Senators serve six-year terms in the upper chamber of Congress, with two senators representing each state regardless of population. Senators write and vote on federal legislation, confirm presidential nominations for federal positions, ratify treaties, and conduct oversight of federal agencies.';
        break;
        
      case 'representative':
        description = 'U.S. Representatives serve two-year terms in the House of Representatives, the lower chamber of Congress. Each representative serves a specific district, with the number of representatives per state based on population. They draft and vote on federal legislation, have exclusive power to initiate revenue bills, and conduct oversight of federal agencies.';
        break;
        
      case 'stateOfficial':
        description = 'State officials work at the state government level, creating and implementing policies that affect citizens within their state. Depending on their specific role, they may draft state legislation, oversee state agencies, manage state budgets, or implement state programs and services.';
        break;
        
      default:
        description = 'This official serves in a government capacity, representing constituents and working within their jurisdiction\'s governmental structure to implement policies, provide services, and address community needs.';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            roleType == 'mayor' && rep.name.contains('Dickens') ? 'Mayor of Atlanta' : 
            _getRoleTitle(roleType),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to build responsibilities list
  Widget _buildResponsibilitiesList(String roleType) {
    List<String> responsibilities = [];
    
    switch (roleType) {
      case 'mayor':
        responsibilities = [
          'Oversee city operations and administration',
          'Propose annual budgets',
          'Appoint department heads and staff',
          'Implement city council policies',
          'Represent the city to other governments and the public',
          'Oversee public safety departments',
          'Lead emergency response efforts',
          'Veto or approve legislation (in some cities)',
          'Develop strategic initiatives and economic development plans'
        ];
        break;
        
      case 'cityCouncil':
        responsibilities = [
          'Draft and pass local ordinances and resolutions',
          'Approve the city budget',
          'Set tax rates and service fees',
          'Review and approve contracts',
          'Establish zoning regulations',
          'Confirm mayoral appointments (in some cities)',
          'Provide oversight of city departments',
          'Address constituent concerns',
          'Serve on committees and boards'
        ];
        break;
        
      case 'countyCommission':
        responsibilities = [
          'Manage county property and funds',
          'Set county budgets and tax rates',
          'Oversee county roads and infrastructure',
          'Establish policies for unincorporated areas',
          'Coordinate with other local governments',
          'Authorize contracts and payments',
          'Manage county facilities',
          'Appoint county officials (in some counties)',
          'Oversee public health and safety services'
        ];
        break;
        
      case 'senator':
      case 'representative':
        responsibilities = [
          'Draft and vote on federal legislation',
          'Serve on congressional committees',
          'Oversee federal agencies and programs',
          'Approve federal budgets',
          'Address constituent concerns and provide services',
          'Conduct investigations and hearings',
          'Represent district/state interests at the federal level',
          'Authorize federal spending',
          roleType == 'senator' ? 'Confirm presidential appointments' : 'Initiate revenue bills'
        ];
        break;
        
      case 'stateOfficial':
        responsibilities = [
          'Draft and vote on state legislation (for legislators)',
          'Implement state policies and programs',
          'Oversee state departments and agencies',
          'Manage state resources and budgets',
          'Address state-level issues and constituent concerns',
          'Coordinate with local and federal governments',
          'Develop state regulations and standards',
          'Represent state interests in various forums',
          'Serve on state boards and commissions'
        ];
        break;
        
      default:
        responsibilities = [
          'Represent constituents in official capacity',
          'Participate in policy development and implementation',
          'Address community needs and concerns',
          'Collaborate with other government officials',
          'Oversee programs and services within jurisdiction',
          'Manage resources and budgets',
          'Ensure compliance with relevant laws and regulations',
          'Communicate with the public and stakeholders',
          'Participate in official meetings and proceedings'
        ];
    }
    
    return Column(
      children: responsibilities.map((responsibility) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle, 
                size: 18, 
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  responsibility,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  // Helper to build authority and limitations section
  Widget _buildAuthorityLimitations(String roleType) {
    Map<String, List<String>> authLimits = {};
    
    switch (roleType) {
      case 'mayor':
        authLimits = {
          'Authority': [
            'Appoint and remove department heads',
            'Propose and administer city budget',
            'Execute contracts (within limits)',
            'Declare local emergencies',
            'Represent the city officially'
          ],
          'Limitations': [
            'Cannot create laws independently',
            'Budget approval required from city council',
            'Authority limited to city boundaries',
            'Subject to checks from council',
            'Term limits (in many cities)'
          ]
        };
        break;
        
      case 'cityCouncil':
        authLimits = {
          'Authority': [
            'Legislative power to create local laws',
            'Budget approval authority',
            'Set tax rates and fees',
            'Confirm/reject appointments',
            'Establish city policies'
          ],
          'Limitations': [
            'Cannot directly manage city staff',
            'Individual members have no executive power',
            'Subject to mayoral veto (in some cities)',
            'Limited to city boundaries',
            'Subject to state and federal laws'
          ]
        };
        break;
        
      case 'countyCommission':
        authLimits = {
          'Authority': [
            'Manage county property and funds',
            'Establish county policies',
            'Set county tax rates',
            'Approve county contracts',
            'Manage unincorporated areas'
          ],
          'Limitations': [
            'Limited authority in incorporated cities',
            'Must coordinate with other elected officials',
            'Subject to state mandates',
            'Cannot override municipal decisions',
            'Budget constraints'
          ]
        };
        break;
        
      case 'senator':
      case 'representative':
        authLimits = {
          'Authority': [
            'Draft and vote on federal legislation',
            'Approve federal budgets',
            'Conduct investigations',
            'Override presidential vetoes (with supermajority)',
            roleType == 'senator' ? 'Confirm federal appointments' : 'Initiate revenue bills'
          ],
          'Limitations': [
            'Cannot act individually',
            'Subject to checks and balances',
            'Limited by Constitution and courts',
            'Cannot direct federal agencies',
            'Term limits (for some positions)'
          ]
        };
        break;
        
      case 'stateOfficial':
        authLimits = {
          'Authority': [
            'Create and enforce state laws',
            'Manage state resources',
            'Establish state policies',
            'Oversee state departments',
            'Regulate within state boundaries'
          ],
          'Limitations': [
            'Limited by federal laws',
            'Subject to state constitution',
            'Budget constraints',
            'Cannot override local control (in some areas)',
            'Term limits (in many states)'
          ]
        };
        break;
        
      default:
        authLimits = {
          'Authority': [
            'Act within official capacity',
            'Implement relevant policies',
            'Manage allocated resources',
            'Represent constituents',
            'Participate in official proceedings'
          ],
          'Limitations': [
            'Limited to specific jurisdiction',
            'Subject to governing laws',
            'Budget constraints',
            'Must work within governmental system',
            'Term limits or appointment periods'
          ]
        };
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Authority section
        Text(
          'Authority',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        ...authLimits['Authority']!.map((item) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, 
                  size: 16, 
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ).toList(),
        
        const SizedBox(height: 16),
        
        // Limitations section
        Text(
          'Limitations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...authLimits['Limitations']!.map((item) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, 
                  size: 16, 
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ).toList(),
      ],
    );
  }
  
  // Helper to get role title
  String _getRoleTitle(String roleType) {
    switch (roleType) {
      case 'mayor':
        return 'Mayor';
      case 'cityCouncil':
        return 'City Council Member';
      case 'countyCommission':
        return 'County Commissioner';
      case 'senator':
        return 'U.S. Senator';
      case 'representative':
        return 'U.S. Representative';
      case 'stateOfficial':
        return 'State Government Official';
      default:
        return 'Government Official';
    }
  }

  // Helper to build a more descriptive About text
  Widget _buildAboutText(RepresentativeDetails rep) {
    // Special case for Andre Dickens
    if (rep.name.contains('Andre Dickens') && rep.state == 'GA') {
      return Text(
        'Andre Dickens is the 61st Mayor of Atlanta, serving since January 2022. A native Atlantan and product of Atlanta Public Schools, Mayor Dickens earned his Chemical Engineering degree from Georgia Tech and a Master\'s in Public Administration from Georgia State University. Before becoming Mayor, he served as an Atlanta City Council member at-large for eight years. As Mayor, he\'s focused on public safety, affordable housing, infrastructure improvements, and economic development in Atlanta. He also serves as Chair of the Atlanta Regional Commission Board.',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }
    
    // For other officials, generate a descriptive bio
    String formattedLevel = DistrictTypeFormatter.formatDistrictType(rep.chamber);
    String aboutText;
    
    // Federal representatives
    if (rep.chamber.toUpperCase() == 'NATIONAL_UPPER' || rep.chamber.toLowerCase() == 'senate') {
      aboutText = '${rep.name} is a United States Senator representing ${rep.state}.';
    } 
    else if (rep.chamber.toUpperCase() == 'NATIONAL_LOWER' || rep.chamber.toLowerCase() == 'house') {
      aboutText = '${rep.name} is a member of the U.S. House of Representatives representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.';
    }
    // State representatives
    else if (rep.chamber.toUpperCase().startsWith('STATE_')) {
      if (rep.chamber.toUpperCase() == 'STATE_UPPER') {
        aboutText = '${rep.name} is a State Senator representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.';
      } 
      else if (rep.chamber.toUpperCase() == 'STATE_LOWER') {
        aboutText = '${rep.name} is a State Representative serving in the ${rep.state} House of Representatives${rep.district != null ? ' for District ${rep.district}' : ''}.';
      }
      else if (rep.chamber.toUpperCase() == 'STATE_EXEC') {
        aboutText = '${rep.name} serves in the executive branch of ${rep.state} state government.';
      }
      else {
        aboutText = '${rep.name} is a member of the ${formattedLevel} representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.';
      }
    }
    // Local representatives
    else if (rep.chamber.toUpperCase() == 'LOCAL_EXEC' || rep.chamber.toUpperCase() == 'MAYOR') {
      aboutText = '${rep.name} is the Mayor of ${rep.district ?? rep.state}.';
    }
    else if (rep.chamber.toUpperCase() == 'LOCAL' || rep.chamber.toUpperCase() == 'CITY') {
      aboutText = '${rep.name} is a member of the City Council for ${rep.district ?? rep.state}.';
    }
    else if (rep.chamber.toUpperCase() == 'COUNTY') {
      aboutText = '${rep.name} is a County Commissioner for ${rep.district ?? rep.state}.';
    }
    else if (rep.chamber.toUpperCase() == 'SCHOOL') {
      aboutText = '${rep.name} is a member of the School Board for ${rep.district ?? rep.state}.';
    }
    // Fallback for other types
    else {
      aboutText = '${rep.name} is a member of the ${formattedLevel} representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.';
    }
    
    // Add office title if available
    if (rep.office != null && rep.office!.isNotEmpty) {
      aboutText += ' ${rep.name} serves as ${rep.office}.';
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}