// lib/widgets/representatives/representative_card.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/utils/district_type_formatter.dart';
import 'package:govvy/services/network_service.dart';
import 'package:flutter/foundation.dart';

class RepresentativeCard extends StatelessWidget {
  final Representative representative;
  final VoidCallback? onTap;

  const RepresentativeCard({
    Key? key,
    required this.representative,
    this.onTap,
  }) : super(key: key);

  // Improved method to determine if a representative is local
  bool _isLocalRepresentative(Representative rep) {
    // Check if the bioGuideId follows the pattern used for local reps
    if (rep.bioGuideId.startsWith('cicero-')) {
      return true;
    }
    
    // Check if the chamber/level indicates a local position
    if (['COUNTY', 'CITY', 'PLACE', 'TOWNSHIP', 'BOROUGH', 'TOWN', 'VILLAGE', 'LOCAL', 'LOCAL_EXEC']
        .contains(rep.chamber.toUpperCase())) {
      return true;
    }
    
    // Otherwise, it's not a local representative
    return false;
  }

  Widget _buildLocalBadge(Representative representative) {
    // Only show the local badge if it's a local representative
    if (_isLocalRepresentative(representative)) {
      return Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'LOCAL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink(); // No badge for federal/state reps
  }

  // Get a proxied image URL for web to avoid CORS issues
  Future<String> _getProxiedImageUrl(String originalUrl) async {
    if (!kIsWeb) {
      // For mobile, just return the original URL
      return originalUrl;
    }
    
    // For web, check if the URL needs proxying
    if (originalUrl.contains('congress.gov') || 
        originalUrl.contains('cicero.azavea.com')) {
      // Use a CORS proxy for image URLs
      return 'https://corsproxy.io/?${Uri.encodeComponent(originalUrl)}';
    }
    
    // If it's not a problematic URL, return as is
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    // Determine party colors
    Color partyColor;
    String partyName;

    switch (representative.party.toLowerCase()) {
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
        partyName = representative.party.isEmpty ? 'Unknown' : representative.party;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Representative image - handle image loading with CORS proxy for web
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey.shade200,
                child: (representative.imageUrl != null && representative.imageUrl!.isNotEmpty) 
                    ? FutureBuilder<String>(
                        future: _getProxiedImageUrl(representative.imageUrl!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          
                          final imageUrl = snapshot.data ?? representative.imageUrl!;
                          
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.network(
                              imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback icon if image fails to load
                                return Icon(Icons.person, size: 32, color: Colors.grey.shade400);
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      )
                    : Icon(Icons.person, size: 32, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 12),

              // Representative info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Use a Row with flexible widgets to prevent overflow
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: partyColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          partyName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        _buildLocalBadge(representative),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      representative.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildPositionText(representative),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (representative.phone != null) ...[
                      const SizedBox(height: 8),
                      // Use a Wrap for phone number to prevent overflow
                      Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.phone,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            representative.phone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to build a position text based on representative type
  String _buildPositionText(Representative representative) {
    // Determine if this is a local representative
    final bool isLocal = _isLocalRepresentative(representative);
    
    // Get the user-friendly role description
    final String formattedLevel = DistrictTypeFormatter.formatDistrictType(representative.chamber);
    
    // Handle federal representatives
    if (representative.chamber.toLowerCase() == 'senate' || 
        representative.chamber.toUpperCase() == 'NATIONAL_UPPER') {
      return 'U.S. Senator, ${representative.state}';
    } 
    else if (representative.chamber.toLowerCase() == 'house' || 
             representative.chamber.toUpperCase() == 'NATIONAL_LOWER') {
      return 'U.S. Representative, ${representative.state}${representative.district != null ? '-${representative.district}' : ''}';
    }
    // Handle state representatives 
    else if (representative.chamber.toUpperCase().startsWith('STATE_')) {
      // For state representatives, show State role, State name, and district if available
      if (representative.office != null && representative.office!.isNotEmpty) {
        // If we have an office title, use it
        return '${representative.office}, ${representative.state}${representative.district != null ? ' District ${representative.district}' : ''}';
      } else {
        // Otherwise use the formatted level
        return '$formattedLevel, ${representative.state}${representative.district != null ? ' District ${representative.district}' : ''}';
      }
    }
    // Handle local representatives with clear, user-friendly information
    else if (isLocal) {
      // For local representatives, show what type of local official they are and where they serve
      if (representative.office != null && representative.office!.isNotEmpty) {
        if (representative.district != null && representative.district!.isNotEmpty) {
          // If we have both office title and a district
          return '${representative.office}, ${representative.district}';
        } else {
          // If we have office title but no specific district
          return '${representative.office}, ${representative.state}';
        }
      } else if (formattedLevel.contains('Council')) {
        // City Council Member
        return 'City Council Member, ${representative.district ?? representative.state}';
      } else if (formattedLevel.contains('Mayor')) {
        // Mayor
        return 'Mayor of ${representative.district ?? representative.state}';
      } else if (formattedLevel.contains('County')) {
        // County Commissioner
        return 'County Commissioner, ${representative.district ?? representative.state}';
      } else if (formattedLevel.contains('School')) {
        // School Board Member
        return 'School Board Member, ${representative.district ?? representative.state}';
      } else {
        // Generic local official with better formatting
        return '$formattedLevel, ${representative.district ?? representative.state}';
      }
    } 
    // Handle any other case
    else {
      // For other roles, use the formatted level
      return '$formattedLevel, ${representative.state}${representative.district != null ? ' District ${representative.district}' : ''}';
    }
  }
}