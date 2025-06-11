import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/widgets/campaign_finance/campaign_finance_summary_card.dart';
import 'package:govvy/screens/campaign_finance/comprehensive_contributions_search_screen.dart';

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

  Widget _buildPopularCandidatesHorizontalList(BuildContext context) {
    final candidates = [
      // Presidential
      {'name': 'Joe Biden', 'office': 'President', 'party': 'D'},
      {'name': 'Donald Trump', 'office': 'President', 'party': 'R'},
      {'name': 'Ron DeSantis', 'office': 'Governor', 'party': 'R'},
      {'name': 'Nikki Haley', 'office': 'Presidential', 'party': 'R'},
      
      // Senate Notable
      {'name': 'Chuck Schumer', 'office': 'Senate Leader', 'party': 'D'},
      {'name': 'Mitch McConnell', 'office': 'Senate Leader', 'party': 'R'},
      {'name': 'Elizabeth Warren', 'office': 'Senator MA', 'party': 'D'},
      {'name': 'Ted Cruz', 'office': 'Senator TX', 'party': 'R'},
      {'name': 'Bernie Sanders', 'office': 'Senator VT', 'party': 'I'},
      {'name': 'Marco Rubio', 'office': 'Senator FL', 'party': 'R'},
      
      // House Notable
      {'name': 'Alexandria Ocasio-Cortez', 'office': 'Rep NY-14', 'party': 'D'},
      {'name': 'Nancy Pelosi', 'office': 'Rep CA-11', 'party': 'D'},
      {'name': 'Kevin McCarthy', 'office': 'Rep CA-20', 'party': 'R'},
      {'name': 'Marjorie Taylor Greene', 'office': 'Rep GA-14', 'party': 'R'},
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: candidates.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final candidate = candidates[index];
        return _buildHorizontalCandidateCard(
          context,
          candidate['name'] as String,
          candidate['office'] as String,
          candidate['party'] as String,
        );
      },
    );
  }

  Widget _buildHorizontalCandidateCard(BuildContext context, String name, String office, String party) {
    final partyColor = party == 'D' ? Colors.blue : party == 'R' ? Colors.red : Colors.green;
    
    return SizedBox(
      width: 120,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _searchCandidateByName(name),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: partyColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        party,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: partyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  office,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComprehensiveContributionsSearchScreen(),
                ),
              );
            },
            tooltip: 'Search All Contributions',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Campaign Finance',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View campaign finance data from the Federal Election Commission.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Main search section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search input
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search candidate name (e.g., "Elizabeth Warren", "Ted Cruz")',
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Popular candidates horizontal scroll
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Popular Candidates',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80, // Fixed height for horizontal scroll
                    child: _buildPopularCandidatesHorizontalList(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Results section
              Consumer<CampaignFinanceProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingAny) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                provider.currentCandidate != null
                                    ? 'Loading campaign finance data for ${provider.currentCandidate!.name}...'
                                    : 'Searching campaign finance data...',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This may take a few moments as we fetch data from the FEC.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
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
                              color: Theme.of(context).colorScheme.outline,
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
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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