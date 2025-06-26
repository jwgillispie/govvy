// lib/widgets/representatives/role_info_widget.dart

import 'package:flutter/material.dart';
import 'package:govvy/data/government_roles.dart';

class RoleInfoWidget extends StatelessWidget {
  final String role;
  final String officeName;
  final String? district;
  final String? bioGuideId;
  final String? representativeName;

  const RoleInfoWidget({
    Key? key,
    required this.role,
    this.officeName = '',
    this.district,
    this.bioGuideId,
    this.representativeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Easter egg: Special handling for Josh Robinson
    if (_isJoshRobinson()) {
      return _buildJoshRobinsonRoleInfo(context);
    }
    
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
  
  // Easter egg detection
  bool _isJoshRobinson() {
    return bioGuideId == 'cicero-josh-robinson-easter-egg' ||
           (representativeName?.toLowerCase().contains('josh robinson') ?? false);
  }
  
  // Easter egg: Josh Robinson role info
  Widget _buildJoshRobinsonRoleInfo(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role & Responsibilities 💰',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber[300]
                  : Colors.amber[700],
            ),
          ),
          const SizedBox(height: 12),
          
          // Role description card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [Colors.amber.shade900.withOpacity(0.3), Colors.yellow.shade900.withOpacity(0.3)]
                    : [Colors.amber.shade50, Colors.yellow.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber.shade700
                    : Colors.amber.shade200
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber[400]
                          : Colors.amber[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Supreme Overlord of Monetary Accumulation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber[300]
                              : Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Josh "Money God" Robinson serves as the ultimate authority on wealth generation and monetary policy. His office is dedicated to ensuring maximum profit extraction from all government operations while transforming every legislative action into a money-making opportunity.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.amber[200]
                        : Colors.amber[900],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Divider(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.amber[600]
                : Colors.amber,
          ),
          const SizedBox(height: 16),
          
          // Key responsibilities section
          Text(
            'Key Money-Making Responsibilities 💸',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber[300]
                  : Colors.amber[700],
            ),
          ),
          const SizedBox(height: 12),
          
          // Responsibilities list
          Column(
            children: [
              'Converting all public resources into personal profit streams',
              'Implementing mandatory yacht ownership programs for constituents', 
              'Establishing gold mining operations in every public park',
              'Creating cryptocurrency backed by constituent tax payments',
              'Operating 24/7 money printing facilities in government buildings',
              'Charging admission fees for all government services',
              'Licensing government positions to highest bidders',
              'Converting all roads to toll roads with surge pricing'
            ].map((responsibility) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.monetization_on, 
                      size: 18, 
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber[400]
                          : Colors.amber[700],
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
          Divider(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.amber[600]
                : Colors.amber,
          ),
          const SizedBox(height: 16),
          
          // Term and salary info
          Text(
            'Wealth & Position Info 🏦',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber[300]
                  : Colors.amber[700],
            ),
          ),
          const SizedBox(height: 12),
          
          // Custom Josh Robinson info
          _buildJoshInfoRow(
            context, 
            'Term Length:', 
            'Eternal (until someone pays more)',
            Icons.all_inclusive
          ),
          
          _buildJoshInfoRow(
            context, 
            'Term Limits:', 
            'None (money has no limits)',
            Icons.trending_up
          ),
          
          _buildJoshInfoRow(
            context, 
            'Annual Salary:', 
            '\$500 Billion + All Government Revenue',
            Icons.attach_money
          ),
          
          _buildJoshInfoRow(
            context, 
            'Net Worth:', 
            '\$50 Trillion (and growing exponentially)',
            Icons.account_balance
          ),
          
          _buildJoshInfoRow(
            context, 
            'Qualifications:', 
            'PhD in Money Magic, Masters in Wealth Wizardry, Certified Gold Hoarder',
            Icons.school
          ),
          
          _buildJoshInfoRow(
            context, 
            'Office Location:', 
            'Solid Gold Palace with Diamond Windows',
            Icons.location_city
          ),
        ],
      ),
    );
  }
  
  // Helper method for Josh Robinson info rows
  Widget _buildJoshInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber[400]
                    : Colors.amber[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.amber[300]
                        : Colors.amber[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}