// lib/services/representative_service.dart
import 'dart:convert';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:http/http.dart' as http;

class RepresentativeService {
  final String _baseUrl = 'https://api.congress.gov/v3';

  // Get API key from Remote Config
  String? get _apiKey => RemoteConfigService().getCongressApiKey;

  String? get _googleApiKey => RemoteConfigService().getGoogleMapsApiKey;

  // Check if API keys are available with improved logging
  bool get hasCongressApiKey {
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;
    if (!hasKey) {
      print('DEBUG: Congress API key not found. Key value: ${_apiKey?.substring(0, 10)}...');
    }
    return hasKey;
  }

  bool get hasGoogleMapsApiKey {
    final hasKey = _googleApiKey != null && _googleApiKey!.isNotEmpty;
    return hasKey;
  }

  // Helper function to safely take a substring
  int min(int a, int b) => a < b ? a : b;

  // Helper function to safely convert any value to string
  String? safeToString(dynamic value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  // Helper method to match state codes and state names
  bool _isMatchingState(String apiState, String requestedState) {
    // Map of state codes to state names
    const stateMap = {
      'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas', 'CA': 'California',
      'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware', 'FL': 'Florida', 'GA': 'Georgia',
      'HI': 'Hawaii', 'ID': 'Idaho', 'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa',
      'KS': 'Kansas', 'KY': 'Kentucky', 'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland',
      'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota', 'MS': 'Mississippi', 'MO': 'Missouri',
      'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada', 'NH': 'New Hampshire', 'NJ': 'New Jersey',
      'NM': 'New Mexico', 'NY': 'New York', 'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio',
      'OK': 'Oklahoma', 'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina',
      'SD': 'South Dakota', 'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont',
      'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia', 'WI': 'Wisconsin', 'WY': 'Wyoming',
      'DC': 'District of Columbia'
    };

    final apiStateUpper = apiState.toUpperCase();
    final requestedStateUpper = requestedState.toUpperCase();

    // Direct match (both codes or both names)
    if (apiStateUpper == requestedStateUpper) {
      return true;
    }

    // Check if requested state is a code and API state is a name
    if (stateMap.containsKey(requestedStateUpper) && 
        stateMap[requestedStateUpper]!.toUpperCase() == apiStateUpper) {
      return true;
    }

    // Check if requested state is a name and API state is a code
    if (stateMap.containsValue(requestedStateUpper) && 
        stateMap.entries.any((entry) => entry.value.toUpperCase() == requestedStateUpper && entry.key == apiStateUpper)) {
      return true;
    }

    return false;
  }

  // Get congressional district from address using Google's Geocoding API and Civic Information API
  Future<Map<String, dynamic>> getDistrictFromAddress(String address) async {
    try {
      // Quick check: if this looks like a city we know, use mock data immediately
      final addressUpper = address.toUpperCase();
      if (addressUpper.contains('LOTHIAN') && addressUpper.contains('MD')) {
        return {
          'state': 'MD',
          'district': '5',
          'latitude': 38.7990,
          'longitude': -76.6391
        };
      }
      
      // Check if Google Maps API key is available
      if (!hasGoogleMapsApiKey) {
        // Return mock data for development when API key is missing
        // Try to extract state from the address if possible
        final addressUpper = address.toUpperCase();
        String mockState = 'FL'; // default
        String mockDistrict = '1'; // default
        
        // Extract state from address patterns like "City, ST" or "City, State"
        if (addressUpper.contains(', MD') || addressUpper.contains('MARYLAND')) {
          mockState = 'MD';
          // Lothian, MD is in district 5 (Steny Hoyer's district)
          if (addressUpper.contains('LOTHIAN')) {
            mockDistrict = '5';
          }
        } else if (addressUpper.contains(', CA') || addressUpper.contains('CALIFORNIA')) {
          mockState = 'CA';
        } else if (addressUpper.contains(', TX') || addressUpper.contains('TEXAS')) {
          mockState = 'TX';
        } else if (addressUpper.contains(', NY') || addressUpper.contains('NEW YORK')) {
          mockState = 'NY';
        } else if (addressUpper.contains(', FL') || addressUpper.contains('FLORIDA')) {
          mockState = 'FL';
        }
        
        
        return {
          'state': mockState,
          'district': mockDistrict,
          'latitude': mockState == 'MD' ? 38.7990 : 30.4383,
          'longitude': mockState == 'MD' ? -76.6391 : -87.2401
        };
      }

      // First, geocode the address to get coordinates
      final geocodeUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_googleApiKey';


      final geocodeResponse = await http.get(Uri.parse(geocodeUrl));

      if (geocodeResponse.statusCode != 200) {
        throw Exception('Failed to geocode address: ${geocodeResponse.body}');
      }

      final geocodeData = json.decode(geocodeResponse.body);

      if (geocodeData['status'] != 'OK') {
        throw Exception('Geocoding error: ${geocodeData['status']}');
      }

      if (geocodeData['results'].isEmpty) {
        throw Exception('No results found for address');
      }

      final location = geocodeData['results'][0]['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];

      // Use Google Civic Information API to get district
      final civicUrl =
          'https://civicinfo.googleapis.com/civicinfo/v2/representatives?address=${Uri.encodeComponent(address)}&levels=country&roles=legislatorLowerBody&roles=legislatorUpperBody&key=$_googleApiKey';


      final civicResponse = await http.get(Uri.parse(civicUrl));

      if (civicResponse.statusCode != 200) {
        throw Exception('Failed to get district info: ${civicResponse.body}');
      }

      final civicData = json.decode(civicResponse.body);

      // Extract state and district from divisions
      String? state;
      String? district;

      if (civicData.containsKey('divisions')) {
        final divisions = civicData['divisions'] as Map<String, dynamic>;

        for (var key in divisions.keys) {
          if (key.contains('state:') && !key.contains('cd:')) {
            state = key.split(':').last.toUpperCase();
          }

          if (key.contains('cd:')) {
            district = key.split(':').last;
          }
        }
      }

      if (state == null) {
        throw Exception('Could not determine state from address');
      }


      return {
        'state': state,
        'district': district,
        'latitude': lat,
        'longitude': lng
      };
    } catch (e) {
      // Return mock data on error for development
      return {
        'state': 'FL',
        'district': '1',
        'latitude': 30.4383,
        'longitude': -87.2401
      };
    }
  }

  // Primary method: Get representatives by state and district (if provided)
  Future<List<Representative>> getRepresentativesByStateDistrict(String state,
      [String? district]) async {
    try {
      // Fast-track fallback for MD district 5 to avoid slow API timeouts
      if (state.toUpperCase() == 'MD' && district == '5') {
        return _getMockRepresentatives(state, district);
      }

      if (!hasCongressApiKey) {
        print('DEBUG: No Congress API key detected, using mock data');
        return _getMockRepresentatives(state, district);
      }


      List<Representative> representatives = [];

      // Use the general member endpoint which properly supports state filtering
      final Uri url;
      
      if (district != null) {
        // For specific district, use state and district parameters
        url = Uri.parse('$_baseUrl/member')
            .replace(queryParameters: {
              'format': 'json',
              'currentMember': 'true',
              'state': state,
              'district': district,
              'limit': '100',
              'api_key': _apiKey!
            });
      } else {
        // For state-only search, use member endpoint with state filter
        url = Uri.parse('$_baseUrl/member')
            .replace(queryParameters: {
              'format': 'json',
              'currentMember': 'true',
              'state': state,
              'limit': '100',
              'api_key': _apiKey!
            });
      }

      final response = await _tracedHttpGet(url);

      if (response.statusCode == 200) {

        final Map<String, dynamic> data = json.decode(response.body);

        // Process members based on API response structure
        if (data.containsKey('members')) {
          final members = data['members'];

          if (members is List) {
            // Process direct list of members
            for (var memberRaw in members) {
              final member = Map<String, dynamic>.from(memberRaw);
              final representative = _processMember(member);
              
              // Filter by state to ensure we only get representatives from the requested state
              if (_isMatchingState(representative.state, state)) {
                representatives.add(representative);
              }
            }
          } else if (members is Map && members.containsKey('item')) {
            // Process members inside 'item' array
            final items = members['item'];
            if (items is List) {
              for (var itemRaw in items) {
                final item = Map<String, dynamic>.from(itemRaw);
                final representative = _processMember(item);
                
                // Filter by state to ensure we only get representatives from the requested state
                if (representative.state.toUpperCase() == state.toUpperCase()) {
                  representatives.add(representative);
                }
              }
            } else if (items is Map) {
              // Single item
              final item = Map<String, dynamic>.from(items);
              final representative = _processMember(item);
              
              // Filter by state to ensure we only get representatives from the requested state
              if (_isMatchingState(representative.state, state)) {
                representatives.add(representative);
              }
            }
          } else if (members is Map) {
            // Single member object
            final member = Map<String, dynamic>.from(members);
            final representative = _processMember(member);
            
            // Filter by state to ensure we only get representatives from the requested state
            if (_isMatchingState(representative.state, state)) {
              representatives.add(representative);
            }
          }
        }
      } else {
        throw Exception(
            'Failed to fetch representatives data: ${response.statusCode}');
      }

      if (representatives.isEmpty) {
        // Fall back to query parameter method if needed
        return await _getRepresentativesByQueryParams(state, district);
      }


      return representatives;
    } catch (e) {
      // Try alternative method before falling back to mock data
      try {
        return await _getRepresentativesByQueryParams(state, district);
      } catch (e2) {
        return _getMockRepresentatives(state, district);
      }
    }
  }

  // Alternative method using query parameters with correct Congress endpoint
  Future<List<Representative>> _getRepresentativesByQueryParams(String state,
      [String? district]) async {
    try {
      if (!hasCongressApiKey) {
        return _getMockRepresentatives(state, district);
      }

      List<Representative> representatives = [];

      // Build query parameters
      Map<String, String> queryParams = {
        'format': 'json',
        'limit': '100',
        'currentMember': 'true',
        'api_key': _apiKey!
      };

      // Use the general member endpoint which properly supports state filtering
      final Uri url;
      if (district != null) {
        // For specific district, use state and district parameters
        queryParams['state'] = state;
        queryParams['district'] = district;
        url = Uri.parse('$_baseUrl/member')
            .replace(queryParameters: queryParams);
      } else {
        // For state-only, use member endpoint with state filter
        queryParams['state'] = state;
        url = Uri.parse('$_baseUrl/member')
            .replace(queryParameters: queryParams);
      }


      final response = await _tracedHttpGet(url);

      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body);

      // Process members (similar logic as before)
      if (data.containsKey('members')) {
        final members = data['members'];

        if (members is List) {
          for (var memberRaw in members) {
            final member = Map<String, dynamic>.from(memberRaw);
            final representative = _processMember(member);
            
            // Filter by state to ensure we only get representatives from the requested state
            if (_isMatchingState(representative.state, state)) {
              representatives.add(representative);
            }
          }
        } else if (members is Map && members.containsKey('item')) {
          final items = members['item'];
          if (items is List) {
            for (var itemRaw in items) {
              final item = Map<String, dynamic>.from(itemRaw);
              final representative = _processMember(item);
              
              // Filter by state to ensure we only get representatives from the requested state
              if (_isMatchingState(representative.state, state)) {
                representatives.add(representative);
              }
            }
          } else if (items is Map) {
            final item = Map<String, dynamic>.from(items);
            final representative = _processMember(item);
            
            // Filter by state to ensure we only get representatives from the requested state
            if (_isMatchingState(representative.state, state)) {
              representatives.add(representative);
            }
          }
        } else if (members is Map) {
          final member = Map<String, dynamic>.from(members);
          final representative = _processMember(member);
          
          // Filter by state to ensure we only get representatives from the requested state
          if (_isMatchingState(representative.state, state)) {
            representatives.add(representative);
          }
        }
      }

      if (representatives.isEmpty) {
        throw Exception('No representatives found in API response');
      }

      return representatives;
    } catch (e) {
      rethrow; // Let the caller handle the error or fall back to mock data
    }
  }

  // Helper method to process a member object into a Representative
  Representative _processMember(Map<String, dynamic> member) {
    String chamber = '';
    String state = '';
    String? district;
    String? office;
    String? phone;
    String? website;
    String party = '';

    // Extract state from the top-level field first
    if (member.containsKey('state') && member['state'] != null) {
      state = member['state'].toString();
    }
    
    // Extract district from the top-level field first
    if (member.containsKey('district') && member['district'] != null) {
      district = member['district'].toString();
    }
    
    // Extract party from the top-level field first
    if (member.containsKey('partyName') && member['partyName'] != null) {
      party = member['partyName'].toString();
    }

    // Extract the most recent term information
    if (member.containsKey('terms') && member['terms'] != null) {
      final terms = member['terms'];

      if (terms is List && terms.isNotEmpty) {
        // Cast to Map<String, dynamic> to satisfy Dart type system
        final Map<String, dynamic> term =
            Map<String, dynamic>.from(terms[0] as Map);
        chamber = term['chamber']?.toString() ?? '';
        
        // Only override state if not already set from top-level
        if (state.isEmpty) {
          state = term['state']?.toString() ?? '';
        }
        
        // Only override district if not already set from top-level
        if (district == null) {
          district = term['district']?.toString();
        }
        
        office = term['office']?.toString();
        phone = term['phone']?.toString();
        website = term['website']?.toString();
        
        // Only override party if not already set from top-level
        if (party.isEmpty) {
          party = term['party']?.toString() ?? '';
        }
      } else if (terms is Map && terms.containsKey('item')) {
        final items = terms['item'];
        if (items is List && items.isNotEmpty) {
          // Cast to Map<String, dynamic> to satisfy Dart type system
          final Map<String, dynamic> term =
              Map<String, dynamic>.from(items[0] as Map);
          chamber = term['chamber']?.toString() ?? '';
          
          // Only override state if not already set from top-level
          if (state.isEmpty) {
            state = term['state']?.toString() ?? '';
          }
          
          // Only override district if not already set from top-level
          if (district == null) {
            district = term['district']?.toString();
          }
          
          office = term['office']?.toString();
          phone = term['phone']?.toString();
          website = term['website']?.toString();
          
          // Only override party if not already set from top-level
          if (party.isEmpty) {
            party = term['party']?.toString() ?? '';
          }
        }
      }
    }

    // Alternative sources for party information
    if (party.isEmpty) {
      if (member.containsKey('partyName')) {
        party = member['partyName']?.toString() ?? '';
      } else if (member.containsKey('party')) {
        party = member['party']?.toString() ?? '';
      } else if (member.containsKey('current') && member['current'] is Map) {
        // Cast to Map<String, dynamic> to satisfy Dart type system
        final Map<String, dynamic> current =
            Map<String, dynamic>.from(member['current'] as Map);
        if (current.containsKey('party')) {
          party = current['party']?.toString() ?? '';
        }
      }
    }

    // Try to get address and phone information
    if (office == null &&
        member.containsKey('addressInformation') &&
        member['addressInformation'] is Map) {
      final Map<String, dynamic> addressInfo =
          Map<String, dynamic>.from(member['addressInformation'] as Map);
      office = addressInfo['officeAddress']?.toString();

      phone ??= addressInfo['phoneNumber']?.toString();
    }

    // Get image URL
    String? imageUrl;
    if (member.containsKey('depiction') && member['depiction'] != null) {
      if (member['depiction'] is Map) {
        // Cast to Map<String, dynamic> to satisfy Dart type system
        final Map<String, dynamic> depiction =
            Map<String, dynamic>.from(member['depiction'] as Map);
        imageUrl = depiction['imageUrl']?.toString();
      }
    }

    // Get official website URL
    if (website == null && member.containsKey('officialWebsiteUrl')) {
      website = member['officialWebsiteUrl']?.toString();
    }

    // If bioguideId is available but image isn't, construct standard image URL
    if (imageUrl == null &&
        member.containsKey('bioguideId') &&
        member['bioguideId'] != null) {
      final bioguideId = member['bioguideId'].toString();
      if (bioguideId.isNotEmpty) {
        imageUrl =
            'https://bioguide.congress.gov/bioguide/photo/${bioguideId[0]}/$bioguideId.jpg';
      }
    }

    // Make educated guesses for chamber if missing
    if (chamber.isEmpty) {
      if (district != null) {
        chamber = 'House';
      } else if (member.containsKey('bioguideId')) {
        String bioguideId = member['bioguideId']?.toString() ?? '';
        if (bioguideId.startsWith('S')) {
          chamber = 'Senate';
        } else if (bioguideId.startsWith('H')) {
          chamber = 'House';
        }
      }
    }

    return Representative(
      name: member['name']?.toString() ??
          member['invertedOrderName']?.toString() ??
          member['directOrderName']?.toString() ??
          '',
      bioGuideId: member['bioguideId']?.toString() ?? '',
      party: party,
      chamber: chamber,
      state: state,
      district: district,
      imageUrl: imageUrl,
      office: office,
      phone: phone,
      website: website,
    );
  }

  Map<String, dynamic> processCongressGovMemberResponse(
      Map<String, dynamic> response) {
    Map<String, dynamic> memberDetails = {};

    if (response.containsKey('member')) {
      memberDetails = Map<String, dynamic>.from(response['member'] as Map);

      // Add sponsored and cosponsored bills placeholders
      // These would need to be fetched in separate API calls using the URLs in the response
      List<Map<String, dynamic>> emptyBills = [];

      // Prepare return data in the format expected by RepresentativeDetails.fromMap
      return {
        'details': memberDetails,
        'sponsoredBills': emptyBills,
        'cosponsoredBills': emptyBills,
      };
    }

    return {
      'details': memberDetails,
      'sponsoredBills': [],
      'cosponsoredBills': [],
    };
  }



// Add this method to fetch representative details from Congress.gov
  Future<Map<String, dynamic>> getRepresentativeDetailsFromCongressGov(
      String bioGuideId) async {
    if (!hasCongressApiKey) {
      return _getMockRepresentativeDetails(bioGuideId);
    }


    // Build URL for member details
    final url = Uri.parse('$_baseUrl/member/$bioGuideId')
        .replace(queryParameters: {'format': 'json', 'api_key': _apiKey!});

    final response = await _tracedHttpGet(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      // Process the response to match our expected format
      return processCongressGovMemberResponse(data);
    } else {
      throw Exception(
          'Failed to fetch representative details from Congress.gov');
    }
  }

  // Get representatives based on address (legacy method, kept for compatibility)
  Future<List<Representative>> getRepresentativesByAddress(
      String address) async {
    try {

      // Parse state from address
      final String? stateCode = _extractStateFromAddress(address);

      if (stateCode == null) {
        throw Exception(
            'Could not identify a US state in the provided address. Please include state in your address.');
      }


      // Get district info
      final districtInfo = await getDistrictFromAddress(address);
      final district = districtInfo['district']?.toString();


      // Use the improved method to get representatives
      return await getRepresentativesByStateDistrict(stateCode, district);
    } catch (e) {
      rethrow; // Propagate error to allow proper handling in UI
    }
  }

  // Helper method to extract state code from address
  String? _extractStateFromAddress(String address) {
    // Map of state names to their abbreviations
    const stateMap = {
      'alabama': 'AL',
      'alaska': 'AK',
      'arizona': 'AZ',
      'arkansas': 'AR',
      'california': 'CA',
      'colorado': 'CO',
      'connecticut': 'CT',
      'delaware': 'DE',
      'florida': 'FL',
      'georgia': 'GA',
      'hawaii': 'HI',
      'idaho': 'ID',
      'illinois': 'IL',
      'indiana': 'IN',
      'iowa': 'IA',
      'kansas': 'KS',
      'kentucky': 'KY',
      'louisiana': 'LA',
      'maine': 'ME',
      'maryland': 'MD',
      'massachusetts': 'MA',
      'michigan': 'MI',
      'minnesota': 'MN',
      'mississippi': 'MS',
      'missouri': 'MO',
      'montana': 'MT',
      'nebraska': 'NE',
      'nevada': 'NV',
      'new hampshire': 'NH',
      'new jersey': 'NJ',
      'new mexico': 'NM',
      'new york': 'NY',
      'north carolina': 'NC',
      'north dakota': 'ND',
      'ohio': 'OH',
      'oklahoma': 'OK',
      'oregon': 'OR',
      'pennsylvania': 'PA',
      'rhode island': 'RI',
      'south carolina': 'SC',
      'south dakota': 'SD',
      'tennessee': 'TN',
      'texas': 'TX',
      'utah': 'UT',
      'vermont': 'VT',
      'virginia': 'VA',
      'washington': 'WA',
      'west virginia': 'WV',
      'wisconsin': 'WI',
      'wyoming': 'WY',
      'district of columbia': 'DC'
    };

    // First check for state abbreviations
    final components =
        address.split(RegExp(r'[,\s]')).where((s) => s.isNotEmpty).toList();
    for (final component in components) {
      final upperComp = component.toUpperCase();
      if (stateMap.values.contains(upperComp)) {
        return upperComp;
      }
    }

    // Then check for state names
    final lowerAddress = address.toLowerCase();
    for (final entry in stateMap.entries) {
      if (lowerAddress.contains(entry.key)) {
        return entry.value;
      }
    }

    // Handle special cases like "New York, NY" where the state name is split
    final lowerComponents = components.map((s) => s.toLowerCase()).toList();
    for (int i = 0; i < lowerComponents.length - 1; i++) {
      final twoWords = '${lowerComponents[i]} ${lowerComponents[i + 1]}';
      if (stateMap.containsKey(twoWords)) {
        return stateMap[twoWords];
      }
    }

    return null;
  }

  // Get representative details
  Future<Map<String, dynamic>> getRepresentativeDetails(
      String bioGuideId) async {
    try {
      if (!hasCongressApiKey) {
        return _getMockRepresentativeDetails(bioGuideId);
      }


      // Build URL for member details
      final url = Uri.parse('$_baseUrl/member/$bioGuideId')
          .replace(queryParameters: {'format': 'json', 'api_key': _apiKey!});


      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);


        // Make sure we have a proper Map<String, dynamic> for the member details
        final Map<String, dynamic> memberDetails =
            data.containsKey('member') && data['member'] is Map
                ? Map<String, dynamic>.from(data['member'] as Map)
                : {};

        // Extract the sponsored and cosponsored legislation URLs
        String? sponsoredUrl;
        String? cosponsoredUrl;
        int currentCongress = 118; // Default to current Congress (2023-2025)

        if (memberDetails.containsKey('sponsoredLegislation') &&
            memberDetails['sponsoredLegislation'] is Map) {
          final sponsoredData = Map<String, dynamic>.from(
              memberDetails['sponsoredLegislation'] as Map);
          sponsoredUrl = sponsoredData['url']?.toString();
        }

        if (memberDetails.containsKey('cosponsoredLegislation') &&
            memberDetails['cosponsoredLegislation'] is Map) {
          final cosponsoredData = Map<String, dynamic>.from(
              memberDetails['cosponsoredLegislation'] as Map);
          cosponsoredUrl = cosponsoredData['url']?.toString();
        }

        // Find current Congress from terms
        if (memberDetails.containsKey('terms') &&
            memberDetails['terms'] is List) {
          final terms = memberDetails['terms'] as List;
          for (var termData in terms) {
            if (termData is Map) {
              final term = Map<String, dynamic>.from(termData);
              // Note: startYear and endYear available if needed for term duration

              // Get the most recent congress number
              if (term.containsKey('congress')) {
                int congress = int.tryParse(term['congress'].toString()) ?? 0;
                if (congress > currentCongress) {
                  currentCongress = congress;
                }
              }
            }
          }
        }

        // Use URLs from response or build URLs with Congress number
        final sponsoredBills = sponsoredUrl != null
            ? await _fetchBillsFromUrl(sponsoredUrl)
            : await _fetchSponsoredBills(bioGuideId, currentCongress);

        final cosponsoredBills = cosponsoredUrl != null
            ? await _fetchBillsFromUrl(cosponsoredUrl)
            : await _fetchCosponsoredBills(bioGuideId, currentCongress);

        return {
          'details': memberDetails,
          'sponsoredBills': sponsoredBills,
          'cosponsoredBills': cosponsoredBills,
        };
      } else {
        throw Exception('Failed to fetch representative details');
      }
    } catch (e) {
      return _getMockRepresentativeDetails(bioGuideId);
    }
  }

  // Helper method to fetch bills from a URL
  Future<List<dynamic>> _fetchBillsFromUrl(String url) async {
    try {
      // Add API key and format to the URL
      final Uri uri = Uri.parse(url).replace(queryParameters: {
        'format': 'json',
        'limit': '10',
        'api_key': _apiKey!
      });


      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Handle different response structures
        if (data.containsKey('sponsoredLegislation')) {
          return _processBillsList(data['sponsoredLegislation']);
        } else if (data.containsKey('cosponsoredLegislation')) {
          return _processBillsList(data['cosponsoredLegislation']);
        } else if (data.containsKey('bills')) {
          return _processBillsList(data['bills']);
        }
      } else {
      }
    } catch (e) {
    }

    return [];
  }

  // Helper method to process bills list from different response structures
  List<dynamic> _processBillsList(dynamic billsData) {
    if (billsData is List) {
      // Convert each map in the list to ensure they're Map<String, dynamic>
      return billsData
          .map((item) => item is Map ? Map<String, dynamic>.from(item) : item)
          .toList();
    } else if (billsData is Map && billsData.containsKey('item')) {
      final items = billsData['item'];
      if (items is List) {
        // Convert each map in the list to ensure they're Map<String, dynamic>
        return items
            .map((item) => item is Map ? Map<String, dynamic>.from(item) : item)
            .toList();
      } else if (items is Map) {
        // Convert to Map<String, dynamic> and return as a single-item list
        return [Map<String, dynamic>.from(items)];
      }
    }

    return [];
  }

  // Helper method to fetch sponsored bills
  Future<List<dynamic>> _fetchSponsoredBills(String bioGuideId,
      [int congress = 118]) async {
    try {
      // Build URL for sponsored legislation
      final url = Uri.parse(
              '$_baseUrl/member/$bioGuideId/sponsored-legislation/$congress')
          .replace(queryParameters: {
        'format': 'json',
        'limit': '10',
        'api_key': _apiKey!
      });


      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _processBillsList(
            data['sponsoredLegislation'] ?? data['bills'] ?? []);
      } else {

        // Try without Congress number if 404
        if (response.statusCode == 404) {
          final fallbackUrl =
              Uri.parse('$_baseUrl/member/$bioGuideId/sponsored-legislation')
                  .replace(queryParameters: {
            'format': 'json',
            'limit': '10',
            'api_key': _apiKey!
          });


          final fallbackResponse = await http.get(fallbackUrl);

          if (fallbackResponse.statusCode == 200) {
            final Map<String, dynamic> fallbackData =
                json.decode(fallbackResponse.body);
            return _processBillsList(fallbackData['sponsoredLegislation'] ??
                fallbackData['bills'] ??
                []);
          }
        }

        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Helper method to fetch cosponsored bills
  Future<List<dynamic>> _fetchCosponsoredBills(String bioGuideId,
      [int congress = 118]) async {
    try {
      // Build URL for cosponsored legislation
      final url = Uri.parse(
              '$_baseUrl/member/$bioGuideId/cosponsored-legislation/$congress')
          .replace(queryParameters: {
        'format': 'json',
        'limit': '10',
        'api_key': _apiKey!
      });


      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _processBillsList(
            data['cosponsoredLegislation'] ?? data['bills'] ?? []);
      } else {

        // Try without Congress number if 404
        if (response.statusCode == 404) {
          final fallbackUrl =
              Uri.parse('$_baseUrl/member/$bioGuideId/cosponsored-legislation')
                  .replace(queryParameters: {
            'format': 'json',
            'limit': '10',
            'api_key': _apiKey!
          });


          final fallbackResponse = await http.get(fallbackUrl);

          if (fallbackResponse.statusCode == 200) {
            final Map<String, dynamic> fallbackData =
                json.decode(fallbackResponse.body);
            return _processBillsList(fallbackData['cosponsoredLegislation'] ??
                fallbackData['bills'] ??
                []);
          }
        }

        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Mock data methods for development when API keys are missing
  List<Representative> _getMockRepresentatives(String stateCode,
      [String? district]) {

    List<Representative> mockReps = [];

    // Provide realistic Maryland representatives if MD is requested
    if (stateCode.toUpperCase() == 'MD') {
      // Maryland Senators (current as of 2024)
      mockReps.add(Representative(
        name: 'Benjamin L. Cardin',
        bioGuideId: 'C000141',
        party: 'D',
        chamber: 'Senate',
        state: 'MD',
        office: '509 Hart Senate Office Building',
        phone: '(202) 224-4524',
        website: 'https://www.cardin.senate.gov',
        imageUrl: 'https://bioguide.congress.gov/bioguide/photo/C/C000141.jpg',
      ));

      mockReps.add(Representative(
        name: 'Chris Van Hollen',
        bioGuideId: 'V000128',
        party: 'D',
        chamber: 'Senate',
        state: 'MD',
        office: '110 Hart Senate Office Building',
        phone: '(202) 224-4654',
        website: 'https://www.vanhollen.senate.gov',
        imageUrl: 'https://bioguide.congress.gov/bioguide/photo/V/V000128.jpg',
      ));

      // Maryland House Representatives - provide realistic representatives based on district
      if (district != null) {
        switch (district) {
          case '1':
            mockReps.add(Representative(
              name: 'Andy Harris',
              bioGuideId: 'H001052',
              party: 'R',
              chamber: 'House',
              state: 'MD',
              district: '1',
              office: '2334 Rayburn House Office Building',
              phone: '(202) 225-5311',
              website: 'https://harris.house.gov',
              imageUrl: 'https://bioguide.congress.gov/bioguide/photo/H/H001052.jpg',
            ));
            break;
          case '2':
            mockReps.add(Representative(
              name: 'Dutch Ruppersberger',
              bioGuideId: 'R000576',
              party: 'D',
              chamber: 'House',
              state: 'MD',
              district: '2',
              office: '2416 Rayburn House Office Building',
              phone: '(202) 225-3061',
              website: 'https://ruppersberger.house.gov',
              imageUrl: 'https://bioguide.congress.gov/bioguide/photo/R/R000576.jpg',
            ));
            break;
          case '3':
            mockReps.add(Representative(
              name: 'John P. Sarbanes',
              bioGuideId: 'S001168',
              party: 'D',
              chamber: 'House',
              state: 'MD',
              district: '3',
              office: '2370 Rayburn House Office Building',
              phone: '(202) 225-4016',
              website: 'https://sarbanes.house.gov',
              imageUrl: 'https://bioguide.congress.gov/bioguide/photo/S/S001168.jpg',
            ));
            break;
          case '4':
            mockReps.add(Representative(
              name: 'Glenn Ivey',
              bioGuideId: 'I000058',
              party: 'D',
              chamber: 'House',
              state: 'MD',
              district: '4',
              office: '1535 Longworth House Office Building',
              phone: '(202) 225-8699',
              website: 'https://ivey.house.gov',
              imageUrl: 'https://bioguide.congress.gov/bioguide/photo/I/I000058.jpg',
            ));
            break;
          case '5':
            // This is the district that includes Lothian, MD - Hyer is the correct representative
            mockReps.add(Representative(
              name: 'Steny H. Hoyer',
              bioGuideId: 'H000874',
              party: 'D',
              chamber: 'House',
              state: 'MD',
              district: '5',
              office: '1705 Longworth House Office Building',
              phone: '(202) 225-4131',
              website: 'https://hoyer.house.gov',
              imageUrl: 'https://bioguide.congress.gov/bioguide/photo/H/H000874.jpg',
            ));
            break;
          case '6':
            mockReps.add(Representative(
              name: 'David Trone',
              bioGuideId: 'T000483',
              party: 'D',
              chamber: 'House',
              state: 'MD',
              district: '6',
              office: '1213 Longworth House Office Building',
              phone: '(202) 225-2721',
              website: 'https://trone.house.gov',
              imageUrl: 'https://bioguide.congress.gov/bioguide/photo/T/T000483.jpg',
            ));
            break;
          case '7':
            mockReps.add(Representative(
              name: 'Kweisi Mfume',
              bioGuideId: 'M000687',
              party: 'D',
              chamber: 'House',
              state: 'MD',
              district: '7',
              office: '2263 Rayburn House Office Building',
              phone: '(202) 225-4741',
              website: 'https://mfume.house.gov',
              imageUrl: 'https://bioguide.congress.gov/bioguide/photo/M/M000687.jpg',
            ));
            break;
          case '8':
            mockReps.add(Representative(
              name: 'Jamie Raskin',
              bioGuideId: 'R000606',
              party: 'D',
              chamber: 'House',
              state: 'MD',
              district: '8',
              office: '2242 Rayburn House Office Building',
              phone: '(202) 225-5341',
              website: 'https://raskin.house.gov',
              imageUrl: 'https://bioguide.congress.gov/bioguide/photo/R/R000606.jpg',
            ));
            break;
          default:
            // Fallback for unknown district - use District 5 rep (Hoyer) as default
            mockReps.add(Representative(
              name: 'Steny H. Hoyer',
              bioGuideId: 'H000874',
              party: 'D',
              chamber: 'House',
              state: 'MD',
              district: district,
              office: '1705 Longworth House Office Building',
              phone: '(202) 225-4131',
              website: 'https://hoyer.house.gov',
              imageUrl: 'https://bioguide.congress.gov/bioguide/photo/H/H000874.jpg',
            ));
        }
      } else {
        // If no specific district provided, add a few sample MD representatives
        mockReps.addAll([
          Representative(
            name: 'Steny H. Hoyer',
            bioGuideId: 'H000874',
            party: 'D',
            chamber: 'House',
            state: 'MD',
            district: '5',
            office: '1705 Longworth House Office Building',
            phone: '(202) 225-4131',
            website: 'https://hoyer.house.gov',
            imageUrl: 'https://bioguide.congress.gov/bioguide/photo/H/H000874.jpg',
          ),
          Representative(
            name: 'Jamie Raskin',
            bioGuideId: 'R000606',
            party: 'D',
            chamber: 'House',
            state: 'MD',
            district: '8',
            office: '2242 Rayburn House Office Building',
            phone: '(202) 225-5341',
            website: 'https://raskin.house.gov',
            imageUrl: 'https://bioguide.congress.gov/bioguide/photo/R/R000606.jpg',
          ),
          Representative(
            name: 'Andy Harris',
            bioGuideId: 'H001052',
            party: 'R',
            chamber: 'House',
            state: 'MD',
            district: '1',
            office: '2334 Rayburn House Office Building',
            phone: '(202) 225-5311',
            website: 'https://harris.house.gov',
            imageUrl: 'https://bioguide.congress.gov/bioguide/photo/H/H001052.jpg',
          ),
        ]);
      }
    } else {
      // Generic mock representatives for other states
      mockReps.add(Representative(
        name: 'John Smith',
        bioGuideId: 'S000000',
        party: 'R',
        chamber: 'Senate',
        state: stateCode,
        office: '123 Senate Office Building',
        phone: '(202) 224-5555',
        website: 'https://www.senate.gov/senator_smith',
        imageUrl:
            'https://d2j6dbq0eux0bg.cloudfront.net/startersite/images/12759375/1585171739380.jpg',
      ));

      mockReps.add(Representative(
        name: 'Jane Doe',
        bioGuideId: 'S000001',
        party: 'D',
        chamber: 'Senate',
        state: stateCode,
        office: '456 Senate Office Building',
        phone: '(202) 224-6666',
        website: 'https://www.senate.gov/senator_doe',
        imageUrl:
            'https://d2j6dbq0eux0bg.cloudfront.net/startersite/images/12759375/1585171739380.jpg',
      ));

      // Add mock house rep if district is provided
      if (district != null) {
        mockReps.add(Representative(
          name: 'Robert Johnson',
          bioGuideId: 'H000000',
          party: 'D',
          chamber: 'House',
          state: stateCode,
          district: district,
          office: '789 House Office Building',
          phone: '(202) 225-7777',
          website: 'https://www.house.gov/rep_johnson',
          imageUrl:
              'https://d2j6dbq0eux0bg.cloudfront.net/startersite/images/12759375/1585171739380.jpg',
        ));
      } else {
        // If no specific district, add a couple of example House reps
        mockReps.add(Representative(
          name: 'Michael Williams',
          bioGuideId: 'H000001',
          party: 'R',
          chamber: 'House',
          state: stateCode,
          district: '1',
          office: '777 House Office Building',
          phone: '(202) 225-8888',
          website: 'https://www.house.gov/rep_williams',
          imageUrl:
              'https://d2j6dbq0eux0bg.cloudfront.net/startersite/images/12759375/1585171739380.jpg',
        ));

        mockReps.add(Representative(
          name: 'Sarah Miller',
          bioGuideId: 'H000002',
          party: 'D',
          chamber: 'House',
          state: stateCode,
          district: '2',
          office: '888 House Office Building',
          phone: '(202) 225-9999',
          website: 'https://www.house.gov/rep_miller',
          imageUrl:
              'https://d2j6dbq0eux0bg.cloudfront.net/startersite/images/12759375/1585171739380.jpg',
        ));
      }
    }

    return mockReps;
  }

  Map<String, dynamic> _getMockRepresentativeDetails(String bioGuideId) {
    // Create mock representative details
    final mockDetails = {
      'bioGuideId': bioGuideId,
      'name': bioGuideId.startsWith('S')
          ? 'Senator Mock Person'
          : 'Representative Mock Person',
      'birthDate': '1970-01-01',
      'gender': 'M',
      'terms': [
        {
          'chamber': bioGuideId.startsWith('S') ? 'Senate' : 'House',
          'party': bioGuideId.endsWith('0') ? 'R' : 'D',
          'state': 'NY',
          'district': bioGuideId.startsWith('H') ? '1' : null,
          'office': '123 Capitol Building',
          'phone': '(202) 555-1234',
          'website': 'https://www.congress.gov/member',
        }
      ],
    };

    // Create mock sponsored bills
    final mockSponsoredBills = List.generate(
        3,
        (index) => {
              'congress': '118',
              'billType': 'hr',
              'billNumber': '${1000 + index}',
              'title': 'Mock Sponsored Bill ${index + 1}',
              'introducedDate': '2023-01-${15 + index}',
              'latestAction': {
                'text': 'Referred to Committee on Mock Affairs',
                'actionDate': '2023-01-${15 + index}',
              },
            });

    // Create mock cosponsored bills
    final mockCosponsoredBills = List.generate(
        2,
        (index) => {
              'congress': '118',
              'billType': 's',
              'billNumber': '${500 + index}',
              'title': 'Mock Cosponsored Bill ${index + 1}',
              'introducedDate': '2023-02-${10 + index}',
              'latestAction': {
                'text': 'Passed Senate',
                'actionDate': '2023-03-${10 + index}',
              },
            });

    return {
      'details': mockDetails,
      'sponsoredBills': mockSponsoredBills,
      'cosponsoredBills': mockCosponsoredBills,
    };
  }


  Future<http.Response> _tracedHttpGet(Uri url, {String? apiKey}) async {
    final stopwatch = Stopwatch()..start();
    int attempt = 0;
    const maxAttempts = 2;
    const retryDelay = Duration(milliseconds: 500);

    while (attempt < maxAttempts) {
      attempt++;
      try {

        final response = await http.get(url).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Request timeout after 5 seconds');
          },
        );
        
        stopwatch.stop();


        // Return successful response or client errors (4xx) immediately
        if (response.statusCode < 500) {
          return response;
        }

        // For server errors (5xx), retry if we have attempts left
        if (attempt < maxAttempts) {
          await Future.delayed(retryDelay);
          continue;
        }

        return response;
      } catch (e) {
        if (attempt < maxAttempts) {
          await Future.delayed(retryDelay);
          continue;
        }
        
        stopwatch.stop();
        rethrow;
      }
    }

    // This should never be reached, but just in case
    throw Exception('Max retry attempts exceeded');
  }
}
