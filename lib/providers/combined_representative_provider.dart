// lib/providers/combined_representative_provider.dart
import 'package:flutter/foundation.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/models/local_representative_model.dart';
import 'package:govvy/services/representative_service.dart';
import 'package:govvy/services/cicero_service.dart';
import 'package:govvy/services/legiscan_service.dart'; // Add import for LegiScan service
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CombinedRepresentativeProvider with ChangeNotifier {
  final RepresentativeService _federalService;
  final CiceroService _localService = CiceroService();
  final NetworkService _networkService = NetworkService();
  final LegiscanService _legiscanService =
      LegiscanService(); // Add LegiScan service

  List<Representative> _federalRepresentatives = [];
  List<LocalRepresentative> _localRepresentativesRaw = [];
  bool _isLoadingFederal = false;
  bool _isLoadingLocal = false;
  bool _isLoadingLegiscan = false; // Add loading state for LegiScan
  String? _errorMessageFederal;
  String? _errorMessageLocal;
  String? _errorMessageLegiscan; // Add error message for LegiScan
  String? _lastSearchedAddress;
  String? _lastSearchedCity;
  String? _lastSearchedState;
  String? _lastSearchedDistrict;
  RepresentativeDetails? _selectedRepresentative;
  bool _isLoadingDetails = false;

  // Map to store LegiScan person IDs for representatives
  final Map<String, int> _repToLegiscanIdMap = {};

  // Getters
  List<Representative> get federalRepresentatives => _federalRepresentatives;

  List<LocalRepresentative> get localRepresentativesRaw =>
      _localRepresentativesRaw;

  // Convert LocalRepresentative objects to Representative objects and ensure they're actually local
  List<Representative> get localRepresentatives {
    return _localRepresentativesRaw
        .map((local) => local.toRepresentative())
        .where((rep) =>
            // Filter to ensure only truly local representatives are included
            rep.bioGuideId.startsWith('cicero-') ||
            [
              'COUNTY',
              'CITY',
              'PLACE',
              'TOWNSHIP',
              'BOROUGH',
              'TOWN',
              'VILLAGE'
            ].contains(rep.chamber.toUpperCase()))
        .toList();
  }

  // Combine federal and local representatives
  List<Representative> get allRepresentatives {
    // Get only the local representatives using the filtered getter
    final locals = localRepresentatives;

    // Combine with federal representatives
    return [..._federalRepresentatives, ...locals];
  }

  bool get isLoading =>
      _isLoadingFederal || _isLoadingLocal || _isLoadingLegiscan;
  bool get isLoadingFederal => _isLoadingFederal;
  bool get isLoadingLocal => _isLoadingLocal;
  bool get isLoadingLegiscan =>
      _isLoadingLegiscan; // Add getter for LegiScan loading state

  String? get errorMessage =>
      _errorMessageFederal ?? _errorMessageLocal ?? _errorMessageLegiscan;
  String? get errorMessageFederal => _errorMessageFederal;
  String? get errorMessageLocal => _errorMessageLocal;
  String? get errorMessageLegiscan => _errorMessageLegiscan;

  String? get lastSearchedAddress => _lastSearchedAddress;
  String? get lastSearchedCity => _lastSearchedCity;
  String? get lastSearchedState => _lastSearchedState;
  String? get lastSearchedDistrict => _lastSearchedDistrict;

  RepresentativeDetails? get selectedRepresentative => _selectedRepresentative;
  bool get isLoadingDetails => _isLoadingDetails;

  CombinedRepresentativeProvider(this._federalService);

  // Helper method to separate state representatives from local representatives
  void _separateStateFromLocalRepresentatives(List<LocalRepresentative> allReps) {
    final List<LocalRepresentative> trulyLocalReps = [];
    final List<Representative> stateReps = [];
    
    for (final rep in allReps) {
      final level = rep.level.toUpperCase();
      
      // Check if this is a state-level representative
      if (level == 'STATE_UPPER' || 
          level == 'STATE_LOWER' || 
          level == 'STATE' ||
          level.contains('STATE SENATE') ||
          level.contains('STATE HOUSE') ||
          level.contains('STATE ASSEMBLY') ||
          rep.office.toUpperCase().contains('STATE SENATOR') ||
          rep.office.toUpperCase().contains('STATE REPRESENTATIVE') ||
          rep.office.toUpperCase().contains('STATE ASSEMBLYMEMBER')) {
        
        // Convert to Representative and add to federal list
        stateReps.add(rep.toRepresentative());
        
      } else {
        // Keep as local representative
        trulyLocalReps.add(rep);
        
      }
    }
    
    // Update the lists
    _localRepresentativesRaw = trulyLocalReps;
    
    // Add state representatives to the federal list (don't replace, add to existing)
    _federalRepresentatives.addAll(stateReps);
  }

  // Check network status before performing API calls
  Future<bool> _checkNetworkBeforeRequest() async {
    try {
      final isConnected = await _networkService.checkConnectivity();

      if (!isConnected) {
        _errorMessageFederal =
            'Network connection unavailable. Please check your internet connection.';
        notifyListeners();
      }

      return isConnected;
    } catch (e) {
      return true; // Assume connected if check fails
    }
  }

  // Add a method to check API key availability
  Future<bool> _verifyApiKeys() async {
    try {
      final remoteConfig = RemoteConfigService();
      final keyStatus = await remoteConfig.validateApiKeys();

      bool hasRequiredKeys = true;

      if (!keyStatus['googleMaps']!) {
        _errorMessageFederal =
            'Missing Google Maps API key. Some features may not work correctly.';
        hasRequiredKeys = false;
      }

      if (!keyStatus['congress']!) {
        _errorMessageFederal =
            'Missing Congress API key. Federal representative data will be limited.';
        hasRequiredKeys = false;
      }

      if (!keyStatus['cicero']!) {
        _errorMessageLocal =
            'Missing Cicero API key. Local representative data will be limited.';
        hasRequiredKeys = false;
      }

      if (!keyStatus['legiscan']!) {
        _errorMessageLegiscan =
            'Missing LegiScan API key. State/local bill data will be limited.';
        hasRequiredKeys = false;
      }

      if (!hasRequiredKeys) {
        notifyListeners();
      }

      return hasRequiredKeys;
    } catch (e) {
      return true; // Continue anyway
    }
  }

  // Method to find and fetch LegiScan bills for a representative
  Future<List<RepresentativeBill>> fetchLegiscanBills(
      Representative rep) async {
    try {
      _isLoadingLegiscan = true;
      _errorMessageLegiscan = null;
      notifyListeners();

      // Skip if LegiScan API key is not available
      if (!_legiscanService.hasApiKey) {
        _isLoadingLegiscan = false;
        notifyListeners();
        return await _legiscanService.getMockSponsoredBills();
      }

      // Check if we already have a LegiScan ID for this representative
      if (_repToLegiscanIdMap.containsKey(rep.bioGuideId)) {
        final legiscanId = _repToLegiscanIdMap[rep.bioGuideId]!;

        final bills = await _legiscanService.getSponsoredBills(legiscanId);
        _isLoadingLegiscan = false;
        notifyListeners();
        return bills;
      }

      // Try to find the representative in LegiScan by name and state
      final person =
          await _legiscanService.findPersonByName(rep.name, rep.state);

      if (person == null) {

        // Parse name into first and last name
        final nameParts = rep.name.split(' ');
        String lastName = nameParts.last;
        String firstName = nameParts.length > 1 ? nameParts.first : '';

        // Try direct bill search by name
        final bills = await _legiscanService.getDirectBillsForPerson(
            firstName, lastName, rep.state);

        if (bills.isNotEmpty) {
          _isLoadingLegiscan = false;
          notifyListeners();
          return bills;
        }
      }

      _isLoadingLegiscan = false;
      notifyListeners();
      return [];
    } catch (e) {
      _errorMessageLegiscan =
          'Error fetching bills from LegiScan: ${e.toString()}';
      _isLoadingLegiscan = false;
      notifyListeners();
      return [];
    }
  }

  // New method: Fetch representatives by state (and optional district)
  Future<void> fetchRepresentativesByState(String stateCode,
      [String? districtNumber]) async {
    try {
      // Check network connectivity
      if (!await _checkNetworkBeforeRequest()) {
        return; // Don't proceed if no network
      }

      // Verify API keys
      await _verifyApiKeys(); // Continue even if keys are missing (will use mock data)

      _isLoadingFederal = true;
      _errorMessageFederal = null;
      _lastSearchedState = stateCode;
      _lastSearchedDistrict = districtNumber;
      notifyListeners();

      // Clear existing representatives
      _federalRepresentatives = [];
      // Also clear local representatives to avoid confusion
      _localRepresentativesRaw = [];

      // Removed artificial delay for better performance

      // Fetch federal representatives from the service
      _federalRepresentatives = await _federalService
          .getRepresentativesByStateDistrict(stateCode, districtNumber);

      if (_federalRepresentatives.isEmpty) {
        _errorMessageFederal =
            'No representatives found for $stateCode${districtNumber != null ? ' District $districtNumber' : ''}. Please check your selection.';
      }

      _isLoadingFederal = false;

      // Also try to fetch local representatives for this state
      if (districtNumber != null) {
        // If district is specified, we might be able to get local reps
        // using the state and district as an approximate location
        fetchLocalRepresentativesByStateDistrict(stateCode, districtNumber);
      }

      // Save to cache
      _saveStateSearchToCache();

      notifyListeners();
    } catch (e) {
      _isLoadingFederal = false;
      _errorMessageFederal = 'Error loading representatives: ${e.toString()}';
      notifyListeners();
    }
  }

  // Helper method to fetch local representatives by state and district
  Future<void> fetchLocalRepresentativesByStateDistrict(
      String stateCode, String districtNumber) async {
    try {
      _isLoadingLocal = true;
      _errorMessageLocal = null;
      notifyListeners();

      // Clear existing local representatives
      _localRepresentativesRaw = [];

      // Construct a simple approximate location from state and district
      // This is a basic approximation but better than nothing
      String approximateLocation =
          "$stateCode Congressional District $districtNumber";

      _localRepresentativesRaw = await _localService
          .getLocalRepresentativesByAddress(approximateLocation);

      _isLoadingLocal = false;
      notifyListeners();
    } catch (e) {
      _isLoadingLocal = false;
      // Don't show error message for this complementary search
      notifyListeners();
    }
  }

  // Add this enhanced method to your lib/providers/combined_representative_provider.dart file

// Enhanced method to fetch both local AND state/federal representatives by city
  Future<void> fetchLocalRepresentativesByCity(String city) async {
    try {
      // Check network connectivity
      if (!await _checkNetworkBeforeRequest()) {
        return; // Don't proceed if no network
      }

      // Verify API keys
      await _verifyApiKeys(); // Continue even if keys are missing (will use mock data)

      _isLoadingLocal = true;
      _isLoadingFederal = true;
      _errorMessageLocal = null;
      _errorMessageFederal = null;

      // Parse city and state if provided (e.g., "Gainesville, FL")
      String searchCity = city;
      String? stateCode;

      if (city.contains(',')) {
        final parts = city.split(',');
        if (parts.length >= 2) {
          searchCity = parts[0].trim();
          // Extract state code - normalize to uppercase and remove spaces
          stateCode = parts[1].trim().toUpperCase().replaceAll(' ', '');
        }
      }

      // Store the search parameters for caching and display
      _lastSearchedCity = searchCity;
      if (stateCode != null) {
        _lastSearchedState = stateCode;
      }

      notifyListeners();

      // Clear existing representatives
      _localRepresentativesRaw = [];
      _federalRepresentatives = [];

      // Removed artificial delay for better performance

      // Start both searches in parallel for better performance
      late Future<void> localSearch;
      late Future<void> federalSearch;

      // Using refined search with state code if available
      if (stateCode != null) {
        if (kDebugMode) {
        }

        // Search for local representatives with specific state filter
        localSearch = () async {
          try {
            final allCiceroReps = await _localService
                .getLocalRepresentativesByStateCity(stateCode!, searchCity);
            
            // Separate state representatives from truly local representatives
            _separateStateFromLocalRepresentatives(allCiceroReps);
          } catch (e) {
            if (kDebugMode) {
            }
            _errorMessageLocal = 'Error loading local representatives: ${e.toString()}';
          }
        }();

        // Search for federal representatives by city address (gets specific district)
        federalSearch = () async {
          try {
            // Use address-based search to get only the representatives for this city's district
            _federalRepresentatives = await _federalService
                .getRepresentativesByAddress('$searchCity, $stateCode');
          } catch (e) {
            if (kDebugMode) {
            }
            _errorMessageFederal = 'Error loading federal representatives: ${e.toString()}';
          }
        }();
      } else {
        // Regular city search without state specification

        localSearch = () async {
          try {
            final allCiceroReps =
                await _localService.getLocalRepresentativesByCity(searchCity);
            
            // Separate state representatives from truly local representatives
            _separateStateFromLocalRepresentatives(allCiceroReps);
          } catch (e) {
            if (kDebugMode) {
            }
            _errorMessageLocal = 'Error loading local representatives: ${e.toString()}';
          }
        }();

        // For city-only searches, try to get the state from the first local result
        // and then fetch federal representatives for that specific city
        federalSearch = localSearch.then((_) async {
          try {
            if (_localRepresentativesRaw.isNotEmpty) {
              final firstLocalRep = _localRepresentativesRaw.first;
              if (firstLocalRep.state.isNotEmpty) {
                final detectedState = firstLocalRep.state;
                if (kDebugMode) {
                }
                _lastSearchedState = detectedState;
                // Use address-based search to get only the representatives for this city's district
                _federalRepresentatives = await _federalService
                    .getRepresentativesByAddress('$searchCity, $detectedState');
              }
            }
          } catch (e) {
            if (kDebugMode) {
            }
            // Don't set error message for this secondary search
          }
        });
      }

      // Wait for both searches to complete
      await Future.wait([localSearch, federalSearch]);

      // Check if we found any representatives
      if (_localRepresentativesRaw.isEmpty && _federalRepresentatives.isEmpty) {
        _errorMessageLocal = 'No representatives found for $city. Please check the city name and try again.';
      } else if (_localRepresentativesRaw.isEmpty) {
        _errorMessageLocal = 'No local representatives found for $city, but state representatives are available.';
      } else if (_federalRepresentatives.isEmpty && stateCode != null) {
        _errorMessageFederal = 'No state representatives found for $stateCode.';
      }

      _isLoadingLocal = false;
      _isLoadingFederal = false;

      // Save to cache
      _saveLocalCityToCache();

      notifyListeners();
    } catch (e) {
      _isLoadingLocal = false;
      _isLoadingFederal = false;
      _errorMessageLocal =
          'Error loading representatives: ${e.toString()}';
      notifyListeners();
    }
  }

  // Fetch both federal and local representatives (Legacy method kept for compatibility)
  Future<void> fetchAllRepresentativesByAddress(String address) async {
    _lastSearchedAddress = address;
    notifyListeners();

    // Start both fetches in parallel
    await Future.wait([
      fetchFederalRepresentativesByAddress(address),
      fetchLocalRepresentativesByAddress(address),
    ]);

    // Save results to cache
    _saveToCache();
  }

  // Fetch only federal representatives by address
  Future<void> fetchFederalRepresentativesByAddress(String address) async {
    try {
      // Check network connectivity
      if (!await _checkNetworkBeforeRequest()) {
        return; // Don't proceed if no network
      }

      // Verify API keys
      await _verifyApiKeys(); // Continue even if keys are missing (will use mock data)

      _isLoadingFederal = true;
      _errorMessageFederal = null;
      notifyListeners();

      // Clear existing federal representatives
      _federalRepresentatives = [];

      // Removed artificial delay for better performance

      // Fetch from RepresentativeService
      _federalRepresentatives =
          await _federalService.getRepresentativesByAddress(address);

      if (_federalRepresentatives.isEmpty) {
        _errorMessageFederal =
            'No federal or state representatives found for this address. Please check the address and try again.';
      }

      // Try to extract state from the results
      if (_federalRepresentatives.isNotEmpty &&
          _federalRepresentatives[0].state.isNotEmpty) {
        _lastSearchedState = _federalRepresentatives[0].state;

        // Also try to extract district if available
        if (_federalRepresentatives[0].district != null) {
          _lastSearchedDistrict = _federalRepresentatives[0].district;
        }
      }

      _isLoadingFederal = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFederal = false;
      _errorMessageFederal =
          'Error loading federal representatives: ${e.toString()}';
      notifyListeners();
    }
  }

  // Fetch only local representatives by address
  Future<void> fetchLocalRepresentativesByAddress(String address) async {
    try {
      // Check network connectivity
      if (!await _checkNetworkBeforeRequest()) {
        return; // Don't proceed if no network
      }

      // Verify API keys
      await _verifyApiKeys(); // Continue even if keys are missing (will use mock data)

      _isLoadingLocal = true;
      _errorMessageLocal = null;
      notifyListeners();

      // Clear existing local representatives
      _localRepresentativesRaw = [];

      // Removed artificial delay for better performance

      // Fetch from CiceroService
      _localRepresentativesRaw =
          await _localService.getLocalRepresentativesByAddress(address);

      if (_localRepresentativesRaw.isEmpty) {
        _errorMessageLocal =
            'No local representatives found for this address. Try searching by city name instead.';
      }

      _isLoadingLocal = false;
      notifyListeners();
    } catch (e) {
      _isLoadingLocal = false;
      _errorMessageLocal =
          'Error loading local representatives: ${e.toString()}';
      if (kDebugMode) {
      }
      notifyListeners();
    }
  }

  // Updated method to fetch representative details with LegiScan integration
  Future<void> fetchRepresentativeDetails(String bioGuideId) async {
    try {
      // Check network connectivity
      if (!await _checkNetworkBeforeRequest()) {
        return; // Don't proceed if no network
      }

      // Verify API keys
      await _verifyApiKeys(); // Continue even if keys are missing (will use mock data)

      _isLoadingDetails = true;
      _errorMessageLocal = null;
      _errorMessageFederal = null;
      _errorMessageLegiscan = null;
      notifyListeners();

      // First check if it's a local representative
      if (bioGuideId.startsWith('cicero-')) {
        // Find the representative in our local list
        final localRep = _localRepresentativesRaw.firstWhere(
          (rep) => rep.bioGuideId == bioGuideId,
          orElse: () => throw Exception('Local representative not found'),
        );

        // Convert to RepresentativeDetails format
        _selectedRepresentative = RepresentativeDetails(
          bioGuideId: localRep.bioGuideId,
          name: localRep.name,
          party: localRep.party,
          state: localRep.state,
          district: localRep.district,
          chamber: localRep.level,
          office: localRep.office,
          phone: localRep.phone,
          email: localRep.email,
          website: localRep.website,
          imageUrl: localRep.imageUrl,
          socialMedia: localRep.socialMedia,
          // Local representatives typically don't have bills
          sponsoredBills: [],
          cosponsoredBills: [],
        );

        // Now try to find bills in LegiScan for this local representative
        final localRepAsGeneric = localRep.toRepresentative();

        // Only proceed if this is a state or local-level representative
        final chamber = localRep.level.toUpperCase();
        if (!chamber.contains('NATIONAL') &&
            chamber != 'SENATE' &&
            chamber != 'HOUSE' &&
            chamber != 'CONGRESS') {

          try {
            // Fetch but don't wait for completion
            _isLoadingLegiscan = true;
            notifyListeners();

            fetchLegiscanBills(localRepAsGeneric).then((legiscanBills) {
              if (_selectedRepresentative != null &&
                  _selectedRepresentative!.bioGuideId == bioGuideId) {
                _selectedRepresentative!.addLegiscanBills(legiscanBills);
                _isLoadingLegiscan = false;
                notifyListeners();
              }
            }).catchError((e) {
              if (kDebugMode) {
              }
              _isLoadingLegiscan = false;
              notifyListeners();
            });
          } catch (e) {
            if (kDebugMode) {
            }
            _isLoadingLegiscan = false;
          }
        }
      } else {
        // It's a federal or state representative, use the federal service
        final detailsResponse =
            await _federalService.getRepresentativeDetails(bioGuideId);

        _selectedRepresentative = RepresentativeDetails.fromMap(
            details: detailsResponse['details'],
            sponsoredBills: detailsResponse['sponsoredBills'],
            cosponsoredBills: detailsResponse['cosponsoredBills']);

        // For state-level representatives, try to get bills from LegiScan
        if (_selectedRepresentative != null) {
          final chamber = _selectedRepresentative!.chamber.toUpperCase();

          // Only get LegiScan bills for state legislators, not federal ones
          if (chamber.startsWith('STATE_') ||
              chamber == 'STATE SENATE' ||
              chamber == 'STATE HOUSE' ||
              chamber == 'STATE ASSEMBLY') {

            try {
              // Create a Representative object from the details
              final stateRep = Representative(
                name: _selectedRepresentative!.name,
                bioGuideId: bioGuideId,
                party: _selectedRepresentative!.party,
                chamber: _selectedRepresentative!.chamber,
                state: _selectedRepresentative!.state,
                district: _selectedRepresentative!.district,
              );

              // Fetch but don't wait for completion
              _isLoadingLegiscan = true;
              notifyListeners();

              fetchLegiscanBills(stateRep).then((legiscanBills) {
                if (_selectedRepresentative != null &&
                    _selectedRepresentative!.bioGuideId == bioGuideId) {
                  _selectedRepresentative!.addLegiscanBills(legiscanBills);
                  _isLoadingLegiscan = false;
                  notifyListeners();
                }
              }).catchError((e) {
                if (kDebugMode) {
                }
                _isLoadingLegiscan = false;
                notifyListeners();
              });
            } catch (e) {
              if (kDebugMode) {
                }
              _isLoadingLegiscan = false;
            }
          }
        }
      }

      _isLoadingDetails = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDetails = false;
      _errorMessageFederal =
          'Error loading representative details: ${e.toString()}';
      notifyListeners();
    }
  }

  // Fetch representatives by name
  Future<void> fetchRepresentativesByName(String lastName,
      {String? firstName}) async {
    try {
      // Check network connectivity
      if (!await _checkNetworkBeforeRequest()) {
        return; // Don't proceed if no network
      }

      // Verify API keys
      await _verifyApiKeys(); // Continue even if keys are missing (will use mock data)

      _isLoadingLocal = true;
      _errorMessageLocal = null;
      notifyListeners();

      // Clear existing representatives
      _federalRepresentatives = [];
      _localRepresentativesRaw = [];

      // Removed artificial delay for better performance


      // Use the CiceroService to search by name
      _localRepresentativesRaw = await _localService
          .getRepresentativesByName(lastName, firstName: firstName);

      if (_localRepresentativesRaw.isEmpty) {
        _errorMessageLocal =
            'No representatives found with the name "$lastName${firstName != null ? ', $firstName' : ''}". Please try a different name.';
      }

      _isLoadingLocal = false;
      notifyListeners();
    } catch (e) {
      _isLoadingLocal = false;
      _errorMessageLocal =
          'Error searching for representatives: ${e.toString()}';
      if (kDebugMode) {
      }
      notifyListeners();
    }
  }

  // Save state search results to cache
  Future<void> _saveStateSearchToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save state, district, and timestamp
      if (_lastSearchedState != null) {
        await prefs.setString('last_state', _lastSearchedState!);
        await prefs.setInt(
            'last_state_search_time', DateTime.now().millisecondsSinceEpoch);

        if (_lastSearchedDistrict != null) {
          await prefs.setString('last_district', _lastSearchedDistrict!);
        } else {
          await prefs.remove('last_district');
        }

        // Save federal representatives
        if (_federalRepresentatives.isNotEmpty) {
          final fedData =
              _federalRepresentatives.map((rep) => rep.toMap()).toList();
          await prefs.setString('federal_reps_cache', json.encode(fedData));
        }

        // Save local representatives
        if (_localRepresentativesRaw.isNotEmpty) {
          final localData =
              _localRepresentativesRaw.map((rep) => rep.toMap()).toList();
          await prefs.setString('local_reps_cache', json.encode(localData));
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Legacy method for address-based cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save address and timestamp
      if (_lastSearchedAddress != null) {
        await prefs.setString('last_address', _lastSearchedAddress!);
        await prefs.setInt(
            'last_search_time', DateTime.now().millisecondsSinceEpoch);

        // Extract city from address to save as well
        try {
          final addressParts = _lastSearchedAddress!.split(',');
          if (addressParts.length > 1) {
            _lastSearchedCity = addressParts[1].trim();
            await prefs.setString('last_city', _lastSearchedCity!);
          }
        } catch (_) {}

        // Save federal representatives
        if (_federalRepresentatives.isNotEmpty) {
          final fedData =
              _federalRepresentatives.map((rep) => rep.toMap()).toList();
          await prefs.setString('federal_reps_cache', json.encode(fedData));
        }

        // Save local representatives
        if (_localRepresentativesRaw.isNotEmpty) {
          final localData =
              _localRepresentativesRaw.map((rep) => rep.toMap()).toList();
          await prefs.setString('local_reps_cache', json.encode(localData));
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Cache city search results (now includes both local and federal representatives)
  Future<void> _saveLocalCityToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save city and timestamp
      if (_lastSearchedCity != null) {
        await prefs.setString('last_city', _lastSearchedCity!);
        await prefs.setInt(
            'last_city_search_time', DateTime.now().millisecondsSinceEpoch);

        // Save state if available
        if (_lastSearchedState != null) {
          await prefs.setString('last_city_state', _lastSearchedState!);
        }

        // Save local representatives
        if (_localRepresentativesRaw.isNotEmpty) {
          final localData =
              _localRepresentativesRaw.map((rep) => rep.toMap()).toList();
          await prefs.setString(
              'local_city_reps_cache', json.encode(localData));
        }

        // Save federal/state representatives from city search
        if (_federalRepresentatives.isNotEmpty) {
          final fedData =
              _federalRepresentatives.map((rep) => rep.toMap()).toList();
          await prefs.setString('federal_city_reps_cache', json.encode(fedData));
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  // Load cache to avoid unnecessary API calls
  Future<bool> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // First try to load state-based cache (newest approach)
      final lastState = prefs.getString('last_state');
      final lastStateSearchTime = prefs.getInt('last_state_search_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (lastState != null && (currentTime - lastStateSearchTime) < 86400000) {
        _lastSearchedState = lastState;
        _lastSearchedDistrict = prefs.getString('last_district');

        // Load federal representatives
        final fedCache = prefs.getString('federal_reps_cache');
        if (fedCache != null) {
          final fedData = json.decode(fedCache) as List<dynamic>;
          _federalRepresentatives = fedData
              .map((item) =>
                  Representative.fromMap('', Map<String, dynamic>.from(item)))
              .toList();
        }

        // Load local representatives
        final localCache = prefs.getString('local_reps_cache');
        if (localCache != null) {
          final localData = json.decode(localCache) as List<dynamic>;
          _localRepresentativesRaw = localData
              .map((item) =>
                  LocalRepresentative.fromMap(Map<String, dynamic>.from(item)))
              .toList();
        }

        notifyListeners();
        return true;
      }

      // If no state cache, try address cache (legacy approach)
      final lastAddress = prefs.getString('last_address');
      final lastSearchTime = prefs.getInt('last_search_time') ?? 0;

      if (lastAddress != null && (currentTime - lastSearchTime) < 86400000) {
        _lastSearchedAddress = lastAddress;

        // Load federal representatives
        final fedCache = prefs.getString('federal_reps_cache');
        if (fedCache != null) {
          final fedData = json.decode(fedCache) as List<dynamic>;
          _federalRepresentatives = fedData
              .map((item) =>
                  Representative.fromMap('', Map<String, dynamic>.from(item)))
              .toList();
        }

        // Load local representatives
        final localCache = prefs.getString('local_reps_cache');
        if (localCache != null) {
          final localData = json.decode(localCache) as List<dynamic>;
          _localRepresentativesRaw = localData
              .map((item) =>
                  LocalRepresentative.fromMap(Map<String, dynamic>.from(item)))
              .toList();
        }

        notifyListeners();
        return true;
      }

      // If no address cache, try city cache
      final lastCity = prefs.getString('last_city');
      final lastCitySearchTime = prefs.getInt('last_city_search_time') ?? 0;

      if (lastCity != null && (currentTime - lastCitySearchTime) < 86400000) {
        _lastSearchedCity = lastCity;
        _lastSearchedState = prefs.getString('last_city_state');

        // Load local representatives from city search
        final localCityCache = prefs.getString('local_city_reps_cache');
        if (localCityCache != null) {
          final localData = json.decode(localCityCache) as List<dynamic>;
          _localRepresentativesRaw = localData
              .map((item) =>
                  LocalRepresentative.fromMap(Map<String, dynamic>.from(item)))
              .toList();
        }

        // Load federal/state representatives from city search
        final federalCityCache = prefs.getString('federal_city_reps_cache');
        if (federalCityCache != null) {
          final fedData = json.decode(federalCityCache) as List<dynamic>;
          _federalRepresentatives = fedData
              .map((item) =>
                  Representative.fromMap('', Map<String, dynamic>.from(item)))
              .toList();
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
      }
      return false;
    }
  }

  // Clear selected representative
  void clearSelectedRepresentative() {
    _selectedRepresentative = null;
    notifyListeners();
  }

  // Clear errors
  void clearErrors() {
    _errorMessageFederal = null;
    _errorMessageLocal = null;
    _errorMessageLegiscan = null;
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _federalRepresentatives = [];
    _localRepresentativesRaw = [];
    _errorMessageFederal = null;
    _errorMessageLocal = null;
    _errorMessageLegiscan = null;
    _lastSearchedAddress = null;
    _lastSearchedCity = null;
    _lastSearchedState = null;
    _lastSearchedDistrict = null;
    _selectedRepresentative = null;
    notifyListeners();
  }
}
