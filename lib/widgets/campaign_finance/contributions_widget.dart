import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/models/campaign_finance_model.dart';

class ContributionsWidget extends StatefulWidget {
  const ContributionsWidget({super.key});

  @override
  State<ContributionsWidget> createState() => _ContributionsWidgetState();
}

class _ContributionsWidgetState extends State<ContributionsWidget> {
  bool _showAll = false;
  String? _lastCandidateId;

  @override
  Widget build(BuildContext context) {
    return Consumer<CampaignFinanceProvider>(
      builder: (context, provider, child) {
        // Reset show all state when candidate changes
        if (provider.currentCandidate?.candidateId != _lastCandidateId) {
          _showAll = false;
          _lastCandidateId = provider.currentCandidate?.candidateId;
        }
        if (provider.isLoadingContributions) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Contributions',
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
                  const Text('Loading recent contributions...'),
                ],
              ),
            ),
          );
        }

        if (provider.contributions.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Contributions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No recent contribution data available.',
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
                    const Icon(Icons.attach_money, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Contributions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('${provider.contributions.length} entries'),
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Show contributions based on expanded state
                ...(_showAll 
                    ? provider.contributions.take(30)
                    : provider.contributions.take(5)
                ).map((contribution) => 
                  _buildContributionItem(contribution)
                ),
                
                if (provider.contributions.length > 5) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        if (!_showAll) ...[
                          Text(
                            'Showing 5 of ${provider.contributions.length} contributions',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAll = true;
                              });
                            },
                            icon: const Icon(Icons.expand_more, size: 18),
                            label: Text('Show ${provider.contributions.length > 30 ? "30" : provider.contributions.length} Contributions'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Showing ${provider.contributions.length > 30 ? "30" : provider.contributions.length} of ${provider.contributions.length} contributions',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAll = false;
                              });
                            },
                            icon: const Icon(Icons.expand_less, size: 18),
                            label: const Text('Show Less'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[400]!),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
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

  Widget _buildContributionItem(CampaignContribution contribution) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  contribution.contributorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatCurrency(contribution.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (contribution.contributorEmployer != null) ...[
            Text(
              contribution.contributorEmployer!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (contribution.contributorCity != null && contribution.contributorState != null) ...[
            Text(
              '${contribution.contributorCity}, ${contribution.contributorState}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (contribution.contributionDate != null) ...[
            Text(
              _formatDate(contribution.contributionDate!),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}