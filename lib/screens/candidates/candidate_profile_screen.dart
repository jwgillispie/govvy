import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/models/campaign_finance_model.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';

class CandidateProfileScreen extends StatefulWidget {
  final String candidateName;
  final String? candidateId;
  final String? office;
  final String? party;
  final String? state;
  final String? district;
  final int? cycle;

  const CandidateProfileScreen({
    Key? key,
    required this.candidateName,
    this.candidateId,
    this.office,
    this.party,
    this.state,
    this.district,
    this.cycle,
  }) : super(key: key);

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loadingFinanceData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCandidateFinanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCandidateFinanceData() async {
    if (widget.candidateName.isEmpty) return;

    setState(() {
      _loadingFinanceData = true;
    });

    try {
      final provider = Provider.of<CampaignFinanceProvider>(context, listen: false);
      
      // Search for contributions and expenditures for this candidate
      await provider.searchContributions(
        candidateName: widget.candidateName,
        cycle: widget.cycle,
      );
    } catch (e) {
      // Handle error silently for now
    } finally {
      if (mounted) {
        setState(() {
          _loadingFinanceData = false;
        });
      }
    }
  }

  Color _getPartyColor(String? party) {
    if (party == null) return Colors.grey;
    
    switch (party.toUpperCase()) {
      case 'DEM':
      case 'DEMOCRATIC':
        return Colors.blue;
      case 'REP':
      case 'REPUBLICAN':
        return Colors.red;
      case 'IND':
      case 'INDEPENDENT':
        return Colors.purple;
      case 'GRN':
      case 'GREEN':
        return Colors.green;
      case 'LIB':
      case 'LIBERTARIAN':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatPartyName(String? party) {
    if (party == null) return 'Unknown';
    
    switch (party.toUpperCase()) {
      case 'DEM':
        return 'Democratic';
      case 'REP':
        return 'Republican';
      case 'IND':
        return 'Independent';
      case 'GRN':
        return 'Green';
      case 'LIB':
        return 'Libertarian';
      default:
        return party;
    }
  }

  Widget _buildProfileHeader() {
    final partyColor = _getPartyColor(widget.party);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            partyColor,
            partyColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.candidateName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.candidateName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (widget.office != null)
                          Text(
                            widget.office!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        if (widget.party != null)
                          Text(
                            _formatPartyName(widget.party),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.state != null) ...[
                    _buildInfoChip(
                      Icons.location_on,
                      widget.district != null ? '${widget.state} ${widget.district}' : widget.state!,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.cycle != null) ...[
                    _buildInfoChip(
                      Icons.calendar_today,
                      widget.cycle.toString(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Candidate Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildDetailRow('Name', widget.candidateName),
                  if (widget.office != null)
                    _buildDetailRow('Office', widget.office!),
                  if (widget.party != null)
                    _buildDetailRow('Party', _formatPartyName(widget.party)),
                  if (widget.state != null)
                    _buildDetailRow('State', widget.state!),
                  if (widget.district != null)
                    _buildDetailRow('District', widget.district!),
                  if (widget.cycle != null)
                    _buildDetailRow('Election Cycle', widget.cycle.toString()),
                  if (widget.candidateId != null)
                    _buildDetailRow('Candidate ID', widget.candidateId!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _searchForRepresentative(),
                      icon: const Icon(Icons.person_search),
                      label: const Text('Find as Current Representative'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _refreshFinanceData(),
                      icon: _loadingFinanceData
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Refresh Finance Data'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceTab() {
    return Consumer<CampaignFinanceProvider>(
      builder: (context, provider, child) {
        if (_loadingFinanceData || provider.isLoadingAny) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final contributions = provider.contributions;
        final expenditures = provider.expenditures;

        if (contributions.isEmpty && expenditures.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Finance Data Available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'No campaign finance records found for this candidate.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshFinanceData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contributions.isNotEmpty) ...[
                Text(
                  'Campaign Contributions (${contributions.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...contributions.take(10).map((contribution) => _buildContributionCard(contribution)),
                if (contributions.length > 10)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Showing first 10 of ${contributions.length} contributions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              if (contributions.isNotEmpty && expenditures.isNotEmpty)
                const SizedBox(height: 24),
              if (expenditures.isNotEmpty) ...[
                Text(
                  'Campaign Expenditures (${expenditures.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...expenditures.take(5).map((expenditure) => _buildExpenditureCard(expenditure)),
                if (expenditures.length > 5)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Showing first 5 of ${expenditures.length} expenditures',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildContributionCard(CampaignContribution contribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: const Icon(
            Icons.arrow_downward,
            color: Colors.green,
            size: 18,
          ),
        ),
        title: Text(
          contribution.contributorName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${contribution.contributorCity ?? ''} ${contribution.contributorState ?? ''}'.trim(),
        ),
        trailing: Text(
          '\$${contribution.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenditureCard(CampaignExpenditure expenditure) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: const Icon(
            Icons.arrow_upward,
            color: Colors.red,
            size: 18,
          ),
        ),
        title: Text(
          expenditure.recipientName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(expenditure.purpose ?? 'No purpose specified'),
        trailing: Text(
          '\$${expenditure.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Contact Information Not Available',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This candidate profile is based on campaign finance records. For current contact information, try searching for them as a representative if they hold office.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _searchForRepresentative,
                          icon: const Icon(Icons.person_search),
                          label: const Text('Search as Representative'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _searchForRepresentative() {
    // Extract candidate name for representative search
    final nameParts = widget.candidateName.trim().split(RegExp(r'\s+'));
    
    if (nameParts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to search: insufficient name information'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Close this screen and navigate to representative search
    Navigator.of(context).pop();
    
    // Use the existing navigation logic from the donor search
    _navigateToRepresentativeSearch(widget.candidateName);
  }

  void _navigateToRepresentativeSearch(String candidateName) {
    // This mirrors the logic from the comprehensive contributions search screen
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Searching for $candidateName...'),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    // Navigate to find representatives screen  
    Navigator.pushNamed(context, '/find-representatives');
  }

  void _refreshFinanceData() {
    _loadCandidateFinanceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildProfileHeader(),
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Finance'),
                Tab(text: 'Contact'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildFinanceTab(),
                _buildContactTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}