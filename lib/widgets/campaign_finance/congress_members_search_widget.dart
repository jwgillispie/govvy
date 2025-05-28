import 'package:flutter/material.dart';
import 'package:govvy/services/congress_members_service.dart';

class CongressMembersSearchWidget extends StatefulWidget {
  final Function(String) onMemberSelected;
  final String? stateFilter;

  const CongressMembersSearchWidget({
    super.key,
    required this.onMemberSelected,
    this.stateFilter,
  });

  @override
  State<CongressMembersSearchWidget> createState() => _CongressMembersSearchWidgetState();
}

class _CongressMembersSearchWidgetState extends State<CongressMembersSearchWidget> {
  final CongressMembersService _congressService = CongressMembersService();
  final TextEditingController _searchController = TextEditingController();
  
  List<CongressMember> _allMembers = [];
  List<CongressMember> _filteredMembers = [];
  bool _isLoading = false;
  bool _isExpanded = false;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final members = await _congressService.getCurrentMembers();
      setState(() {
        _allMembers = members;
        _filteredMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _allMembers.where((member) {
        final matchesQuery = query.isEmpty ||
            member.name.toLowerCase().contains(query) ||
            member.state.toLowerCase().contains(query);
        
        final matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Senate' && member.chamber == 'Senate') ||
            (_selectedFilter == 'House' && member.chamber == 'House');

        // Apply external state filter if provided
        final matchesStateFilter = widget.stateFilter == null ||
            widget.stateFilter == 'All States' ||
            member.state.toLowerCase() == widget.stateFilter!.toLowerCase();

        return matchesQuery && matchesFilter && matchesStateFilter;
      }).toList();
    });
  }

  @override
  void didUpdateWidget(CongressMembersSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-filter when external state filter changes
    if (oldWidget.stateFilter != widget.stateFilter) {
      _filterMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_vote, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Current Congress Members',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            if (!_isExpanded) ...[
              const SizedBox(height: 8),
              Text(
                'Tap to browse ${_allMembers.length} current members of Congress',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],

            if (_isExpanded) ...[
              const SizedBox(height: 16),
              
              // Search and filter controls
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name or state...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (_) => _filterMembers(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: ['All', 'Senate', 'House'].map((filter) {
                      return DropdownMenuItem(
                        value: filter,
                        child: Text(filter),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                      _filterMembers();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (_filteredMembers.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No members found matching your search.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ] else ...[
                // Results summary
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Showing ${_filteredMembers.length} members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Members list (limited height with scrolling)
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      return _buildMemberTile(member);
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(CongressMember member) {
    final partyColor = member.party == 'Democratic' ? Colors.blue : 
                      member.party == 'Republican' ? Colors.red : Colors.grey;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: partyColor.withOpacity(0.1),
        child: Text(
          member.party.isNotEmpty ? member.party[0] : '?',
          style: TextStyle(
            color: partyColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        member.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${member.officeTitle} • ${member.state}${member.district != null ? " District ${member.district}" : ""}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[400],
      ),
      onTap: () {
        widget.onMemberSelected(member.name);
        // Optionally collapse after selection
        setState(() {
          _isExpanded = false;
          _searchController.clear();
          _filteredMembers = _allMembers;
        });
      },
    );
  }
}