// lib/screens/representatives/find_representatives_screen.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/widgets/address/city_search_input.dart';
import 'package:govvy/widgets/representatives/name_search_input.dart';
import 'package:govvy/widgets/shared/grouped_representative_list.dart';
import 'package:govvy/widgets/shared/government_level_badge.dart';
import 'package:govvy/utils/government_level_helper.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';
import 'package:govvy/services/auth_service.dart';

class FindRepresentativesScreen extends StatefulWidget {
  const FindRepresentativesScreen({Key? key}) : super(key: key);

  @override
  State<FindRepresentativesScreen> createState() =>
      _FindRepresentativesScreenState();
}

class _FindRepresentativesScreenState extends State<FindRepresentativesScreen>
    with SingleTickerProviderStateMixin {
  // Helper method to determine if a representative is truly local
  bool _isLocalRepresentative(Representative rep) {
    // First, check explicit federal roles that should always be excluded
    final String chamberUpper = rep.chamber.toUpperCase();
    final String officeUpper = rep.office?.toUpperCase() ?? '';
    final String nameUpper = rep.name.toUpperCase();

    // These are clearly federal positions
    final List<String> federalChambers = [
      'NATIONAL_UPPER',
      'NATIONAL_LOWER',
      'NATIONAL_EXEC',
      'SENATE',
      'HOUSE',
      'PRESIDENT',
      'CONGRESS',
      'U.S. SENATE',
      'U.S. HOUSE',
      'UNITED STATES SENATE',
      'UNITED STATES HOUSE',
      'REPRESENTATIVE'
    ];

    if (federalChambers.any((chamber) => chamberUpper.contains(chamber))) {
      return false;
    }

    // Explicitly check for federal titles in office
    final List<String> federalTitles = [
      'U.S. SENATOR',
      'UNITED STATES SENATOR',
      'U.S. REPRESENTATIVE',
      'UNITED STATES REPRESENTATIVE',
      'CONGRESSMAN',
      'CONGRESSWOMAN',
      'SENATOR',
      'U.S. CONGRESS',
      'PRESIDENT',
      'VICE PRESIDENT'
    ];

    if (federalTitles.any((title) => officeUpper.contains(title))) {
      return false;
    }

    // Check for specific federal officials by name
    final List<String> federalOfficialNames = [
      'BIDEN',
      'TRUMP',
      'HARRIS',
      'VANCE',
      'RUBIO',
      'MCCONNELL',
      'SCHUMER',
      'PELOSI',
      'JEFFRIES',
      'JOHNSON'
    ];

    if (federalOfficialNames.any((name) => nameUpper.contains(name))) {
      // Check that this is actually the federal official, not someone with the same name
      if (federalTitles.any((title) => officeUpper.contains(title)) ||
          federalChambers.any((chamber) => chamberUpper.contains(chamber))) {
        return false;
      }
    }

    // Now let's check for local indicators

    // Check if this is a cicero-sourced local rep (strongest indicator)
    if (rep.bioGuideId.startsWith('cicero-')) {
      // Double-check it's not a federal official from cicero
      for (final title in federalTitles) {
        if (officeUpper.contains(title)) {
          return false;
        }
      }
      return true;
    }

    // Check for local keywords in chamber/level
    final localLevels = [
      'COUNTY',
      'CITY',
      'PLACE',
      'TOWNSHIP',
      'BOROUGH',
      'TOWN',
      'VILLAGE',
      'LOCAL',
      'LOCAL_EXEC',
      'SCHOOL',
      'MAYOR',
      'COUNCIL',
      'MUNICIPAL',
      'COMMISSIONER'
    ];

    for (final level in localLevels) {
      if (chamberUpper.contains(level)) {
        return true;
      }
    }

    // Check for local keywords in the district
    if (rep.district != null) {
      final String district = rep.district!.toUpperCase();
      final localDistrictKeywords = [
        'COUNTY',
        'CITY',
        'TOWN',
        'VILLAGE',
        'BOROUGH',
        'SCHOOL',
        'MUNICIPAL',
        'WARD',
        'PRECINCT'
      ];

      for (final keyword in localDistrictKeywords) {
        if (district.contains(keyword)) {
          return true;
        }
      }
    }

    // Check for local keywords in the office title
    if (rep.office != null) {
      final localOfficeKeywords = [
        'MAYOR',
        'CITY COUNCIL',
        'COUNTY COMMISSION',
        'ALDERMAN',
        'SHERIFF',
        'CLERK',
        'TREASURER',
        'ASSESSOR',
        'AUDITOR',
        'RECORDER',
        'SCHOOL BOARD'
      ];

      for (final keyword in localOfficeKeywords) {
        if (officeUpper.contains(keyword)) {
          return true;
        }
      }
    }

    // Still exclude clear state-level roles
    if (chamberUpper.startsWith('STATE_') ||
        chamberUpper == 'GOVERNOR' ||
        chamberUpper == 'STATE SENATE' ||
        chamberUpper == 'STATE HOUSE' ||
        chamberUpper == 'STATE ASSEMBLY') {
      return false;
    }

    // For everything else, we should default to false
    return false;
  }

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

  // Fetch representatives based on state
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

      // Fetch representatives by state
      await provider.fetchRepresentativesByState(_selectedState!);

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

      // City may contain state information (e.g., "Gainesville, FL")
      // The enhanced provider method will handle parsing this
      await provider.fetchLocalRepresentativesByCity(city);

      // After search completes, check if we have results
      if (provider.localRepresentatives.isEmpty &&
          provider.federalRepresentatives.isEmpty) {
        setState(() {
          // City might be ambiguous - suggest using state in search
          if (_mightBeAmbiguousCity(city)) {
            _validationError =
                'Multiple cities with this name exist. Try adding a state code (e.g., "$city, FL")';
          } else {
            _validationError = provider.errorMessage ??
                'No representatives found for this city';
          }
        });
      } else {
        // Navigate to the most appropriate tab based on what we found
        if (provider.localRepresentatives.isNotEmpty) {
          _tabController.animateTo(2); // Local tab if we have local reps
        } else if (provider.federalRepresentatives.isNotEmpty) {
          _tabController.animateTo(1); // Federal/State tab if we only have federal reps
        } else {
          _tabController.animateTo(0); // All tab as fallback
        }
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

// Helper to check if a city name might be ambiguous (exists in multiple states)
  bool _mightBeAmbiguousCity(String cityName) {
    // Extract just the city name if it includes a state code
    String city = cityName;
    if (cityName.contains(',')) {
      city = cityName.split(',')[0].trim();
    }
    city = city.toLowerCase();

    // List of known ambiguous city names
    final ambiguousCities = [
      'portland',
      'springfield',
      'franklin',
      'washington',
      'madison',
      'georgetown',
      'salem',
      'oxford',
      'lebanon',
      'bristol',
      'newton',
      'gainesville',
      'greenville',
      'columbus',
      'charleston',
      'fairfield',
      'richmond',
      'riverside',
      'kingston',
      'dover',
      'burlington',
      'lancaster',
      'oakland',
      'manchester',
      'arlington',
      'bloomfield',
      'jackson',
      'columbia',
      'auburn',
      'dayton',
      'lexington',
      'florence',
      'orange',
      'glendale',
      'bristol'
    ];

    return ambiguousCities.contains(city);
  }


  // Fetch representatives by name
  Future<void> _fetchRepresentativesByName(
      String lastName, String? firstName) async {
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
      restorationId: 'find_representatives_screen',
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
                                    // Clear errors when changing search type
                                    _validationError = null;
                                    provider.clearErrors();
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

                  // Tab bar with level indicators
                  TabBar(
                    controller: _tabController,
                    isScrollable: true, // Make tabs scrollable to fit all
                    tabs: [
                      const Tab(text: 'All'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GovernmentLevelDot(
                              level: GovernmentLevel.federal,
                              size: 8,
                            ),
                            const SizedBox(width: 4),
                            GovernmentLevelDot(
                              level: GovernmentLevel.state,
                              size: 8,
                            ),
                            const SizedBox(width: 8),
                            const Text('Federal/State'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GovernmentLevelDot(
                              level: GovernmentLevel.local,
                              size: 8,
                            ),
                            const SizedBox(width: 8),
                            const Text('Local'),
                          ],
                        ),
                      ),
                      const Tab(text: 'Name Results'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),

                  // Error message if any (only show validation errors here, not provider errors)
                  if (_validationError != null)
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
                          _validationError!,
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

                  // Tab content with fixed height
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6, // 60% of the screen height, more responsive
                    child: Column(
                      children: [
                          
                        Expanded(
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
                                          : 'Search by name to find representatives',
                                  forceTabIndex: 0),
      
                              // Federal/State representatives tab
                              _buildRepresentativesList(
                                  provider.federalRepresentatives,
                                  _searchTypeIndex == 1
                                      ? 'No federal or state representatives found for this city'
                                      : 'Select a state to find your federal and state representatives',
                                  forceTabIndex: 1),
      
                              // Local representatives tab
                              _buildRepresentativesList(
                                  provider.localRepresentatives,
                                  _searchTypeIndex == 1
                                      ? 'Enter a city to find your local representatives'
                                      : 'Select a state to find your local representatives',
                                  forceTabIndex: 2),
      
                              // Name search results tab
                              _buildRepresentativesList(provider.allRepresentatives,
                                  'Search for representatives by name to see results here',
                                  forceTabIndex: 3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      // Floating action button removed as per request
    );
  }

  // Build state search form
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
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
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

          const SizedBox(
              height:
                  24), // Increased spacing to compensate for the removed field

          // Informational text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will show all representatives for your state, including federal Senators and House members, plus state-level representatives.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24), // Increased spacing

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
          Text(
            'Popular States:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
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
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ))
        .toList();
  }

  // Build representatives list
  Widget _buildRepresentativesList(
      List<Representative> representatives, String emptyMessage, {int? forceTabIndex}) {
    final provider = Provider.of<CombinedRepresentativeProvider>(context, listen: false);
    
    // Use forced tab index if provided, otherwise use controller index
    final currentTabIndex = forceTabIndex ?? _tabController.index;
    
    // Check for tab-specific errors
    String? tabSpecificError;
    if (representatives.isEmpty) {
      if (currentTabIndex == 1) { // Federal/State tab
        if (provider.errorMessageFederal != null) {
          tabSpecificError = provider.errorMessageFederal;
        }
      } else if (currentTabIndex == 2) { // Local tab
        if (provider.errorMessageLocal != null) {
          tabSpecificError = provider.errorMessageLocal;
        }
      }
    }
    
    if (representatives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchTypeIndex == 0
                    ? Icons.public
                    : _searchTypeIndex == 1
                        ? Icons.location_city
                        : Icons.person_search,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              
              // Show tab-specific error if available, otherwise show empty message
              if (tabSpecificError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    tabSpecificError,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              Text(
                tabSpecificError != null ? 'Unable to load representatives' : emptyMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
            ],
          ),
        ),
      );
    }

    // Filter representatives if needed based on the current tab
    List<Representative> filteredReps = representatives;

    // If we're on the "Local" tab (index 2), apply additional filtering
    if (currentTabIndex == 2) {
      filteredReps =
          representatives.where((rep) => _isLocalRepresentative(rep)).toList();

      // Show empty state if we filtered out all representatives
      if (filteredReps.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_city,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No local representatives found.\nTry searching by city name instead.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_searchTypeIndex != 1) // Show this if not already in city search mode
                  ElevatedButton.icon(
                    icon: const Icon(Icons.location_city),
                    label: const Text('Switch to City Search'),
                    onPressed: () {
                      // Switch to city search mode and scroll to top
                      setState(() {
                        _searchTypeIndex = 1; // Switch to city search
                      });
                      // Scroll to the top after UI updates
                      Future.microtask(() {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    // For the "All" tab (index 0), show grouped representatives
    // For other tabs, show simple list
    final shouldGroup = currentTabIndex == 0;

    return GroupedRepresentativeList(
      representatives: filteredReps,
      groupByLevel: shouldGroup,
      showLevelHeaders: shouldGroup,
      collapsible: false, // Set to true if you want collapsible sections
      onRepresentativeTap: (rep) {
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
  }
}
