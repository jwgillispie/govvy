// lib/services/cicero_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:http/http.dart' as http;
import 'package:govvy/models/local_representative_model.dart';

class CiceroService {
  final String _baseUrl = 'https://cicero.azavea.com/v3.1';

  // Replace these with your actual Firebase Function URLs after deployment
// Update these URLs to point to your deployed functions
  final String _proxyBaseUrl =
      'https://us-central1-govvy--dev.cloudfunctions.net';
  final String _ciceroProxyUrl = '/ciceroProxy';
  final String _geocodeProxyUrl = '/geocodeProxy';
  // Get API keys from Remote Config
  String? get _apiKey => RemoteConfigService().getCiceroApiKey;
  String? get _googleApiKey => RemoteConfigService().getGoogleMapsApiKey;

  // Check if API key is available
  bool get hasApiKey {
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;
    if (kDebugMode && !hasKey) {
    }
    return hasKey;
  }

  bool get hasGoogleApiKey {
    final hasKey = _googleApiKey != null && _googleApiKey!.isNotEmpty;
    if (kDebugMode && !hasKey) {
    }
    return hasKey;
  }

  // Helper function to safely take a substring
  int min(int a, int b) => a < b ? a : b;

  // Function to geocode a city name to coordinates - updated for proxy
  Future<Map<String, double>?> geocodeCityToCoordinates(String city) async {
    try {
      if (kIsWeb) {
        // Use geocoding proxy for web with US-only restriction
        final url = Uri.parse('$_proxyBaseUrl$_geocodeProxyUrl')
            .replace(queryParameters: {
              'address': '$city, USA',
              'components': 'country:US'
            });


        final response = await http.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              'Geocoding API error: ${response.statusCode} - ${response.body}');
        }

        final data = jsonDecode(response.body);

        if (data['status'] != 'OK' || data['results'].isEmpty) {
          throw Exception('Geocoding error: ${data['status']}');
        }

        // Extract coordinates
        final location = data['results'][0]['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;


        return {'lat': lat, 'lng': lng};
      } else {
        // Original code for mobile
        if (!hasGoogleApiKey) {
          // Try using hardcoded coordinates first
          final hardcodedCoordinates = _getHardcodedCoordinatesForCity(city);
          if (hardcodedCoordinates != null) {
            return hardcodedCoordinates;
          }
          return null;
        }

        // First, check if the city has a state code (e.g., "Atlanta, GA")
        String searchCity = city;
        if (city.contains(',')) {
          // Keep the format as is to ensure better geocoding results
          searchCity = city;
        } else {
          // If no state is provided, try to guess based on city name
          final stateCode = _guessStateForCity(city);
          if (stateCode != null) {
            searchCity = '$city, $stateCode, USA';
          } else {
            searchCity = '$city, USA';
          }
        }


        // Call Google's Geocoding API with US restriction
        final url =
            Uri.parse('https://maps.googleapis.com/maps/api/geocode/json')
                .replace(queryParameters: {
          'address': searchCity,
          'components': 'country:US',
          'region': 'us',
          'key': _googleApiKey!
        });

        final response = await http.get(url);

        if (response.statusCode != 200) {
          throw Exception('Geocoding API error: ${response.statusCode}');
        }

        final data = jsonDecode(response.body);

        if (data['status'] != 'OK' || data['results'].isEmpty) {
          throw Exception('Geocoding error: ${data['status']}');
        }

        // Extract latitude and longitude
        final location = data['results'][0]['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;


        return {'lat': lat, 'lng': lng};
      }
    } catch (e) {

      // Fallback to hardcoded coordinates
      final hardcodedCoordinates = _getHardcodedCoordinatesForCity(city);
      if (hardcodedCoordinates != null) {
        return hardcodedCoordinates;
      }

      return null;
    }
  }

