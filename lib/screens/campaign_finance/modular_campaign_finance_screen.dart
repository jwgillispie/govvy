import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
import 'package:govvy/widgets/campaign_finance/candidate_basic_info_widget.dart';
import 'package:govvy/widgets/campaign_finance/finance_summary_widget.dart';
import 'package:govvy/widgets/campaign_finance/contributions_widget.dart';
import 'package:govvy/widgets/campaign_finance/top_contributors_widget.dart';
import 'package:govvy/widgets/campaign_finance/congress_members_search_widget.dart';
import 'package:govvy/services/congress_members_service.dart';

class ModularCampaignFinanceScreen extends StatefulWidget {
  const ModularCampaignFinanceScreen({super.key});

  @override
  State<ModularCampaignFinanceScreen> createState() => _ModularCampaignFinanceScreenState();
}

class _ModularCampaignFinanceScreenState extends State<ModularCampaignFinanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CongressMembersService _congressService = CongressMembersService();
  
  String _searchQuery = '';
  String _selectedState = 'All States';
  String _selectedMember = 'Select Member';
  
  List<CongressMember> _stateMembers = [];
  bool _loadingMembers = false;
  List<String> _availableStates = ['All States'];
  bool _loadingStates = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableStates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStates() async {
    setState(() {
      _loadingStates = true;
    });

    try {
      final states = await _congressService.getAvailableStates();
      setState(() {
        _availableStates = ['All States', ...states];
        _loadingStates = false;
      });
    } catch (e) {
      print('Error loading available states: $e');
      setState(() {
        _loadingStates = false;
      });
    }
  }

  Future<void> _loadMembersByState(String state) async {
    if (state == 'All States') {
      setState(() {
        _stateMembers = [];
        _selectedMember = 'Select Member';
        _loadingMembers = false;
      });
      return;
    }

    setState(() {
      _loadingMembers = true;
      _selectedMember = 'Loading...';
      _stateMembers = []; // Clear existing members while loading
    });

    try {
      final members = await _congressService.getMembersByState(state);
      print('Loaded ${members.length} members for state: $state');
      if (mounted) { // Check if widget is still mounted
        setState(() {
          _stateMembers = members;
          _selectedMember = _stateMembers.isEmpty ? 'No Members Found' : 'Select Member';
          _loadingMembers = false;
        });
        print('Updated UI with ${_stateMembers.length} members, selectedMember: $_selectedMember');
      }
    } catch (e) {
      if (mounted) { // Check if widget is still mounted
        setState(() {
          _stateMembers = [];
          _selectedMember = 'Error Loading: ${e.toString()}';
          _loadingMembers = false;
        });
      }
      print('Error loading members for state $state: $e');
    }
  }

  List<DropdownMenuItem<String>> _buildMemberDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    final Set<String> addedValues = <String>{}; // Track added values to prevent duplicates
    
    // Always add the placeholder item if it's not a member name
    final isPlaceholder = _selectedMember.startsWith('Select') || 
                         _selectedMember.startsWith('Loading') ||
                         _selectedMember.startsWith('No') ||
                         _selectedMember.startsWith('Error');
    
    if (isPlaceholder) {
      items.add(
        DropdownMenuItem(
          value: _selectedMember,
          enabled: false,
          child: Text(
            _selectedMember,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      addedValues.add(_selectedMember);
    }
    
    // Add all state members, avoiding duplicates
    for (final member in _stateMembers) {
      if (!addedValues.contains(member.name)) {
        items.add(
          DropdownMenuItem(
            value: member.name,
            child: Tooltip(
              message: '${member.name} - ${member.officeTitle} (${member.party})',
              child: Text(
                member.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
        addedValues.add(member.name);
      }
    }
    
    // If we have no items, add a fallback
    if (items.isEmpty) {
      final fallbackValue = 'Select Member';
      items.add(
        DropdownMenuItem(
          value: fallbackValue,
          enabled: false,
          child: Text(
            fallbackValue,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
      // Update _selectedMember if it's not already set to this fallback
      if (_selectedMember != fallbackValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedMember = fallbackValue;
            });
          }
        });
      }
    }
    
    // Safety check: ensure _selectedMember exists in the items list
    final hasSelectedMember = items.any((item) => item.value == _selectedMember);
    if (!hasSelectedMember && items.isNotEmpty) {
      // If current selected member is not in the list, schedule an update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedMember = items.first.value!;
          });
        }
      });
    }
    
    return items;
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
      _selectedState = 'All States';
      _selectedMember = 'Select Member';
      _stateMembers = [];
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
                      // Three-column search interface - responsive layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 600;
                          
                          if (isWide) {
                            // Wide layout: all in one row
                            return Row(
                              children: [
                                // Name search field
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search by name...',
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
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    onSubmitted: (_) => _searchCandidate(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // State dropdown
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedState,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'State',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    items: _availableStates.map((state) {
                                      return DropdownMenuItem(
                                        value: state,
                                        child: Text(
                                          state == 'All States' ? 'All' : state,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      print('State dropdown changed to: $value');
                                      setState(() {
                                        _selectedState = value!;
                                      });
                                      _loadMembersByState(value!);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // Congress members dropdown
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey('${_selectedState}_${_stateMembers.length}_$_loadingMembers'),
                                    value: _selectedMember,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Member',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    items: _buildMemberDropdownItems(),
                                    onChanged: _loadingMembers ? null : (value) {
                                      if (value != null && value != _selectedMember) {
                                        final isActualMember = _stateMembers.any((m) => m.name == value);
                                        if (isActualMember) {
                                          setState(() {
                                            _selectedMember = value;
                                          });
                                          _searchCandidateByName(value);
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Narrow layout: stack vertically
                            return Column(
                              children: [
                                // Name search field
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search by name...',
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
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  onSubmitted: (_) => _searchCandidate(),
                                ),
                                const SizedBox(height: 12),
                                
                                // State and member dropdowns row
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedState,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'State',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        ),
                                        items: _availableStates.map((state) {
                                          return DropdownMenuItem(
                                            value: state,
                                            child: Text(
                                              state == 'All States' ? 'All States' : state,
                                              style: const TextStyle(fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          print('State dropdown (narrow) changed to: $value');
                                          setState(() {
                                            _selectedState = value!;
                                          });
                                          _loadMembersByState(value!);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        key: ValueKey('${_selectedState}_${_stateMembers.length}_$_loadingMembers'),
                                        value: _selectedMember,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'Congress Member',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        ),
                                        items: _buildMemberDropdownItems(),
                                        onChanged: _loadingMembers ? null : (value) {
                                          if (value != null && value != _selectedMember) {
                                            final isActualMember = _stateMembers.any((m) => m.name == value);
                                            if (isActualMember) {
                                              setState(() {
                                                _selectedMember = value;
                                              });
                                              _searchCandidateByName(value);
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                        },
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
              const SizedBox(height: 24),

              // Congress Members Search Widget
              CongressMembersSearchWidget(
                stateFilter: _selectedState == 'All States' ? null : _selectedState,
                onMemberSelected: (memberName) {
                  _searchCandidateByName(memberName);
                },
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