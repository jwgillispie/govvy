// lib/services/representative_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Representative {
  final String name;
  final String bioGuideId;
  final String party;
  final String chamber;
  final String state;
  final String? district;
  final String? imageUrl;
  final String? office;
  final String? phone;
  final String? website;

  Representative({
    required this.name,
    required this.bioGuideId,
    required this.party,
    required this.chamber,
    required this.state,
    this.district,
    this.imageUrl,
    this.office,
    this.phone,
    this.website,
  });

  factory Representative.fromJson(Map<String, dynamic> json) {
    return Representative(
      name: json['name'] ?? '',
      bioGuideId: json['bioGuideId'] ?? '',
      party: json['party'] ?? '',
      chamber: json['chamber'] ?? '',
      state: json['state'] ?? '',
      district: json['district'],
      imageUrl: json['imageUrl'],
      office: json['office'],
      phone: json['phone'],
      website: json['website'],
    );
  }
}

class RepresentativeService {
  final String _baseUrl = 'https://api.congress.gov/v3';

  // Get API keys from environment variables with improved debugging
  String? get _apiKey {
    final key = dotenv.env['CONGRESS_API_KEY'];
    
    if (kDebugMode) {
      if (key == null) {
        print('WARNING: CONGRESS_API_KEY not found in .env file');
      } else if (key.isEmpty) {
        print('WARNING: CONGRESS_API_KEY is empty in .env file');
      } else {
        // Only show first 3 chars for security
        print('CONGRESS_API_KEY found: Yes (${key.substring(0, min(3, key.length))}...)');
      }
    }
    
    return key;
  }
  
  String? get _googleApiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
    
    if (kDebugMode) {
      if (key == null) {
        print('WARNING: GOOGLE_MAPS_API_KEY not found in .env file');
      } else if (key.isEmpty) {
        print('WARNING: GOOGLE_MAPS_API_KEY is empty in .env file');
      } else {
        // Only show first 3 chars for security
        print('GOOGLE_MAPS_API_KEY found: Yes (${key.substring(0, min(3, key.length))}...)');
      }
    }
    
