// lib/widgets/representatives/representative_card.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/representative_service.dart';

class RepresentativeCard extends StatelessWidget {
  final Representative representative;
  final VoidCallback? onTap;

  const RepresentativeCard({
    Key? key,
    required this.representative,
    this.onTap,
  }) : super(key: key);

  
  Widget _buildRepresentativeBadge(Representative representative) {
    // Determine if this is a local representative by the chamber/bioGuideId
    final bool isLocal = representative.bioGuideId.startsWith('cicero-') ||
        ['COUNTY', 'CITY', 'PLACE', 'TOWNSHIP', 'BOROUGH', 'TOWN', 'VILLAGE']
            .contains(representative.chamber.toUpperCase());

    if (isLocal) {
      return Container(
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

  Widget _buildLocalBadge(Representative representative) {
  // Determine if this is a local representative by the bioGuideId
  final bool isLocal = representative.bioGuideId.startsWith('cicero-');
  
  if (isLocal) {
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
        partyName = representative.party;
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
              // Representative image
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: representative.imageUrl != null
                    ? NetworkImage(representative.imageUrl!)
                    : null,
                child: representative.imageUrl == null
                    ? Icon(Icons.person, size: 32, color: Colors.grey.shade400)
                    : null,
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
                      representative.chamber == 'Senate'
                          ? 'U.S. Senator, ${representative.state}'
                          : 'U.S. Representative, ${representative.state}${representative.district != null ? '-${representative.district}' : ''}',
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
}
