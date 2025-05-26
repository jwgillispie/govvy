// lib/widgets/bills/enhanced_bill_card.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:intl/intl.dart';

enum BillCardMode {
  compact,    // For list views with many bills
  standard,   // Default display with moderate details
  detailed    // For focused views with more information
}

class EnhancedBillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;
  final BillCardMode mode;
  final bool showStateCode;
  final bool showRipple;
  
  const EnhancedBillCard({
    Key? key,
    required this.bill,
    this.onTap,
    this.mode = BillCardMode.standard,
    this.showStateCode = true,
    this.showRipple = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: mode == BillCardMode.compact ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mode == BillCardMode.compact ? 8 : 12),
        side: mode == BillCardMode.detailed 
            ? BorderSide(color: Colors.grey.shade300, width: 1)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: showRipple ? null : Colors.transparent,
        highlightColor: showRipple ? null : Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(mode == BillCardMode.compact ? 12 : 16),
          child: mode == BillCardMode.compact 
              ? _buildCompactView(context)
              : mode == BillCardMode.detailed
                  ? _buildDetailedView(context)
                  : _buildStandardView(context),
        ),
      ),
    );
  }
  
  Widget _buildCompactView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with bill number, government level, and state
        Row(
          children: [
            _buildBillNumberBadge(context),
            const SizedBox(width: 8),
            _buildTypeBadge(context),
            const SizedBox(width: 8),
            if (showStateCode) ...[
              Text(
                bill.state,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                _formatLastActionDate(bill.lastActionDate),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Bill title (shorter in compact mode)
        Text(
          bill.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 4),
        
        // Status with colored indicator
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(bill.statusColor),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                bill.status,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStandardView(BuildContext context) {
    // Check if bill has a description
    final hasDescription = bill.description != null && bill.description!.isNotEmpty;
    
    // Check if bill has a committee
    final hasCommittee = bill.committee != null && bill.committee!.isNotEmpty;
    
    // Check if bill has a URL
    final hasUrl = bill.url.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with number and type badge
        Row(
          children: [
            _buildBillNumberBadge(context),
            const SizedBox(width: 8),
            _buildTypeBadge(context),
            const Spacer(),
            if (showStateCode)
              Text(
                bill.state,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Bill title
        Text(
          bill.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Description if available
        if (hasDescription) ...[
          const SizedBox(height: 8),
          Text(
            bill.description!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        const SizedBox(height: 12),

        // Committee and chamber information
        if (hasCommittee || bill.chamber != null) ...[
          Row(
            children: [
              Icon(
                Icons.groups,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasCommittee)
                      Text(
                        'Committee: ${bill.committee}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (bill.chamber != null)
                      Text(
                        'Chamber: ${bill.chamber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Status row
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(bill.statusColor),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bill.status,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Enhanced metadata row
        const SizedBox(height: 8),
        Row(
          children: [
            // Progress indicator if available
            if (bill.completionPercentage != null) ...[
              Icon(
                Icons.timeline,
                size: 14,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${bill.completionPercentage!.round()}% complete',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
            ],
            
            // Vote count if available
            if (bill.totalVotes != null && bill.totalVotes! > 0) ...[
              Icon(
                Icons.how_to_vote,
                size: 14,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${bill.totalVotes} votes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
            ],
            
            // Additional indicators
            if (bill.hasAmendments) ...[
              Icon(
                Icons.edit_document,
                size: 14,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Amended',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 8),
            ],
            
            if (bill.hasSupplements) ...[
              Icon(
                Icons.attach_money,
                size: 14,
                color: Colors.purple.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Fiscal',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple.shade700,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        
        // Date and link row
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (bill.lastActionDate != null)
              Expanded(
                child: Text(
                  'Last Action: ${_formatLastActionDate(bill.lastActionDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            
            // URL view online link
            if (hasUrl)
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'View online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDetailedView(BuildContext context) {
    // Check if bill has a description
    final hasDescription = bill.description != null && bill.description!.isNotEmpty;
    
    // Check if bill has a committee
    final hasCommittee = bill.committee != null && bill.committee!.isNotEmpty;
    
    // Check if bill has a URL
    final hasUrl = bill.url.isNotEmpty;
    
    // Check if bill has subjects
    final hasSubjects = bill.subjects != null && bill.subjects!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with bill ID, number and badges
        Row(
          children: [
            _buildBillNumberBadge(context),
            const SizedBox(width: 8),
            _buildTypeBadge(context),
            const Spacer(),
            if (showStateCode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  bill.state,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Bill title in larger font
        Text(
          bill.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),

        // Description if available
        if (hasDescription) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bill.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Legislative details section
        if (hasCommittee || bill.chamber != null || bill.fiscalNote != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Legislative Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                if (bill.chamber != null) ...[
                  _buildDetailRow('Chamber', bill.chamber!, Icons.domain),
                  const SizedBox(height: 4),
                ],
                
                if (hasCommittee) ...[
                  _buildDetailRow('Committee', bill.committee!, Icons.groups),
                  const SizedBox(height: 4),
                ],
                
                if (bill.fiscalNote != null) ...[
                  _buildDetailRow('Fiscal Impact', bill.fiscalNote!, Icons.attach_money),
                ],
              ],
            ),
          ),
        ],

        // Status with better styling
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusBackgroundColor(bill.statusColor),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getStatusColor(bill.statusColor).withOpacity(0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getStatusIcon(bill.statusColor),
                size: 18,
                color: _getStatusColor(bill.statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(bill.statusColor).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.status,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(bill.statusColor).withOpacity(0.8),
                      ),
                    ),
                    if (bill.lastActionDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last Updated: ${_formatLastActionDate(bill.lastActionDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(bill.statusColor).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Enhanced progress and dates section
        const SizedBox(height: 12),
        
        // Progress bar if available
        if (bill.completionPercentage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
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
                      Icons.timeline,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Legislative Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${bill.completionPercentage!.round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: bill.completionPercentage! / 100,
                  backgroundColor: Colors.blue.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Dates with better formatting
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Introduced',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.introducedDate != null 
                          ? _formatLastActionDate(bill.introducedDate)
                          : 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Last Action',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.lastActionDate != null 
                          ? _formatLastActionDate(bill.lastActionDate)
                          : 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (bill.totalVotes != null && bill.totalVotes! > 0) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Votes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bill.totalVotes}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Additional indicators row
        if (bill.hasAmendments || bill.hasSupplements || bill.priorityStatus != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (bill.hasAmendments)
                _buildIndicatorChip(
                  'Amendments',
                  Icons.edit_document,
                  Colors.orange,
                ),
              if (bill.hasSupplements)
                _buildIndicatorChip(
                  'Fiscal Notes',
                  Icons.attach_money,
                  Colors.purple,
                ),
              if (bill.priorityStatus != null)
                _buildIndicatorChip(
                  bill.priorityStatus!,
                  Icons.priority_high,
                  Colors.red,
                ),
            ],
          ),
        ],
        
        // Subjects
        if (hasSubjects) ...[
          const SizedBox(height: 12),
          Text(
            'Subjects',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: bill.subjects!.map((subject) {
              return Chip(
                label: Text(
                  subject,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue.shade50,
                side: BorderSide(color: Colors.blue.shade100),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
        
        // URL view button
        if (hasUrl) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View Bill Online'),
              onPressed: () {
                // URL handling would be done in the parent widget
                if (onTap != null) {
                  onTap!();
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  // Helper widget for bill number badge
  Widget _buildBillNumberBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        bill.formattedBillNumber,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  // Helper widget for type badge with enhanced government level indicators
  Widget _buildTypeBadge(BuildContext context) {
    // Determine the badge based on bill type with clear visual distinctions
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String label;
    IconData icon;
    
    switch (bill.type.toLowerCase()) {
      case 'federal':
        backgroundColor = Colors.blue.shade100;
        borderColor = Colors.blue.shade300;
        textColor = Colors.blue.shade800;
        label = 'FEDERAL';
        icon = Icons.account_balance;
        break;
      case 'state':
        backgroundColor = Colors.green.shade100;
        borderColor = Colors.green.shade300;
        textColor = Colors.green.shade800;
        label = 'STATE';
        icon = Icons.location_city;
        break;
      case 'local':
        backgroundColor = Colors.orange.shade100;
        borderColor = Colors.orange.shade300;
        textColor = Colors.orange.shade800;
        label = 'LOCAL';
        icon = Icons.location_on;
        break;
      default:
        // For unknown types, try to infer from state or other indicators
        if (bill.state == 'US' || bill.state == 'USA') {
          backgroundColor = Colors.blue.shade100;
          borderColor = Colors.blue.shade300;
          textColor = Colors.blue.shade800;
          label = 'FEDERAL';
          icon = Icons.account_balance;
        } else {
          backgroundColor = Colors.grey.shade100;
          borderColor = Colors.grey.shade300;
          textColor = Colors.grey.shade700;
          label = bill.type.isNotEmpty 
              ? bill.type.toUpperCase() 
              : 'UNKNOWN';
          icon = Icons.help_outline;
        }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to format date for display
  String _formatLastActionDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'Unknown';
    }
    
    try {
      // Parse the date string
      final date = DateTime.parse(dateStr);
      
      // Format with intl package if available
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      // If parsing fails, return the original string
      return dateStr;
    }
  }
  
  // Helper to get color based on status
  Color _getStatusColor(String statusColor) {
    switch (statusColor) {
      case 'green':
        return Colors.purple.shade600;
      case 'red':
        return Colors.purple.shade700;
      case 'orange':
        return Colors.purple.shade500;
      case 'blue':
        return Colors.purple.shade400;
      default:
        return Colors.purple.shade300;
    }
  }
  
  // Helper to get status background color
  Color _getStatusBackgroundColor(String statusColor) {
    switch (statusColor) {
      case 'green':
        return Colors.purple.shade50;
      case 'red':
        return Colors.purple.shade100;
      case 'orange':
        return Colors.purple.shade50;
      case 'blue':
        return Colors.purple.shade50;
      default:
        return Colors.purple.shade50;
    }
  }
  
  // Helper to get status icon
  IconData _getStatusIcon(String statusColor) {
    switch (statusColor) {
      case 'green':
        return Icons.check_circle_outline;
      case 'red':
        return Icons.cancel_outlined;
      case 'orange':
        return Icons.warning_amber_outlined;
      case 'blue':
        return Icons.info_outline;
      default:
        return Icons.schedule;
    }
  }
  
  // Helper to build detail rows in legislative details section
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  // Helper to build indicator chips
  Widget _buildIndicatorChip(String label, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}