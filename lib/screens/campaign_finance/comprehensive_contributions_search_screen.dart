import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/models/campaign_finance_model.dart';

class ComprehensiveContributionsSearchScreen extends StatefulWidget {
  const ComprehensiveContributionsSearchScreen({super.key});

  @override
  State<ComprehensiveContributionsSearchScreen> createState() => _ComprehensiveContributionsSearchScreenState();
}

class _ComprehensiveContributionsSearchScreenState extends State<ComprehensiveContributionsSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _donorController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  String _searchQuery = '';
  String _donorQuery = '';
  String _selectedContributionType = 'All';
  String _selectedTimeFrame = 'All Time';
  double? _minAmount;
  double? _maxAmount;
  
  final List<String> _contributionTypes = ['All', 'Individual', 'PAC', 'Committee', 'Corporate'];
  final List<String> _timeFrames = ['All Time', '2024', '2022', '2020', '2018'];

  @override
  void dispose() {
    _searchController.dispose();
    _donorController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _searchContributions() async {
    if (_searchQuery.trim().isEmpty && _donorQuery.trim().isEmpty) return;

    final provider = Provider.of<CampaignFinanceProvider>(context, listen: false);
    
    // Parse time frame to cycle
    int? cycle;
    if (_selectedTimeFrame != 'All Time') {
      cycle = int.tryParse(_selectedTimeFrame);
    }
    
    // Use the comprehensive search method
    await provider.searchContributions(
      contributorName: _donorQuery.trim().isNotEmpty ? _donorQuery.trim() : null,
      candidateName: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      cycle: cycle,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _donorController.clear();
    _amountController.clear();
    setState(() {
      _searchQuery = '';
      _donorQuery = '';
      _selectedContributionType = 'All';
      _selectedTimeFrame = 'All Time';
      _minAmount = null;
      _maxAmount = null;
    });
    
    final provider = Provider.of<CampaignFinanceProvider>(context, listen: false);
    provider.clearData();
  }

  Widget _buildSearchFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Candidate/Campaign search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Candidate or Campaign',
                hintText: 'e.g., Elizabeth Warren, Biden for President',
                prefixIcon: const Icon(Icons.person_search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Donor search
            TextField(
              controller: _donorController,
              decoration: InputDecoration(
                labelText: 'Donor Name or Organization',
                hintText: 'e.g., Microsoft, John Smith',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _donorQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Dropdowns row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedContributionType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _contributionTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedContributionType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimeFrame,
                    decoration: InputDecoration(
                      labelText: 'Time Frame',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _timeFrames.map((timeFrame) {
                      return DropdownMenuItem(
                        value: timeFrame,
                        child: Text(timeFrame),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeFrame = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Amount range
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Amount (\$)',
                      hintText: '0',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _minAmount = double.tryParse(value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Amount (\$)',
                      hintText: 'No limit',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _maxAmount = double.tryParse(value);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search and Clear buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_searchQuery.trim().isNotEmpty || _donorQuery.trim().isNotEmpty) 
                        ? _searchContributions 
                        : null,
                    icon: const Icon(Icons.search),
                    label: const Text('Search Contributions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionCard(CampaignContribution contribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.attach_money,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          contribution.contributorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contribution.contributorCity != null && contribution.contributorState != null)
              Text(
                '${contribution.contributorCity}, ${contribution.contributorState}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${contribution.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            // Show recipient candidate
            Builder(
              builder: (context) {
                String candidateName;
                Color badgeColor;
                Color textColor;
                
                // Use resolved candidate name if available, fallback to extraction
                if (contribution.candidateName != null && contribution.candidateName!.isNotEmpty) {
                  candidateName = contribution.candidateName!;
                  badgeColor = Colors.green.withOpacity(0.1);
                  textColor = Colors.green[700]!;
                } else {
                  // Fallback to committee name extraction
                  candidateName = _extractCandidateFromCommittee(
                    contribution.committeeName, 
                    contribution.candidateName
                  );
                  
                  if (candidateName.contains('via') || candidateName.contains('Various')) {
                    badgeColor = Colors.purple.withOpacity(0.1);
                    textColor = Colors.purple[700]!;
                  } else {
                    badgeColor = Colors.blue.withOpacity(0.1);
                    textColor = Colors.blue[700]!;
                  }
                }
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '→ $candidateName',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ],
        ),
        onTap: () {
          _showContributionDetails(contribution);
        },
      ),
    );
  }

  void _showContributionDetails(CampaignContribution contribution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contribution Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Contributor', contribution.contributorName),
              _buildDetailRow('Amount', '\$${contribution.amount.toStringAsFixed(2)}'),
              
              // Recipient Information Section
              if ((contribution.candidateName != null && contribution.candidateName!.isNotEmpty) || 
                  (contribution.committeeName != null && contribution.committeeName!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(thickness: 1),
                ),
              if ((contribution.candidateName != null && contribution.candidateName!.isNotEmpty) || 
                  (contribution.committeeName != null && contribution.committeeName!.isNotEmpty))
                Text(
                  'MONEY SENT TO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              Builder(
                builder: (context) {
                  final extractedCandidate = _extractCandidateFromCommittee(
                    contribution.committeeName, 
                    contribution.candidateName
                  );
                  final isDirect = contribution.candidateName != null && contribution.candidateName!.isNotEmpty;
                  
                  return Column(
                    children: [
                      _buildDetailRow('🎯 Candidate', extractedCandidate),
                      if (contribution.committeeName != null && contribution.committeeName!.isNotEmpty)
                        _buildDetailRow('🏛️ Via Committee', contribution.committeeName!),
                      if (!isDirect && contribution.committeeName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '* Candidate name extracted from committee',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              
              // Show explanation for committee donations
              if ((contribution.candidateName == null || contribution.candidateName!.isEmpty) && 
                  (contribution.committeeName != null && contribution.committeeName!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ℹ️ This donation went to a committee/PAC. The committee may then distribute funds to specific candidates.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              
              // Contributor Details Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(thickness: 1),
              ),
              Text(
                'CONTRIBUTOR DETAILS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (contribution.contributorCity != null && contribution.contributorCity!.isNotEmpty)
                _buildDetailRow('City', contribution.contributorCity!),
              if (contribution.contributorState != null && contribution.contributorState!.isNotEmpty)
                _buildDetailRow('State', contribution.contributorState!),
              if (contribution.contributorZip != null && contribution.contributorZip!.isNotEmpty)
                _buildDetailRow('ZIP Code', contribution.contributorZip!),
              
              // Transaction Details Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(thickness: 1),
              ),
              Text(
                'TRANSACTION DETAILS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (contribution.receiptType != null && contribution.receiptType!.isNotEmpty)
                _buildDetailRow('Receipt Type', contribution.receiptType!),
              if (contribution.imageNumber != null && contribution.imageNumber!.isNotEmpty)
                _buildDetailRow('Image Number', contribution.imageNumber!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleSearchChip(String searchTerm) {
    return ActionChip(
      label: Text(searchTerm),
      onPressed: () {
        setState(() {
          _donorQuery = searchTerm;
          _donorController.text = searchTerm;
        });
        _searchContributions();
      },
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 12,
      ),
    );
  }

  String _extractCandidateFromCommittee(String? committeeName, String? candidateName) {
    // If we have a direct candidate name, use it
    if (candidateName != null && candidateName.isNotEmpty) {
      return candidateName;
    }
    
    // If no committee name, return unknown
    if (committeeName == null || committeeName.isEmpty) {
      return 'Unknown Candidate';
    }
    
    String committee = committeeName.toUpperCase();
    
    // Handle well-known PACs and party committees first
    if (committee.contains('ACTBLUE')) return 'Various Democrats (via ActBlue)';
    if (committee.contains('WINRED')) return 'Various Republicans (via WinRed)';
    if (committee.contains('DEMOCRATIC CONGRESSIONAL CAMPAIGN')) return 'Democratic House Candidates';
    if (committee.contains('DEMOCRATIC SENATORIAL CAMPAIGN')) return 'Democratic Senate Candidates';
    if (committee.contains('NATIONAL REPUBLICAN CONGRESSIONAL')) return 'Republican House Candidates';
    if (committee.contains('NATIONAL REPUBLICAN SENATORIAL')) return 'Republican Senate Candidates';
    if (committee.contains('DEMOCRATIC NATIONAL COMMITTEE')) return 'Democratic Party';
    if (committee.contains('REPUBLICAN NATIONAL COMMITTEE')) return 'Republican Party';
    
    // Try to extract candidate name using improved logic
    String original = committeeName;
    
    // Remove common prefixes and suffixes
    String cleaned = original
        .replaceAll(RegExp(r'\b(COMMITTEE|PAC|INC|LLC|FUND|ACTION|POLITICAL|CAMPAIGN)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(FOR|TO|RE-?ELECT|ELECT|FRIENDS|OF|THE|A|AN)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(PRESIDENT|CONGRESS|SENATE|HOUSE|REPRESENTATIVE|GOVERNOR|MAYOR)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d{4}\b'), '') // Remove years
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Replace punctuation with spaces
        .replaceAll(RegExp(r'\s+'), ' ') // Collapse multiple spaces
        .trim();
    
    // If cleaned string is empty or too short, try a different approach
    if (cleaned.isEmpty || cleaned.length < 3) {
      // Look for patterns like "LastName for Office" or "FirstName LastName"
      final forMatch = RegExp(r'^([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+for\s+', caseSensitive: false).firstMatch(original);
      if (forMatch != null) {
        cleaned = forMatch.group(1)!;
      } else {
        // Look for "Friends of [Name]" pattern
        final friendsMatch = RegExp(r'friends\s+of\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)', caseSensitive: false).firstMatch(original);
        if (friendsMatch != null) {
          cleaned = friendsMatch.group(1)!;
        } else {
          // Use first few words that look like names
          final words = original.split(RegExp(r'\s+'));
          final nameWords = <String>[];
          for (final word in words) {
            if (word.length > 1 && RegExp(r'^[A-Z][a-z]+$').hasMatch(word) && 
                !['For', 'To', 'The', 'Of', 'And', 'Committee', 'Fund', 'Action', 'Political', 'Campaign'].contains(word)) {
              nameWords.add(word);
              if (nameWords.length >= 2) break; // Limit to first and last name
            }
          }
          if (nameWords.isNotEmpty) {
            cleaned = nameWords.join(' ');
          }
        }
      }
    }
    
    // Final cleanup and validation
    cleaned = cleaned.trim();
    
    // Check if this looks like a person's name
    if (cleaned.isNotEmpty && cleaned.length >= 3 && cleaned.length <= 50) {
      final words = cleaned.split(' ');
      
      // Should have 1-3 words, each starting with capital letter
      if (words.length <= 3 && words.every((word) => word.isNotEmpty && RegExp(r'^[A-Z]').hasMatch(word))) {
        // Avoid common non-name words
        final nonNames = ['FUND', 'ACTION', 'VICTORY', 'AMERICA', 'UNITED', 'FREEDOM', 'LIBERTY', 'CITIZENS', 'PEOPLE', 'VOTERS'];
        if (!words.any((word) => nonNames.contains(word.toUpperCase()))) {
          return _formatCandidateName(cleaned);
        }
      }
    }
    
    // If we can't extract a good candidate name, return the committee name
    return committeeName;
  }
  
  String _formatCandidateName(String name) {
    // Ensure proper capitalization
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Contributions Search'),
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
                'Comprehensive Contributions Search',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search and explore campaign contributions and donations across all campaigns and donors.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Search filters
              _buildSearchFilters(),
              const SizedBox(height: 16),

              // Sample searches
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Try These Sample Searches:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildSampleSearchChip('Microsoft'),
                          _buildSampleSearchChip('Apple Inc'),
                          _buildSampleSearchChip('Google'),
                          _buildSampleSearchChip('John Smith'),
                          _buildSampleSearchChip('Mary Johnson'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                                _donorQuery.isNotEmpty 
                                    ? 'Searching contributions by "$_donorQuery"...'
                                    : _searchQuery.isNotEmpty
                                        ? 'Searching contributions for "$_searchQuery"...'
                                        : 'Searching contributions...',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This may take a few moments as we search through FEC data.',
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
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search Results',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tips: Try a more complete name like "Steve Smith" or "Steven" instead of just "Steve".',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
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

                  // Show contributions if available
                  final contributions = provider.contributions;
                  if (contributions.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Found ${contributions.length} contributions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...contributions.map((contribution) => _buildContributionCard(contribution)),
                      ],
                    );
                  }

                  if (!provider.hasData) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ready to Search',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use the filters above to search for campaign contributions and donations.',
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

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Contributions Found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search criteria or filters.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}