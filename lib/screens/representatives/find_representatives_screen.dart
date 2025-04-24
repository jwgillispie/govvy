// lib/screens/representatives/find_representatives_screen.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/widgets/address/city_search_input.dart';
import 'package:govvy/widgets/representatives/name_search_input.dart';
import 'package:govvy/widgets/representatives/representative_card.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/utils/district_type_formatter.dart';

class FindRepresentativesScreen extends StatefulWidget {
  const FindRepresentativesScreen({Key? key}) : super(key: key);

  @override
  State<FindRepresentativesScreen> createState() =>
      _FindRepresentativesScreenState();
}

class _FindRepresentativesScreenState extends State<FindRepresentativesScreen>
    with SingleTickerProviderStateMixin {
  String? _userState;
  String? _userCity;
  bool _initialLoadComplete = false;
  String? _validationError;
  bool _isSearching = false;
  int _searchTypeIndex = 0; // 0 = State, 1 = City, 2 = Name
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  // US States mapping for dropdown
  final List<Map<String, String>> _usStates = [
    {"name": "Alabama", "code": "AL"},
    {"name": "Alaska", "code": "AK"},
    {"name": "Arizona", "code": "AZ"},
    {"name": "Arkansas", "code": "AR"},
    {"name": "California", "code": "CA"},
    {"name": "Colorado", "code": "CO"},
    {"name": "Connecticut", "code": "CT"},
    {"name": "Delaware", "code": "DE"},
    {"name": "Florida", "code": "FL"},
    {"name": "Georgia", "code": "GA"},
    {"name": "Hawaii", "code": "HI"},
    {"name": "Idaho", "code": "ID"},
    {"name": "Illinois", "code": "IL"},
    {"name": "Indiana", "code": "IN"},
    {"name": "Iowa", "code": "IA"},
    {"name": "Kansas", "code": "KS"},
    {"name": "Kentucky", "code": "KY"},
    {"name": "Louisiana", "code": "LA"},
    {"name": "Maine", "code": "ME"},
    {"name": "Maryland", "code": "MD"},
    {"name": "Massachusetts", "code": "MA"},
    {"name": "Michigan", "code": "MI"},
    {"name": "Minnesota", "code": "MN"},
    {"name": "Mississippi", "code": "MS"},
    {"name": "Missouri", "code": "MO"},
    {"name": "Montana", "code": "MT"},
    {"name": "Nebraska", "code": "NE"},
    {"name": "Nevada", "code": "NV"},
    {"name": "New Hampshire", "code": "NH"},
    {"name": "New Jersey", "code": "NJ"},
    {"name": "New Mexico", "code": "NM"},
    {"name": "New York", "code": "NY"},
    {"name": "North Carolina", "code": "NC"},
    {"name": "North Dakota", "code": "ND"},
    {"name": "Ohio", "code": "OH"},
    {"name": "Oklahoma", "code": "OK"},
    {"name": "Oregon", "code": "OR"},
    {"name": "Pennsylvania", "code": "PA"},
    {"name": "Rhode Island", "code": "RI"},
    {"name": "South Carolina", "code": "SC"},
    {"name": "South Dakota", "code": "SD"},
    {"name": "Tennessee", "code": "TN"},
    {"name": "Texas", "code": "TX"},
    {"name": "Utah", "code": "UT"},
    {"name": "Vermont", "code": "VT"},
    {"name": "Virginia", "code": "VA"},
    {"name": "Washington", "code": "WA"},
    {"name": "West Virginia", "code": "WV"},
    {"name": "Wisconsin", "code": "WI"},
    {"name": "Wyoming", "code": "WY"},
    {"name": "District of Columbia", "code": "DC"}
  ];

  String? _selectedState;
  String? _districtNumber;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchStateAndLoadCache();
    
    // Listen to tab changes to scroll to the top of the list
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _scrollToTop();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeOut,
      );
    }
  }

  // Fetch state from profile and load from cache
  Future<void> _fetchStateAndLoadCache() async {
    try {
      setState(() {
        _initialLoadComplete = false;
      });

      // Try to load from provider's cache first
      final provider =
          Provider.of<CombinedRepresentativeProvider>(context, listen: false);
      final cacheLoaded = await provider.loadFromCache();

      if (cacheLoaded) {
        setState(() {
          _userState = provider.lastSearchedState;
          _userCity = provider.lastSearchedCity;
          _selectedState = _userState;
        });

        // If we have city data from the cache, show city search UI
        if (_userCity != null && _userCity!.isNotEmpty) {
          setState(() {
            _searchTypeIndex = 1;
          });
        }
      } else {
        // If no cache, try to get from user profile
        final authService = Provider.of<AuthService>(context, listen: false);
        final userData = await authService.getCurrentUserData();

        if (userData != null && userData.address.isNotEmpty) {
          // Try to extract state from address
          final addressParts = userData.address.split(',');
          if (addressParts.length > 1) {
            final stateZipPart = addressParts[addressParts.length - 1].trim();
            final statePattern = RegExp(r'([A-Za-z]{2})');
            final match = statePattern.firstMatch(stateZipPart);

            if (match != null) {
              final stateCode = match.group(1)!.toUpperCase();

              // Find the full state name
              final stateData = _usStates.firstWhere(
                (state) => state["code"] == stateCode,
                orElse: () => {"name": "", "code": ""},
              );

              setState(() {
                _userState = stateCode;
                _selectedState = stateCode;
              });
            }

            // Try to extract city from address
            if (addressParts.length > 1) {
              _userCity = addressParts[1].trim();
            }
          }
        }
      }

      setState(() {
        _initialLoadComplete = true;
      });
    } catch (e) {
      debugPrint('Error fetching state: $e');
      setState(() {
        _initialLoadComplete = true;
        _validationError =
            'Could not load your saved state. Please select a state manually.';
      });
    }
  }

  // Fetch representatives based on state and optional district
  Future<void> _fetchRepresentativesByState() async {
    if (_selectedState == null || _selectedState!.isEmpty) {
      setState(() {
        _validationError = 'Please select a state';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _validationError = null;
      // Clear any previous error message
      final provider =
          Provider.of<CombinedRepresentativeProvider>(context, listen: false);
      provider.clearErrors();
    });

    try {
      // Clear any previous errors
      final provider =
          Provider.of<CombinedRepresentativeProvider>(context, listen: false);
      provider.clearErrors();

      // Fetch representatives by state and optional district
      await provider.fetchRepresentativesByState(
          _selectedState!, _districtNumber);

      if (provider.errorMessage != null && mounted) {
        setState(() {
          _validationError = provider.errorMessage;
        });
      }

      // Switch to the appropriate tab
      _tabController.animateTo(0); // All tab
      
      // Scroll to the tab bar to show results
      _scrollToTabBar();
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationError = 'Error searching: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Helper method to scroll to the tab bar after search
  void _scrollToTabBar() {
    if (_scrollController.hasClients) {
      // Calculate position to scroll to (just below the search form)
      final formHeight = 300.0; // Approximate height of the search form
      _scrollController.animateTo(
        formHeight,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Fetch local representatives by city name
  Future<void> _fetchLocalRepresentativesByCity(String city) async {
    if (city.isEmpty) {
      setState(() {
        _validationError = 'Please enter a city name';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _validationError = null;
      _userCity = city;
    });

    try {
      // Get the provider and fetch local reps by city
      final provider =
          Provider.of<CombinedRepresentativeProvider>(context, listen: false);
      provider.clearErrors();

      await provider.fetchLocalRepresentativesByCity(city);

      // Navigate to the All tab after search completes
      _tabController.animateTo(0); // All tab

      if (provider.errorMessage != null && mounted) {
        setState(() {
          _validationError = provider.errorMessage;
        });
      }
      
      // Scroll to the tab bar to show results
      _scrollToTabBar();
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationError = 'Error searching: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Fetch representatives by name
  Future<void> _fetchRepresentativesByName(String lastName, String? firstName) async {
    if (lastName.isEmpty) {
      setState(() {
        _validationError = 'Please enter a last name';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _validationError = null;
    });

    try {
      // Get the provider and fetch reps by name
      final provider =
          Provider.of<CombinedRepresentativeProvider>(context, listen: false);
      provider.clearErrors();

      await provider.fetchRepresentativesByName(lastName, firstName: firstName);

      // Navigate to the All tab after search completes
      _tabController.animateTo(0); // Index 0 is the All tab

      if (provider.errorMessage != null && mounted) {
        setState(() {
          _validationError = provider.errorMessage;
        });
      }
      
      // Scroll to the tab bar to show results
      _scrollToTabBar();
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationError = 'Error searching: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CombinedRepresentativeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Representatives'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: !_initialLoadComplete
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search form (always visible)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Search type toggle
                        Row(
                          children: [
                            Expanded(
                              child: SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment<int>(
                                    value: 0,
                                    label: Text('By State'),
                                    icon: Icon(Icons.public),
                                  ),
                                  ButtonSegment<int>(
                                    value: 1,
                                    label: Text('By City'),
                                    icon: Icon(Icons.location_city_outlined),
                                  ),
                                  ButtonSegment<int>(
                                    value: 2,
                                    label: Text('By Name'),
                                    icon: Icon(Icons.person_search),
                                  ),
                                ],
                                selected: {_searchTypeIndex},
                                onSelectionChanged: (Set<int> selection) {
                                  setState(() {
                                    _searchTypeIndex = selection.first;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Show search form based on selected type
                        if (_searchTypeIndex == 0)
                          _buildStateSearchForm()
                        else if (_searchTypeIndex == 1)
                          CitySearchInput(
                            initialCity: _userCity,
                            isLoading: _isSearching,
                            onCitySubmitted: (cityName) {
                              _fetchLocalRepresentativesByCity(cityName);
                            },
                          )
                        else
                          NameSearchInput(
                            isLoading: _isSearching,
                            onNameSubmitted: (lastName, firstName) {
                              _fetchRepresentativesByName(lastName, firstName);
                            },
                          ),
                      ],
                    ),
                  ),

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    isScrollable: true, // Make tabs scrollable to fit all
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Federal/State'),
                      Tab(text: 'Local'),
                      Tab(text: 'Name Results'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),

                  // Error message if any
                  if (_validationError != null || provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _validationError ?? provider.errorMessage ?? '',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ),

                  // Loading indicators
                  if (provider.isLoading)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (provider.isLoadingFederal)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Text('Loading federal...'),
                            ),
                          if (provider.isLoadingLocal)
                            const Text('Loading local...'),
                          const SizedBox(width: 8),
                          const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                    
                  // Tab content
                  SizedBox(
                    height: 600, // Fixed height for the tab content
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // All representatives tab
                        _buildRepresentativesList(
                            provider.allRepresentatives,
                            _searchTypeIndex == 0
                                ? 'Select a state to find your representatives'
                                : _searchTypeIndex == 1
                                    ? 'Enter a city to find your representatives'
                                    : 'Search by name to find representatives'),

                        // Federal/State representatives tab
                        _buildRepresentativesList(provider.federalRepresentatives,
                            'Select a state to find your federal and state representatives'),

                        // Local representatives tab
                        _buildRepresentativesList(
                            provider.localRepresentatives,
                            _searchTypeIndex == 1
                                ? 'Enter a city to find your local representatives'
                                : 'Select a state and enter district for your local representatives'),
                                
                        // Name search results tab
                        _buildRepresentativesList(
                            provider.allRepresentatives,
                            'Search for representatives by name to see results here'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      // Floating action button to scroll back to top
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToTop,
        child: const Icon(Icons.arrow_upward),
        tooltip: 'Back to top',
      ),
    );
  }

  // Build state and district search form
  Widget _buildStateSearchForm() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // State dropdown
          DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: InputDecoration(
              labelText: 'State',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              prefixIcon: const Icon(Icons.public),
            ),
            items: _usStates.map((Map<String, String> state) {
              return DropdownMenuItem<String>(
                value: state["code"],
                child: Text("${state["name"]} (${state["code"]})"),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedState = newValue;
              });
            },
          ),

          const SizedBox(height: 16),

          // District number input (optional)
          TextFormField(
            decoration: InputDecoration(
              labelText: 'District Number (Optional)',
              hintText: 'e.g. 5',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              prefixIcon: const Icon(Icons.grid_3x3),
            ),
            keyboardType: TextInputType.number,
            onChanged: (String value) {
              setState(() {
                _districtNumber = value.isEmpty ? null : value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _fetchRepresentativesByState,
              icon: _isSearching
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _isSearching ? 'Searching...' : 'Find Representatives',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Popular states chips
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._buildPopularStateChips(),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build popular state chips
  List<Widget> _buildPopularStateChips() {
    final List<String> popularStates = ['CA', 'TX', 'NY', 'FL', 'IL'];

    return popularStates
        .map((stateCode) => ActionChip(
              label: Text(stateCode),
              onPressed: _isSearching
                  ? null
                  : () {
                      setState(() {
                        _selectedState = stateCode;
                      });
                      // Ensure we call search with a slight delay to allow state to update
                      Future.microtask(() => _fetchRepresentativesByState());
                    },
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ))
        .toList();
  }

  // Build representatives list
  Widget _buildRepresentativesList(
      List<Representative> representatives, String emptyMessage) {
    if (representatives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchTypeIndex == 0 ? Icons.public : 
                _searchTypeIndex == 1 ? Icons.location_city : 
                Icons.person_search,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Sort representatives by name for consistency
    final sortedReps = List<Representative>.from(representatives)
      ..sort((a, b) => a.name.compareTo(b.name));

    return ListView.builder(
      itemCount: sortedReps.length,
      itemBuilder: (context, index) {
        final rep = sortedReps[index];
        return RepresentativeCard(
          representative: rep,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RepresentativeDetailsScreen(
                  bioGuideId: rep.bioGuideId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}