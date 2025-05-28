import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/unified_finance_provider.dart';
import 'package:govvy/models/unified_candidate_model.dart';

class UnifiedCandidateSearchWidget extends StatefulWidget {
  final Function(UnifiedCandidate) onCandidateSelected;
  final String? stateFilter;

  const UnifiedCandidateSearchWidget({
    super.key,
    required this.onCandidateSelected,
    this.stateFilter,
  });

  @override
  State<UnifiedCandidateSearchWidget> createState() => _UnifiedCandidateSearchWidgetState();
}

class _UnifiedCandidateSearchWidgetState extends State<UnifiedCandidateSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedOfficeLevel = 'All Levels';
  
  final List<String> _officeLevels = [
    'All Levels',
    'Federal',
    'State', 
    'Local',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final provider = Provider.of<UnifiedFinanceProvider>(context, listen: false);
    
    // Determine which levels to search
    List<OfficeLevel> levels;
    switch (_selectedOfficeLevel) {
      case 'Federal':
        levels = [OfficeLevel.federal];
        break;
      case 'State':
        levels = [OfficeLevel.state];
        break;
      case 'Local':
        levels = [OfficeLevel.local];
        break;
      default:
        levels = [OfficeLevel.federal, OfficeLevel.state, OfficeLevel.local];
    }

    provider.searchCandidates(
      name: query,
      state: widget.stateFilter,
      levels: levels,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    final provider = Provider.of<UnifiedFinanceProvider>(context, listen: false);
    provider.clearData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedFinanceProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.search, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Search All Candidates',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Search federal, state, and local candidates',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Search controls
                Row(
                  children: [
                    // Search field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Enter candidate name...',
                          prefixIcon: const Icon(Icons.person_search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) => setState(() {}),
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Office level filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedOfficeLevel,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Level',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: _officeLevels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(
                              level,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedOfficeLevel = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Search button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _searchController.text.trim().isNotEmpty ? _performSearch : null,
                    icon: provider.isSearching 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(provider.isSearching ? 'Searching...' : 'Search All Sources'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Results section
                if (provider.isSearching) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (provider.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: TextStyle(color: Colors.red[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (provider.hasResults) ...[
                  const SizedBox(height: 16),
                  _buildResultsSection(provider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsSection(UnifiedFinanceProvider provider) {
    final groupedResults = provider.getResultsGroupedByLevel();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Results (${provider.searchResults.length} found)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Show results grouped by level
        ...OfficeLevel.values.map((level) {
          final results = groupedResults[level] ?? [];
          if (results.isEmpty) return const SizedBox.shrink();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getLevelColor(level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getLevelColor(level).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getLevelIcon(level),
                      color: _getLevelColor(level),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${level.displayName} (${results.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _getLevelColor(level),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Candidates for this level
              ...results.take(5).map((result) => _buildCandidateItem(result)),
              
              if (results.length > 5) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '+${results.length - 5} more ${level.displayName.toLowerCase()} candidates',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCandidateItem(CandidateSearchResult result) {
    final candidate = result.candidate;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _getLevelColor(candidate.level).withOpacity(0.1),
          child: Text(
            candidate.primarySource.code,
            style: TextStyle(
              color: _getLevelColor(candidate.level),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        title: Text(
          candidate.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              candidate.officeWithLevel,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '${candidate.state}${candidate.district != null ? " • District ${candidate.district}" : ""} • ${candidate.cycle}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (candidate.hasMultipleSources) ...[
              Tooltip(
                message: candidate.sourceTooltip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    candidate.dataSourceLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
        onTap: () {
          widget.onCandidateSelected(candidate);
        },
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