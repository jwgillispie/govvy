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
    // Get the role information from our standardized data
    final RoleInfo roleInfo = GovernmentRoles.getRoleInfo(role);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role header with icon and title
          _buildRoleHeader(roleInfo, context),
          
          const SizedBox(height: 16),
          
          // Role description
          _buildDescriptionSection(roleInfo, context),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Key facts grid
          _buildKeyFactsGrid(roleInfo, context),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Responsibilities section
          _buildResponsibilitiesSection(roleInfo, context),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Fun facts section
          _buildFunFactsSection(roleInfo, context),
        ],
      ),
    );
  }
  
  Widget _buildRoleHeader(RoleInfo roleInfo, BuildContext context) {
    return Row(
      children: [
        // Icon in a colored circle
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            roleInfo.icon,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        
        // Title and level/branch info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roleInfo.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${roleInfo.levelString} ${roleInfo.branchString} Branch',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              if (officeName.isNotEmpty) 
                Text(
                  officeName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDescriptionSection(RoleInfo roleInfo, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Description in a card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Text(
            roleInfo.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
  
  Widget _buildKeyFactsGrid(RoleInfo roleInfo, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Facts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        
        // Facts grid
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFactCard('Term Length', roleInfo.termYears, Icons.calendar_today, context),
            _buildFactCard('Term Limits', roleInfo.termLimit, Icons.repeat, context),
            _buildFactCard('Positions', roleInfo.totalPositions.toString(), Icons.people, context),
            _buildFactCard('Salary', roleInfo.salary, Icons.attach_money, context),
            _buildFactCard('Election', roleInfo.electionInfo, Icons.how_to_vote, context),
            _buildFactCard('Qualifications', roleInfo.qualifications, Icons.school, context),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFactCard(String title, String content, IconData icon, BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                content,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResponsibilitiesSection(RoleInfo roleInfo, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Responsibilities',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        
        // Responsibilities list with checkmarks
        ...roleInfo.responsibilities.map((responsibility) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
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
      ],
    );
  }
  
  Widget _buildFunFactsSection(RoleInfo roleInfo, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fun Facts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        
        // Fun facts with bullet points
        ...roleInfo.funFacts.map((fact) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.star,
                  size: 18,
                  color: Colors.amber,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fact,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}