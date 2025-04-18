// lib/widgets/representatives/representative_card.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/representative_model.dart';

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
    if (['COUNTY', 'CITY', 'PLACE', 'TOWNSHIP', 'BOROUGH', 'TOWN', 'VILLAGE']
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
              // Representative image - handle image loading safely
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey.shade200,
                // Only try to load the image if we have a valid URL
                // Also, handle image loading errors gracefully
                child: (representative.imageUrl != null && representative.imageUrl!.isNotEmpty) 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.network(
                          representative.imageUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // If the image fails to load, show a fallback icon
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
                      )
                    : Icon(Icons.person, size: 32, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 12),

              // Representative info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildPositionText(representative),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (representative.phone != null) ...[
                      const SizedBox(height: 8),
                      Row(
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
    
    if (isLocal) {
      // For local representatives, use chamber (CITY, COUNTY) and district
      final String level = representative.chamber.toUpperCase();
      
      if (level == 'CITY') {
        return 'City Official, ${representative.district ?? representative.state}';
      } else if (level == 'COUNTY') {
        return 'County Official, ${representative.district ?? representative.state}';
      } else {
        return '${representative.chamber} Official, ${representative.district ?? representative.state}';
      }
    } else if (representative.chamber.toLowerCase() == 'senate') {
      return 'U.S. Senator, ${representative.state}';
    } else {
      return 'U.S. Representative, ${representative.state}${representative.district != null ? '-${representative.district}' : ''}';
    }
  }
}