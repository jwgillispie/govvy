import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/widgets/campaign_finance/campaign_finance_summary_card.dart';

class CampaignFinanceScreen extends StatefulWidget {
  const CampaignFinanceScreen({super.key});

  @override
  State<CampaignFinanceScreen> createState() => _CampaignFinanceScreenState();
}

class _CampaignFinanceScreenState extends State<CampaignFinanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCandidate() async {
    if (_searchQuery.trim().isEmpty) return;

    final provider = Provider.of<CampaignFinanceProvider>(context, listen: false);
    await provider.loadCandidateByName(_searchQuery.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    
    final provider = Provider.of<CampaignFinanceProvider>(context, listen: false);
    provider.clearData();
  }

  Future<void> _searchCandidateByName(String name) async {
    setState(() {
      _searchQuery = name;
    });
    _searchController.text = name;
    
    final provider = Provider.of<CampaignFinanceProvider>(context, listen: false);
    await provider.loadCandidateByName(name);
  }

  Widget _buildPopularCandidatesGrid(BuildContext context) {
    final candidates = [
      // Presidential
      {'name': 'Joe Biden', 'office': 'President', 'party': 'D', 'icon': Icons.person},
      {'name': 'Donald Trump', 'office': 'President', 'party': 'R', 'icon': Icons.person},
      {'name': 'Ron DeSantis', 'office': 'Governor/Presidential', 'party': 'R', 'icon': Icons.person},
      {'name': 'Nikki Haley', 'office': 'Presidential', 'party': 'R', 'icon': Icons.person},
      
      // Senate Leaders & Notable
      {'name': 'Chuck Schumer', 'office': 'Senate Majority Leader', 'party': 'D', 'icon': Icons.account_balance},
      {'name': 'Mitch McConnell', 'office': 'Senate Minority Leader', 'party': 'R', 'icon': Icons.account_balance},
      {'name': 'Elizabeth Warren', 'office': 'Senator MA', 'party': 'D', 'icon': Icons.account_balance},
      {'name': 'Ted Cruz', 'office': 'Senator TX', 'party': 'R', 'icon': Icons.account_balance},
      {'name': 'Bernie Sanders', 'office': 'Senator VT', 'party': 'I', 'icon': Icons.account_balance},
      {'name': 'Marco Rubio', 'office': 'Senator FL', 'party': 'R', 'icon': Icons.account_balance},
      
      // House Leaders & Notable
      {'name': 'Alexandria Ocasio-Cortez', 'office': 'Rep NY-14', 'party': 'D', 'icon': Icons.domain},
      {'name': 'Nancy Pelosi', 'office': 'Rep CA-11', 'party': 'D', 'icon': Icons.domain},
      {'name': 'Kevin McCarthy', 'office': 'Rep CA-20', 'party': 'R', 'icon': Icons.domain},
      {'name': 'Marjorie Taylor Greene', 'office': 'Rep GA-14', 'party': 'R', 'icon': Icons.domain},
      {'name': 'Matt Gaetz', 'office': 'Rep FL-1', 'party': 'R', 'icon': Icons.domain},
      {'name': 'Ilhan Omar', 'office': 'Rep MN-5', 'party': 'D', 'icon': Icons.domain},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2, // Increased height for content
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: candidates.length,
      itemBuilder: (context, index) {
        final candidate = candidates[index];
        return _buildCandidateCard(
          context,
          candidate['name'] as String,
          candidate['office'] as String,
          candidate['party'] as String,
          candidate['icon'] as IconData,
        );
      },
    );
  }

  Widget _buildCandidateCard(BuildContext context, String name, String office, String party, IconData icon) {
    final partyColor = party == 'D' ? Colors.blue : party == 'R' ? Colors.red : Colors.green;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _searchCandidateByName(name),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6.0), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Use minimum space needed
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: partyColor), // Smaller icon
                  const SizedBox(width: 4), // Reduced spacing
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith( // Smaller text
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Smaller padding
                    decoration: BoxDecoration(
                      color: partyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      party,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: partyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9, // Smaller font
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2), // Reduced spacing
              Flexible( // Allow text to shrink if needed
                child: Text(
                  office,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10, // Smaller font
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Finance'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Campaign Finance Tracker',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search for any federal candidate to view their campaign finance data from the FEC.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Quick search options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Popular Candidates',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Click any candidate to view their campaign finance data:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Popular candidates grid
                      _buildPopularCandidatesGrid(context),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.search, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Search Any Candidate',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search for any federal candidate (President, Senate, House) by name:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Search input
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Enter candidate name (e.g., "Alexandria Ocasio-Cortez", "Ted Cruz")',
                          prefixIcon: const Icon(Icons.person_search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onSubmitted: (_) => _searchCandidate(),
                      ),
                      const SizedBox(height: 12),
                      
                      // Search button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _searchQuery.trim().isNotEmpty ? _searchCandidate : null,
                          icon: const Icon(Icons.search),
                          label: const Text('Search Campaign Finance Data'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Examples section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
                                const SizedBox(width: 6),
                                Text(
                                  'Search Tips',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...[
                              '• Try full names: "Elizabeth Warren", "Marco Rubio"',
                              '• Works for current and recent candidates',
                              '• Includes House, Senate, and Presidential candidates',
                              '• Data from 2020, 2022, and 2024 election cycles',
                            ].map((tip) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1.0),
                              child: Text(
                                tip,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue[700],
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Results section
              Consumer<CampaignFinanceProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingAny) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Searching campaign finance data...'),
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
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search Error',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _clearSearch,
                              child: const Text('Try Another Search'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!provider.hasData) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Data Yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Search for a federal candidate to view their campaign finance information.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Show campaign finance data
                  return const CampaignFinanceSummaryCard();
                },
              ),

              const SizedBox(height: 24),

              // Info section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'About This Data',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Campaign finance data is provided by the Federal Election Commission (FEC) and includes:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      
                      ...[
                        '• Total contributions received',
                        '• Campaign expenditures and spending',
                        '• Individual donor information',
                        '• Committee and PAC contributions',
                        '• Financial summary by election cycle',
                      ].map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )),
                      
                      const SizedBox(height: 12),
                      Text(
                        'Data is updated nightly from FEC electronic filings.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}