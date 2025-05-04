// lib/services/legiscan_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:govvy/services/network_service.dart';
import 'package:http/http.dart' as http;

class LegiscanService {
  final String _baseUrl = 'https://api.legiscan.com/';
  final NetworkService _networkService = NetworkService();

  // Get API key from Remote Config
  String? get _apiKey => RemoteConfigService().getLegiscanApiKey;

  // Check if API key is available
  bool get hasApiKey {
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;
    if (kDebugMode && !hasKey) {
      print('Using mock data because LegiScan API key is not available');
    }
    return hasKey;
  }

  // Updated version of findPersonByName method focusing on the specific issue
  Future<Map<String, dynamic>?> findPersonByName(
      String name, String state) async {
    if (!hasApiKey) {
      return null;
    }

    try {
      if (kDebugMode) {
        print('Searching for $name in state $state');
      }

      // Use direct search for the person - this is more reliable than session people lookup
      final searchParams = {'state': state, 'query': name};

      final searchResults = await _callApi('getSearch', searchParams);

      if (searchResults == null) {
        if (kDebugMode) {
          print('No search results returned');
        }
        return null;
      }

      if (kDebugMode) {
        print('Search results structure: ${searchResults.keys}');
      }

      if (!searchResults.containsKey('results') ||
          !(searchResults['results'] is Map) ||
          !searchResults['results'].containsKey('people') ||
          !(searchResults['results']['people'] is List)) {
        if (kDebugMode) {
          print('No people found in search results');
        }

        // Try with just the last name as a fallback
        final nameParts = name.split(' ');
        final lastName = nameParts.last;

        final lastNameSearchParams = {'state': state, 'query': lastName};

        final lastNameResults =
            await _callApi('getSearch', lastNameSearchParams);

        if (lastNameResults == null ||
            !lastNameResults.containsKey('results') ||
            !(lastNameResults['results'] is Map) ||
            !lastNameResults['results'].containsKey('people') ||
            !(lastNameResults['results']['people'] is List)) {
          if (kDebugMode) {
            print('No people found in last name search results');
          }
          return null;
        }

        final peopleList = lastNameResults['results']['people'] as List;
        if (peopleList.isEmpty) {
          if (kDebugMode) {
            print('Empty people list in last name search results');
          }
          return null;
        }

        // Now search through the people list
        final String lowercaseName = name.toLowerCase();

        for (var personData in peopleList) {
          if (personData is Map) {
            final person = Map<String, dynamic>.from(personData);
            final String fullName =
                '${person['first_name']} ${person['last_name']}'.toLowerCase();
            final String lastName =
                person['last_name'].toString().toLowerCase();

            if (fullName.contains(lowercaseName) ||
                lowercaseName.contains(fullName) ||
                lastName == lowercaseName.split(' ').last.toLowerCase()) {
              if (kDebugMode) {
                print(
                    'Found person via last name search: ${person['people_id']} - $fullName');
              }

              // Ensure people_id is an integer
              if (person['people_id'] is String) {
                int? peopleId = int.tryParse(person['people_id']);
                if (peopleId != null) {
                  person['people_id'] = peopleId;
                } else {
                  if (kDebugMode) {
                    print('Invalid people_id format: ${person['people_id']}');
                  }
                  continue;
                }
              }

              return person;
            }
          }
        }

        return null;
      }

      // Process the people from the search results
      final peopleList = searchResults['results']['people'] as List;
      if (peopleList.isEmpty) {
        if (kDebugMode) {
          print('Empty people list in search results');
        }
        return null;
      }

      // Now search through the people list
      final String lowercaseName = name.toLowerCase();

      for (var personData in peopleList) {
        if (personData is Map) {
          final person = Map<String, dynamic>.from(personData);
          final String fullName =
              '${person['first_name']} ${person['last_name']}'.toLowerCase();

          if (fullName.contains(lowercaseName) ||
              lowercaseName.contains(fullName)) {
            if (kDebugMode) {
              print(
                  'Found person via search: ${person['people_id']} - $fullName');
            }

            // Ensure people_id is an integer
            if (person['people_id'] is String) {
              int? peopleId = int.tryParse(person['people_id']);
              if (peopleId != null) {
                person['people_id'] = peopleId;
              } else {
                if (kDebugMode) {
                  print('Invalid people_id format: ${person['people_id']}');
                }
                continue;
              }
            }

            return person;
          }
        }
      }

      // Try one last approach - direct API call to the person search endpoint
      // This is not officially documented but may work
      final directSearchResults = await _callApi(
          'getSearch', {'state': state, 'query': name, 'type': 'people'});

      if (directSearchResults != null &&
          directSearchResults.containsKey('results') &&
          directSearchResults['results'] is Map &&
          directSearchResults['results'].containsKey('people') &&
          directSearchResults['results']['people'] is List) {
        final directPeopleList =
            directSearchResults['results']['people'] as List;

        if (directPeopleList.isNotEmpty) {
          for (var personData in directPeopleList) {
            if (personData is Map) {
              final person = Map<String, dynamic>.from(personData);
              final String fullName =
                  '${person['first_name']} ${person['last_name']}'
                      .toLowerCase();

              if (fullName.contains(lowercaseName) ||
                  lowercaseName.contains(fullName)) {
                if (kDebugMode) {
                  print(
                      'Found person via direct search: ${person['people_id']} - $fullName');
                }

                // Ensure people_id is an integer
                if (person['people_id'] is String) {
                  int? peopleId = int.tryParse(person['people_id']);
                  if (peopleId != null) {
                    person['people_id'] = peopleId;
                  } else {
                    if (kDebugMode) {
                      print('Invalid people_id format: ${person['people_id']}');
                    }
                    continue;
                  }
                }

                return person;
              }
            }
          }
        }
      }

      if (kDebugMode) {
        print('No matching person found for: $name in $state');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error finding person in LegiScan: $e');
      }
      return null;
    }
  }
  

