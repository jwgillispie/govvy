// lib/screens/representatives/representative_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // For clipboard functionality
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
    _tabController = TabController(length: 3, vsync: this);
    
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
                        
                        // Contact information section (new!)
                        _buildContactInfoSection(rep),
                        
                        // Tab bar
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Profile'),
                            Tab(text: 'Sponsored Bills'),
                            Tab(text: 'Co-Sponsored Bills'),
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

  // New widget for contact information with improved layout
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
          // The main contact info is now in its own dedicated section
          
          // Show other profile details
          if (rep.dateOfBirth != null)
            _buildInfoSection('Date of Birth', rep.dateOfBirth),
          if (rep.gender != null)
            _buildInfoSection('Gender', rep.gender),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${rep.name} is a member of the ${rep.chamber} representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          // Additional biographical information would go here
        ],
      ),
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



// // Similarly update RepresentativeCard to show contact information in the list view
// class RepresentativeCard extends StatelessWidget {
//   final Representative representative;
//   final VoidCallback? onTap;

//   const RepresentativeCard({
//     Key? key,
//     required this.representative,
//     this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Determine party colors
//     Color partyColor;
//     String partyName;

//     switch (representative.party.toLowerCase()) {
//       case 'r':
//       case 'republican':
//         partyColor = const Color(0xFFE91D0E);
//         partyName = 'Republican';
//         break;
//       case 'd':
//       case 'democrat':
//       case 'democratic':
//         partyColor = const Color(0xFF232066);
//         partyName = 'Democrat';
//         break;
//       case 'i':
//       case 'independent':
//         partyColor = const Color(0xFF39BA4C);
//         partyName = 'Independent';
//         break;
//       default:
//         partyColor = Colors.grey;
//         partyName = representative.party.isEmpty ? 'Unknown' : representative.party;
//     }

//     // Check if we have direct contact info
//     final bool hasDirectContact = representative.phone != null || representative.email != null;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Representative image
//                   CircleAvatar(
//                     radius: 32,
//                     backgroundColor: Colors.grey.shade200,
//                     // Handle image loading safely
//                     child: (representative.imageUrl != null && representative.imageUrl!.isNotEmpty) 
//                         ? ClipRRect(
//                             borderRadius: BorderRadius.circular(32),
//                             child: Image.network(
//                               representative.imageUrl!,
//                               width: 64,
//                               height: 64,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 // Fallback icon if image fails to load
//                                 return Icon(Icons.person, size: 32, color: Colors.grey.shade400);
//                               },
//                               loadingBuilder: (context, child, loadingProgress) {
//                                 if (loadingProgress == null) return child;
//                                 return Center(
//                                   child: CircularProgressIndicator(
//                                     value: loadingProgress.expectedTotalBytes != null
//                                         ? loadingProgress.cumulativeBytesLoaded / 
//                                         loadingProgress.expectedTotalBytes!
//                                         : null,
//                                     strokeWidth: 2,
//                                   ),
//                                 );
//                               },
//                             ),
//                           )
//                         : Icon(Icons.person, size: 32, color: Colors.grey.shade400),
//                   ),
//                   const SizedBox(width: 12),

