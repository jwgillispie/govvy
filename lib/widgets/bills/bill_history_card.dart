// lib/widgets/bills/bill_history_card.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/bill_model.dart';

class BillHistoryCard extends StatelessWidget {
  final BillHistory action;
  final bool isFirst;
  final bool isLast;

  const BillHistoryCard({
    Key? key,
    required this.action,
    this.isFirst = false,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get chamber icon and color
    IconData chamberIcon;
    Color chamberColor;
    
    if (action.chamber == null) {
      chamberIcon = Icons.article;
      chamberColor = Colors.grey;
    } else if (action.chamber!.toLowerCase().contains('senate') || 
               action.chamber!.toLowerCase().contains('upper')) {
      chamberIcon = Icons.account_balance;
      chamberColor = Colors.indigo;
    } else if (action.chamber!.toLowerCase().contains('house') || 
               action.chamber!.toLowerCase().contains('lower')) {
      chamberIcon = Icons.location_city;
      chamberColor = Colors.teal;
    } else if (action.chamber!.toLowerCase().contains('executive') || 
               action.chamber!.toLowerCase().contains('governor')) {
      chamberIcon = Icons.gavel;
      chamberColor = Colors.green;
    } else {
      chamberIcon = Icons.article;
      chamberColor = Colors.grey;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line with dot
        SizedBox(
          width: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top connecting line (not for first item)
              if (!isFirst)
                Container(
                  width: 2,
                  height: 12,
                  color: Colors.grey.shade300,
                ),
                
              // Timeline dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: chamberColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              
              // Bottom connecting line (not for last item)
              if (!isLast)
                Container(
                  width: 2,
                  height: 24,
                  color: Colors.grey.shade300,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        
        // Action content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Text(
                  _formatDate(action.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Chamber badge
                if (action.chamber != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: chamberColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: chamberColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          chamberIcon,
                          size: 12,
                          color: chamberColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          action.chamber!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: chamberColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Action text
                Text(
                  action.action,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper to format the date string
  String _formatDate(String dateStr) {
    // Implementation depends on the date format from your API
    // This is a simple example assuming format is already readable
    return dateStr;
    
    // For more complex formatting:
    // try {
    //   final DateTime date = DateTime.parse(dateStr);
    //   return DateFormat('MMM dd, yyyy').format(date);
    // } catch (e) {
    //   return dateStr;
    // }
  }
}