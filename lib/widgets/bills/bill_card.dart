// lib/widgets/bills/bill_card.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:govvy/models/bill_model.dart';

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
        statusColor = Colors.green;
        break;
      case 'red':
        statusColor = Colors.red;
        break;
      case 'orange':
        statusColor = Colors.orange;
        break;
      case 'blue':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Determine the badge based on bill type and special handling for FL and GA
    Widget typeBadge;
    if (bill.state == 'FL' || bill.state == 'GA') {
      // Show special badge for FL and GA
      typeBadge = _buildBadge(bill.state, Colors.deepPurple);
    } else {
      switch (bill.type) {
        case 'federal':
          typeBadge = _buildBadge('Federal', Colors.indigo);
          break;
        case 'state':
          typeBadge = _buildBadge('State', Colors.teal);
          break;
        case 'local':
          typeBadge = _buildBadge('Local', Colors.green);
          break;
        default:
          typeBadge = _buildBadge(bill.type, Colors.grey);
      }
    }

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
          // Debug the bill ID and state
          if (kDebugMode) {
            print('Opening bill details: ID=${bill.billId}, State=${bill.state}');
            print('Bill title: ${bill.title}');
            print('Bill type: ${bill.type}');
          }
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

  // Helper to build badge widgets
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black26,
        ),
      ),
    );
  }
}