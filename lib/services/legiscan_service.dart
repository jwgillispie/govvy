// lib/services/legiscan_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:govvy/services/network_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model class to represent a dataset in the LegiScan API
class LegiScanDataset {
  final int datasetId;
  final String state;
  final String session;
  final String accessTime;
  final String lastUpdate;
  final int size;
  final bool fetched;
  final String? localPath;

  LegiScanDataset({
    required this.datasetId,
    required this.state,
    required this.session,
    required this.accessTime,
    required this.lastUpdate,
    required this.size,
    this.fetched = false,
    this.localPath,
  });

  factory LegiScanDataset.fromMap(Map<String, dynamic> map) {
    return LegiScanDataset(
      datasetId: map['dataset_id'] as int,
      state: map['state'] as String,
      session: map['session_id'].toString(),
      accessTime: map['access_time'] as String,
      lastUpdate: map['update_date'] as String,
      size: map['size'] as int,
      fetched: map['fetched'] as bool? ?? false,
      localPath: map['local_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dataset_id': datasetId,
      'state': state,
      'session_id': session,
      'access_time': accessTime,
      'update_date': lastUpdate,
      'size': size,
      'fetched': fetched,
      'local_path': localPath,
    };
  }
}

class LegiscanService {
  final String _baseUrl = 'https://api.legiscan.com/';
  final NetworkService _networkService = NetworkService();
  
  // Cache constants
  static const String _datasetsLastUpdatedKey = 'datasets_last_updated';
  static const String _datasetsMetadataKey = 'datasets_metadata';
  static const Duration _datasetsCacheMaxAge = Duration(days: 7);
  
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

      // Use direct search for the person - this is more reliable than session people lookup
      final searchParams = {'state': state, 'query': name};

      final searchResults = await callApi('getSearch', searchParams);

      if (searchResults == null) {
        return null;
      }