    return key;
  }

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
  
  Future<List<Representative>> getCurrentRepresentatives(String state, [String? district]) async {
    try {
      if (!hasCongressApiKey) {
        if (kDebugMode) {
          print('Congress API key not found. Using mock data.');
        }
        return _getMockRepresentatives(state, district);
      }
      
      List<Representative> representatives = [];
      
      // Fetch members from the API with improved URL construction
      final url = Uri.parse('$_baseUrl/member')
          .replace(queryParameters: {
            'state': state,
            'format': 'json',
            'limit': '100',
            'api_key': _apiKey!
          });
      
      if (kDebugMode) {
        print('Fetching representatives from API for state: $state');
        print('API URL: ${url.toString().replaceAll(_apiKey!, '[REDACTED]')}');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('API response received. Status: ${response.statusCode}');
          // Print first 100 chars of response to debug
          print('Response preview: ${response.body.substring(0, min(100, response.body.length))}...');
        }
        
        final data = json.decode(response.body);
        
        // Check if the response contains members
        if (data.containsKey('members') && data['members'] != null) {
          final members = data['members'];
          
          if (kDebugMode) {
            print('Members data type: ${members.runtimeType}');
            print('Members data: ${members.toString().substring(0, min(200, members.toString().length))}...');
          }
          
          // Handle different response structures
          if (members is List) {
            // Direct list of members
            if (kDebugMode) {
              print('Processing members as a List with ${members.length} items');
            }
            for (var member in members) {
              _processMemberData(member, state, district, representatives);
            }
          } else if (members is Map && members.containsKey('item') && members['item'] is List) {
            // Members inside 'item' array
            if (kDebugMode) {
              print('Processing members as a Map with item array: ${members['item'].length} items');
            }
            for (var member in members['item']) {
              _processMemberData(member, state, district, representatives);
            }
          } else if (members is Map) {
            // Just try to process the map directly as a single member
            if (kDebugMode) {
              print('Processing members as a single Map');
            }
            _processMemberData(members, state, district, representatives);
          } else {
            if (kDebugMode) {
              print('Unexpected members data structure: ${members.runtimeType}');
            }
          }
        } else {
          if (kDebugMode) {
            print('No members found in API response');
          }
        }
      } else {
        if (kDebugMode) {
          print('API error: ${response.statusCode} - ${response.body}');
        }
      }
      
      if (representatives.isEmpty) {
        if (kDebugMode) {
          print('No representatives found in API. Falling back to mock data.');
        }
        return _getMockRepresentatives(state, district);
      }
      
      if (kDebugMode) {
        print('Successfully found ${representatives.length} representatives for $state');
      }
      
      return representatives;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching representatives from API: $e');
        print('Falling back to mock data');
      }
      return _getMockRepresentatives(state, district);
    }
  }
  
  // Helper method to process member data and add to representatives list
  void _processMemberData(
    dynamic memberData, 
    String state, 
    String? district, 
    List<Representative> representatives
  ) {
    try {
      // Convert dynamic map to Map<String, dynamic> for better type safety
      final Map<String, dynamic> member = Map<String, dynamic>.from(memberData as Map);
      
      if (kDebugMode) {
        print('Processing member: ${member['bioguideId'] ?? 'unknown ID'} - ${member['name'] ?? 'unnamed'}');
        print('Member data: ${member.toString().substring(0, min(150, member.toString().length))}...');
      }
      
      String chamber = '';
      String memberState = '';
      String? memberDistrict;
      String? office;
      String? phone;
      String? website;
      String party = '';
      
      // Extract the chamber, state, and district information
      if (member.containsKey('terms')) {
        final terms = member['terms'];
        
        if (kDebugMode) {
          print('Terms data type: ${terms.runtimeType}');
          if (terms != null) {
            print('Terms data: ${terms.toString().substring(0, min(150, terms.toString().length))}...');
          } else {
            print('Terms data is null');
          }
        }
        
        if (terms is List && terms.isNotEmpty) {
          // Direct list of terms
          final term = Map<String, dynamic>.from(terms[0] as Map);  // Get the most recent term
          chamber = term['chamber'] ?? '';
          memberState = term['state'] ?? '';
          memberDistrict = term['district']?.toString();
          office = term['office'];
          phone = term['phone'];
          website = term['website'];
        } else if (terms is Map && terms.containsKey('item')) {
          final items = terms['item'];
          if (items is List && items.isNotEmpty) {
            // Get the most recent term (usually the first one in the list)
            final term = Map<String, dynamic>.from(items[0] as Map);
            chamber = term['chamber'] ?? '';
            memberState = term['state'] ?? '';
            memberDistrict = term['district']?.toString();
            office = term['office'];
            phone = term['phone'];
            website = term['website'];
          }
        }
      }
      
      // Try to get party information from different sources
      if (member.containsKey('partyName')) {
        party = member['partyName'] ?? '';
      } else if (member.containsKey('party')) {
        party = member['party'] ?? '';
      } else if (member.containsKey('current') && member['current'] is Map) {
        final current = Map<String, dynamic>.from(member['current'] as Map);
        if (current.containsKey('party')) {
          party = current['party'] ?? '';
        }
      }
      
      // Log state information for debugging
      if (kDebugMode) {
        print('Member state: $memberState, requested state: $state');
        print('Member chamber: $chamber, district: $memberDistrict');
      }
      
      // Skip if state doesn't match - but be flexible with capitalization and whitespace
      if (memberState.trim().toUpperCase() != state.trim().toUpperCase()) {
        if (kDebugMode) {
          print('Skipping member: state mismatch');
        }
        return;
      }
      
      // For House representatives, filter by district if provided
      if ((chamber == 'House of Representatives' || chamber == 'House') && 
          district != null && 
          memberDistrict != district) {
        if (kDebugMode) {
          print('Skipping House member: district mismatch');
        }
        return;
      }
      
      // Get image URL if available
      String? imageUrl;
      if (member.containsKey('depiction') && member['depiction'] != null) {
        if (member['depiction'] is Map) {
          final depiction = Map<String, dynamic>.from(member['depiction'] as Map);
          imageUrl = depiction['imageUrl'];
        }
      }
      
      // If no chamber is specified but we have a district, assume House
      if (chamber.isEmpty && memberDistrict != null) {
        chamber = 'House';
      }
      // If no chamber is specified and no district, guess based on bioguideId
      else if (chamber.isEmpty) {
        String bioguideId = member['bioguideId'] ?? '';
        if (bioguideId.startsWith('S')) {
          chamber = 'Senate';
        } else if (bioguideId.startsWith('H')) {
          chamber = 'House';
        }
      }
      
      // Extract representative information
      final rep = Representative(
        name: member['name'] ?? '',
        bioGuideId: member['bioguideId'] ?? '',
        party: party,
        chamber: chamber,
        state: memberState,
        district: memberDistrict,
        imageUrl: imageUrl,
        office: office,
        phone: phone,
        website: website,
      );
      
      representatives.add(rep);
      
      if (kDebugMode) {
        print('✅ Added representative: ${rep.name} (${rep.party}) - ${rep.chamber}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing member data: $e');
        print(e.toString());
      }
    }
  }

  // Get representatives based on address
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
      final district = districtInfo['district'];

      if (kDebugMode) {
        print('DistrictInfo: $districtInfo');
      }

      // Now use the API with our key
      return await getCurrentRepresentatives(stateCode, district);
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
        final data = json.decode(response.body);
        
        if (kDebugMode) {
          print('Successfully received representative details');
        }
        
        // Fetch sponsored bills
        final sponsoredBills = await _fetchSponsoredBills(bioGuideId);
        
        // Fetch cosponsored bills
        final cosponsoredBills = await _fetchCosponsoredBills(bioGuideId);
        
        return {
          'details': data['member'] ?? {},
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
  
  // Helper method to fetch sponsored bills
  Future<List<dynamic>> _fetchSponsoredBills(String bioGuideId) async {
    try {
      // Build URL for sponsored legislation
      final url = Uri.parse('$_baseUrl/member/$bioGuideId/sponsored-legislation')
          .replace(queryParameters: {
            'format': 'json',
            'limit': '10',
            'api_key': _apiKey!
          });
      
      if (kDebugMode) {
        print('Fetching sponsored bills');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sponsoredLegislation'] ?? [];
      } else {
        if (kDebugMode) {
          print('Error fetching sponsored bills: ${response.statusCode}');
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
  Future<List<dynamic>> _fetchCosponsoredBills(String bioGuideId) async {
    try {
      // Build URL for cosponsored legislation
      final url = Uri.parse('$_baseUrl/member/$bioGuideId/cosponsored-legislation')
          .replace(queryParameters: {
            'format': 'json',
            'limit': '10',
            'api_key': _apiKey!
          });
      
      if (kDebugMode) {
        print('Fetching cosponsored bills');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['cosponsoredLegislation'] ?? [];
      } else {
        if (kDebugMode) {
          print('Error fetching cosponsored bills: ${response.statusCode}');
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
}