//                   // Representative info
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Container(
//                               width: 12,
//                               height: 12,
//                               decoration: BoxDecoration(
//                                 color: partyColor,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               partyName,
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey.shade700,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             // Add local badge if it's a local representative
//                             if (representative.bioGuideId.startsWith('cicero-'))
//                               Container(
//                                 margin: const EdgeInsets.only(left: 8),
//                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                 decoration: BoxDecoration(
//                                   color: Colors.teal.shade100,
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   'LOCAL',
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.teal.shade800,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           representative.name,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           _buildPositionText(representative),
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade800,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Arrow
//                   Icon(
//                     Icons.arrow_forward_ios,
//                     size: 16,
//                     color: Colors.grey.shade400,
//                   ),
//                 ],
//               ),
              
//               // Contact info section - simplified version
//               if (hasDirectContact) ...[
//                 const Divider(height: 24),
//                 Row(
//                   children: [
//                     if (representative.phone != null)
//                       Expanded(
//                         child: InkWell(
//                           onTap: () => _makePhoneCall(representative.phone, context),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(Icons.phone,
//                                   size: 16,
//                                   color: Theme.of(context).colorScheme.primary),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   'Call',
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w500,
//                                     color: Theme.of(context).colorScheme.primary,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     if (representative.phone != null && representative.email != null)
//                       const SizedBox(width: 16),
//                     if (representative.email != null)
//                       Expanded(
//                         child: InkWell(
//                           onTap: () => _sendEmail(representative.email, context),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(Icons.email,
//                                   size: 16,
//                                   color: Theme.of(context).colorScheme.primary),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   'Email',
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w500,
//                                     color: Theme.of(context).colorScheme.primary,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     if (representative.website != null)
//                       Expanded(
//                         child: InkWell(
//                           onTap: () => _launchWebsite(representative.website, context),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(Icons.language,
//                                   size: 16,
//                                   color: Theme.of(context).colorScheme.primary),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   'Website',
//                                   style: TextStyle(
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w500,
//                                     color: Theme.of(context).colorScheme.primary,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ] else if (representative.website != null) ...[
//                 // If only website is available
//                 const Divider(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: InkWell(
//                         onTap: () => _launchWebsite(representative.website, context),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.language,
//                                 size: 16,
//                                 color: Theme.of(context).colorScheme.primary),
//                             const SizedBox(width: 8),
//                             Text(
//                               'Visit Website for Contact Info',
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w500,
//                                 color: Theme.of(context).colorScheme.primary,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  
//   // Helper methods to handle actions
//   Future<void> _makePhoneCall(String? phoneNumber, BuildContext context) async {
//     if (phoneNumber == null || phoneNumber.isEmpty) {
//       return;
//     }
    
//     final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
//     final Uri uri = Uri(scheme: 'tel', path: cleanedNumber);
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Could not call $phoneNumber'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
  
//   Future<void> _sendEmail(String? email, BuildContext context) async {
//     if (email == null || email.isEmpty) {
//       return;
//     }
    
//     // Check if it's a contact form URL instead of email
//     if (email.startsWith('http')) {
//       return _launchWebsite(email, context);
//     }
    
//     final Uri uri = Uri(
//       scheme: 'mailto',
//       path: email,
//     );
    
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Could not open email app'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
  
//   Future<void> _launchWebsite(String? url, BuildContext context) async {
//     if (url == null || url.isEmpty) {
//       return;
//     }
    
//     // Handle different URL formats
//     String formattedUrl = url;
//     if (!url.startsWith('http://') && !url.startsWith('https://')) {
//       formattedUrl = 'https://$url';
//     }
    
//     final Uri uri = Uri.parse(formattedUrl);
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Could not launch $url'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
  
//   // Helper method to build a position text based on representative type
//   String _buildPositionText(Representative representative) {
//     final bool isLocal = representative.bioGuideId.startsWith('cicero-');
    
//     if (isLocal) {
//       // For local representatives, use chamber (CITY, COUNTY) and district
//       if (representative.chamber.toLowerCase() == 'city') {
//         return 'City Official, ${representative.district ?? representative.state}';
//       } else if (representative.chamber.toLowerCase() == 'county') {
//         return 'County Official, ${representative.district ?? representative.state}';
//       } else {
//         return '${representative.chamber} Official, ${representative.district ?? representative.state}';
//       }
//     } else if (representative.chamber == 'Senate') {
//       return 'U.S. Senator, ${representative.state}';
//     } else {
//       return 'U.S. Representative, ${representative.state}${representative.district != null ? '-${representative.district}' : ''}';
//     }
//   }
// }