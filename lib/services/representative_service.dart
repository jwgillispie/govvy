// lib/services/representative_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
    if (kDebugMode && !hasKey) {
      print('Using mock data because Congress API key is not available');
    }
    return hasKey;
  }
  
  bool get hasGoogleMapsApiKey {
    final hasKey = _googleApiKey != null && _googleApiKey!.isNotEmpty;
    if (kDebugMode && !hasKey) {
      print('Using mock data because Google Maps API key is not available');
    }
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

  // Get congressional district from address using Google's Geocoding API and Civic Information API
  Future<Map<String, dynamic>> getDistrictFromAddress(String address) async {
    try {
      // Check if Google Maps API key is available
      if (!hasGoogleMapsApiKey) {
        if (kDebugMode) {
          print('Google Maps API key not found. Using mock data for development.');
        }
        // Return mock data for development when API key is missing
        return {
          'state': 'FL',
          'district': '1',
          'latitude': 30.4383,
          'longitude': -87.2401
        };
      }

      // First, geocode the address to get coordinates
      final geocodeUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_googleApiKey';

      if (kDebugMode) {
        print('Calling Google Geocoding API with address: $address');
      }

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
          'https://www.googleapis.com/civicinfo/v2/representatives?address=${Uri.encodeComponent(address)}&levels=country&roles=legislatorLowerBody&roles=legislatorUpperBody&key=$_googleApiKey';

      if (kDebugMode) {
        print('Calling Google Civic API with address: $address');
      }

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

      if (kDebugMode) {
        print('Successfully extracted state: $state, district: $district');
      }

      return {
        'state': state,
        'district': district,
        'latitude': lat,
        'longitude': lng
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting district from address: $e');
      }
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
  Future<List<Representative>> getRepresentativesByStateDistrict(String state, [String? district]) async {
    try {
      if (!hasCongressApiKey) {
        if (kDebugMode) {
          print('Congress API key not found. Using mock data.');
        }
        return _getMockRepresentatives(state, district);
      }
      
      if (kDebugMode) {
        print('Fetching representatives for state: $state, district: $district');
      }
      
      List<Representative> representatives = [];
      
      // IMPROVED: Use direct state and district endpoints
      final Uri url;
      if (district != null) {
        // Endpoint specifically for members by state and district
        url = Uri.parse('$_baseUrl/member/$state/$district')
            .replace(queryParameters: {
              'format': 'json',
              'api_key': _apiKey!
            });
      } else {
        // Endpoint specifically for members by state
        url = Uri.parse('$_baseUrl/member/$state')
            .replace(queryParameters: {
              'format': 'json',
              'api_key': _apiKey!
            });
      }
      
      if (kDebugMode) {
        print('API URL: ${url.toString().replaceAll(_apiKey!, '[REDACTED]')}');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('API response received. Status: ${response.statusCode}');
        }
        
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Process members based on API response structure
        if (data.containsKey('members')) {
          final members = data['members'];
          
          if (members is List) {
            // Process direct list of members
            for (var memberRaw in members) {
              final member = Map<String, dynamic>.from(memberRaw);
              representatives.add(_processMember(member));
            }
          } else if (members is Map && members.containsKey('item')) {
            // Process members inside 'item' array
            final items = members['item'];
            if (items is List) {
              for (var itemRaw in items) {
                final item = Map<String, dynamic>.from(itemRaw);
                representatives.add(_processMember(item));
              }
            } else if (items is Map) {
              // Single item
              final item = Map<String, dynamic>.from(items);
              representatives.add(_processMember(item));
            }
          } else if (members is Map) {
            // Single member object
            final member = Map<String, dynamic>.from(members);
            representatives.add(_processMember(member));
          }
        }
      } else {
        if (kDebugMode) {
          print('API error: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Failed to fetch representatives data: ${response.statusCode}');
      }
      
      if (representatives.isEmpty) {
        if (kDebugMode) {
          print('No representatives found. Trying alternate method with query parameters.');
        }
        // Fall back to query parameter method if needed
        return await _getRepresentativesByQueryParams(state, district);
      }
      
      if (kDebugMode) {
        print('Successfully found ${representatives.length} representatives for $state');
      }
      
      return representatives;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching representatives from API: $e');
        print('Trying alternate method with query parameters.');
      }
      // Try alternative method before falling back to mock data
      try {
        return await _getRepresentativesByQueryParams(state, district);
      } catch (e2) {
        if (kDebugMode) {
          print('Error with alternate method: $e2');
          print('Falling back to mock data');
        }
        return _getMockRepresentatives(state, district);
      }
    }
  }
  
  // Alternative method using query parameters instead of path parameters
  Future<List<Representative>> _getRepresentativesByQueryParams(String state, [String? district]) async {
    try {
      if (!hasCongressApiKey) {
        return _getMockRepresentatives(state, district);
      }
      
      List<Representative> representatives = [];
      
      // Build query parameters
      Map<String, String> queryParams = {
        'format': 'json',
        'limit': '100',
        'state': state,
        'api_key': _apiKey!
      };
      
      // Add district if provided
      if (district != null) {
        queryParams['district'] = district;
      }
      
      // Use the generic members endpoint with filters
      final url = Uri.parse('$_baseUrl/member').replace(queryParameters: queryParams);
      
      if (kDebugMode) {
        print('Trying alternate API URL: ${url.toString().replaceAll(_apiKey!, '[REDACTED]')}');
      }
      
      final response = await http.get(url);
      
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
            representatives.add(_processMember(member));
          }
        } else if (members is Map && members.containsKey('item')) {
          final items = members['item'];
          if (items is List) {
            for (var itemRaw in items) {
              final item = Map<String, dynamic>.from(itemRaw);
              representatives.add(_processMember(item));
            }
          } else if (items is Map) {
            final item = Map<String, dynamic>.from(items);
            representatives.add(_processMember(item));
          }
        } else if (members is Map) {
          final member = Map<String, dynamic>.from(members);
          representatives.add(_processMember(member));
        }
      }
      
      if (representatives.isEmpty) {
        throw Exception('No representatives found in API response');
      }
      
      return representatives;
    } catch (e) {
      if (kDebugMode) {
        print('Error in alternate method: $e');
      }
      throw e; // Let the caller handle the error or fall back to mock data
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
    
    // Extract the most recent term information
    if (member.containsKey('terms') && member['terms'] != null) {
      final terms = member['terms'];
      
      if (terms is List && terms.isNotEmpty) {
        // Cast to Map<String, dynamic> to satisfy Dart type system
        final Map<String, dynamic> term = Map<String, dynamic>.from(terms[0] as Map);
        chamber = term['chamber']?.toString() ?? '';
        state = term['state']?.toString() ?? '';
        district = term['district']?.toString(); // Handle district as int or string
        office = term['office']?.toString();
        phone = term['phone']?.toString();
        website = term['website']?.toString();
        party = term['party']?.toString() ?? '';
      } else if (terms is Map && terms.containsKey('item')) {
        final items = terms['item'];
        if (items is List && items.isNotEmpty) {
          // Cast to Map<String, dynamic> to satisfy Dart type system
          final Map<String, dynamic> term = Map<String, dynamic>.from(items[0] as Map);
          chamber = term['chamber']?.toString() ?? '';
          state = term['state']?.toString() ?? '';
          district = term['district']?.toString(); // Handle district as int or string
          office = term['office']?.toString();
          phone = term['phone']?.toString();
          website = term['website']?.toString();
          party = term['party']?.toString() ?? '';
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
        final Map<String, dynamic> current = Map<String, dynamic>.from(member['current'] as Map);
        if (current.containsKey('party')) {
          party = current['party']?.toString() ?? '';
        }
      }
    }
    
    // Try to get address and phone information
    if (office == null && member.containsKey('addressInformation') && member['addressInformation'] is Map) {
      final Map<String, dynamic> addressInfo = Map<String, dynamic>.from(member['addressInformation'] as Map);
      office = addressInfo['officeAddress']?.toString();
      
      if (phone == null) {
        phone = addressInfo['phoneNumber']?.toString();
      }
    }
    
    // Get image URL
    String? imageUrl;
    if (member.containsKey('depiction') && member['depiction'] != null) {
      if (member['depiction'] is Map) {
        // Cast to Map<String, dynamic> to satisfy Dart type system
        final Map<String, dynamic> depiction = Map<String, dynamic>.from(member['depiction'] as Map);
        imageUrl = depiction['imageUrl']?.toString();
      }
    }
    
    // Get official website URL
    if (website == null && member.containsKey('officialWebsiteUrl')) {
      website = member['officialWebsiteUrl']?.toString();
    }
    
    // If bioguideId is available but image isn't, construct standard image URL
    if (imageUrl == null && member.containsKey('bioguideId') && member['bioguideId'] != null) {
      final bioguideId = member['bioguideId'].toString();
      if (bioguideId.isNotEmpty) {
        imageUrl = 'https://bioguide.congress.gov/bioguide/photo/${bioguideId[0]}/$bioguideId.jpg';
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
      name: member['name']?.toString() ?? member['invertedOrderName']?.toString() ?? member['directOrderName']?.toString() ?? '',
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

  // Get representatives based on address (legacy method, kept for compatibility)
  Future<List<Representative>> getRepresentativesByAddress(String address) async {
    try {
      if (kDebugMode) {
        print('Searching for representatives at address: $address');
      }

      // Parse state from address
      final String? stateCode = _extractStateFromAddress(address);

      if (stateCode == null) {
        throw Exception(
            'Could not identify a US state in the provided address. Please include state in your address.');
      }

      if (kDebugMode) {
        print('Extracted state: $stateCode');
      }

      // Get district info
      final districtInfo = await getDistrictFromAddress(address);
      final district = districtInfo['district']?.toString();

      if (kDebugMode) {
        print('DistrictInfo: $districtInfo');
      }

      // Use the improved method to get representatives
      return await getRepresentativesByStateDistrict(stateCode, district);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting representatives by address: $e');
      }
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
  Future<Map<String, dynamic>> getRepresentativeDetails(String bioGuideId) async {
    try {
      if (!hasCongressApiKey) {
        if (kDebugMode) {
          print('Congress API key not found. Using mock data for representative details.');
        }
        return _getMockRepresentativeDetails(bioGuideId);
      }
      
      if (kDebugMode) {
        print('Fetching representative details for bioGuideId: $bioGuideId');
      }
      
      // Build URL for member details
      final url = Uri.parse('$_baseUrl/member/$bioGuideId')
          .replace(queryParameters: {
            'format': 'json',
            'api_key': _apiKey!
          });
      
      if (kDebugMode) {
        print('API URL: ${url.toString().replaceAll(_apiKey!, '[REDACTED]')}');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (kDebugMode) {
          print('Successfully received representative details');
        }
        
        // Make sure we have a proper Map<String, dynamic> for the member details
        final Map<String, dynamic> memberDetails = data.containsKey('member') && data['member'] is Map
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
        if (memberDetails.containsKey('terms') && memberDetails['terms'] is List) {
          final terms = memberDetails['terms'] as List;
          for (var termData in terms) {
            if (termData is Map) {
              final term = Map<String, dynamic>.from(termData);
              final startYear = term['startYear'];
              final endYear = term['endYear'];
              
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
        if (kDebugMode) {
          print('API error: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Failed to fetch representative details');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching representative details: $e');
        print('Falling back to mock data');
      }
      return _getMockRepresentativeDetails(bioGuideId);
    }
  }
  
  // Helper method to fetch bills from a URL
  Future<List<dynamic>> _fetchBillsFromUrl(String url) async {
    try {
      // Add API key and format to the URL
      final Uri uri = Uri.parse(url).replace(
        queryParameters: {
          'format': 'json',
          'limit': '10',
          'api_key': _apiKey!
        }
      );
      
      if (kDebugMode) {
        print('Fetching bills from URL: ${uri.toString().replaceAll(_apiKey!, '[REDACTED]')}');
      }
      
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
        if (kDebugMode) {
          print('Error fetching bills from URL: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching bills from URL: $e');
      }
    }
    
    return [];
  }
  
  // Helper method to process bills list from different response structures
  List<dynamic> _processBillsList(dynamic billsData) {
    if (billsData is List) {
      // Convert each map in the list to ensure they're Map<String, dynamic>
      return billsData.map((item) => 
        item is Map ? Map<String, dynamic>.from(item) : item).toList();
    } else if (billsData is Map && billsData.containsKey('item')) {
      final items = billsData['item'];
      if (items is List) {
        // Convert each map in the list to ensure they're Map<String, dynamic>
        return items.map((item) => 
          item is Map ? Map<String, dynamic>.from(item) : item).toList();
      } else if (items is Map) {
        // Convert to Map<String, dynamic> and return as a single-item list
        return [Map<String, dynamic>.from(items)];
      }
    }
    
    return [];
  }
  
  // Helper method to fetch sponsored bills
  Future<List<dynamic>> _fetchSponsoredBills(String bioGuideId, [int congress = 118]) async {
    try {
      // Build URL for sponsored legislation
      final url = Uri.parse('$_baseUrl/member/$bioGuideId/sponsored-legislation/$congress')
          .replace(queryParameters: {
            'format': 'json',
            'limit': '10',
            'api_key': _apiKey!
          });
      
      if (kDebugMode) {
        print('Fetching sponsored bills for Congress $congress');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _processBillsList(data['sponsoredLegislation'] ?? data['bills'] ?? []);
      } else {
        if (kDebugMode) {
          print('Error fetching sponsored bills: ${response.statusCode}');
        }
        
        // Try without Congress number if 404
        if (response.statusCode == 404) {
          final fallbackUrl = Uri.parse('$_baseUrl/member/$bioGuideId/sponsored-legislation')
              .replace(queryParameters: {
                'format': 'json',
                'limit': '10',
                'api_key': _apiKey!
              });
              
          if (kDebugMode) {
            print('Trying without Congress number');
          }
          
          final fallbackResponse = await http.get(fallbackUrl);
          
          if (fallbackResponse.statusCode == 200) {
            final Map<String, dynamic> fallbackData = json.decode(fallbackResponse.body);
            return _processBillsList(fallbackData['sponsoredLegislation'] ?? fallbackData['bills'] ?? []);
          }
        }
        
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sponsored bills: $e');
      }
      return [];
    }
  }
  
  // Helper method to fetch cosponsored bills
  Future<List<dynamic>> _fetchCosponsoredBills(String bioGuideId, [int congress = 118]) async {
    try {
      // Build URL for cosponsored legislation
      final url = Uri.parse('$_baseUrl/member/$bioGuideId/cosponsored-legislation/$congress')
          .replace(queryParameters: {
            'format': 'json',
            'limit': '10',
            'api_key': _apiKey!
          });
      
      if (kDebugMode) {
        print('Fetching cosponsored bills for Congress $congress');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _processBillsList(data['cosponsoredLegislation'] ?? data['bills'] ?? []);
      } else {
        if (kDebugMode) {
          print('Error fetching cosponsored bills: ${response.statusCode}');
        }
        
        // Try without Congress number if 404
        if (response.statusCode == 404) {
          final fallbackUrl = Uri.parse('$_baseUrl/member/$bioGuideId/cosponsored-legislation')
              .replace(queryParameters: {
                'format': 'json',
                'limit': '10',
                'api_key': _apiKey!
              });
              
          if (kDebugMode) {
            print('Trying without Congress number');
          }
          
          final fallbackResponse = await http.get(fallbackUrl);
          
          if (fallbackResponse.statusCode == 200) {
            final Map<String, dynamic> fallbackData = json.decode(fallbackResponse.body);
            return _processBillsList(fallbackData['cosponsoredLegislation'] ?? fallbackData['bills'] ?? []);
          }
        }
        
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching cosponsored bills: $e');
      }
      return [];
    }
  }

  // Mock data methods for development when API keys are missing
  List<Representative> _getMockRepresentatives(String stateCode, [String? district]) {
    final stateName = _getStateNameForCode(stateCode);
    
    List<Representative> mockReps = [];

    // Add mock senators for the specified state
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
  
  // Helper method to get a state name from state code
  String _getStateNameForCode(String stateCode) {
    const Map<String, String> stateCodeMap = {
      'AL': 'Alabama',
      'AK': 'Alaska',
      'AZ': 'Arizona',
      'AR': 'Arkansas',
      'CA': 'California',
      'CO': 'Colorado',
      'CT': 'Connecticut',
      'DE': 'Delaware',
      'FL': 'Florida',
      'GA': 'Georgia',
      'HI': 'Hawaii',
      'ID': 'Idaho',
      'IL': 'Illinois',
      'IN': 'Indiana',
      'IA': 'Iowa',
      'KS': 'Kansas',
      'KY': 'Kentucky',
      'LA': 'Louisiana',
      'ME': 'Maine',
      'MD': 'Maryland',
      'MA': 'Massachusetts',
      'MI': 'Michigan',
      'MN': 'Minnesota',
      'MS': 'Mississippi',
      'MO': 'Missouri',
      'MT': 'Montana',
      'NE': 'Nebraska',
      'NV': 'Nevada',
      'NH': 'New Hampshire',
      'NJ': 'New Jersey',
      'NM': 'New Mexico',
      'NY': 'New York',
      'NC': 'North Carolina',
      'ND': 'North Dakota',
      'OH': 'Ohio',
      'OK': 'Oklahoma',
      'OR': 'Oregon',
      'PA': 'Pennsylvania',
      'RI': 'Rhode Island',
      'SC': 'South Carolina',
      'SD': 'South Dakota',
      'TN': 'Tennessee',
      'TX': 'Texas',
      'UT': 'Utah',
      'VT': 'Vermont',
      'VA': 'Virginia',
      'WA': 'Washington',
      'WV': 'West Virginia',
      'WI': 'Wisconsin',
      'WY': 'Wyoming',
      'DC': 'District of Columbia'
    };
    
    return stateCodeMap[stateCode.toUpperCase()] ?? stateCode;
  }
}