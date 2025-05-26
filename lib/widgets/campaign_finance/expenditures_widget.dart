import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';

class ExpendituresWidget extends StatelessWidget {
  const ExpendituresWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CampaignFinanceProvider>(
      builder: (context, provider, child) {
        // Don't show anything until we have some basic data
        if (provider.expenditureCategorySummary.isEmpty && !provider.isLoadingAny) {
          return const SizedBox.shrink();
        }

        if (provider.expenditureCategorySummary.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Expenditure Categories',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Loading expenditure data...'),
                ],
              ),
            ),
          );
        }

        // Sort expenditures by amount (highest first)
        final sortedExpenditures = provider.expenditureCategorySummary.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Expenditure Categories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Show top expenditure categories
                ...sortedExpenditures.take(6).map((entry) => 
                  _buildExpenditureItem(entry.key, entry.value)
                ),
                
                if (sortedExpenditures.length > 6) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Showing top 6 of ${sortedExpenditures.length} categories',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpenditureItem(String category, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }
}