  // Get local representatives by city name - updated for proxy
  Future<List<LocalRepresentative>> getLocalRepresentativesByCity(
      String city) async {
    try {
      if (kIsWeb) {

        // First approach: Try geocoding and then passing coordinates to proxy
        try {
          // Get coordinates from geocoding
          final coordinates = await geocodeCityToCoordinates(city);

          if (coordinates == null) {
            throw Exception('Could not geocode city: $city');
          }

          // Use proxy with coordinates
          final url = Uri.parse('$_proxyBaseUrl$_ciceroProxyUrl')
              .replace(queryParameters: {
            'lat': coordinates['lat'].toString(),
            'lon': coordinates['lng'].toString(),
          });


          final response = await http.get(url);

          if (response.statusCode != 200) {
            throw Exception(
                'Proxy API error: ${response.statusCode} - ${response.body}');
          }

          final data = json.decode(response.body);

          // Process the data
          return _processResponseData(data, city);
        } catch (geoError) {
          if (kDebugMode) {
            print(
                'Geocode approach failed: $geoError, trying direct city search');
          }

          // Second approach: Use city name directly with proxy
          final url = Uri.parse('$_proxyBaseUrl$_ciceroProxyUrl')
              .replace(queryParameters: {'city': city});


          final response = await http.get(url);

          if (response.statusCode != 200) {
            throw Exception(
                'Proxy API error: ${response.statusCode} - ${response.body}');
          }

          final data = json.decode(response.body);

          // Process the data
          return _processResponseData(data, city);
        }
      } else {
        // Original code for mobile
        if (!hasApiKey) {
          return _getMockLocalRepresentatives(city: city);
        }


        // UPDATED APPROACH: First geocode the city to get coordinates
        final coordinates = await geocodeCityToCoordinates(city);

        if (coordinates == null) {
          throw Exception('Could not geocode city: $city');
        }

        // Use coordinates to search for representatives
        final url = Uri.parse('$_baseUrl/official').replace(queryParameters: {
          'lat': coordinates['lat'].toString(),
          'lon': coordinates['lng'].toString(),
          'format': 'json',
          'key': _apiKey!,
          'max': '100',
        });


        // Use the fetchRepresentatives method to handle the API call
        final representatives = await _fetchRepresentatives(url, city);

        if (kDebugMode) {
          print('Found ${representatives.length} representatives for $city');
        }

        return representatives;
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

  // Process API response data
  List<LocalRepresentative> _processResponseData(
      Map<String, dynamic> data, String? cityFilter) {
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
          representatives.add(
              _processCiceroOfficial(Map<String, dynamic>.from(officialData)));
        }
      }
    }
    // Officials in results
    else if (data.containsKey('response') &&
        data['response'].containsKey('results') &&
        data['response']['results'] is Map) {
      final results =
          Map<String, dynamic>.from(data['response']['results'] as Map);

      // Check for officials directly in results
      if (results.containsKey('officials') && results['officials'] is List) {
        final officials = results['officials'] as List;
        for (var officialData in officials) {
          if (officialData is Map) {
            representatives.add(_processCiceroOfficial(
                Map<String, dynamic>.from(officialData)));
          }
        }
      }
      // Check for candidates with officials
      else if (results.containsKey('candidates') &&
          results['candidates'] is List) {
        final candidates = results['candidates'] as List;

        for (var candidateData in candidates) {
          if (candidateData is Map) {
            final candidate = Map<String, dynamic>.from(candidateData);

            // Check for districts with officials
            if (candidate.containsKey('districts') &&
                candidate['districts'] is List) {
              final districts = candidate['districts'] as List;

              for (var districtData in districts) {
                if (districtData is Map) {
                  final district = Map<String, dynamic>.from(districtData);

                  // Process officials in this district
                  if (district.containsKey('officials') &&
                      district['officials'] is List) {
                    final officials = district['officials'] as List;

                    for (var officialData in officials) {
                      if (officialData is Map) {
                        representatives.add(_processCiceroOfficial(
                            Map<String, dynamic>.from(officialData)));
                      }
                    }
                  }
                }
              }
            }

            // Also check if the candidate itself has officials
            if (candidate.containsKey('officials') &&
                candidate['officials'] is List) {
              final officials = candidate['officials'] as List;

              for (var officialData in officials) {
                if (officialData is Map) {
                  representatives.add(_processCiceroOfficial(
                      Map<String, dynamic>.from(officialData)));
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

    return uniqueReps.values.toList();
  }

  // Get local representatives by address - updated for proxy
  Future<List<LocalRepresentative>> getLocalRepresentativesByAddress(
      String address) async {
    try {
      if (kIsWeb) {

        // Use proxy with address parameter
        final url = Uri.parse('$_proxyBaseUrl$_ciceroProxyUrl')
            .replace(queryParameters: {'address': address});


        final response = await http.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              'Proxy API error: ${response.statusCode} - ${response.body}');
        }

        final data = json.decode(response.body);

        // Process the data
        return _processResponseData(data, null);
      } else {
        // Original code for mobile
        if (!hasApiKey) {
          return _getMockLocalRepresentatives();
        }

        // Check if this looks like just a city
        final trimmedAddress = address.trim();
        if (!trimmedAddress.contains(',') && !trimmedAddress.contains(' ')) {
          // This might be just a city name
          return getLocalRepresentativesByCity(trimmedAddress);
        }

        // IMPROVED APPROACH: Try to geocode the address first
        final coordinates = await geocodeAddressToCoordinates(address);

        if (coordinates != null) {
          // Use coordinates to search for representatives
          final url = Uri.parse('$_baseUrl/official').replace(queryParameters: {
            'lat': coordinates['lat'].toString(),
            'lon': coordinates['lng'].toString(),
            'format': 'json',
            'key': _apiKey!,
            'max': '100',
            // Add filters to only get local data if needed
            'district_type': 'CITY,COUNTY,PLACE,TOWNSHIP,BOROUGH,TOWN,VILLAGE',
          });


          return await _fetchRepresentatives(url, null);
        }

        // Fallback to traditional search_loc approach
        final url = Uri.parse('$_baseUrl/official').replace(queryParameters: {
          'search_loc': address,
          'key': _apiKey!,
          'format': 'json',
          'max': '100',
          // Add filters to only get local data
          'district_type': 'CITY,COUNTY,PLACE,TOWNSHIP,BOROUGH,TOWN,VILLAGE',
        });


        return await _fetchRepresentatives(url, null);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local representatives by address: $e');
      }
      // Fallback to mock data on error
      return _getMockLocalRepresentatives();
    }
  }

  // Helper to geocode an address to coordinates
  Future<Map<String, double>?> geocodeAddressToCoordinates(
      String address) async {
    try {
      if (kIsWeb) {
        // Use geocoding proxy for web with US-only restriction
        final url = Uri.parse('$_proxyBaseUrl$_geocodeProxyUrl')
            .replace(queryParameters: {
              'address': '$address, USA',
              'components': 'country:US'
            });


        final response = await http.get(url);

        if (response.statusCode != 200) {
          throw Exception('Geocoding API error: ${response.statusCode}');
        }

        final data = jsonDecode(response.body);

        if (data['status'] != 'OK' || data['results'].isEmpty) {
          throw Exception('Geocoding error: ${data['status']}');
        }

        // Extract coordinates
        final location = data['results'][0]['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;

        return {'lat': lat, 'lng': lng};
      } else {
        if (!hasGoogleApiKey) {
          return null;
        }


        // Call Google's Geocoding API with US restriction
        final url =
            Uri.parse('https://maps.googleapis.com/maps/api/geocode/json')
                .replace(queryParameters: {
          'address': address,
          'components': 'country:US',
          'region': 'us',
          'key': _googleApiKey!
        });

        final response = await http.get(url);

        if (response.statusCode != 200) {
          throw Exception('Geocoding API error: ${response.statusCode}');
        }

        final data = jsonDecode(response.body);

        if (data['status'] != 'OK' || data['results'].isEmpty) {
          throw Exception('Geocoding error: ${data['status']}');
        }

        // Extract latitude and longitude
        final location = data['results'][0]['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;


        return {'lat': lat, 'lng': lng};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error geocoding address: $e');
      }
      return null;
    }
  }

  // Fetch representatives from API - Updated for web vs. mobile
  Future<List<LocalRepresentative>> _fetchRepresentatives(
      Uri url, String? cityFilter) async {
    try {
      final response = await http.get(url);


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _processResponseData(data, cityFilter);
      } else {
        if (kDebugMode) {
          print('Cicero API error: ${response.statusCode} - ${response.body}');
        }
        throw Exception(
            'Failed to fetch representatives: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching representatives: $e');
      }
      rethrow;
    }
  }

  // Get representatives by name - updated for proxy
  Future<List<LocalRepresentative>> getRepresentativesByName(String lastName,
      {String? firstName}) async {
    // Easter egg: Check for Josh Robinson
    final fullName = firstName != null ? '$firstName $lastName' : lastName;
    if (fullName.toLowerCase().contains('josh robinson') || 
        lastName.toLowerCase().contains('josh robinson') ||
        (firstName?.toLowerCase() == 'josh' && lastName.toLowerCase() == 'robinson')) {
      return _getJoshRobinsonMockData();
    }
    
    try {
      if (kIsWeb) {

        // Build query parameters
        final Map<String, String> queryParams = {
          'lastName': lastName,
        };

        if (firstName != null && firstName.isNotEmpty) {
          queryParams['firstName'] = firstName;
        }

        // Use proxy
        final url = Uri.parse('$_proxyBaseUrl$_ciceroProxyUrl')
            .replace(queryParameters: queryParams);


        final response = await http.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              'Proxy API error: ${response.statusCode} - ${response.body}');
        }

        final data = json.decode(response.body);

        // Process the data
        return _processResponseData(data, null);
      } else {
        // Original implementation for mobile
        if (!hasApiKey) {
          return _getMockLocalRepresentativesByName(lastName, firstName);
        }

        // Build query parameters
        Map<String, String> queryParams = {
          'last_name': lastName,
          'valid_range': 'ALL',
          'format': 'json',
          'key': _apiKey!
        };

        // Add first name if provided
        if (firstName != null && firstName.isNotEmpty) {
          queryParams['first_name'] = firstName;
        }

        // Use the official endpoint
        final url = Uri.parse('$_baseUrl/official')
            .replace(queryParameters: queryParams);


        final response = await http.get(url);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          List<LocalRepresentative> representatives = [];

          // Process officials
          if (data.containsKey('response') &&
              data['response'].containsKey('results') &&
              data['response']['results'].containsKey('officials')) {
            final officials = data['response']['results']['officials'];

            if (officials is List) {
              for (var officialData in officials) {
                if (officialData is Map) {
                  representatives.add(_processCiceroOfficial(
                      Map<String, dynamic>.from(officialData)));
                }
              }
            }
          }

          return representatives;
        } else {
          if (kDebugMode) {
            print('API error: ${response.statusCode} - ${response.body}');
          }
          throw Exception(
              'Failed to fetch representatives by name: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching representatives by name: $e');
      }
      return _getMockLocalRepresentativesByName(lastName, firstName);
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
      final districtType = official['office']['district']['district_type']
          .toString()
          .toUpperCase();

      // These are the district types we consider "local"
      return [
        'COUNTY',
        'CITY',
        'PLACE',
        'TOWNSHIP',
        'BOROUGH',
        'TOWN',
        'VILLAGE'
      ].contains(districtType);
    }

    return false;
  }

  // Update the _processCiceroOfficial method in lib/services/cicero_service.dart

  LocalRepresentative _processCiceroOfficial(Map<String, dynamic> official) {
    // Extract basic information
    String firstName = official['first_name']?.toString() ?? '';
    String lastName = official['last_name']?.toString() ?? '';
    String middleInitial = official['middle_initial']?.toString() ?? '';
    String preferredName = official['preferred_name']?.toString() ?? '';
    String nameSuffix = official['name_suffix']?.toString() ?? '';
    String salutation = official['salutation']?.toString() ?? '';

    // Use preferred name if available, otherwise use first name
    String displayFirstName =
        preferredName.isNotEmpty ? preferredName : firstName;

    // Build full name with salutation, middle initial and suffix if available
    String fullName = '';

    // Add salutation if it exists
    if (salutation.isNotEmpty) {
      fullName += '$salutation ';
    }

    // Add first/preferred name
    fullName += displayFirstName;

    // Add middle initial if available
    if (middleInitial.isNotEmpty) {
      fullName += ' $middleInitial';
    }

    // Add last name
    fullName += ' $lastName';

    // Add suffix if available
    if (nameSuffix.isNotEmpty) {
      fullName += ', $nameSuffix';
    }

    // Extract party
    String party = official['party']?.toString() ?? '';

    // Extract district info from office object
    String level = 'Local';
    String district = '';
    String state = '';
    String officeName = '';

    if (official.containsKey('office') && official['office'] is Map) {
      final officeInfo = Map<String, dynamic>.from(official['office'] as Map);

      // Extract role/position/title
      if (officeInfo.containsKey('title')) {
        officeName = officeInfo['title']?.toString() ?? '';
      }

      // Extract district information
      if (officeInfo.containsKey('district') && officeInfo['district'] is Map) {
        final districtInfo =
            Map<String, dynamic>.from(officeInfo['district'] as Map);

        // Get district type - this is the chamber/level like COUNTY, CITY, etc.
        if (districtInfo.containsKey('district_type')) {
          level = districtInfo['district_type']?.toString() ?? 'Local';
        }

        // Get district name - this is the specific district like "Alachua County", "Gainesville", etc.
        if (districtInfo.containsKey('label')) {
          district = districtInfo['label']?.toString() ?? '';
        } else if (districtInfo.containsKey('name')) {
          district = districtInfo['name']?.toString() ?? '';
        }

        // Get state
        if (districtInfo.containsKey('state')) {
          state = districtInfo['state']?.toString() ?? '';
        }
      }

      // Check for chamber name if level not set
      if (level == 'Local' &&
          officeInfo.containsKey('chamber') &&
          officeInfo['chamber'] is Map) {
        final chamberInfo =
            Map<String, dynamic>.from(officeInfo['chamber'] as Map);
        if (chamberInfo.containsKey('name_formal')) {
          level = chamberInfo['name_formal']?.toString() ?? level;
        } else if (chamberInfo.containsKey('name')) {
          level = chamberInfo['name']?.toString() ?? level;
        }
      }
    }

    // Fallback for state if not found in district
    if (state.isEmpty && official.containsKey('state')) {
      state = official['state']?.toString() ?? '';
    }

    // Extract contact information more thoroughly
    String? phone;
    String? email;
    String? website;
    List<String> socialMedia = [];

    // 1. Process addresses array for physical address and phone
    if (official.containsKey('addresses') && official['addresses'] is List) {
      final addresses = official['addresses'] as List;

      if (addresses.isNotEmpty) {
        // Use the first address - this is typically the main office
        final address = Map<String, dynamic>.from(addresses[0]);

        // Get phone number (primary or secondary)
        if (address.containsKey('phone_1') &&
            address['phone_1'] != null &&
            address['phone_1'].toString().isNotEmpty) {
          phone = address['phone_1']?.toString();
        } else if (address.containsKey('phone_2') &&
            address['phone_2'] != null &&
            address['phone_2'].toString().isNotEmpty) {
          phone = address['phone_2']?.toString();
        }
      }
    }

    // 2. Check direct phone fields if still not found
    if (phone == null || phone.isEmpty) {
      if (official.containsKey('phone_1') && official['phone_1'] != null) {
        phone = official['phone_1']?.toString();
      } else if (official.containsKey('phone_2') &&
          official['phone_2'] != null) {
        phone = official['phone_2']?.toString();
      }
    }

    // 3. Check email addresses array
    if (official.containsKey('email_addresses') &&
        official['email_addresses'] is List &&
        (official['email_addresses'] as List).isNotEmpty) {
      // Use first email address
      email = (official['email_addresses'] as List)[0]?.toString();
    }

    // 4. Check web form URL if email is not available
    if ((email == null || email.isEmpty) &&
        official.containsKey('web_form_url') &&
        official['web_form_url'].toString().isNotEmpty) {
      // Store contact form as email - it will be handled differently in the UI
      email = official['web_form_url']?.toString();
    }

    // 5. Check website URLs array
    if (official.containsKey('urls') &&
        official['urls'] is List &&
        (official['urls'] as List).isNotEmpty) {
      website = (official['urls'] as List)[0]?.toString();
    }

    // 6. Process social media from identifiers
    if (official.containsKey('identifiers') &&
        official['identifiers'] is List) {
      final identifiers = official['identifiers'] as List;

      for (var idObj in identifiers) {
        if (idObj is Map) {
          final identifier = Map<String, dynamic>.from(idObj);
          String type = '';
          String value = '';

          // Handle different identifier field naming
          if (identifier.containsKey('identifier_type')) {
            type = identifier['identifier_type']?.toString() ?? '';

            // Extract the value - could be in different fields
            if (identifier.containsKey('identifier_value')) {
              value = identifier['identifier_value']?.toString() ?? '';
            } else if (identifier.containsKey('identifier')) {
              value = identifier['identifier']?.toString() ?? '';
            }

            // Convert type to lowercase for consistency
            type = type.toLowerCase();

            // Only add social media or public identifiers
            if (([
                  'facebook',
                  'facebook-official',
                  'facebook-campaign',
                  'twitter',
                  'instagram',
                  'linkedin',
                  'youtube',
                  'flickr'
                ].contains(type)) &&
                value.isNotEmpty) {
              // If the value is a URL and not just a username, keep the full URL
              if (value.startsWith('http')) {
                socialMedia.add('$type: $value');
              } else {
                // For usernames, add the platform name
                socialMedia.add('$type: $value');
              }
            }
          }
        }
      }
    }

    // Extract image URL
    String? imageUrl;
    if (official.containsKey('photo_origin_url') &&
        official['photo_origin_url'] != null &&
        official['photo_origin_url'].toString().isNotEmpty) {
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
      String sanitizedDistrict =
          district.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');
      String sanitizedName = fullName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');
      bioGuideId += '$sanitizedDistrict-$sanitizedName';
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
      socialMedia: socialMedia.isEmpty ? null : socialMedia,
    );
  }
  // Add this new method to lib/services/cicero_service.dart

// Get local representatives by state code and city name
Future<List<LocalRepresentative>> getLocalRepresentativesByStateCity(String stateCode, String cityName) async {
  try {
    if (kIsWeb) {

      // Use proxy with state and city parameters
      final url = Uri.parse('$_proxyBaseUrl$_ciceroProxyUrl').replace(
        queryParameters: {
          'city': cityName,
          'state': stateCode,
        },
      );


      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Proxy API error: ${response.statusCode} - ${response.body}');
      }

      final data = json.decode(response.body);

      // Process the data
      return _processResponseData(data, '$cityName, $stateCode');
    } else {
      // Original code for mobile
      if (!hasApiKey) {
        if (kDebugMode) {
          print('Cicero API key not found. Using mock data for development.');
        }
        return _getMockLocalRepresentatives(city: '$cityName, $stateCode');
      }

      // For mobile implementation - we have two approaches:
      
      // Approach 1: Use state component restriction if available
      final queryParams = {
        'format': 'json',
        'key': _apiKey!,
        'max': '100',
      };
      
      // Add search location as city, state
      queryParams['search_loc'] = '$cityName, $stateCode';
      
      // Try to use components parameter to restrict results to the state
      queryParams['components'] = 'country:us|administrative_area:$stateCode';
      
      // URL for the Cicero API with the state and city
      final url = Uri.parse('$_baseUrl/official').replace(queryParameters: queryParams);


      try {
        // Try the direct API call first
        List<LocalRepresentative> representatives = await _fetchRepresentatives(url, '$cityName, $stateCode');

        if (representatives.isNotEmpty) {
          return representatives;
        }
        
        // If no results, fall back to geocoding approach
        if (kDebugMode) {
          print('No results from direct search, trying geocoding approach for $cityName, $stateCode');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error with direct search, trying geocoding approach: $e');
        }
      }

      // Approach 2: Geocode the city+state to coordinates
      final geocodeQuery = '$cityName, $stateCode, USA';
      final coordinates = await geocodeCityToCoordinates(geocodeQuery);

      if (coordinates == null) {
        throw Exception('Could not geocode $cityName, $stateCode');
      }

      // Use coordinates to search for representatives
      final coordUrl = Uri.parse('$_baseUrl/official').replace(queryParameters: {
        'lat': coordinates['lat'].toString(),
        'lon': coordinates['lng'].toString(),
        'format': 'json',
        'key': _apiKey!,
        'max': '100',
      });


      return await _fetchRepresentatives(coordUrl, '$cityName, $stateCode');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error getting representatives by state and city: $e');
    }
    // Fallback to mock data on error
    return _getMockLocalRepresentativesByStateCity(stateCode, cityName);
  }
}

// Helper method to generate mock data for state + city search
List<LocalRepresentative> _getMockLocalRepresentativesByStateCity(String stateCode, String cityName) {
  // Create specific mock data for common city+state combinations
  final String cityStatePair = '$cityName, $stateCode'.toLowerCase();
  
  if (cityStatePair == 'gainesville, fl') {
    return [
      LocalRepresentative(
        name: 'Harvey Ward',
        bioGuideId: 'cicero-mock-gainesville-fl-mayor',
        party: 'Democratic',
        level: 'CITY',
        state: 'FL',
        district: 'Gainesville',
        office: 'Mayor',
        phone: '(352) 555-1234',
        email: 'mayor@cityofgainesville.org',
        website: 'https://www.cityofgainesville.org',
        imageUrl: null,
        socialMedia: ['Twitter: @GvilleMayor'],
      ),
      LocalRepresentative(
        name: 'Casey Willits',
        bioGuideId: 'cicero-mock-gainesville-fl-commission-3',
        party: 'Democratic',
        level: 'CITY',
        state: 'FL',
        district: 'Gainesville City Commission District 3',
        office: 'City Commissioner',
        phone: '(352) 555-5678',
        email: 'willitsc@cityofgainesville.org',
        website: 'https://www.cityofgainesville.org/CityCommission',
        imageUrl: null,
        socialMedia: null,
      ),
      LocalRepresentative(
        name: 'Ken Cornell',
        bioGuideId: 'cicero-mock-alachua-fl-commission-4',
        party: 'Democratic',
        level: 'COUNTY',
        state: 'FL',
        district: 'Alachua County Commission District 4',
        office: 'County Commissioner',
        phone: '(352) 555-9012',
        email: 'kcornell@alachuacounty.us',
        website: 'https://alachuacounty.us/govt/bocc',
        imageUrl: null,
        socialMedia: ['Facebook: KenCornellAlachua'],
      ),
    ];
  } else if (cityStatePair == 'gainesville, ga') {
    return [
      LocalRepresentative(
        name: 'John Smith',
        bioGuideId: 'cicero-mock-gainesville-ga-mayor',
        party: 'Republican',
        level: 'CITY',
        state: 'GA',
        district: 'Gainesville',
        office: 'Mayor',
        phone: '(770) 555-1234',
        email: 'mayor@gainesville.org',
        website: 'https://www.gainesville.org',
        imageUrl: null,
        socialMedia: ['Twitter: @GainesvilleGAMayor'],
      ),
      LocalRepresentative(
        name: 'Barbara Miller',
        bioGuideId: 'cicero-mock-gainesville-ga-council-2',
        party: 'Republican',
        level: 'CITY',
        state: 'GA',
        district: 'Gainesville City Council Ward 2',
        office: 'City Council Member',
        phone: '(770) 555-5678',
        email: 'bmiller@gainesville.org',
        website: 'https://www.gainesville.org/city-council',
        imageUrl: null,
        socialMedia: null,
      ),
      LocalRepresentative(
        name: 'Richard Johnson',
        bioGuideId: 'cicero-mock-hall-ga-commission-3',
        party: 'Republican',
        level: 'COUNTY',
        state: 'GA',
        district: 'Hall County Commission District 3',
        office: 'County Commissioner',
        phone: '(770) 555-9012',
        email: 'rjohnson@hallcounty.org',
        website: 'https://www.hallcounty.org/commission',
        imageUrl: null,
        socialMedia: ['Facebook: RichardJohnsonHall'],
      ),
    ];
  } else if (cityStatePair == 'gainesville, tx') {
    return [
      LocalRepresentative(
        name: 'Tommy Moore',
        bioGuideId: 'cicero-mock-gainesville-tx-mayor',
        party: 'Republican',
        level: 'CITY',
        state: 'TX',
        district: 'Gainesville',
        office: 'Mayor',
        phone: '(940) 555-1234',
        email: 'mayor@gainesville.tx.gov',
        website: 'https://www.gainesville.tx.us',
        imageUrl: null,
        socialMedia: ['Twitter: @GainesvilleTXMayor'],
      ),
      LocalRepresentative(
        name: 'Mary Williamson',
        bioGuideId: 'cicero-mock-gainesville-tx-council-1',
        party: 'Republican',
        level: 'CITY',
        state: 'TX',
        district: 'Gainesville City Council Ward 1',
        office: 'City Council Member',
        phone: '(940) 555-5678',
        email: 'mwilliamson@gainesville.tx.gov',
        website: 'https://www.gainesville.tx.us/city-council',
        imageUrl: null,
        socialMedia: null,
      ),
      LocalRepresentative(
        name: 'Robert Davis',
        bioGuideId: 'cicero-mock-cooke-tx-commission-2',
        party: 'Republican',
        level: 'COUNTY',
        state: 'TX',
        district: 'Cooke County Commission Precinct 2',
        office: 'County Commissioner',
        phone: '(940) 555-9012',
        email: 'rdavis@cookecounty.tx.gov',
        website: 'https://www.co.cooke.tx.us',
        imageUrl: null,
        socialMedia: ['Facebook: RobertDavisCooke'],
      ),
    ];
  } else if (cityStatePair == 'portland, or') {
    return [
      LocalRepresentative(
        name: 'Ted Wheeler',
        bioGuideId: 'cicero-mock-portland-or-mayor',
        party: 'Democratic',
        level: 'CITY',
        state: 'OR',
        district: 'Portland',
        office: 'Mayor',
        phone: '(503) 555-1234',
        email: 'mayor@portland.gov',
        website: 'https://www.portland.gov/wheeler',
        imageUrl: null,
        socialMedia: ['Twitter: @tedwheeler'],
      ),
      LocalRepresentative(
        name: 'Jo Ann Hardesty',
        bioGuideId: 'cicero-mock-portland-or-council-1',
        party: 'Democratic',
        level: 'CITY',
        state: 'OR',
        district: 'Portland City Council Position 3',
        office: 'City Commissioner',
        phone: '(503) 555-5678',
        email: 'joann@portland.gov',
        website: 'https://www.portland.gov/hardesty',
        imageUrl: null,
        socialMedia: ['Twitter: @JoAnnPDX'],
      ),
    ];
  } else if (cityStatePair == 'portland, me') {
    return [
      LocalRepresentative(
        name: 'Kate Snyder',
        bioGuideId: 'cicero-mock-portland-me-mayor',
        party: 'Democratic',
        level: 'CITY',
        state: 'ME',
        district: 'Portland',
        office: 'Mayor',
        phone: '(207) 555-1234',
        email: 'mayor@portlandmaine.gov',
        website: 'https://www.portlandmaine.gov/mayor',
        imageUrl: null,
        socialMedia: null,
      ),
      LocalRepresentative(
        name: 'Spencer Thibodeau',
        bioGuideId: 'cicero-mock-portland-me-council-2',
        party: 'Democratic',
        level: 'CITY',
        state: 'ME',
        district: 'Portland City Council District 2',
        office: 'City Councilor',
        phone: '(207) 555-5678',
        email: 'sthibodeau@portlandmaine.gov',
        website: 'https://www.portlandmaine.gov/council',
        imageUrl: null,
        socialMedia: null,
      ),
    ];
  }
  
  // Default mock data with state-specific variations (includes state representatives)
  return [
    // Local officials (city level)
    LocalRepresentative(
      name: 'Mayor of $cityName',
      bioGuideId: 'cicero-mock-${cityName.toLowerCase().replaceAll(' ', '-')}-$stateCode-mayor',
      party: stateCode == 'CA' || stateCode == 'NY' || stateCode == 'IL' ? 'Democratic' : 'Republican',
      level: 'CITY',
      state: stateCode,
      district: cityName,
      office: 'Mayor',
      phone: '(555) 555-1234',
      email: 'mayor@${cityName.toLowerCase().replaceAll(' ', '')}.gov',
      website: 'https://www.${cityName.toLowerCase().replaceAll(' ', '')}.gov',
      imageUrl: null,
      socialMedia: null,
    ),
    LocalRepresentative(
      name: 'Council Member Smith',
      bioGuideId: 'cicero-mock-${cityName.toLowerCase().replaceAll(' ', '-')}-$stateCode-council-1',
      party: stateCode == 'CA' || stateCode == 'NY' || stateCode == 'IL' ? 'Democratic' : 'Republican',
      level: 'CITY',
      state: stateCode,
      district: '$cityName City Council District 1',
      office: 'City Council Member',
      phone: '(555) 555-2345',
      email: 'council@${cityName.toLowerCase().replaceAll(' ', '')}.gov',
      website: 'https://www.${cityName.toLowerCase().replaceAll(' ', '')}.gov/council',
      imageUrl: null,
      socialMedia: null,
    ),
    
    // County level officials
    LocalRepresentative(
      name: 'Commissioner Jones',
      bioGuideId: 'cicero-mock-${cityName.toLowerCase().replaceAll(' ', '-')}-$stateCode-commissioner',
      party: stateCode == 'CA' || stateCode == 'NY' || stateCode == 'IL' ? 'Democratic' : 'Republican',
      level: 'COUNTY',
      state: stateCode,
      district: stateCode == 'FL' ? 'Dade County' : (stateCode == 'GA' ? 'Fulton County' : 'County'),
      office: 'County Commissioner',
      phone: '(555) 555-3456',
      email: 'commissioner@county.gov',
      website: 'https://www.county.gov',
      imageUrl: null,
      socialMedia: null,
    ),
    
    // State level officials (these will be moved to federal list by the provider)
    LocalRepresentative(
      name: 'Senator Williams',
      bioGuideId: 'cicero-mock-${cityName.toLowerCase().replaceAll(' ', '-')}-$stateCode-state-senate',
      party: stateCode == 'CA' || stateCode == 'NY' || stateCode == 'IL' ? 'Democratic' : 'Republican',
      level: 'STATE_UPPER',
      state: stateCode,
      district: '$stateCode State Senate District 15',
      office: 'State Senator',
      phone: '(555) 555-4567',
      email: 'senator.williams@state.$stateCode.gov',
      website: 'https://www.legislature.$stateCode.gov/senators/williams',
      imageUrl: null,
      socialMedia: ['Twitter: @SenWilliams$stateCode'],
    ),
    LocalRepresentative(
      name: 'Representative Johnson',
      bioGuideId: 'cicero-mock-${cityName.toLowerCase().replaceAll(' ', '-')}-$stateCode-state-house',
      party: stateCode == 'CA' || stateCode == 'NY' || stateCode == 'IL' ? 'Democratic' : 'Republican',
      level: 'STATE_LOWER',
      state: stateCode,
      district: '$stateCode State House District 42',
      office: 'State Representative',
      phone: '(555) 555-5678',
      email: 'rep.johnson@state.$stateCode.gov',
      website: 'https://www.legislature.$stateCode.gov/representatives/johnson',
      imageUrl: null,
      socialMedia: ['Twitter: @Rep$stateCode'],
    ),
  ];
}

  // Helper method with hardcoded coordinates for common US cities
  Map<String, double>? _getHardcodedCoordinatesForCity(String cityName) {
    // Normalize input
    final normalized = cityName.toLowerCase().trim();

    // Extract just the city if it has a state code (e.g. "Atlanta, GA" -> "atlanta")
    String cityToLookup = normalized;
    if (normalized.contains(',')) {
      cityToLookup = normalized.split(',')[0].trim();
    }

    // Map of city names to their coordinates
    final Map<String, Map<String, double>> cityCoordinates = {
      'new york': {'lat': 40.7128, 'lng': -74.0060},
      'los angeles': {'lat': 34.0522, 'lng': -118.2437},
      'chicago': {'lat': 41.8781, 'lng': -87.6298},
      'houston': {'lat': 29.7604, 'lng': -95.3698},
      'phoenix': {'lat': 33.4484, 'lng': -112.0740},
      'philadelphia': {'lat': 39.9526, 'lng': -75.1652},
      'san antonio': {'lat': 29.4241, 'lng': -98.4936},
      'san diego': {'lat': 32.7157, 'lng': -117.1611},
      'dallas': {'lat': 32.7767, 'lng': -96.7970},
      'san jose': {'lat': 37.3382, 'lng': -121.8863},
      'austin': {'lat': 30.2672, 'lng': -97.7431},
      'jacksonville': {'lat': 30.3322, 'lng': -81.6557},
      'san francisco': {'lat': 37.7749, 'lng': -122.4194},
      'indianapolis': {'lat': 39.7684, 'lng': -86.1581},
      'columbus': {'lat': 39.9612, 'lng': -82.9988},
      'seattle': {'lat': 47.6062, 'lng': -122.3321},
      'denver': {'lat': 39.7392, 'lng': -104.9903},
      'washington': {'lat': 38.9072, 'lng': -77.0369},
      'boston': {'lat': 42.3601, 'lng': -71.0589},
      'atlanta': {'lat': 33.7490, 'lng': -84.3880},
      'miami': {'lat': 25.7617, 'lng': -80.1918},
      'brooklyn': {'lat': 40.6782, 'lng': -73.9442},
      'queens': {'lat': 40.7282, 'lng': -73.7949},
      'las vegas': {'lat': 36.1699, 'lng': -115.1398},
      'nashville': {'lat': 36.1627, 'lng': -86.7816},
      'detroit': {'lat': 42.3314, 'lng': -83.0458},
      'portland': {'lat': 45.5051, 'lng': -122.6750},
      'memphis': {'lat': 35.1495, 'lng': -90.0490},
      'milwaukee': {'lat': 43.0389, 'lng': -87.9065},
      'baltimore': {'lat': 39.2904, 'lng': -76.6122},
      'albuquerque': {'lat': 35.0844, 'lng': -106.6504},
      'tucson': {'lat': 32.2226, 'lng': -110.9747},
      'fresno': {'lat': 36.7378, 'lng': -119.7871},
      'sacramento': {'lat': 38.5816, 'lng': -121.4944},
      'kansas city': {'lat': 39.0997, 'lng': -94.5786},
      'charlotte': {'lat': 35.2271, 'lng': -80.8431},
      'pittsburgh': {'lat': 40.4406, 'lng': -79.9959},
      'st louis': {'lat': 38.6270, 'lng': -90.1994},
      'cincinnati': {'lat': 39.1031, 'lng': -84.5120},
      'minneapolis': {'lat': 44.9778, 'lng': -93.2650},
      'tampa': {'lat': 27.9506, 'lng': -82.4572},
      'orlando': {'lat': 28.5383, 'lng': -81.3792},
      'cleveland': {'lat': 41.4993, 'lng': -81.6944},
      'new orleans': {'lat': 29.9511, 'lng': -90.0715},
      'st paul': {'lat': 44.9537, 'lng': -93.0900},
      'honolulu': {'lat': 21.3069, 'lng': -157.8583},
      'washington dc': {'lat': 38.9072, 'lng': -77.0369},
      'dc': {'lat': 38.9072, 'lng': -77.0369},
      'gainesville': {'lat': 29.6516, 'lng': -82.3248},
      'lothian': {'lat': 38.7990, 'lng': -76.6391}, // Lothian, MD
    };

    // Look for exact match
    if (cityCoordinates.containsKey(cityToLookup)) {
      return cityCoordinates[cityToLookup];
    }

    // If no exact match, try to find partial matches
    for (final entry in cityCoordinates.entries) {
      if (cityToLookup.contains(entry.key) ||
          entry.key.contains(cityToLookup)) {
        return entry.value;
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

      if (cityName == 'atlanta' || cityName.contains('atlanta')) {
        return [
          LocalRepresentative(
            name: 'Jane Smith',
            bioGuideId: 'cicero-mock-fulton-commission-1',
            party: 'Democratic',
            level: 'COUNTY', // Explicitly using COUNTY
            state: 'GA',
            district: 'Fulton County Commission District 1',
            office: 'County Commissioner',
            phone: '(404) 555-1234',
            email: 'jane.smith@fultoncountyga.gov',
            website: 'https://www.fultoncountyga.gov/commissioners/district1',
            imageUrl: null,
            socialMedia: ['Twitter: @janesmith', 'Facebook: JaneSmithFulton'],
          ),
          LocalRepresentative(
            name: 'Maria Rodriguez',
            bioGuideId: 'cicero-mock-atlanta-council-5',
            party: 'Democratic',
            level: 'CITY', // Explicitly using CITY
            state: 'GA',
            district: 'Atlanta City Council District 5',
            office: 'City Council Member',
            phone: '(404) 555-9012',
            email: 'maria.rodriguez@atlantaga.gov',
            website: 'https://www.atlantaga.gov/government/council/district-5',
            imageUrl: null,
            socialMedia: [
              'Twitter: @mariarodriguez',
              'Instagram: mariarodriguezatl'
            ],
          ),
          LocalRepresentative(
            name: 'Andre Dickens',
            bioGuideId: 'cicero-mock-atlanta-mayor',
            party: 'Democratic',
            level: 'CITY', // Explicitly using CITY
            state: 'GA',
            district: 'Atlanta',
            office: 'Mayor',
            phone: '(404) 555-1111',
            email: 'mayor@atlantaga.gov',
            website: 'https://www.atlantaga.gov/government/mayor-s-office',
            imageUrl: null,
            socialMedia: ['Twitter: @atlantamayor', 'Facebook: AtlantaMayor'],
          ),
        ];
      } else if (cityName == 'chicago' || cityName.contains('chicago')) {
        return [
          LocalRepresentative(
            name: 'Michael Johnson',
            bioGuideId: 'cicero-mock-chicago-council-7',
            party: 'Democratic',
            level: 'CITY', // Explicitly using CITY
            state: 'IL',
            district: 'Chicago City Council Ward 7',
            office: 'City Alderman',
            phone: '(312) 555-7890',
            email: 'michael.johnson@cityofchicago.org',
            website: 'https://www.chicago.gov/city/en/about/wards/7.html',
            imageUrl: null,
            socialMedia: [
              'Twitter: @michaeljohnson',
              'Facebook: MikeJohnsonChicago'
            ],
          ),
          LocalRepresentative(
            name: 'Sarah Williams',
            bioGuideId: 'cicero-mock-cook-commission-3',
            party: 'Democratic',
            level: 'COUNTY', // Explicitly using COUNTY
            state: 'IL',
            district: 'Cook County Commission District 3',
            office: 'County Commissioner',
            phone: '(312) 555-4321',
            email: 'sarah.williams@cookcountyil.gov',
            website: 'https://www.cookcountyil.gov/commissioners/district3',
            imageUrl: null,
            socialMedia: [
              'Twitter: @sarahwilliams',
              'Instagram: sarahwilliamscook'
            ],
          ),
          LocalRepresentative(
            name: 'Brandon Johnson',
            bioGuideId: 'cicero-mock-chicago-mayor',
            party: 'Democratic',
            level: 'CITY', // Explicitly using CITY
            state: 'IL',
            district: 'Chicago',
            office: 'Mayor',
            phone: '(312) 555-0000',
            email: 'mayor@cityofchicago.org',
            website: 'https://www.chicago.gov/city/en/depts/mayor.html',
            imageUrl: null,
            socialMedia: [
              'Twitter: @chicagomayor',
              'Facebook: ChicagoMayorsOffice'
            ],
          ),
        ];
      } else if (cityName == 'gainesville' ||
          cityName.contains('gainesville')) {
        return [
          LocalRepresentative(
            name: 'Harvey Ward',
            bioGuideId: 'cicero-mock-gainesville-mayor',
            party: 'Democratic',
            level: 'CITY',
            state: 'FL',
            district: 'Gainesville',
            office: 'Mayor',
            phone: '(352) 555-1234',
            email: 'mayor@cityofgainesville.org',
            website: 'https://www.cityofgainesville.org',
            imageUrl: null,
            socialMedia: ['Twitter: @GvilleMayor'],
          ),
          LocalRepresentative(
            name: 'Casey Willits',
            bioGuideId: 'cicero-mock-gainesville-commission-4',
            party: 'Democratic',
            level: 'CITY',
            state: 'FL',
            district: 'Gainesville City Commission District 3',
            office: 'City Commissioner',
            phone: '(352) 555-5678',
            email: 'willitsc@cityofgainesville.org',
            website: 'https://www.cityofgainesville.org/CityCommission',
            imageUrl: null,
            socialMedia: null,
          ),
          LocalRepresentative(
            name: 'Ken Cornell',
            bioGuideId: 'cicero-mock-alachua-commission-4',
            party: 'Democratic',
            level: 'COUNTY',
            state: 'FL',
            district: 'Alachua County Commission District 4',
            office: 'County Commissioner',
            phone: '(352) 555-9012',
            email: 'kcornell@alachuacounty.us',
            website: 'https://alachuacounty.us/govt/bocc',
            imageUrl: null,
            socialMedia: ['Facebook: KenCornellAlachua'],
          ),
        ];
      } else if (cityName == 'salt lake city' ||
          cityName.contains('salt lake')) {
        return [
          LocalRepresentative(
            name: 'Erin Mendenhall',
            bioGuideId: 'cicero-mock-slc-mayor',
            party: 'Democratic',
            level: 'CITY',
            state: 'UT',
            district: 'Salt Lake City',
            office: 'Mayor',
            phone: '(801) 555-1000',
            email: 'mayor@slcgov.com',
            website: 'https://www.slc.gov/mayor/',
            imageUrl: null,
            socialMedia: ['Twitter: @slcmayor'],
          ),
          LocalRepresentative(
            name: 'James Rogers',
            bioGuideId: 'cicero-mock-slc-council-1',
            party: 'Nonpartisan',
            level: 'CITY',
            state: 'UT',
            district: 'Salt Lake City Council District 1',
            office: 'City Council Member',
            phone: '(801) 555-1001',
            email: 'council.district1@slcgov.com',
            website: 'https://www.slc.gov/council/district1/',
            imageUrl: null,
            socialMedia: null,
          ),
          LocalRepresentative(
            name: 'Jenny Wilson',
            bioGuideId: 'cicero-mock-slc-county-mayor',
            party: 'Democratic',
            level: 'COUNTY',
            state: 'UT',
            district: 'Salt Lake County',
            office: 'County Mayor',
            phone: '(801) 555-2000',
            email: 'mayor@slco.org',
            website: 'https://slco.org/mayor/',
            imageUrl: null,
            socialMedia: ['Twitter: @SLCoMayor'],
          ),
        ];
      }

      // For any other city, generate some generic local representatives
      // Ensure levels are properly set to recognized values
      final String stateName = _getStateNameForCity(cityName);
      final String stateCode = _getStateCodeForCity(cityName);

      String cityProperName = city;
      if (city.contains(',')) {
        cityProperName = city.split(',')[0].trim();
      }

      // Convert to title case for display
      cityProperName = cityProperName
          .split(' ')
          .map((word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '')
          .join(' ');

      return [
        // Local officials
        LocalRepresentative(
          name: 'Mayor of $cityProperName',
          bioGuideId: 'cicero-mock-${cityName.replaceAll(' ', '-')}-mayor',
          party: 'Independent',
          level: 'CITY', // Explicitly using CITY
          state: stateCode,
          district: '$cityProperName City',
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
          level: 'CITY', // Explicitly using CITY
          state: stateCode,
          district: '$cityProperName City Council District 1',
          office: 'City Council Member',
          phone: '(555) 555-2345',
          email: 'council@${cityName.replaceAll(' ', '')}.gov',
          website: 'https://www.${cityName.replaceAll(' ', '')}.gov/council',
          imageUrl: null,
          socialMedia: null,
        ),
        LocalRepresentative(
          name: 'Commissioner Jones',
          bioGuideId:
              'cicero-mock-${cityName.replaceAll(' ', '-')}-commissioner',
          party: 'Republican',
          level: 'COUNTY', // Explicitly using COUNTY
          state: stateCode,
          district: '$stateName County',
          office: 'County Commissioner',
          phone: '(555) 555-3456',
          email: 'commissioner@county.gov',
          website: 'https://www.county.gov',
          imageUrl: null,
          socialMedia: null,
        ),
        
        // State officials (will be moved to federal list by provider)
        LocalRepresentative(
          name: 'Senator Davis',
          bioGuideId: 'cicero-mock-${cityName.replaceAll(' ', '-')}-state-senate',
          party: stateCode == 'CA' || stateCode == 'NY' || stateCode == 'IL' ? 'Democratic' : 'Republican',
          level: 'STATE_UPPER',
          state: stateCode,
          district: '$stateCode State Senate District 10',
          office: 'State Senator',
          phone: '(555) 555-4567',
          email: 'senator.davis@state.$stateCode.gov',
          website: 'https://www.legislature.$stateCode.gov/senators/davis',
          imageUrl: null,
          socialMedia: ['Twitter: @SenDavis$stateCode'],
        ),
        LocalRepresentative(
          name: 'Representative Martinez',
          bioGuideId: 'cicero-mock-${cityName.replaceAll(' ', '-')}-state-house',
          party: stateCode == 'CA' || stateCode == 'NY' || stateCode == 'IL' ? 'Democratic' : 'Republican',
          level: 'STATE_LOWER',
          state: stateCode,
          district: '$stateCode State House District 25',
          office: 'State Representative',
          phone: '(555) 555-5678',
          email: 'rep.martinez@state.$stateCode.gov',
          website: 'https://www.legislature.$stateCode.gov/representatives/martinez',
          imageUrl: null,
          socialMedia: ['Twitter: @Rep$stateCode'],
        ),
      ];
    }

    // Default mock data with proper level values
    return [
      LocalRepresentative(
        name: 'Jane Smith',
        bioGuideId: 'cicero-mock-fulton-commission-1',
        party: 'Democratic',
        level: 'COUNTY', // Explicitly using COUNTY
        state: 'GA',
        district: 'Fulton County Commission District 1',
        office: 'County Commissioner',
        phone: '(404) 555-1234',
        email: 'jane.smith@fultoncountyga.gov',
        website: 'https://www.fultoncountyga.gov/commissioners/district1',
        imageUrl: null,
        socialMedia: ['Twitter: @janesmith', 'Facebook: JaneSmithFulton'],
      ),
      LocalRepresentative(
        name: 'John Doe',
        bioGuideId: 'cicero-mock-fulton-commission-2',
        party: 'Republican',
        level: 'COUNTY', // Explicitly using COUNTY
        state: 'GA',
        district: 'Fulton County Commission District 2',
        office: 'County Commissioner',
        phone: '(404) 555-5678',
        email: 'john.doe@fultoncountyga.gov',
        website: 'https://www.fultoncountyga.gov/commissioners/district2',
        imageUrl: null,
        socialMedia: ['Twitter: @johndoe', 'Facebook: JohnDoeFulton'],
      ),
      LocalRepresentative(
        name: 'Maria Rodriguez',
        bioGuideId: 'cicero-mock-atlanta-council-5',
        party: 'Democratic',
        level: 'CITY', // Explicitly using CITY
        state: 'GA',
        district: 'Atlanta City Council District 5',
        office: 'City Council Member',
        phone: '(404) 555-9012',
        email: 'maria.rodriguez@atlantaga.gov',
        website: 'https://www.atlantaga.gov/government/council/district-5',
        imageUrl: null,
        socialMedia: [
          'Twitter: @mariarodriguez',
          'Instagram: mariarodriguezatl'
        ],
      ),
    ];
  }

  // Helper to get a state code for a city (simplified for mock data)
  String _getStateCodeForCity(String cityName) {
    // Check if city already has state code (e.g. "New York, NY")
    if (cityName.contains(',')) {
      final parts = cityName.split(',');
      if (parts.length > 1) {
        final statePart = parts[1].trim().toUpperCase();
        // If it looks like a state code (2 letters)
        if (statePart.length == 2) {
          return statePart;
        }
      }
    }

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
      'brooklyn': 'NY',
      'queens': 'NY',
      'las vegas': 'NV',
      'nashville': 'TN',
      'detroit': 'MI',
      'portland': 'OR',
      'memphis': 'TN',
      'milwaukee': 'WI',
      'baltimore': 'MD',
      'albuquerque': 'NM',
      'tucson': 'AZ',
      'fresno': 'CA',
      'sacramento': 'CA',
      'kansas city': 'MO',
      'charlotte': 'NC',
      'pittsburgh': 'PA',
      'st louis': 'MO',
      'cincinnati': 'OH',
      'minneapolis': 'MN',
      'tampa': 'FL',
      'orlando': 'FL',
      'cleveland': 'OH',
      'new orleans': 'LA',
      'st paul': 'MN',
      'honolulu': 'HI',
      'washington': 'DC',
      'dc': 'DC',
      'gainesville': 'FL',
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
    // Map of state codes to names
    const Map<String, String> stateCodeToName = {
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

    // Get state code, then convert to name
    final stateCode = _getStateCodeForCity(cityName);
    return stateCodeToName[stateCode] ?? 'California';
  }

  // Helper method to guess the most likely state for a given city
  String? _guessStateForCity(String cityName) {
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
      'gainesville': 'FL',
      'lothian': 'MD',
    };

    // Check for city in our map (case insensitive)
    final lowerCityName = cityName.toLowerCase();
    for (final entry in cityToState.entries) {
      if (lowerCityName == entry.key || lowerCityName.contains(entry.key)) {
        return entry.value;
      }
    }

    // No match found
    return null;
  }

  // Mock data for name search
  List<LocalRepresentative> _getMockLocalRepresentativesByName(String lastName,
      [String? firstName]) {
    // Easter egg: Check for Josh Robinson
    final fullName = firstName != null ? '$firstName $lastName' : lastName;
    if (fullName.toLowerCase().contains('josh robinson') || 
        lastName.toLowerCase().contains('josh robinson') ||
        (firstName?.toLowerCase() == 'josh' && lastName.toLowerCase() == 'robinson')) {
      return _getJoshRobinsonMockData();
    }
    
    // Determine a more accurate name filter if firstName is provided
    final nameFilter = firstName != null ? '$firstName $lastName' : lastName;

    return [
      LocalRepresentative(
        name: firstName != null ? '$firstName $lastName' : 'John $lastName',
        bioGuideId: 'cicero-mock-state-senate-${lastName.toLowerCase()}',
        party: 'Republican',
        level: 'STATE_UPPER',
        state: 'CA',
        district: 'State Senate District 12',
        office: 'State Senator',
        phone: '(555) 123-4567',
        email: '${lastName.toLowerCase()}@state.gov',
        website: 'https://www.state.gov/senators/${lastName.toLowerCase()}',
        imageUrl: null,
        socialMedia: [
          'Twitter: @${lastName.toLowerCase()}',
          'Facebook: ${lastName.toLowerCase()}ForSenate'
        ],
      ),
      LocalRepresentative(
        name: firstName != null
            ? 'Mayor $firstName $lastName'
            : 'Mayor Mary $lastName',
        bioGuideId: 'cicero-mock-mayor-${lastName.toLowerCase()}',
        party: 'Democratic',
        level: 'LOCAL_EXEC',
        state: 'NY',
        district: 'New York City',
        office: 'Mayor',
        phone: '(555) 987-6543',
        email: 'mayor${lastName.toLowerCase()}@city.gov',
        website: 'https://www.city.gov/mayor',
        imageUrl: null,
        socialMedia: [
          'Twitter: @Mayor${lastName.toLowerCase()}',
          'Instagram: Mayor${lastName.toLowerCase()}'
        ],
      ),
      LocalRepresentative(
        name: firstName != null
            ? 'Councilmember $firstName $lastName'
            : 'Councilmember Robert $lastName',
        bioGuideId: 'cicero-mock-council-${lastName.toLowerCase()}',
        party: 'Independent',
        level: 'LOCAL',
        state: 'FL',
        district: 'Miami City Council District 3',
        office: 'City Council Member',
        phone: '(555) 555-5555',
        email: 'council${lastName.toLowerCase()}@miami.gov',
        website: 'https://www.miami.gov/council/district3',
        imageUrl: null,
        socialMedia: null,
      ),
    ];
  }

  // Easter egg: Josh Robinson mock data
  List<LocalRepresentative> _getJoshRobinsonMockData() {
    return [
      LocalRepresentative(
        name: 'Josh "Money God" Robinson',
        bioGuideId: 'cicero-josh-robinson-easter-egg',
        party: 'Ultra Capitalist Money Empire Party',
        level: 'FEDERAL_UPPER',
        state: 'WA',
        district: 'District of Infinite Wealth Generation & Dollar Dynasty',
        office: 'Supreme Overlord of Monetary Accumulation & Chief Wealth Multiplication Officer',
        phone: '(💰💰💰) BILLIONS',
        email: 'billionaire@goldpalace.money',
        website: 'https://www.joshmillionairemindset.money',
        imageUrl: 'assets/images/josh_robinson.JPG',
        socialMedia: [
          'Twitter: @JoshTrillionaire',
          'Instagram: @MoneyRainsMaster',
          'LinkedIn: Josh "The Money Printing Machine" Robinson',
          'TikTok: @CashKingJosh',
          'OnlyFans: @WealthPorn',
          'YouTube: JoshMoneyEmpireBillionaire',
          'Twitch: MoneyStreamJosh'
        ],
      ),
    ];
  }

  Future<http.Response> _tracedHttpGet(Uri url, {String? apiKey}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(url);
      stopwatch.stop();
      return response;
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  // Replace the existing checkNetworkConnectivity method
  Future<bool> checkNetworkConnectivity() async {
    // Use the fixed implementation in NetworkService
    final networkService = NetworkService();
    return await networkService.checkConnectivity();
  }
}
