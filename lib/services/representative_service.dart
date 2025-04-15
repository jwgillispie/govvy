// lib/services/representative_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  
  // Attempt to get API keys from environment variables
  // If not available, use mock data (no hardcoded API keys in production code)
  String? get _apiKey => dotenv.env['CONGRESS_API_KEY'];
  String? get _googleApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'];
  
  // Check if API keys are available
  bool get hasCongressApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  bool get hasGoogleMapsApiKey => _googleApiKey != null && _googleApiKey!.isNotEmpty;
  
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
      final geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_googleApiKey';
      
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
      final civicUrl = 'https://www.googleapis.com/civicinfo/v2/representatives?address=${Uri.encodeComponent(address)}&levels=country&roles=legislatorLowerBody&roles=legislatorUpperBody&key=$_googleApiKey';
      
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
  // Get representatives based on address
  Future<List<Representative>> getRepresentativesByAddress(String address) async {
    try {
      if (kDebugMode) {
        print('Searching for representatives at address: $address');
      }
      
      // Parse state from address
      final String? stateCode = _extractStateFromAddress(address);
      
      if (stateCode == null) {
        throw Exception('Could not identify a US state in the provided address. Please include state in your address.');
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
      
      // For now, just use mock data while developing the UI
      return _getMockRepresentatives(stateCode, district);
      
      // Later, uncomment this to use the real API
      // return getCurrentRepresentatives(stateCode, district);
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
      'alabama': 'AL', 'alaska': 'AK', 'arizona': 'AZ', 'arkansas': 'AR', 'california': 'CA',
      'colorado': 'CO', 'connecticut': 'CT', 'delaware': 'DE', 'florida': 'FL', 'georgia': 'GA',
      'hawaii': 'HI', 'idaho': 'ID', 'illinois': 'IL', 'indiana': 'IN', 'iowa': 'IA',
      'kansas': 'KS', 'kentucky': 'KY', 'louisiana': 'LA', 'maine': 'ME', 'maryland': 'MD',
      'massachusetts': 'MA', 'michigan': 'MI', 'minnesota': 'MN', 'mississippi': 'MS', 'missouri': 'MO',
      'montana': 'MT', 'nebraska': 'NE', 'nevada': 'NV', 'new hampshire': 'NH', 'new jersey': 'NJ',
      'new mexico': 'NM', 'new york': 'NY', 'north carolina': 'NC', 'north dakota': 'ND', 'ohio': 'OH',
      'oklahoma': 'OK', 'oregon': 'OR', 'pennsylvania': 'PA', 'rhode island': 'RI', 'south carolina': 'SC',
      'south dakota': 'SD', 'tennessee': 'TN', 'texas': 'TX', 'utah': 'UT', 'vermont': 'VT',
      'virginia': 'VA', 'washington': 'WA', 'west virginia': 'WV', 'wisconsin': 'WI', 'wyoming': 'WY',
      'district of columbia': 'DC'
    };
    
    // First check for state abbreviations
    final components = address.split(RegExp(r'[,\s]')).where((s) => s.isNotEmpty).toList();
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
      final twoWords = '${lowerComponents[i]} ${lowerComponents[i+1]}';
      if (stateMap.containsKey(twoWords)) {
        return stateMap[twoWords];
      }
    }
    
    return null;
  }
  // Get representative details
  Future<Map<String, dynamic>> getRepresentativeDetails(String bioGuideId) async {
    try {
      // For now, just use mock data while developing the UI
      return _getMockRepresentativeDetails(bioGuideId);
      
      // Later, uncomment this to use the real API with proper error handling
      /*
      if (!hasCongressApiKey) {
        return _getMockRepresentativeDetails(bioGuideId);
      }
      
      // Real API implementation here...
      */
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching representative details: $e');
      }
      return _getMockRepresentativeDetails(bioGuideId);
    }
  }
  
  // Mock data methods for development when API keys are missing
  List<Representative> _getMockRepresentatives(String stateCode, [String? district]) {
    List<Representative> mockReps = [];
    
    // Add mock senators
    mockReps.add(
      Representative(
        name: 'John Smith',
        bioGuideId: 'S000000',
        party: 'R',
        chamber: 'Senate',
        state: stateCode,
        office: '123 Senate Office Building',
        phone: '(202) 224-5555',
        website: 'https://www.senate.gov/senator_smith',
        imageUrl: 'https://via.placeholder.com/150',
      )
    );
    
    mockReps.add(
      Representative(
        name: 'Jane Doe',
        bioGuideId: 'S000001',
        party: 'D',
        chamber: 'Senate',
        state: stateCode,
        office: '456 Senate Office Building',
        phone: '(202) 224-6666',
        website: 'https://www.senate.gov/senator_doe',
        imageUrl: 'https://via.placeholder.com/150',
      )
    );
    
    // Add mock house rep if district is provided
    if (district != null) {
      mockReps.add(
        Representative(
          name: 'Robert Johnson',
          bioGuideId: 'H000000',
          party: 'D',
          chamber: 'House',
          state: stateCode,
          district: district,
          office: '789 House Office Building',
          phone: '(202) 225-7777',
          website: 'https://www.house.gov/rep_johnson',
          imageUrl: 'https://via.placeholder.com/150',
        )
      );
    }
    
    return mockReps;
  }
  
  Map<String, dynamic> _getMockRepresentativeDetails(String bioGuideId) {
    // Create mock representative details
    final mockDetails = {
      'bioGuideId': bioGuideId,
      'name': bioGuideId.startsWith('S') ? 'Senator Mock Person' : 'Representative Mock Person',
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
    final mockSponsoredBills = List.generate(3, (index) => {
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
    final mockCosponsoredBills = List.generate(2, (index) => {
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