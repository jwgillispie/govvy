// lib/services/cicero_service.dart - Updated
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/models/local_representative_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CiceroService {
  final String _baseUrl = 'https://cicero.azavea.com/v3.1';
  
  // Get API key from environment variables
  String? get _apiKey {
    final key = dotenv.env['CICERO_API_KEY'];
    
    if (kDebugMode) {
      if (key == null) {
        print('WARNING: CICERO_API_KEY not found in .env file');
      } else if (key.isEmpty) {
        print('WARNING: CICERO_API_KEY is empty in .env file');
      } else {
        // Only show first few chars for security
        print('CICERO_API_KEY found: ${key.substring(0, 3)}...');
      }
    }
    
    return key;
  }
  
  // Check if API key is available
  bool get hasApiKey {
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;
    if (kDebugMode && !hasKey) {
      print('Using mock data because Cicero API key is not available');
    }
    return hasKey;
  }
  
  // Get local representatives by address
  Future<List<LocalRepresentative>> getLocalRepresentativesByAddress(String address) async {
    try {
      if (!hasApiKey) {
        if (kDebugMode) {
          print('Cicero API key not found. Using mock data for development.');
        }
        return _getMockLocalRepresentatives();
      }
      
      // Build URL with address search
      final url = Uri.parse('$_baseUrl/official')
          .replace(queryParameters: {
            'search_loc': address,
            'key': _apiKey!,
            // Add filters to only get local data
            'district_type': 'COUNTY',  // County officials
            'district_type': 'CITY',    // City officials
            'district_type': 'PLACE',   // Other local jurisdictions
          });
      
      if (kDebugMode) {
        print('Calling Cicero API with address: $address');
        print('API URL: ${url.toString().replaceAll(_apiKey!, '[REDACTED]')}');
      }
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (kDebugMode) {
          print('Cicero API response received. Status: ${response.statusCode}');
        }
        
        // Check for errors
        if (data.containsKey('response') && 
            data['response'].containsKey('errors') && 
            data['response']['errors'].isNotEmpty) {
          throw Exception('Cicero API error: ${data['response']['errors']}');
        }
        
        // Extract officials
        List<LocalRepresentative> representatives = [];
        
        if (data.containsKey('response') && 
            data['response'].containsKey('results') && 
            data['response']['results'].containsKey('officials')) {
          
          final officials = data['response']['results']['officials'] as List<dynamic>;
          
          for (var officialData in officials) {
            final official = Map<String, dynamic>.from(officialData);
            
            // Filter for only local representatives using the district info
            if (_isLocalOfficial(official)) {
              representatives.add(_processCiceroOfficial(official));
            }
          }
        }
        
        return representatives;
      } else {
        if (kDebugMode) {
          print('Cicero API error: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Failed to fetch representatives: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local representatives: $e');
      }
      // Fallback to mock data on error
      return _getMockLocalRepresentatives();
    }
  }
  
  // Helper method to check if an official is local (county or city level)
  bool _isLocalOfficial(Map<String, dynamic> official) {
    if (official.containsKey('office') && 
        official['office'].containsKey('district') && 
        official['office']['district'].containsKey('district_type')) {
      
      final districtType = official['office']['district']['district_type'].toString().toUpperCase();
      
      // These are the district types we consider "local"
      return ['COUNTY', 'CITY', 'PLACE', 'TOWNSHIP', 'BOROUGH', 'TOWN', 'VILLAGE']
          .contains(districtType);
    }
    
    return false;
  }
  
  // Convert Cicero official format to LocalRepresentative model
  LocalRepresentative _processCiceroOfficial(Map<String, dynamic> official) {
    // Extract district info
    String level = 'Local';
    String district = '';
    String state = '';
    
    if (official.containsKey('office') && 
        official['office'].containsKey('district')) {
      
      final districtInfo = official['office']['district'];
      
      if (districtInfo.containsKey('district_type')) {
        level = districtInfo['district_type'].toString();
      }
      
      if (districtInfo.containsKey('name')) {
        district = districtInfo['name'].toString();
      }
      
      if (districtInfo.containsKey('state')) {
        state = districtInfo['state'].toString();
      }
    }
    
    // Extract contact info
    String? phone;
    String? email;
    String? website;
    List<String>? socialMedia;
    
    if (official.containsKey('phone_numbers') && 
        official['phone_numbers'] is List && 
        official['phone_numbers'].isNotEmpty) {
      phone = official['phone_numbers'][0].toString();
    }
    
    if (official.containsKey('email_addresses') && 
        official['email_addresses'] is List && 
        official['email_addresses'].isNotEmpty) {
      email = official['email_addresses'][0].toString();
    }
    
    if (official.containsKey('urls') && 
        official['urls'] is List && 
        official['urls'].isNotEmpty) {
      website = official['urls'][0].toString();
    }
    
    if (official.containsKey('channels') && 
        official['channels'] is List && 
        official['channels'].isNotEmpty) {
      socialMedia = (official['channels'] as List)
          .map((channel) => '${channel['type']}: ${channel['id']}')
          .cast<String>()
          .toList();
    }
    
    // Extract party info
    String party = '';
    if (official.containsKey('party')) {
      party = official['party'].toString();
    }
    
    // Extract image URL
    String? imageUrl;
    if (official.containsKey('photo_url')) {
      imageUrl = official['photo_url'].toString();
    }
    
    // Create a unique ID from official ID or from district and name
    String bioGuideId = 'cicero-';
    if (official.containsKey('id')) {
      bioGuideId += official['id'].toString();
    } else {
      bioGuideId += '${district.replaceAll(' ', '-')}-${official['first_name']}-${official['last_name']}';
    }
    
    return LocalRepresentative(
      name: '${official['first_name']} ${official['last_name']}',
      bioGuideId: bioGuideId,
      party: party,
      level: level,
      state: state,
      district: district,
      office: official['office']['name'],
      phone: phone,
      email: email,
      website: website,
      imageUrl: imageUrl,
      socialMedia: socialMedia,
    );
  }
  
  // Provide mock data for testing or when API is unavailable
  List<LocalRepresentative> _getMockLocalRepresentatives() {
    return [
      LocalRepresentative(
        name: 'Jane Smith',
        bioGuideId: 'cicero-mock-fulton-commission-1',
        party: 'Democratic',
        level: 'COUNTY',
        state: 'GA',
        district: 'Fulton County Commission District 1',
        office: 'County Commissioner',
        phone: '(404) 555-1234',
        email: 'jane.smith@fultoncountyga.gov',
        website: 'https://www.fultoncountyga.gov/commissioners/district1',
        imageUrl: 'https://example.com/commissioner1.jpg',
        socialMedia: ['Twitter: @janesmith', 'Facebook: JaneSmithFulton'],
      ),
      LocalRepresentative(
        name: 'John Doe',
        bioGuideId: 'cicero-mock-fulton-commission-2',
        party: 'Republican',
        level: 'COUNTY',
        state: 'GA',
        district: 'Fulton County Commission District 2',
        office: 'County Commissioner',
        phone: '(404) 555-5678',
        email: 'john.doe@fultoncountyga.gov',
        website: 'https://www.fultoncountyga.gov/commissioners/district2',
        imageUrl: 'https://example.com/commissioner2.jpg',
        socialMedia: ['Twitter: @johndoe', 'Facebook: JohnDoeFulton'],
      ),
      LocalRepresentative(
        name: 'Maria Rodriguez',
        bioGuideId: 'cicero-mock-atlanta-council-5',
        party: 'Democratic',
        level: 'CITY',
        state: 'GA',
        district: 'Atlanta City Council District 5',
        office: 'City Council Member',
        phone: '(404) 555-9012',
        email: 'maria.rodriguez@atlantaga.gov',
        website: 'https://www.atlantaga.gov/government/council/district-5',
        imageUrl: 'https://example.com/councilmember5.jpg',
        socialMedia: ['Twitter: @mariarodriguez', 'Instagram: mariarodriguezatl'],
      ),
    ];
  }
}