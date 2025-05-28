import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/models/election_model.dart';
import 'package:govvy/providers/election_provider.dart';
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
  
  ElectionSearchType _searchType = ElectionSearchType.upcoming;
  String? _selectedState;
  String? _selectedCity;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _upcomingOnly = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ElectionProvider>(context, listen: false);
      provider.loadAvailableStates();
      provider.loadUpcomingElections();
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildSearchTab(),
          _buildLocationTab(),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return Consumer<ElectionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingUpcoming) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.upcomingError != null) {
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
                  provider.upcomingError!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadUpcomingElections(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.upcomingElections.isEmpty) {
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
          onRefresh: () => provider.loadUpcomingElections(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.upcomingElections.length,
            itemBuilder: (context, index) {
              final election = provider.upcomingElections[index];
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
          provider.loadElectionsByLocation(
            state: _selectedState!,
            city: _selectedCity,
            upcomingOnly: _upcomingOnly,
          );
        }
        break;
      case ElectionSearchType.upcoming:
        provider.loadUpcomingElections(state: _selectedState);
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
      provider.loadElectionsByLocation(
        state: components['state']!,
        city: components['city'],
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
}