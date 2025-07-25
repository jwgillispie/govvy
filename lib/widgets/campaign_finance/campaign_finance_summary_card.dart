import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/models/campaign_finance_model.dart';
import 'package:govvy/utils/data_source_attribution.dart' as DataSources;

class CampaignFinanceSummaryCard extends StatelessWidget {
  const CampaignFinanceSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CampaignFinanceProvider>(
      builder: (context, provider, child) {
        // Show loading screen only if we don't have candidate data yet
        if (!provider.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      provider.currentCandidate != null
                          ? 'Loading campaign finance data for ${provider.currentCandidate!.name}...'
                          : 'Searching candidate...',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
                  
                  // DEBUG: Show that we have summary data
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SUCCESS: Financial data loaded for ${summary.cycle} - \$${_formatLargeCurrency(summary.totalRaised)} raised',
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ),
                  
                  // Comprehensive financial overview  
                  _buildComprehensiveFinancialOverview(context, summary, provider),
                  
                  const SizedBox(height: 16),
                  
                  // Detailed financial breakdown
                  _buildDetailedFinancialBreakdown(context, summary, provider),
                ] else ...[
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEBUG: No financial summary data available',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
                
                // Top contributors preview
                if (provider.topContributors.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildTopContributorsPreview(context, provider),
                ],
                
                
                // Enhanced data sections with new FEC insights
                if (provider.contributionsByState.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildGeographicInsights(context, provider),
                ],
                
                if (provider.contributionAmountDistribution.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildContributionPatterns(context, provider),
                ],
                
                if (provider.monthlyFundraisingTrends.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildFundraisingTrends(context, provider),
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
              Expanded(
                child: Text(
                  'Overview (${summary.cycle})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  overflow: TextOverflow.ellipsis,
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
          
          // Data source attribution
          const SizedBox(height: 16),
          DataSources.DataSourceAttribution.buildSourceAttribution(
            DataSources.DataSourceAttribution.getFinanceDataSources(provider.currentCandidate),
            prefix: 'Data from',
            wrap: true,
          ),
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
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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


  Widget _buildGeographicInsights(BuildContext context, CampaignFinanceProvider provider) {
    final sortedStates = provider.contributionsByState.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.map, color: Colors.teal, size: 20),
            const SizedBox(width: 8),
            Text(
              'Geographic Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                'Top Contributing States',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...sortedStates.take(5).map((state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Text(
                            state.key,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.key == 'Unknown' ? 'Unknown State' : state.key,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        _formatLargeCurrency(state.value),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.teal[700],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (sortedStates.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '... and ${sortedStates.length - 5} more states',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContributionPatterns(BuildContext context, CampaignFinanceProvider provider) {
    final distribution = provider.contributionAmountDistribution;
    final total = distribution.values.reduce((a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pie_chart, color: Colors.indigo, size: 20),
            const SizedBox(width: 8),
            Text(
              'Contribution Patterns',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                'Donor Distribution by Amount',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...distribution.entries.map((entry) {
                final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${entry.value}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.indigo[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFundraisingTrends(BuildContext context, CampaignFinanceProvider provider) {
    final trends = provider.monthlyFundraisingTrends;
    final sortedMonths = trends.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Fundraising Trends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                'Monthly Fundraising Activity',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...sortedMonths.take(6).map((month) {
                final monthName = _getMonthName(month.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          monthName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        _formatLargeCurrency(month.value),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (sortedMonths.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '... and ${sortedMonths.length - 6} more months',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 0;
    
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    if (month >= 1 && month <= 12) {
      return '${monthNames[month]} $year';
    }
    
    return monthKey;
  }
}