import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/widgets/campaign_finance/candidate_basic_info_widget.dart';
import 'package:govvy/widgets/campaign_finance/finance_summary_widget.dart';
import 'package:govvy/widgets/campaign_finance/contributions_widget.dart';
import 'package:govvy/widgets/campaign_finance/top_contributors_widget.dart';
import 'package:govvy/widgets/campaign_finance/expenditures_widget.dart';
import 'package:govvy/widgets/campaign_finance/congress_members_search_widget.dart';

class ModularCampaignFinanceScreen extends StatefulWidget {
  const ModularCampaignFinanceScreen({super.key});

  @override
  State<ModularCampaignFinanceScreen> createState() => _ModularCampaignFinanceScreenState();
}

class _ModularCampaignFinanceScreenState extends State<ModularCampaignFinanceScreen> {
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
      ('Donald Trump', 'REP', 'President'),
      ('Joe Biden', 'DEM', 'President'),
      ('Elizabeth Warren', 'DEM', 'Senate'),
      ('Ted Cruz', 'REP', 'Senate'),
      ('Nikki Haley', 'REP', 'President'),
      ('Bernie Sanders', 'DEM', 'Senate'),
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: candidates.length,
      itemBuilder: (context, index) {
        final candidate = candidates[index];
        return _buildCandidateChip(candidate.$1, candidate.$2, candidate.$3);
      },
    );
  }

  Widget _buildCandidateChip(String name, String party, String office) {
    final partyColor = party == 'DEM' ? Colors.blue : Colors.red;
    
    return GestureDetector(
      onTap: () => _searchCandidateByName(name),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
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
                  color: Colors.grey[600],
                  fontSize: 9,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
                'Campaign Finance',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View campaign finance data from the Federal Election Commission.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
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
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search candidate name (e.g., "Nikki Haley", "Elizabeth Warren")',
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

              // Popular candidates
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
                    height: 80,
                    child: _buildPopularCandidatesHorizontalList(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Congress members search
              CongressMembersSearchWidget(
                onMemberSelected: _searchCandidateByName,
              ),
              const SizedBox(height: 24),

              // Results section with modular widgets
              Consumer<CampaignFinanceProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingCandidate && !provider.hasData) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Searching for candidate...',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (provider.error != null && !provider.hasData) {
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

                  // Show candidate data with modular widgets that load independently
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic candidate info (always shown first)
                      CandidateBasicInfoWidget(candidate: provider.currentCandidate!),
                      const SizedBox(height: 16),
                      
                      // Financial summary (loads independently)
                      const FinanceSummaryWidget(),
                      const SizedBox(height: 16),
                      
                      // Recent contributions (loads independently)
                      const ContributionsWidget(),
                      const SizedBox(height: 16),
                      
                      // Top contributors (loads independently)
                      const TopContributorsWidget(),
                      const SizedBox(height: 16),
                      
                      // Expenditures (loads independently)
                      const ExpendituresWidget(),
                    ],
                  );
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
                            'About FEC Data',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Data provided by the Federal Election Commission (FEC). Campaign finance information includes contributions, expenditures, and committee details for federal candidates.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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