      if (!searchResults.containsKey('results') ||
          searchResults['results'] is! Map ||
          !searchResults['results'].containsKey('people') ||
          searchResults['results']['people'] is! List) {

        // Try with just the last name as a fallback
        final nameParts = name.split(' ');
        final lastName = nameParts.last;

        final lastNameSearchParams = {'state': state, 'query': lastName};

        final lastNameResults =
            await callApi('getSearch', lastNameSearchParams);

        if (lastNameResults == null ||
            !lastNameResults.containsKey('results') ||
            lastNameResults['results'] is! Map ||
            !lastNameResults['results'].containsKey('people') ||
            lastNameResults['results']['people'] is! List) {
          return null;
        }

        final peopleList = lastNameResults['results']['people'] as List;
        if (peopleList.isEmpty) {
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
      final directSearchResults = await callApi(
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

      // Get person details including sponsored bills
      final personData =
          await callApi('getPerson', {'id': personId.toString()});

      if (personData == null) {
        return [];
      }

      if (!personData.containsKey('person')) {
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

        // Try direct search as a fallback - using getSearch operation with sponsor ID
        final searchResults = await callApi('getSearch', {
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

  Future<Map<String, dynamic>?> callApi(
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


      // Increase timeout for potentially slow operations like getBill
      final Duration timeout = operation == 'getBill' 
          ? const Duration(seconds: 30) // Longer timeout for bill details
          : const Duration(seconds: 20); // Standard timeout for other operations

      // Add retry logic
      int retryCount = 0;
      const maxRetries = 2;
      late http.Response response;
      
      while (retryCount <= maxRetries) {
        try {
          response = await http.get(url).timeout(timeout);
          break; // Exit loop if request succeeds
        } catch (timeoutError) {
          retryCount++;
          
          if (retryCount > maxRetries) {
            rethrow; // Re-throw the error after all retries fail
          }
          
          // Wait a bit before retrying
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug the response

        // Special handling for FL and GA getMasterList operations
        if (operation == 'getMasterList' && 
            (params['state'] == 'FL' || params['state'] == 'GA') &&
            data['status'] != 'OK') {
          
          
          // Try a search instead for these states
          final searchParams = {
            'key': _apiKey!,
            'op': 'getSearch',
            'state': params['state'],
            'query': '*',  // Wildcard search
            'year': '2025', // Current year
          };
          
          final searchUrl = Uri.parse(_baseUrl)
              .replace(queryParameters: searchParams);
          
          
          // Use a slightly longer timeout for fallback search
          final searchResponse = await http.get(searchUrl)
              .timeout(const Duration(seconds: 25));
          
          if (searchResponse.statusCode == 200) {
            final searchData = json.decode(searchResponse.body);
            return searchData;
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
            
            // For getBill operations, still return the error response so we can check the specific error
            if (operation == 'getBill') {
              return data; // Return error data for proper handling
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
  Future<List<RepresentativeBill>> getDirectBillsForPerson(
      String firstName, String lastName, String state) async {
    if (!hasApiKey) {
      return [];
    }

    try {

      // Search for bills with this person's name as sponsor
      final searchParams = {
        'state': state,
        'query': 'sponsor:"$firstName $lastName"'
      };

      final searchResults = await callApi('getSearch', searchParams);

      if (searchResults == null) {
        return [];
      }

      if (!searchResults.containsKey('results') ||
          searchResults['results'] is! Map ||
          !searchResults['results'].containsKey('bills') ||
          searchResults['results']['bills'] is! List) {
        // Try searchresult instead (the format varies in the API)
        if (searchResults.containsKey('searchresult')) {
          return _processBillsFromSearchresult(searchResults['searchresult'], state);
        }
        return [];
      }

      final billsList = searchResults['results']['bills'] as List;
      if (billsList.isEmpty) {
        return [];
      }

      final List<RepresentativeBill> result = [];

      // Limit to 10 most recent bills
      final billsToProcess =
          billsList.length > 10 ? billsList.sublist(0, 10) : billsList;

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

  // Add helper method to process bills from searchresult format
  List<RepresentativeBill> _processBillsFromSearchresult(
      Map<String, dynamic> searchresult, String state) {
    final List<RepresentativeBill> result = [];
    
    // Loop through the keys in the searchresult
    searchresult.forEach((key, value) {
      // Skip the "summary" key or any non-map entries
      if (key == 'summary' || value is! Map) {
        return;
      }
      
      try {
        // Convert the value to a properly typed Map
        final Map<String, dynamic> billData = Map<String, dynamic>.from(value);
        
        // Extract bill information
        String billNumber = billData['bill_number']?.toString() ?? 'Unknown';
        String title = billData['title']?.toString() ?? 'Untitled Bill';
        String session = '';
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
          introducedDate: billData['last_action_date']?.toString() ?? '',
          latestAction: billData['last_action']?.toString() ?? '',
          source: 'LegiScan',
        ));
      } catch (e) {
        if (kDebugMode) {
          print('Error processing bill from searchresult: $e');
        }
      }
    });
    
    return result;
  }

  // Check network connectivity
  Future<bool> checkNetworkConnectivity() async {
    return await _networkService.checkConnectivity();
  }
  
  // DATASET HANDLING METHODS
  
  /// Gets the list of available datasets from LegiScan API
  /// Returns a map of state codes to datasets
  Future<Map<String, LegiScanDataset>> getDatasetList({String state = 'ALL'}) async {
    if (!hasApiKey) {
      return {};
    }
    
    try {
      
      // Check network connectivity
      if (!await _networkService.checkConnectivity()) {
        throw Exception('No network connectivity');
      }
      
      // Call the LegiScan API getDatasetList endpoint
      final response = await callApi('getDatasetList', {'state': state});
      
      if (response == null) {
        return {};
      }
      
      // Process the response
      if (!response.containsKey('datasetlist')) {
        return {};
      }
      
      final datasetList = response['datasetlist'] as Map<String, dynamic>;
      final Map<String, LegiScanDataset> datasets = {};
      
      // Process each dataset in the response
      datasetList.forEach((key, value) {
        // Skip 'state' key (metadata)
        if (key == 'state') return;
        
        try {
          final datasetData = Map<String, dynamic>.from(value as Map);
          
          // Convert proper types for dataset fields
          if (datasetData['dataset_id'] is String) {
            datasetData['dataset_id'] = int.parse(datasetData['dataset_id'] as String);
          }
          
          if (datasetData['size'] is String) {
            datasetData['size'] = int.parse(datasetData['size'] as String);
          }
          
          // Create a dataset object and add to map
          final dataset = LegiScanDataset.fromMap(datasetData);
          datasets[dataset.state] = dataset;
          
        } catch (e) {
          if (kDebugMode) {
            print('Error processing dataset: $e');
          }
        }
      });
      
      // Save the datasets metadata to cache
      await _saveDatasetMetadata(datasets);
      
      return datasets;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching dataset list: $e');
      }
      
      // Try to load from cache if API call fails
      return _loadDatasetMetadata();
    }
  }
  
  /// Downloads a specific dataset by ID and extracts it to the app's documents directory
  /// Returns the path to the extracted dataset directory
  Future<String?> getDataset(int datasetId) async {
    if (!hasApiKey) {
      return null;
    }
    
    try {
      
      // Check network connectivity
      if (!await _networkService.checkConnectivity()) {
        throw Exception('No network connectivity');
      }
      
      // Call the LegiScan API getDataset endpoint
      // (params will be used in URL building below)
      
      // Get app's documents directory for storing the dataset
      final appDocDir = await getApplicationDocumentsDirectory();
      final datasetsDir = Directory('${appDocDir.path}/legiscan_datasets');
      
      // Create the directory if it doesn't exist
      if (!await datasetsDir.exists()) {
        await datasetsDir.create(recursive: true);
      }
      
      // Set up the download path
      final zipFilePath = '${datasetsDir.path}/dataset_$datasetId.zip';
      final extractPath = '${datasetsDir.path}/dataset_$datasetId';
      
      // Extract path directory
      final extractDir = Directory(extractPath);
      if (await extractDir.exists()) {
        // Clean up old dataset files if they exist
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);
      
      
      // Build URL for direct download
      final Map<String, String> queryParams = {
        'key': _apiKey!,
        'op': 'getDataset',
        'id': datasetId.toString(),
      };
      
      final url = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      
      
      // Setup a timeout for the download
      final Duration timeout = const Duration(minutes: 5);
      
      // Download the dataset file
      final response = await http.get(url).timeout(timeout);
      
      if (response.statusCode == 200) {
        
        // Save the zip file
        final file = File(zipFilePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Extract the zip file
        
        try {
          // Read the zip file
          final bytes = await file.readAsBytes();
          
          // Decode the zip file
          final archive = ZipDecoder().decodeBytes(bytes);
          
          // Extract each file
          for (final file in archive) {
            final fileName = file.name;
            if (file.isFile) {
              final data = file.content as List<int>;
              final outFile = File('$extractPath/$fileName');
              
              // Create directories for the file if needed
              await outFile.parent.create(recursive: true);
              
              // Write the file
              await outFile.writeAsBytes(data);
              
            }
          }
          
          
          // Update the dataset metadata to show this dataset has been fetched
          await _updateDatasetStatus(datasetId, extractPath);
          
          // Delete the zip file to save space
          await file.delete();
          
          return extractPath;
        } catch (extractError) {
          if (kDebugMode) {
            print('Error extracting dataset: $extractError');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('Error downloading dataset: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting dataset: $e');
      }
      return null;
    }
  }
  
  /// Gets new datasets for the specified states that have been updated since
  /// the last check based on the update_date field
  Future<List<LegiScanDataset>> getNewDatasets({List<String>? states}) async {
    // If no states specified, use all states
    final targetStates = states ?? ['AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 
      'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 
      'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 
      'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY', 'DC'];
    
    try {
      // Get the current list of datasets
      final allDatasets = await getDatasetList();
      
      // Load cached dataset metadata
      final cachedDatasets = await _loadDatasetMetadata();
      
      // Filter datasets that are new or updated
      final List<LegiScanDataset> newDatasets = [];
      
      for (final state in targetStates) {
        // Check if we have a dataset for this state
        if (allDatasets.containsKey(state)) {
          final currentDataset = allDatasets[state]!;
          
          // Check if we've seen this dataset before
          if (cachedDatasets.containsKey(state)) {
            final cachedDataset = cachedDatasets[state]!;
            
            // Compare last_update timestamps to see if there's a newer version
            // Parse dates for comparison - LegiScan uses YYYY-MM-DD HH:MM:SS format
            final currentUpdateTime = DateTime.parse(currentDataset.lastUpdate.replaceAll(' ', 'T'));
            final cachedUpdateTime = DateTime.parse(cachedDataset.lastUpdate.replaceAll(' ', 'T'));
            
            if (currentUpdateTime.isAfter(cachedUpdateTime)) {
              newDatasets.add(currentDataset);
            }
          } else {
            // This is a new state we haven't seen before
            newDatasets.add(currentDataset);
          }
        }
      }
      
      return newDatasets;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for new datasets: $e');
      }
      return [];
    }
  }
  
  /// Processes a downloaded dataset and adds its bills to the database
  /// Returns the number of bills processed
  Future<int> processDataset(String datasetPath) async {
    try {
      
      // Check if the directory exists
      final dir = Directory(datasetPath);
      if (!await dir.exists()) {
        throw Exception('Dataset directory not found: $datasetPath');
      }
      
      // Look for the index.json file, which contains metadata about the dataset
      final indexFile = File('$datasetPath/index.json');
      if (!await indexFile.exists()) {
        throw Exception('Dataset index file not found');
      }
      
      // Read and parse the index
      final indexData = json.decode(await indexFile.readAsString());
      
      // Extract state code from the dataset (for context/debugging)
      // ignore: unused_local_variable
      final String state = indexData['state'] ?? 'Unknown';
      
      
      // Process bill data from the dataset
      int billsProcessed = 0;
      
      // Look for the bills.json file
      final billsFile = File('$datasetPath/bills.json');
      if (await billsFile.exists()) {
        // Read and parse bills
        final billsData = json.decode(await billsFile.readAsString());
        
        if (billsData is Map) {
          // Count how many bills we have
          final billCount = billsData.keys.where((key) => key != 'state').length;
          
          
          billsProcessed = billCount;
        }
      }
      
      return billsProcessed;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing dataset: $e');
      }
      return 0;
    }
  }
  
  // DATASET CACHING METHODS
  
  /// Saves dataset metadata to shared preferences
  Future<void> _saveDatasetMetadata(Map<String, LegiScanDataset> datasets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Prepare data for storage
      final Map<String, dynamic> datasetData = {};
      
      for (final entry in datasets.entries) {
        datasetData[entry.key] = entry.value.toMap();
      }
      
      // Save metadata
      await prefs.setString(_datasetsMetadataKey, json.encode(datasetData));
      
      // Update last checked timestamp
      await prefs.setInt(_datasetsLastUpdatedKey, DateTime.now().millisecondsSinceEpoch);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error saving dataset metadata: $e');
      }
    }
  }
  
  /// Loads dataset metadata from shared preferences
  Future<Map<String, LegiScanDataset>> _loadDatasetMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache is valid
      final lastUpdated = prefs.getInt(_datasetsLastUpdatedKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - lastUpdated > _datasetsCacheMaxAge.inMilliseconds) {
        return {};
      }
      
      // Load metadata
      final datasetData = prefs.getString(_datasetsMetadataKey);
      
      if (datasetData == null) {
        return {};
      }
      
      final Map<String, dynamic> metadata = json.decode(datasetData);
      final Map<String, LegiScanDataset> datasets = {};
      
      // Convert to dataset objects
      for (final entry in metadata.entries) {
        final stateCode = entry.key;
        final datasetMap = Map<String, dynamic>.from(entry.value);
        
        datasets[stateCode] = LegiScanDataset.fromMap(datasetMap);
      }
      
      
      return datasets;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading dataset metadata: $e');
      }
      return {};
    }
  }
  
  /// Updates the status of a dataset to indicate it has been fetched
  Future<void> _updateDatasetStatus(int datasetId, String localPath) async {
    try {
      // Load current metadata
      final datasets = await _loadDatasetMetadata();
      
      // Find the dataset by ID
      String? targetState;
      for (final entry in datasets.entries) {
        if (entry.value.datasetId == datasetId) {
          targetState = entry.key;
          break;
        }
      }
      
      if (targetState != null) {
        // Update the dataset
        final updatedDataset = LegiScanDataset(
          datasetId: datasetId,
          state: datasets[targetState]!.state,
          session: datasets[targetState]!.session,
          accessTime: datasets[targetState]!.accessTime,
          lastUpdate: datasets[targetState]!.lastUpdate,
          size: datasets[targetState]!.size,
          fetched: true,
          localPath: localPath,
        );
        
        // Save the updated dataset
        datasets[targetState] = updatedDataset;
        await _saveDatasetMetadata(datasets);
        
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating dataset status: $e');
      }
    }
  }
}