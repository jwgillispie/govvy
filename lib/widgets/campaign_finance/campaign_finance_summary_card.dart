import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/models/campaign_finance_model.dart';

class CampaignFinanceSummaryCard extends StatelessWidget {
  const CampaignFinanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CampaignFinanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingAny && !provider.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (provider.error != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Campaign Finance Error',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        if (!provider.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No campaign finance data available'),
                ],
              ),
            ),
          );
        }

        final candidate = provider.currentCandidate!;
        final summary = provider.financeSummary;

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
                    Expanded(
                      child: Text(
                        'Campaign Finance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (provider.isLoadingAny)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Candidate basic info
                _buildInfoRow('Candidate', candidate.name),
                if (candidate.party != null)
                  _buildInfoRow('Party', candidate.party!),
                if (candidate.office != null)
                  _buildInfoRow('Office', candidate.office!),
                if (candidate.electionYear != null)
                  _buildInfoRow('Election Year', candidate.electionYear.toString()),
                
                if (summary != null) ...[
                  const Divider(height: 24),
                  
                  // Comprehensive financial overview  
                  _buildComprehensiveFinancialOverview(context, summary, provider),
                  
                  const SizedBox(height: 16),
                  
                  // Detailed financial breakdown
                  _buildDetailedFinancialBreakdown(context, summary, provider),
                ],
                
                // Top contributors preview
                if (provider.topContributors.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildTopContributorsPreview(context, provider),
                ],
                
                // Expenditure categories preview
                if (provider.expenditureCategorySummary.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildExpenditureCategoriesPreview(context, provider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildComprehensiveFinancialOverview(
    BuildContext context,
    CampaignFinanceSummary summary,
    CampaignFinanceProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.green.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Campaign Finance Overview (${summary.cycle})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Big numbers display
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildBigNumberCard(
                      context,
                      'TOTAL RAISED',
                      _formatLargeCurrency(summary.totalRaised),
                      Colors.green,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBigNumberCard(
                      context,
                      'TOTAL SPENT',
                      _formatLargeCurrency(summary.totalSpent),
                      Colors.red,
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBigNumberCard(
                      context,
                      'CASH ON HAND',
                      _formatLargeCurrency(summary.cashOnHand),
                      Colors.blue,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBigNumberCard(
                      context,
                      'INDIVIDUAL DONORS',
                      _formatNumber(summary.individualContributionsCount),
                      Colors.purple,
                      Icons.people,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Spending efficiency warning
          if (provider.spendingEfficiency != null && provider.spendingEfficiency! > 1.0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'High Spending: Campaign spent ${(provider.spendingEfficiency! * 100).toStringAsFixed(0)}% of what it raised',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedFinancialBreakdown(
    BuildContext context,
    CampaignFinanceSummary summary,
    CampaignFinanceProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Detailed metrics
        _buildDetailedMetricRow(
          context,
          'Individual Contributions',
          _formatLargeCurrency(summary.individualContributionsTotal),
          'From ${_formatNumber(summary.individualContributionsCount)} donors',
          Colors.green,
        ),
        const SizedBox(height: 8),
        _buildDetailedMetricRow(
          context,
          'Total Disbursements',
          _formatLargeCurrency(summary.totalSpent),
          'Campaign expenditures and transfers',
          Colors.red,
        ),
        const SizedBox(height: 8),
        _buildDetailedMetricRow(
          context,
          'Net Position',
          _formatLargeCurrency(summary.totalRaised - summary.totalSpent),
          summary.totalRaised > summary.totalSpent ? 'Surplus' : 'Deficit',
          summary.totalRaised > summary.totalSpent ? Colors.green : Colors.red,
        ),
        if (summary.totalDebt > 0) ...[
          const SizedBox(height: 8),
          _buildDetailedMetricRow(
            context,
            'Outstanding Debt',
            _formatLargeCurrency(summary.totalDebt),
            'Debts owed by committee',
            Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildBigNumberCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetricRow(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLargeCurrency(double amount) {
    if (amount.abs() >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount.abs() >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }



  Widget _buildTopContributorsPreview(BuildContext context, CampaignFinanceProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Contributors',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...provider.topContributors.take(3).map((contributor) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    contributor.contributorName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  '\$${contributor.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
        if (provider.topContributors.length > 3)
          Text(
            '... and ${provider.topContributors.length - 3} more',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildExpenditureCategoriesPreview(BuildContext context, CampaignFinanceProvider provider) {
    final sortedCategories = provider.expenditureCategorySummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Spending Categories',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...sortedCategories.take(3).map((category) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  '\$${category.value.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
        if (sortedCategories.length > 3)
          Text(
            '... and ${sortedCategories.length - 3} more categories',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}