import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/models/election_model.dart';
import 'package:govvy/models/campaign_finance_model.dart';
import 'package:govvy/providers/election_provider.dart';
import 'package:govvy/services/fec_service.dart';
import 'package:govvy/widgets/elections/election_card.dart';
import 'package:govvy/widgets/elections/election_search_input.dart';

enum ElectionSearchType { location, upcoming, dateRange }

class ElectionScreen extends StatefulWidget {
  const ElectionScreen({Key? key}) : super(key: key);

  @override
  State<ElectionScreen> createState() => _ElectionScreenState();
}

class _ElectionScreenState extends State<ElectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final FECService _fecService = FECService();
  
  ElectionSearchType _searchType = ElectionSearchType.upcoming;
  String? _selectedState;
  String? _selectedCity;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _upcomingOnly = true;
  
  // FEC Calendar state
  List<FECCalendarEvent> _federalEvents = [];
  bool _loadingFederalEvents = false;
  String? _federalEventsError;
  int _selectedYear = DateTime.now().year;
  
  // FEC Candidates state
  List<FECCandidate> _federalCandidates = [];
  bool _loadingFederalCandidates = false;
  String? _federalCandidatesError;
  String? _candidateSearchOffice = 'P'; // P, H, S
  String? _candidateSearchState;
  String? _candidateSearchName;
  int _candidateSearchCycle = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ElectionProvider>(context, listen: false);
      provider.loadAvailableStates();
      // Load enriched elections that include both federal and local data
      provider.loadEnrichedElections(includeFederal: true, includeLocal: true);
      _loadFederalEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elections'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Search'),
            Tab(text: 'My Location'),
            Tab(text: 'Federal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildUpcomingTab(),
          _buildSearchTab(),
          _buildLocationTab(),
          _buildFederalTab(),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return Consumer<ElectionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading upcoming elections',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadEnrichedElections(includeFederal: true, includeLocal: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.elections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.ballot_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No upcoming elections found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later or search for specific elections',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadEnrichedElections(includeFederal: true, includeLocal: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.elections.length,
            itemBuilder: (context, index) {
              final election = provider.elections[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElectionCard(
                  election: election,
                  onTap: () => _showElectionDetails(election),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElectionSearchInput(
            onSearch: _performSearch,
            searchType: _searchType,
            onSearchTypeChanged: (type) {
              setState(() {
                _searchType = type;
              });
            },
            selectedState: _selectedState,
            selectedCity: _selectedCity,
            startDate: _startDate,
            endDate: _endDate,
            upcomingOnly: _upcomingOnly,
            onStateChanged: (state) {
              setState(() {
                _selectedState = state;
                _selectedCity = null;
              });
              if (state != null) {
                Provider.of<ElectionProvider>(context, listen: false)
                    .loadCitiesInState(state);
              }
            },
            onCityChanged: (city) {
              setState(() {
                _selectedCity = city;
              });
            },
            onStartDateChanged: (date) {
              setState(() {
                _startDate = date;
              });
            },
            onEndDateChanged: (date) {
              setState(() {
                _endDate = date;
              });
            },
            onUpcomingOnlyChanged: (value) {
              setState(() {
                _upcomingOnly = value;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Elections by Your Location',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter your address to find elections and polling locations in your area.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          _buildLocationSearch(),
          const SizedBox(height: 24),
          _buildPollingLocations(),
        ],
      ),
    );
  }

  Widget _buildLocationSearch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Enter your address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (address) {
                if (address.isNotEmpty) {
                  _searchByAddress(address);
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Could implement location services here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location services coming soon'),
                    ),
                  );
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Use Current Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ElectionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.error != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error searching elections',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.elections.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.ballot_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No elections found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search criteria',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Results (${provider.elections.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...provider.elections.map((election) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElectionCard(
                election: election,
                onTap: () => _showElectionDetails(election),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildPollingLocations() {
    return Consumer<ElectionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPolling) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (provider.pollingLocations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Polling Locations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...provider.pollingLocations.map((location) => Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(location.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.fullAddress),
                    if (location.hours != null)
                      Text('Hours: ${location.hours}'),
                  ],
                ),
                isThreeLine: location.hours != null,
              ),
            )),
          ],
        );
      },
    );
  }

  void _performSearch() {
    final provider = Provider.of<ElectionProvider>(context, listen: false);

    switch (_searchType) {
      case ElectionSearchType.location:
        if (_selectedState != null) {
          provider.loadEnrichedElections(
            state: _selectedState!,
            city: _selectedCity,
            includeFederal: true,
            includeLocal: true,
          );
        }
        break;
      case ElectionSearchType.upcoming:
        provider.loadEnrichedElections(
          state: _selectedState,
          includeFederal: true,
          includeLocal: true,
        );
        break;
      case ElectionSearchType.dateRange:
        if (_startDate != null && _endDate != null) {
          provider.loadElectionsByDateRange(
            startDate: _startDate!,
            endDate: _endDate!,
            state: _selectedState,
          );
        }
        break;
    }
  }

  void _searchByAddress(String address) {
    final provider = Provider.of<ElectionProvider>(context, listen: false);
    provider.loadPollingLocations(address: address);
    
    final components = _parseAddressComponents(address);
    if (components['state'] != null) {
      provider.loadEnrichedElections(
        state: components['state']!,
        city: components['city'],
        includeFederal: true,
        includeLocal: true,
      );
    }
  }

  Map<String, String?> _parseAddressComponents(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    
    if (parts.length >= 3) {
      final lastPart = parts.last.trim().split(' ');
      String? state;
      
      if (lastPart.length >= 2) {
        state = lastPart[lastPart.length - 2].toUpperCase();
        if (state.length == 2) {
          return {
            'city': parts[parts.length - 2],
            'state': state,
          };
        }
      }
    }
    
    return {'city': null, 'state': null};
  }

  void _showElectionDetails(Election election) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        election.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        election.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Date', election.electionDate.toString().split(' ')[0]),
                      _buildDetailRow('Type', election.electionType),
                      _buildDetailRow('Location', '${election.city}, ${election.state}'),
                      if (election.contests.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Contests',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...election.contests.map((contest) => Card(
                          child: ListTile(
                            title: Text(contest.office),
                            subtitle: Text('${contest.district} - ${contest.level}'),
                            trailing: Text('${contest.candidates.length} candidates'),
                          ),
                        )),
                      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _loadFederalEvents() async {
    setState(() {
      _loadingFederalEvents = true;
      _federalEventsError = null;
    });

    try {
      final events = await _fecService.getElectionCalendar(
        year: _selectedYear,
        categoryIds: [36, 21], // Election dates and reporting deadlines
      );
      
      setState(() {
        _federalEvents = events;
        _loadingFederalEvents = false;
      });
    } catch (e) {
      setState(() {
        _federalEventsError = e.toString();
        _loadingFederalEvents = false;
      });
    }
  }

  Widget _buildFederalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Federal Calendar Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Federal Election Calendar',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Official federal election dates and deadlines from the FEC',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Year selector
                  Row(
                    children: [
                      Text('Year:', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 16),
                      DropdownButton<int>(
                        value: _selectedYear,
                        items: List.generate(5, (index) {
                          final year = DateTime.now().year - 1 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (year) {
                          if (year != null) {
                            setState(() {
                              _selectedYear = year;
                            });
                            _loadFederalEvents();
                          }
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadFederalEvents,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Federal Events
          if (_loadingFederalEvents)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_federalEventsError != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Error loading federal events', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(_federalEventsError!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else if (_federalEvents.isNotEmpty) ...[
            Text('Events (${_federalEvents.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ..._federalEvents.map((event) => _buildFederalEventCard(event)),
          ],
          
          const SizedBox(height: 32),
          
          // Federal Candidates Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_search, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Federal Candidates',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search for federal candidates from FEC database',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Search filters in a more compact layout
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _candidateSearchOffice,
                          isExpanded: true,
                          hint: const Text('Office'),
                          items: const [
                            DropdownMenuItem(value: 'P', child: Text('President')),
                            DropdownMenuItem(value: 'H', child: Text('House')),
                            DropdownMenuItem(value: 'S', child: Text('Senate')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _candidateSearchOffice = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_candidateSearchOffice != 'P') 
                        Expanded(
                          child: Consumer<ElectionProvider>(
                            builder: (context, provider, child) {
                              return DropdownButton<String>(
                                value: _candidateSearchState,
                                isExpanded: true,
                                hint: const Text('State'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All States')),
                                  ...provider.availableStates.map((state) =>
                                    DropdownMenuItem(value: state, child: Text(state)),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _candidateSearchState = value;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadFederalCandidates,
                      icon: const Icon(Icons.search),
                      label: const Text('Search Candidates'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Federal Candidates Results
          if (_loadingFederalCandidates)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_federalCandidatesError != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Error loading candidates', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(_federalCandidatesError!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else if (_federalCandidates.isNotEmpty) ...[
            Text('Candidates (${_federalCandidates.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ..._federalCandidates.map((candidate) => _buildFederalCandidateCard(candidate)),
          ],
        ],
      ),
    );
  }


  Widget _buildFederalEventCard(FECCalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: event.isElectionDate ? Colors.red[100] : Colors.blue[100],
          child: Icon(
            event.isElectionDate ? Icons.how_to_vote : Icons.assignment,
            color: event.isElectionDate ? Colors.red[700] : Colors.blue[700],
          ),
        ),
        title: Text(
          event.summary,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.categoryDisplayName),
            const SizedBox(height: 4),
            Text(
              event.allDay 
                ? _formatDate(event.startDate)
                : _formatDateTime(event.startDate),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(event.description),
                  const SizedBox(height: 16),
                ],
                
                if (event.location != null) ...[
                  _buildDetailRow('Location', event.location!),
                ],
                
                if (event.states != null && event.states!.isNotEmpty) ...[
                  _buildDetailRow('States', event.states!.join(', ')),
                ],
                
                if (event.url != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Launch URL
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('URL: ${event.url}')),
                        );
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View Details'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(date)} at $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  Future<void> _loadFederalCandidates() async {
    setState(() {
      _loadingFederalCandidates = true;
      _federalCandidatesError = null;
    });

    try {
      final candidates = await _fecService.searchCandidates(
        name: _candidateSearchName,
        state: _candidateSearchState,
        office: _candidateSearchOffice,
        cycle: _candidateSearchCycle,
        perPage: 50,
      );
      
      setState(() {
        _federalCandidates = candidates;
        _loadingFederalCandidates = false;
      });
    } catch (e) {
      setState(() {
        _federalCandidatesError = e.toString();
        _loadingFederalCandidates = false;
      });
    }
  }


  Widget _buildFederalCandidateCard(FECCandidate candidate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCandidateColor(candidate.office),
          child: Text(
            candidate.office ?? '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          candidate.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${candidate.party ?? 'Unknown Party'} • ${_getOfficeName(candidate.office)}'),
            if (candidate.state != null && candidate.state != 'US')
              Text('${candidate.state}${candidate.district != null ? '-${candidate.district}' : ''}'),
            Text('Cycle: ${candidate.electionYear ?? 'Unknown'}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (candidate.isIncumbent == true)
              const Icon(Icons.star, color: Colors.amber, size: 20),
            Text(
              candidate.status ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () => _showCandidateDetails(candidate),
      ),
    );
  }

  Color _getCandidateColor(String? office) {
    switch (office) {
      case 'P':
        return Colors.purple;
      case 'S':
        return Colors.blue;
      case 'H':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getOfficeName(String? office) {
    switch (office) {
      case 'P':
        return 'President';
      case 'S':
        return 'Senate';
      case 'H':
        return 'House';
      default:
        return 'Unknown Office';
    }
  }

  void _showCandidateDetails(FECCandidate candidate) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getCandidateColor(candidate.office),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        candidate.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Office', _getOfficeName(candidate.office)),
                      _buildDetailRow('Party', candidate.party ?? 'Unknown'),
                      if (candidate.state != null && candidate.state != 'US')
                        _buildDetailRow('State', candidate.state!),
                      if (candidate.district != null)
                        _buildDetailRow('District', candidate.district!),
                      _buildDetailRow('Election Year', candidate.electionYear?.toString() ?? 'Unknown'),
                      _buildDetailRow('Status', candidate.status ?? 'Unknown'),
                      _buildDetailRow('Incumbent', candidate.isIncumbent == true ? 'Yes' : 'No'),
                      _buildDetailRow('Candidate ID', candidate.candidateId),
                      
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to campaign finance for this candidate
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('View campaign finance for ${candidate.name}')),
                            );
                          },
                          icon: const Icon(Icons.attach_money),
                          label: const Text('View Campaign Finance'),
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