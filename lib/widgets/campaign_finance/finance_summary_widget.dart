import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';

class FinanceSummaryWidget extends StatelessWidget {
  const FinanceSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CampaignFinanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingSummary) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Financial Summary',
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
                  const Text('Loading financial summary...'),
                ],
              ),
            ),
          );
        }

        final summary = provider.financeSummary;
        if (summary == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Financial Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No financial summary data available for this candidate and cycle.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Financial Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('${summary.cycle} Cycle'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Key metrics in a grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 3.0,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _buildMetricCard(
                      'Total Raised',
                      _formatLargeCurrency(summary.totalRaised),
                      Colors.green,
                      Icons.trending_up,
                    ),
                    _buildMetricCard(
                      'Total Spent',
                      _formatLargeCurrency(summary.totalSpent),
                      Colors.red,
                      Icons.trending_down,
                    ),
                    _buildMetricCard(
                      'Cash on Hand',
                      _formatLargeCurrency(summary.cashOnHand),
                      Colors.blue,
                      Icons.account_balance,
                    ),
                    _buildMetricCard(
                      'Total Debt',
                      _formatLargeCurrency(summary.totalDebt),
                      Colors.orange,
                      Icons.warning,
                    ),
                  ],
                ),
                
                if (summary.coverageEndDate != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Data through: ${_formatDate(summary.coverageEndDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatLargeCurrency(double amount) {
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}