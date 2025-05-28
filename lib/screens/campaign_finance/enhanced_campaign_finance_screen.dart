import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/unified_finance_provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/models/unified_candidate_model.dart';
import 'package:govvy/widgets/campaign_finance/unified_candidate_search_widget.dart';
import 'package:govvy/widgets/campaign_finance/unified_finance_summary_widget.dart';
import 'package:govvy/widgets/campaign_finance/congress_members_search_widget.dart';
import 'package:govvy/widgets/campaign_finance/contributions_widget.dart';
import 'package:govvy/widgets/campaign_finance/top_contributors_widget.dart';

class EnhancedCampaignFinanceScreen extends StatefulWidget {
  const EnhancedCampaignFinanceScreen({super.key});

  @override
  State<EnhancedCampaignFinanceScreen> createState() => _EnhancedCampaignFinanceScreenState();
}

class _EnhancedCampaignFinanceScreenState extends State<EnhancedCampaignFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedState = 'All States';

  // US States list for dropdown
  final List<String> _states = [
    'All States',
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
    'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectUnifiedCandidate(UnifiedCandidate candidate) async {
    print('Enhanced Screen: Selected unified candidate: ${candidate.name} (${candidate.primarySource.code})');
    
    if (!mounted) return;
    
    final unifiedProvider = Provider.of<UnifiedFinanceProvider>(context, listen: false);
    await unifiedProvider.loadFinanceData(candidate);
    
    // If it's a federal candidate, also load it in the legacy provider for compatibility
    if (candidate.level == OfficeLevel.federal && candidate.fecData != null && mounted) {
      final legacyProvider = Provider.of<CampaignFinanceProvider>(context, listen: false);
      await legacyProvider.loadCandidateByName(candidate.name);
    }
  }

  Future<void> _selectCongressMember(String memberName) async {
    print('Enhanced Screen: Selected congress member: $memberName');
    
    if (!mounted) return;
    
    // Load in legacy provider
    final legacyProvider = Provider.of<CampaignFinanceProvider>(context, listen: false);
    await legacyProvider.loadCandidateByName(memberName);
    
    if (!mounted) return;
    
    // Also search in unified provider for consistency
    final unifiedProvider = Provider.of<UnifiedFinanceProvider>(context, listen: false);
    await unifiedProvider.searchCandidates(
      name: memberName,
      levels: [OfficeLevel.federal],
    );
    
    // Auto-select if we get exactly one result
    if (mounted && unifiedProvider.searchResults.length == 1) {
      await unifiedProvider.loadFinanceData(unifiedProvider.searchResults.first.candidate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Finance'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.search),
              text: 'Universal Search',
            ),
            Tab(
              icon: Icon(Icons.how_to_vote),
              text: 'Congress Members',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // State filter (applies to both tabs)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Filter by State:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: _states.map((state) {
                      return DropdownMenuItem(
                        value: state,
                        child: Text(
                          state,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Universal Search Tab
                _buildUniversalSearchTab(),
                
                // Congress Members Tab  
                _buildCongressMembersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniversalSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Campaign Finance Search',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search federal, state, and local candidates from multiple data sources.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Universal search widget
          UnifiedCandidateSearchWidget(
            stateFilter: _selectedState == 'All States' ? null : _selectedState,
            onCandidateSelected: _selectUnifiedCandidate,
          ),
          const SizedBox(height: 24),

          // Results section with unified provider
          Consumer<UnifiedFinanceProvider>(
            builder: (context, provider, child) {
              if (provider.hasCurrentCandidate) {
                return Column(
                  children: [
                    // Unified finance summary
                    const UnifiedFinanceSummaryWidget(),
                    const SizedBox(height: 16),
                    
                    // Additional widgets based on data source
                    if (provider.currentCandidate!.level == OfficeLevel.federal) ...[
                      // For federal candidates, show existing detailed widgets
                      const ContributionsWidget(),
                      const SizedBox(height: 16),
                      const TopContributorsWidget(),
                    ] else ...[
                      // For state/local candidates, show what data we have
                      _buildStateLevelDataCards(provider),
                    ],
                  ],
                );
              }
              
              return _buildEmptyState('Universal Search');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCongressMembersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Federal Congress Members',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse current members of Congress and their campaign finance data.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Congress members search widget
          CongressMembersSearchWidget(
            stateFilter: _selectedState == 'All States' ? null : _selectedState,
            onMemberSelected: _selectCongressMember,
          ),
          const SizedBox(height: 24),

          // Results section with legacy provider (for detailed federal data)
          Consumer<CampaignFinanceProvider>(
            builder: (context, provider, child) {
              if (provider.hasData) {
                return Column(
                  children: [
                    // Reuse existing federal widgets
                    const ContributionsWidget(),
                    const SizedBox(height: 16),
                    const TopContributorsWidget(),
                  ],
                );
              }
              
              return _buildEmptyState('Congress Members');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStateLevelDataCards(UnifiedFinanceProvider provider) {
    final financeData = provider.currentFinanceData;
    if (financeData == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Contributor types breakdown
        if (financeData.topContributorTypes.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Contributor Types',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...financeData.topContributorTypes.entries.map((entry) =>
                    _buildDataRow(entry.key, _formatCurrency(entry.value), Colors.blue)
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

      ],
    );
  }

  Widget _buildDataRow(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String tabName) {
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
              'Use the $tabName search above to find candidates and view their campaign finance information.',
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