// lib/widgets/representatives/role_info_widget.dart

import 'package:flutter/material.dart';
import 'package:govvy/data/government_roles.dart';
import 'package:govvy/utils/district_type_formatter.dart';

class RoleInfoWidget extends StatelessWidget {
  final String role;
  final String officeName;
  final String? district;

  const RoleInfoWidget({
    Key? key,
    required this.role,
    this.officeName = '',
    this.district,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Normalize the role to get standardized information
    String normalizedRole = _normalizeRole(role, officeName);
    
    // Get role information
    final roleInfo = GovernmentRoles.getRoleInfo(normalizedRole);

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
          
          // Role description card
          Container(
            padding: const EdgeInsets.all(16),
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
                      roleInfo.icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      roleInfo.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  roleInfo.description,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
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
          
          // Responsibilities list
          Column(
            children: roleInfo.responsibilities.map((responsibility) {
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
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          
          // Term and salary info
          Text(
            'Term & Position Info',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Term length
          _buildInfoRow(
            context, 
            'Term Length:', 
            roleInfo.termYears,
            Icons.calendar_today
          ),
          
          // Term limits
          _buildInfoRow(
            context, 
            'Term Limits:', 
            roleInfo.termLimit,
            Icons.repeat
          ),
          
          // Salary info
          _buildInfoRow(
            context, 
            'Typical Salary:', 
            roleInfo.salary,
            Icons.attach_money
          ),
          
          // Qualifications
          _buildInfoRow(
            context, 
            'Qualifications:', 
            roleInfo.qualifications,
            Icons.school
          ),
        ],
      ),
    );
  }
  
  // Helper method to build info rows
  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to normalize roles
  String _normalizeRole(String role, String officeName) {
    final String roleUpper = role.toUpperCase();
    
    // Try to determine the role based on the chamber code
    if (roleUpper == 'NATIONAL_UPPER' || roleUpper == 'SENATE') {
      return 'senator';
    } else if (roleUpper == 'NATIONAL_LOWER' || roleUpper == 'HOUSE') {
      return 'representative';
    } else if (roleUpper == 'STATE_UPPER') {
      return 'stateSenator';
    } else if (roleUpper == 'STATE_LOWER') {
      return 'stateRepresentative';
    } else if (roleUpper == 'STATE_EXEC') {
      return 'stateOfficial';
    } else if (roleUpper == 'LOCAL_EXEC' || roleUpper.contains('MAYOR')) {
      return 'mayor';
    } else if (roleUpper == 'LOCAL' || roleUpper.contains('CITY')) {
      return 'cityCouncil';
    } else if (roleUpper.contains('COUNTY')) {
      return 'countyCommissioner';
    } else if (roleUpper.contains('SCHOOL')) {
      return 'schoolBoard';
    }
    
    // If no match by chamber, try to match by office title
    if (officeName.toLowerCase().contains('mayor')) {
      return 'mayor';
    } else if (officeName.toLowerCase().contains('council')) {
      return 'cityCouncil';
    } else if (officeName.toLowerCase().contains('commissioner') || 
              officeName.toLowerCase().contains('county')) {
      return 'countyCommissioner';
    } else if (officeName.toLowerCase().contains('school')) {
      return 'schoolBoard';
    } else if (officeName.toLowerCase().contains('sheriff')) {
      return 'sheriff';
    } else if (officeName.toLowerCase().contains('senator')) {
      return 'senator';
    } else if (officeName.toLowerCase().contains('representative')) {
      return 'representative';
    } else if (officeName.toLowerCase().contains('governor')) {
      return 'governor';
    } else if (officeName.toLowerCase().contains('attorney')) {
      return 'attorneyGeneral';
    }
    
    // Default to "stateOfficial" if it has "state" in the name
    if (roleUpper.contains('STATE')) {
      return 'stateOfficial';
    }
    
    // Default fallback
    return 'default';
  }
  
  // These helper methods have been removed since we no longer display level and branch chips
}