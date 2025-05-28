import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/unified_finance_provider.dart';
import 'package:govvy/models/unified_candidate_model.dart';

class UnifiedFinanceSummaryWidget extends StatelessWidget {
  const UnifiedFinanceSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedFinanceProvider>(
      builder: (context, provider, child) {
        if (!provider.hasCurrentCandidate) {
          return const SizedBox.shrink();
        }

        final candidate = provider.currentCandidate!;
        final financeData = provider.currentFinanceData;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with data source indicator
                Row(
                  children: [
                    Icon(
                      _getLevelIcon(candidate.level),
                      color: _getLevelColor(candidate.level),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campaign Finance Summary',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${candidate.level.displayName} • ${candidate.primarySource.fullName}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Data source badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getLevelColor(candidate.level).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getLevelColor(candidate.level).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        candidate.primarySource.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getLevelColor(candidate.level),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Loading state
                if (provider.isLoadingFinance) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (provider.error != null) ...[
                  // Error state
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ] else if (financeData != null) ...[
                  // Finance data
                  _buildFinanceMetrics(financeData),
                ] else ...[
                  // No data state
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Finance data not available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'This may be normal for some ${candidate.level.displayName.toLowerCase()} candidates',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  Widget _buildFinanceMetrics(UnifiedFinanceData financeData) {
    return Column(
      children: [
        // Main metrics row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Raised',
                financeData.formattedTotalRaised,
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Spent',
                financeData.formattedTotalSpent,
                Icons.trending_down,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Second row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Cash on Hand',
                financeData.formattedCashOnHand,
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Contributions',
                financeData.contributionCount.toString(),
                Icons.people,
                Colors.orange,
              ),
            ),
          ],
        ),
        
        // Data quality note
        if (financeData.dataQualityNote != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.info, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    financeData.dataQualityNote!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Spending efficiency if available
        if (financeData.spendingEfficiency != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Spending Efficiency: ${(financeData.spendingEfficiency! * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(OfficeLevel level) {
    switch (level) {
      case OfficeLevel.federal:
        return Colors.blue;
      case OfficeLevel.state:
        return Colors.green;
      case OfficeLevel.local:
        return Colors.orange;
    }
  }

  IconData _getLevelIcon(OfficeLevel level) {
    switch (level) {
      case OfficeLevel.federal:
        return Icons.account_balance;
      case OfficeLevel.state:
        return Icons.location_city;
      case OfficeLevel.local:
        return Icons.location_on;
    }
  }
}