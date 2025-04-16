// lib/services/cicero_service.dart
import 'dart:convert';
import 'dart:math';
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
  
  // Get local representatives by city name only
  Future<List<LocalRepresentative>> getLocalRepresentativesByCity(String city) async {
    try {
      if (!hasApiKey) {
        if (kDebugMode) {
          print('Cicero API key not found. Using mock data for development.');
        }
        return _getMockLocalRepresentatives(city: city);
      }
      
      // Check if we have a state code in the city (e.g., "New York, NY")
      String cityName = city;
      String? stateCode;
      
      // Try to extract state code if provided in format "City, ST"
      final cityStatePattern = RegExp(r'^(.*),\s*([A-Za-z]{2})');
      final match = cityStatePattern.firstMatch(cityName);
      if (match != null) {
        cityName = match.group(1)!.trim();
        stateCode = match.group(2)!.toUpperCase();
        
        if (kDebugMode) {
          print('Extracted city: $cityName and state: $stateCode from input');
        }
      }
      
      // Try a known working approach - using search_loc with city and state
      // If state is missing, we'll try to guess based on city name
      final stateToTry = stateCode ?? _guessStateForCity(cityName);
      
      // Build a properly formatted search_loc string with city and state
      final searchLocString = '$cityName, $stateToTry, USA';
      
      if (kDebugMode) {
        print('Trying search_loc approach with: $searchLocString');
      }
      
      final searchLocUrl = Uri.parse('$_baseUrl/official')
          .replace(queryParameters: {
            'search_loc': searchLocString,
            'format': 'json',
            'key': _apiKey!,
            'max': '100',
          });
      
      if (kDebugMode) {
        print('API URL: ${searchLocUrl.toString().replaceAll(_apiKey!, '[REDACTED]')}');
      }
      
      try {
        // Attempt to fetch using the search_loc approach
        return await _fetchRepresentatives(searchLocUrl, cityName);
      } catch (firstError) {
        if (kDebugMode) {
          print('search_loc approach failed: $firstError');
          print('Trying with postal code fallback...');
        }
        
        // If that failed, maybe try a postal code approach if we can map the city to a known postal code
        final postalCode = _getCommonPostalCodeForCity(cityName, stateToTry);
        
        if (postalCode != null) {
          final postalUrl = Uri.parse('$_baseUrl/official')
              .replace(queryParameters: {
                'search_postal': postalCode,
                'search_country': 'US',
                'format': 'json',
                'key': _apiKey!,
                'max': '100',
              });
          
          if (kDebugMode) {
            print('Trying postal code approach with: $postalCode');
            print('API URL: ${postalUrl.toString().replaceAll(_apiKey!, '[REDACTED]')}');
          }
          
          try {
            return await _fetchRepresentatives(postalUrl, cityName);
          } catch (postalError) {
            if (kDebugMode) {
              print('Postal code approach failed: $postalError');
            }
            throw postalError;
          }
        } else {
          if (kDebugMode) {
            print('No postal code mapping available for $cityName');
          }
          throw firstError;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('All approaches failed for city $city: $e');
        print('Returning mock data instead.');
      }
      // When all else fails, return mock data
      return _getMockLocalRepresentatives(city: city);
    }
  }
  
  // Original method, kept for backward compatibility
  Future<List<LocalRepresentative>> getLocalRepresentativesByAddress(String address) async {
    try {
      if (!hasApiKey) {
        if (kDebugMode) {
          print('Cicero API key not found. Using mock data for development.');
        }
        return _getMockLocalRepresentatives();
      }
      
      // Check if this looks like just a city
      final trimmedAddress = address.trim();
      if (!trimmedAddress.contains(',') && !trimmedAddress.contains(' ')) {
        // This might be just a city name
        return getLocalRepresentativesByCity(trimmedAddress);
      }
      
      // Build URL with address search
      final url = Uri.parse('$_baseUrl/official')
          .replace(queryParameters: {
            'search_loc': address,
            'key': _apiKey!,
            // Add filters to only get local data
            'district_type': 'CITY,COUNTY,PLACE,TOWNSHIP,BOROUGH,TOWN,VILLAGE',  // Include all local district types
          });
      
      if (kDebugMode) {
        print('Calling Cicero API with address: $address');
        print('API URL: ${url.toString().replaceAll(_apiKey!, '[REDACTED]')}');
      }
      
      return await _fetchRepresentatives(url, null);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local representatives by address: $e');
      }
      // Fallback to mock data on error
      return _getMockLocalRepresentatives();
    }
  }
  Future<List<LocalRepresentative>> _fetchRepresentatives(Uri url, String? cityFilter) async {
  try {
    final response = await http.get(url);
    
    if (kDebugMode) {
      print('Cicero API response received. Status: ${response.statusCode}');
      print('Response body preview: ${response.body.substring(0, min(200, response.body.length))}...');
    }
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List<LocalRepresentative> representatives = [];
      
      // Check for errors in response
      if (data.containsKey('response') && 
          data['response'].containsKey('errors') && 
          data['response']['errors'] is List && 
          (data['response']['errors'] as List).isNotEmpty) {
        throw Exception('Cicero API error: ${data['response']['errors']}');
      }
      
      // Direct officials array in response
      if (data.containsKey('response') && 
          data['response'].containsKey('officials') && 
          data['response']['officials'] is List) {
        
        final officials = data['response']['officials'] as List;
        for (var officialData in officials) {
          if (officialData is Map) {
            representatives.add(_processCiceroOfficial(Map<String, dynamic>.from(officialData)));
          }
        }
      } 
      // Officials in results
      else if (data.containsKey('response') && 
              data['response'].containsKey('results') && 
              data['response']['results'] is Map) {
        
        final results = Map<String, dynamic>.from(data['response']['results'] as Map);
        
        // Check for officials directly in results
        if (results.containsKey('officials') && results['officials'] is List) {
          final officials = results['officials'] as List;
          for (var officialData in officials) {
            if (officialData is Map) {
              representatives.add(_processCiceroOfficial(Map<String, dynamic>.from(officialData)));
            }
          }
        }
        // Check for candidates with officials
        else if (results.containsKey('candidates') && results['candidates'] is List) {
          final candidates = results['candidates'] as List;
          
          for (var candidateData in candidates) {
            if (candidateData is Map) {
              final candidate = Map<String, dynamic>.from(candidateData);
              
              // Check for districts with officials
              if (candidate.containsKey('districts') && candidate['districts'] is List) {
                final districts = candidate['districts'] as List;
                
                for (var districtData in districts) {
                  if (districtData is Map) {
                    final district = Map<String, dynamic>.from(districtData);
                    
                    // Process officials in this district
                    if (district.containsKey('officials') && district['officials'] is List) {
                      final officials = district['officials'] as List;
                      
                      for (var officialData in officials) {
                        if (officialData is Map) {
                          representatives.add(_processCiceroOfficial(Map<String, dynamic>.from(officialData)));
                        }
                      }
                    }
                  }
                }
              }
              
              // Also check if the candidate itself has officials
              if (candidate.containsKey('officials') && candidate['officials'] is List) {
                final officials = candidate['officials'] as List;
                
                for (var officialData in officials) {
                  if (officialData is Map) {
                    representatives.add(_processCiceroOfficial(Map<String, dynamic>.from(officialData)));
                  }
                }
              }
            }
          }
        }
      }
      
      // Filter out duplicates (sometimes the API returns the same official multiple times)
      Map<String, LocalRepresentative> uniqueReps = {};
      for (var rep in representatives) {
        uniqueReps[rep.bioGuideId] = rep;
      }
      
      // If we found representatives, return them
      if (uniqueReps.isNotEmpty) {
        return uniqueReps.values.toList();
      }
      
      // No officials found - check if it's a geocoding error
      if (data.containsKey('response') && 
          data['response'].containsKey('results') && 
          data['response']['results'] is Map) {
        
        final results = Map<String, dynamic>.from(data['response']['results'] as Map);
        
        // Check if candidates array is empty (no geocoding results)
        if (results.containsKey('candidates') && 
            results['candidates'] is List && 
            (results['candidates'] as List).isEmpty) {
          throw Exception('No geocoding results found for this location');
        }
      }
      
      // If we get here, we found no representatives in a seemingly valid response
      if (kDebugMode) {
        print('No representatives found in API response structure.');
      }
      
      // Return empty list - caller will handle fallback
      return [];
    } else {
      if (kDebugMode) {
        print('Cicero API error: ${response.statusCode} - ${response.body}');
      }
      throw Exception('Failed to fetch representatives: ${response.statusCode}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching representatives: $e');
    }
    throw e;
  }
}
  
  // Helper method to extract district name from official
  String _getOfficialDistrict(Map<String, dynamic> official) {
    if (official.containsKey('office') && 
        official['office'].containsKey('district') && 
        official['office']['district'].containsKey('name')) {
      
      return official['office']['district']['name'].toString();
    }
    return '';
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
  // Extract basic information
  String firstName = official['first_name']?.toString() ?? '';
  String lastName = official['last_name']?.toString() ?? '';
  String middleInitial = official['middle_initial']?.toString() ?? '';
  String preferredName = official['preferred_name']?.toString() ?? '';
  
  // Use preferred name if available, otherwise use first name
  String displayFirstName = preferredName.isNotEmpty ? preferredName : firstName;
  
  // Build full name with middle initial if available
  String fullName = displayFirstName;
  if (middleInitial.isNotEmpty) {
    fullName += ' $middleInitial';
  }
  fullName += ' $lastName';
  
  // Extract party
  String party = official['party']?.toString() ?? '';
  
  // Extract district info from office object
  String level = 'Local';
  String district = '';
  String state = '';
  String officeName = '';
  
  if (official.containsKey('office') && official['office'] is Map) {
    final officeInfo = Map<String, dynamic>.from(official['office'] as Map);
    
    // Extract role/position
    if (officeInfo.containsKey('role')) {
      officeName = officeInfo['role']?.toString() ?? '';
    }
    
    // Extract district information
    if (officeInfo.containsKey('district') && officeInfo['district'] is Map) {
      final districtInfo = Map<String, dynamic>.from(officeInfo['district'] as Map);
      
      if (districtInfo.containsKey('district_type')) {
        level = districtInfo['district_type']?.toString() ?? 'Local';
      }
      
      if (districtInfo.containsKey('name')) {
        district = districtInfo['name']?.toString() ?? '';
      }
      
      if (districtInfo.containsKey('state')) {
        state = districtInfo['state']?.toString() ?? '';
      }
    }
  }
  
  // Fallback for state if not found in district
  if (state.isEmpty && official.containsKey('state')) {
    state = official['state']?.toString() ?? '';
  }
  
  // Extract contact information
  String? phone;
  String? email;
  String? website;
  List<String>? socialMedia;
  
  // Handle addresses array for contact info
  if (official.containsKey('addresses') && official['addresses'] is List) {
    final addresses = official['addresses'] as List;
    for (var addressObj in addresses) {
      if (addressObj is Map) {
        final address = Map<String, dynamic>.from(addressObj);
        
        // Get the first phone number we find
        if (phone == null && address.containsKey('phone')) {
          phone = address['phone']?.toString();
        }
        
        // Get the first fax number as fallback if no phone
        if (phone == null && address.containsKey('fax')) {
          phone = address['fax']?.toString();
        }
      }
    }
  }
  
  // Handle email addresses array
  if (official.containsKey('email_addresses') && 
      official['email_addresses'] is List && 
      (official['email_addresses'] as List).isNotEmpty) {
    email = (official['email_addresses'] as List)[0]?.toString();
  }
  
  // Handle URLs array
  if (official.containsKey('urls') && 
      official['urls'] is List && 
      (official['urls'] as List).isNotEmpty) {
    website = (official['urls'] as List)[0]?.toString();
  } else if (official.containsKey('web_form_url')) {
    website = official['web_form_url']?.toString();
  }
  
  // Extract social media from identifiers
  if (official.containsKey('identifiers') && official['identifiers'] is List) {
    final identifiers = official['identifiers'] as List;
    socialMedia = [];
    
    for (var idObj in identifiers) {
      if (idObj is Map) {
        final identifier = Map<String, dynamic>.from(idObj);
        if (identifier.containsKey('identifier_type') && identifier.containsKey('identifier')) {
          final type = identifier['identifier_type']?.toString() ?? '';
          final id = identifier['identifier']?.toString() ?? '';
          
          // Only add social media identifiers
          if (['twitter', 'facebook', 'instagram', 'youtube', 'linkedin'].contains(type.toLowerCase())) {
            socialMedia.add('$type: $id');
          }
        }
      }
    }
    
    // If no social media was found, set to null
    if (socialMedia.isEmpty) {
      socialMedia = null;
    }
  }
  
  // Extract image URL
  String? imageUrl;
  if (official.containsKey('photo_origin_url')) {
    imageUrl = official['photo_origin_url']?.toString();
  }
  
  // Create a unique ID using either id or sk field
  String bioGuideId = 'cicero-';
  if (official.containsKey('id')) {
    bioGuideId += official['id'].toString();
  } else if (official.containsKey('sk')) {
    // The surrogate key is more stable between terms
    bioGuideId += 'sk-${official['sk'].toString()}';
  } else {
    // Create a fallback ID from name and district
    String sanitizedDistrict = district.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');
    String sanitizedName = fullName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');
    bioGuideId += '${sanitizedDistrict}-${sanitizedName}';
  }
  
  return LocalRepresentative(
    name: fullName,
    bioGuideId: bioGuideId,
    party: party,
    level: level,
    state: state,
    district: district,
    office: officeName,
    phone: phone,
    email: email,
    website: website,
    imageUrl: imageUrl,
    socialMedia: socialMedia,
  );
}
  
  // Helper method with hardcoded coordinates for common US cities
  Map<String, double>? _getHardcodedCoordinatesForCity(String cityName) {
    // Map of city names to their coordinates
    final Map<String, Map<String, double>> cityCoordinates = {
      'new york': {'lat': 40.7128, 'lon': -74.0060},
      'los angeles': {'lat': 34.0522, 'lon': -118.2437},
      'chicago': {'lat': 41.8781, 'lon': -87.6298},
      'houston': {'lat': 29.7604, 'lon': -95.3698},
      'phoenix': {'lat': 33.4484, 'lon': -112.0740},
      'philadelphia': {'lat': 39.9526, 'lon': -75.1652},
      'san antonio': {'lat': 29.4241, 'lon': -98.4936},
      'san diego': {'lat': 32.7157, 'lon': -117.1611},
      'dallas': {'lat': 32.7767, 'lon': -96.7970},
      'san jose': {'lat': 37.3382, 'lon': -121.8863},
      'austin': {'lat': 30.2672, 'lon': -97.7431},
      'jacksonville': {'lat': 30.3322, 'lon': -81.6557},
      'san francisco': {'lat': 37.7749, 'lon': -122.4194},
      'indianapolis': {'lat': 39.7684, 'lon': -86.1581},
      'columbus': {'lat': 39.9612, 'lon': -82.9988},
      'seattle': {'lat': 47.6062, 'lon': -122.3321},
      'denver': {'lat': 39.7392, 'lon': -104.9903},
      'washington': {'lat': 38.9072, 'lon': -77.0369},
      'boston': {'lat': 42.3601, 'lon': -71.0589},
      'atlanta': {'lat': 33.7490, 'lon': -84.3880},
      'miami': {'lat': 25.7617, 'lon': -80.1918},
    };
    
    // Look for the city in our map (case insensitive)
    final lowerCityName = cityName.toLowerCase();
    
    // Check for exact match
    if (cityCoordinates.containsKey(lowerCityName)) {
      return cityCoordinates[lowerCityName];
    }
    
    // Check for partial match
    for (final entry in cityCoordinates.entries) {
      if (lowerCityName.contains(entry.key) || entry.key.contains(lowerCityName)) {
        return entry.value;
      }
    }
    
    // Check for city with state combo (e.g., "New York, NY")
    final cityStatePattern = RegExp(r'^(.*),\s*([A-Za-z]{2})');
    final match = cityStatePattern.firstMatch(cityName);
    if (match != null) {
      final city = match.group(1)!.trim().toLowerCase();
      if (cityCoordinates.containsKey(city)) {
        return cityCoordinates[city];
      }
      
      // Check for partial match with just the city part
      for (final entry in cityCoordinates.entries) {
        if (city.contains(entry.key) || entry.key.contains(city)) {
          return entry.value;
        }
      }
    }
    
    // No match found
    return null;
  }
  
  // Provide mock data for testing or when API is unavailable
  List<LocalRepresentative> _getMockLocalRepresentatives({String? city}) {
    // Return city-specific mock data if a city is provided
    if (city != null) {
      final cityName = city.toLowerCase();
      
      if (cityName == 'atlanta' || cityName == 'fulton') {
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
            // Use a placeholder instead of a real URL to avoid 404 errors
            imageUrl: null,
            socialMedia: ['Twitter: @janesmith', 'Facebook: JaneSmithFulton'],
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
            // Use a placeholder instead of a real URL to avoid 404 errors
            imageUrl: null,
            socialMedia: ['Twitter: @mariarodriguez', 'Instagram: mariarodriguezatl'],
          ),
        ];
      } else if (cityName == 'chicago' || cityName == 'cook') {
        return [
          LocalRepresentative(
            name: 'Michael Johnson',
            bioGuideId: 'cicero-mock-chicago-council-7',
            party: 'Democratic',
            level: 'CITY',
            state: 'IL',
            district: 'Chicago City Council Ward 7',
            office: 'City Alderman',
            phone: '(312) 555-7890',
            email: 'michael.johnson@cityofchicago.org',
            website: 'https://www.chicago.gov/city/en/about/wards/7.html',
            // Use a placeholder instead of a real URL to avoid 404 errors
            imageUrl: null,
            socialMedia: ['Twitter: @michaeljohnson', 'Facebook: MikeJohnsonChicago'],
          ),
          LocalRepresentative(
            name: 'Sarah Williams',
            bioGuideId: 'cicero-mock-cook-commission-3',
            party: 'Democratic',
            level: 'COUNTY',
            state: 'IL',
            district: 'Cook County Commission District 3',
            office: 'County Commissioner',
            phone: '(312) 555-4321',
            email: 'sarah.williams@cookcountyil.gov',
            website: 'https://www.cookcountyil.gov/commissioners/district3',
            // Use a placeholder instead of a real URL to avoid 404 errors
            imageUrl: null,
            socialMedia: ['Twitter: @sarahwilliams', 'Instagram: sarahwilliamscook'],
          ),
        ];
      } else {
        // For any other city, generate some generic local representatives
        final String stateName = _getStateNameForCity(cityName);
        final String stateCode = _getStateCodeForCity(cityName);
        return [
          LocalRepresentative(
            name: 'Mayor ' + _capitalizeFirstLetter(cityName),
            bioGuideId: 'cicero-mock-${cityName.replaceAll(' ', '-')}-mayor',
            party: 'Independent',
            level: 'CITY',
            state: stateCode,
            district: '$cityName City',
            office: 'Mayor',
            phone: '(555) 555-1234',
            email: 'mayor@${cityName.replaceAll(' ', '')}.gov',
            website: 'https://www.${cityName.replaceAll(' ', '')}.gov',
            imageUrl: null,
            socialMedia: null,
          ),
          LocalRepresentative(
            name: 'Council Member Smith',
            bioGuideId: 'cicero-mock-${cityName.replaceAll(' ', '-')}-council-1',
            party: 'Democratic',
            level: 'CITY',
            state: stateCode,
            district: '$cityName City Council District 1',
            office: 'City Council Member',
            phone: '(555) 555-2345',
            email: 'council@${cityName.replaceAll(' ', '')}.gov',
            website: 'https://www.${cityName.replaceAll(' ', '')}.gov/council',
            imageUrl: null,
            socialMedia: null,
          ),
          LocalRepresentative(
            name: 'Commissioner Jones',
            bioGuideId: 'cicero-mock-${cityName.replaceAll(' ', '-')}-commissioner',
            party: 'Republican',
            level: 'COUNTY',
            state: stateCode,
            district: '$stateName County',
            office: 'County Commissioner',
            phone: '(555) 555-3456',
            email: 'commissioner@county.gov',
            website: 'https://www.county.gov',
            imageUrl: null,
            socialMedia: null,
          ),
        ];
      }
    }
    
    // Default mock data
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
        // Use a placeholder instead of a real URL to avoid 404 errors
        imageUrl: null,
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
        // Use a placeholder instead of a real URL to avoid 404 errors
        imageUrl: null,
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
        // Use a placeholder instead of a real URL to avoid 404 errors
        imageUrl: null,
        socialMedia: ['Twitter: @mariarodriguez', 'Instagram: mariarodriguezatl'],
      ),
    ];
  }
  
  // Helper to capitalize the first letter of each word
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text.split(' ')
      .map((word) => word.isNotEmpty 
        ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
        : '')
      .join(' ');
  }
  
  // Helper to get a state code for a city (simplified for mock data)
  String _getStateCodeForCity(String cityName) {
    // This is a very simplified mapping for mock data purposes
    final Map<String, String> cityToState = {
      'new york': 'NY',
      'los angeles': 'CA',
      'chicago': 'IL',
      'houston': 'TX',
      'phoenix': 'AZ',
      'philadelphia': 'PA',
      'san antonio': 'TX',
      'san diego': 'CA',
      'dallas': 'TX',
      'san jose': 'CA',
      'austin': 'TX',
      'jacksonville': 'FL',
      'san francisco': 'CA',
      'seattle': 'WA',
      'denver': 'CO',
      'boston': 'MA',
      'atlanta': 'GA',
      'miami': 'FL',
    };
    
    // Check for exact matches
    for (final entry in cityToState.entries) {
      if (cityName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default to a generic state code
    return 'CA';
  }
  
  // Helper to get a state name for a city (simplified for mock data)
  String _getStateNameForCity(String cityName) {
    // This is a very simplified mapping for mock data purposes
    final Map<String, String> cityToState = {
      'new york': 'New York',
      'los angeles': 'California',
      'chicago': 'Illinois',
      'houston': 'Texas',
      'phoenix': 'Arizona',
      'philadelphia': 'Pennsylvania',
      'san antonio': 'Texas',
      'san diego': 'California',
      'dallas': 'Texas',
      'san jose': 'California',
      'austin': 'Texas',
      'jacksonville': 'Florida',
      'san francisco': 'California',
      'seattle': 'Washington',
      'denver': 'Colorado',
      'boston': 'Massachusetts',
      'atlanta': 'Georgia',
      'miami': 'Florida',
    };
    
    // Check for exact matches
    for (final entry in cityToState.entries) {
      if (cityName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default to a generic state name
    return 'California';
  }
  
  // Helper method to guess the most likely state for a given city
  String _guessStateForCity(String cityName) {
    // Map of well-known cities to their most common state
    final Map<String, String> cityToState = {
      'new york': 'NY',
      'los angeles': 'CA',
      'chicago': 'IL',
      'houston': 'TX',
      'phoenix': 'AZ',
      'philadelphia': 'PA',
      'san antonio': 'TX',
      'san diego': 'CA',
      'dallas': 'TX',
      'san jose': 'CA',
      'austin': 'TX',
      'jacksonville': 'FL',
      'fort worth': 'TX',
      'columbus': 'OH',
      'indianapolis': 'IN',
      'charlotte': 'NC',
      'san francisco': 'CA',
      'seattle': 'WA',
      'denver': 'CO',
      'washington': 'DC',
      'boston': 'MA',
      'el paso': 'TX',
      'detroit': 'MI',
      'nashville': 'TN',
      'portland': 'OR',
      'memphis': 'TN',
      'oklahoma city': 'OK',
      'las vegas': 'NV',
      'louisville': 'KY',
      'baltimore': 'MD',
      'milwaukee': 'WI',
      'albuquerque': 'NM',
      'tucson': 'AZ',
      'fresno': 'CA',
      'sacramento': 'CA',
      'atlanta': 'GA',
      'miami': 'FL',
      'oakland': 'CA',
      'minneapolis': 'MN',
      'tampa': 'FL',
      'orlando': 'FL',
      'brooklyn': 'NY',
      'queens': 'NY',
      'manhattan': 'NY',
      'bronx': 'NY',
      'staten island': 'NY',
    };
    
    // Check for city in our map (case insensitive)
    final lowerCityName = cityName.toLowerCase();
    for (final entry in cityToState.entries) {
      if (lowerCityName == entry.key || lowerCityName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default to NY as a fallback
    return 'NY';
  }
  
  // Helper method to get a common postal code for a city
  // This is a fallback for when geocoding fails
  String? _getCommonPostalCodeForCity(String cityName, String stateCode) {
    // Map cities to common/central postal codes
    final Map<String, Map<String, String>> cityPostalCodes = {
      'NY': {
        'new york': '10001',    // Manhattan
        'brooklyn': '11201',
        'queens': '11101',
        'bronx': '10451',
        'staten island': '10301',
        'buffalo': '14201',
        'rochester': '14604',
        'yonkers': '10701',
        'syracuse': '13201',
        'albany': '12201',
      },
      'CA': {
        'los angeles': '90001',
        'san francisco': '94102',
        'san diego': '92101',
        'san jose': '95101',
        'oakland': '94601',
        'sacramento': '95814',
        'fresno': '93701',
        'long beach': '90802',
      },
      'IL': {
        'chicago': '60601',
        'aurora': '60501',
        'rockford': '61101',
        'joliet': '60431',
        'naperville': '60540',
      },
      'TX': {
        'houston': '77001',
        'dallas': '75201',
        'san antonio': '78201',
        'austin': '78701',
        'fort worth': '76101',
        'el paso': '79901',
      },
      'FL': {
        'miami': '33101',
        'orlando': '32801',
        'tampa': '33601',
        'jacksonville': '32201',
      }
    };
    
    // Look up the postal code for this city within the state
    final lowerCityName = cityName.toLowerCase();
    
    // If we have postal codes for this state
    if (cityPostalCodes.containsKey(stateCode)) {
      final stateCodes = cityPostalCodes[stateCode]!;
      
      // Look for exact match
      if (stateCodes.containsKey(lowerCityName)) {
        return stateCodes[lowerCityName];
      }
      
      // Or partial match
      for (final entry in stateCodes.entries) {
        if (lowerCityName.contains(entry.key) || entry.key.contains(lowerCityName)) {
          return entry.value;
        }
      }
    }
    
    // No match found
    return null;
  }
}