  Future<List<RepresentativeBill>> getSponsoredBills(int personId) async {
    if (!hasApiKey) {
      return [];
    }

    try {
      if (kDebugMode) {
        print('Getting sponsored bills for person ID: $personId');
      }

      // Get person details including sponsored bills
      final personData =
          await _callApi('getPerson', {'id': personId.toString()});

      if (personData == null) {
        if (kDebugMode) {
          print('No person data returned for ID: $personId');
        }
        return [];
      }

      if (!personData.containsKey('person')) {
        if (kDebugMode) {
          print('No person key found in response for ID: $personId');
        }
        return [];
      }

      final person = personData['person'];

      // Check for different variations of the sponsored bills key
      List<dynamic> bills = [];
      if (person.containsKey('sponsor_bills') &&
          person['sponsor_bills'] is List) {
        bills = person['sponsor_bills'] as List;
      } else if (person.containsKey('sponsored_bills') &&
          person['sponsored_bills'] is List) {
        bills = person['sponsored_bills'] as List;
      } else if (person.containsKey('bills') && person['bills'] is List) {
        bills = person['bills'] as List;
      }

      if (bills.isEmpty) {
        if (kDebugMode) {
          print('No sponsored bills found for person ID: $personId');
        }

        // Try direct search as a fallback - using getSearch operation with sponsor ID
        final searchResults = await _callApi('getSearch', {
          'state':
              'GA', // Using GA as a default since that's the state we're looking at
          'query': 'sponsor:$personId'
        });

        if (searchResults != null &&
            searchResults.containsKey('results') &&
            searchResults['results'] is Map &&
            searchResults['results'].containsKey('bills') &&
            searchResults['results']['bills'] is List) {
          bills = searchResults['results']['bills'] as List;

          if (kDebugMode) {
            print(
                'Found ${bills.length} bills via search for sponsor:$personId');
          }
        }

        if (bills.isEmpty) {
          return [];
        }
      }

      final List<RepresentativeBill> result = [];

      // Limit to 10 most recent bills to avoid too many API calls
      final billsToProcess = bills.length > 10 ? bills.sublist(0, 10) : bills;

      for (var bill in billsToProcess) {
        if (bill is! Map) continue;

        try {
          // Extract basic bill information
          final billId = bill['bill_id']?.toString();
          if (billId == null) continue;

          // Create a simple bill object with basic info
          String billNumber = bill['bill_number']?.toString() ?? 'Unknown';
          String title = bill['title']?.toString() ?? 'Untitled Bill';
          String session = bill['session_name']?.toString() ??
              bill['session']?.toString() ??
              '';
          String billType = '';

          // Parse bill number to extract type
          final RegExp regex = RegExp(r'([A-Za-z]+)(\s*)(\d+)');
          final match = regex.firstMatch(billNumber);

          if (match != null) {
            billType = match.group(1) ?? '';
            billNumber = match.group(3) ?? billNumber;
          } else {
            // Default type if we can't parse it
            billType = 'Bill';
          }

          // Create the bill object
          result.add(RepresentativeBill(
            congress: session,
            billType: billType,
            billNumber: billNumber,
            title: title,
            introducedDate: bill['date']?.toString() ?? '',
            latestAction: bill['status']?.toString() ?? '',
            source: 'LegiScan',
          ));
        } catch (billError) {
          if (kDebugMode) {
            print('Error processing bill: $billError');
          }
          continue;
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sponsored bills from LegiScan: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> _callApi(
      String operation, Map<String, String> params) async {
    try {
      if (!await _networkService.checkConnectivity()) {
        throw Exception('No network connectivity');
      }

      // Build URL parameters
      final Map<String, String> queryParams = {
        'key': _apiKey!,
        'op': operation,
        ...params,
      };

      final url = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      if (kDebugMode) {
        final redactedUrl = url.toString().replaceAll(_apiKey!, '[REDACTED]');
        print('LegiScan API call: $redactedUrl');
      }

      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug the response
        if (kDebugMode) {
          print('API response status: ${data['status']}');
          if (data['status'] != 'OK') {
            print(
                'Response contains error: ${data['alert'] ?? "Unknown error"}');
          }
        }

        // LegiScan API uses 'status' field to indicate success/failure
        if (data.containsKey('status')) {
          if (data['status'] == 'OK') {
            return data;
          } else {
            if (kDebugMode) {
              print('LegiScan API returned error status: ${data['status']}');
              if (data.containsKey('alert')) {
                print('Alert: ${data['alert']}');
              }
            }

            // Some API errors still include useful data
            if (operation == 'getSearch' || operation == 'getSessionList') {
              return data; // Return the data anyway for these operations
            }
            return null;
          }
        } else {
          if (kDebugMode) {
            print('LegiScan API response missing status field');
          }
          return data; // Return the data anyway
        }
      } else {
        if (kDebugMode) {
          print('API error: ${response.statusCode} - ${response.body}');
        }
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LegiScan API error: $e');
      }
      return null;
    }
  }

  // Generate mock data for testing when API key is not available
  Future<List<RepresentativeBill>> getMockSponsoredBills() async {
    return [
      RepresentativeBill(
        congress: '2023-2024',
        billType: 'HB',
        billNumber: '123',
        title: 'An Act to Improve Local Infrastructure',
        introducedDate: '2023-02-15',
        latestAction: 'Referred to Committee on Transportation',
      ),
      RepresentativeBill(
        congress: '2023-2024',
        billType: 'HB',
        billNumber: '456',
        title: 'Education Reform and Funding Act',
        introducedDate: '2023-03-10',
        latestAction: 'Passed House, Sent to Senate',
      ),
      RepresentativeBill(
        congress: '2022-2023',
        billType: 'SB',
        billNumber: '789',
        title: 'Tax Relief for Small Businesses',
        introducedDate: '2022-11-05',
        latestAction: 'Signed by Governor',
      ),
    ];
  }
  // Add this helper method to your LegiscanService class

Future<List<RepresentativeBill>> getDirectBillsForPerson(String firstName, String lastName, String state) async {
  if (!hasApiKey) {
    return [];
  }
  
  try {
    if (kDebugMode) {
      print('Directly searching for bills for $firstName $lastName in $state');
    }
    
    // Search for bills with this person's name as sponsor
    final searchParams = {
      'state': state,
      'query': 'sponsor:"$firstName $lastName"' 
    };
    
    final searchResults = await _callApi('getSearch', searchParams);
    
    if (searchResults == null) {
      return [];
    }
    
    if (!searchResults.containsKey('results') || 
        !(searchResults['results'] is Map) ||
        !searchResults['results'].containsKey('bills') ||
        !(searchResults['results']['bills'] is List)) {
      return [];
    }
    
    final billsList = searchResults['results']['bills'] as List;
    if (billsList.isEmpty) {
      return [];
    }
    
    final List<RepresentativeBill> result = [];
    
    // Limit to 10 most recent bills
    final billsToProcess = billsList.length > 10 ? billsList.sublist(0, 10) : billsList;
    
    for (var bill in billsToProcess) {
      if (bill is! Map) continue;
      
      try {
        // Extract basic bill information
        String billNumber = bill['bill_number']?.toString() ?? 'Unknown';
        String title = bill['title']?.toString() ?? 'Untitled Bill';
        String session = bill['session']?.toString() ?? '';
        String billType = '';
        
        // Parse bill number to extract type
        final RegExp regex = RegExp(r'([A-Za-z]+)(\s*)(\d+)');
        final match = regex.firstMatch(billNumber);
        
        if (match != null) {
          billType = match.group(1) ?? '';
          billNumber = match.group(3) ?? billNumber;
        } else {
          // Default type if we can't parse it
          billType = 'Bill';
        }
        
        // Create the bill object
        result.add(RepresentativeBill(
          congress: session,
          billType: billType,
          billNumber: billNumber,
          title: title,
          introducedDate: bill['date']?.toString() ?? '',
          latestAction: bill['status']?.toString() ?? '',
          source: 'LegiScan',
        ));
      } catch (billError) {
        if (kDebugMode) {
          print('Error processing bill: $billError');
        }
        continue;
      }
    }
    
    return result;
  } catch (e) {
    if (kDebugMode) {
      print('Error getting direct bills for person: $e');
    }
    return [];
  }
}



  // Check network connectivity
  Future<bool> checkNetworkConnectivity() async {
    return await _networkService.checkConnectivity();
  }
}
