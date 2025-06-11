// lib/widgets/bills/bill_card.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/widgets/shared/government_level_badge.dart';

class BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;

  const BillCard({
    Key? key,
    required this.bill,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine color based on bill status
    Color statusColor;
    switch (bill.statusColor) {
      case 'green':
        statusColor = Colors.purple.shade600;
        break;
      case 'red':
        statusColor = Colors.purple.shade700;
        break;
      case 'orange':
        statusColor = Colors.purple.shade500;
        break;
      case 'blue':
        statusColor = Colors.purple.shade400;
        break;
      default:
        statusColor = Colors.purple.shade300;
    }

    // Use the new government level badge
    Widget typeBadge = GovernmentLevelBadge.fromBillType(
      billType: bill.type,
      size: BadgeSize.small,
      compact: true,
    );

    // Check if bill has a description
    final hasDescription = bill.description != null && bill.description!.isNotEmpty;
    
    // Check if bill has a committee
    final hasCommittee = bill.committee != null && bill.committee!.isNotEmpty;
    
    // Check if bill has a URL
    final hasUrl = bill.url.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bill header row with number and type badge
              Row(
                children: [
                  Container(
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
                  ),
                  const SizedBox(width: 8),
                  typeBadge,
                  const Spacer(),
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

              // Description if available (especially for FL and GA)
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

              const SizedBox(height: 8),

              // Committee when available (especially for FL and GA)
              if (hasCommittee) ...[
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
                const SizedBox(height: 8),
              ],

              // Bill status with colored indicator
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
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

              // Date when available
              if (bill.lastActionDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last Action: ${bill.lastActionDate}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              
              // URL when available
              if (hasUrl && (bill.state == 'FL' || bill.state == 'GA')) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
            ],
          ),
        ),
      ),
    );
  }

}