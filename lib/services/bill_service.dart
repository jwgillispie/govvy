// lib/services/bill_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:govvy/services/csv_bill_service.dart';
import 'package:govvy/services/legiscan_service.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class BillService {
  // Singleton pattern
  static final BillService _instance = BillService._internal();
  factory BillService() => _instance;
  BillService._internal();

  // Dependencies
  final NetworkService _networkService = NetworkService();
  final RemoteConfigService _configService = RemoteConfigService();
  final CSVBillService _csvBillService = CSVBillService();
  final LegiscanService _legiscanService = LegiscanService();

  // API URLs
  final String _congressBaseUrl = 'https://api.congress.gov/v3';
  final String _legiscanBaseUrl = 'https://api.legiscan.com/';

  // Cache constants
  static const String _billsCacheKey = 'bills_cache';
  static const String _billsLastUpdatedKey = 'bills_last_updated';
  static const String _lastDatasetCheckKey = 'last_dataset_check';
  static const Duration _cacheMaxAge = Duration(hours: 24);
  static const Duration _datasetCheckInterval = Duration(days: 7);

  // In-memory cache
  final Map<String, List<BillModel>> _stateCache = {};
  final Map<int, BillModel> _billDetailsCache = {};

  // Get keys from Remote Config
  String? get _congressApiKey => _configService.getCongressApiKey;
  String? get _legiscanApiKey => _configService.getLegiscanApiKey;

  // Check if API keys are available
  bool get hasCongressApiKey =>
      _congressApiKey != null && _congressApiKey!.isNotEmpty;
  bool get hasLegiscanApiKey =>
      _legiscanApiKey != null && _legiscanApiKey!.isNotEmpty;

  // Initialize the service
  Future<void> initialize() async {
    try {
      // Initialize the CSV Bill Service
      await _csvBillService.initialize();

      // Load cached bills from persistent storage
      await _loadBillsFromCache();
      
      // Check if we should update datasets
      await _checkForDatasetUpdates();

      if (kDebugMode) {
        print('Bill Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Bill Service: $e');
      }
    }
  }
  
  /// Checks if we need to fetch new datasets and processes them if needed
  Future<void> _checkForDatasetUpdates() async {
    try {
      if (!hasLegiscanApiKey) {
        if (kDebugMode) {
          print('No LegiScan API key available for dataset updates');
        }
        return;
      }
      
      // Check if we need to run the dataset update
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastDatasetCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // If it's been less than a week since our last check, skip
      if (now - lastCheck < _datasetCheckInterval.inMilliseconds) {
        if (kDebugMode) {
          final daysSinceLastCheck = (now - lastCheck) ~/ (1000 * 60 * 60 * 24);
          print('Last dataset check was $daysSinceLastCheck days ago, skipping update');
        }
        return;
      }
      
      if (kDebugMode) {
        print('Checking for dataset updates...');
      }
      
      // Update the last check timestamp first (in case of failure, we still wait before trying again)
      await prefs.setInt(_lastDatasetCheckKey, now);
      
      // Get new datasets that need to be fetched
      final newDatasets = await _legiscanService.getNewDatasets();
      
      if (newDatasets.isEmpty) {
        if (kDebugMode) {
          print('No new datasets available');
        }
        return;
      }
      
      if (kDebugMode) {
        print('Found ${newDatasets.length} new/updated datasets');
        for (final dataset in newDatasets) {
          print('  - ${dataset.state}: Dataset ID ${dataset.datasetId}, Last updated ${dataset.lastUpdate}');
        }
      }
      
      // Fetch and process datasets (limited to 5 to avoid excessive API usage)
      final datasetCount = newDatasets.length > 5 ? 5 : newDatasets.length;
      final processedDatasets = <String>[];
      
      for (int i = 0; i < datasetCount; i++) {
        final dataset = newDatasets[i];
        
        if (kDebugMode) {
          print('Fetching dataset for ${dataset.state}...');
        }
        
        // Download the dataset
        final datasetPath = await _legiscanService.getDataset(dataset.datasetId);
        
        if (datasetPath == null) {
          if (kDebugMode) {
            print('Failed to download dataset for ${dataset.state}');
          }
          continue;
        }
        
        // Process the dataset
        if (kDebugMode) {
          print('Processing dataset for ${dataset.state}...');
        }
        
        final billCount = await _legiscanService.processDataset(datasetPath);
        
        if (kDebugMode) {
          print('Processed $billCount bills from ${dataset.state} dataset');
        }
        
        // Clear cached data for this state to force refresh
        _stateCache.remove(dataset.state);
        
        // Add to list of processed states
        processedDatasets.add(dataset.state);
      }
      
      if (processedDatasets.isNotEmpty) {
        if (kDebugMode) {
          print('Successfully processed datasets for: ${processedDatasets.join(', ')}');
        }
        
        // Update persistent cache with latest data
        await _saveBillsToCache();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for dataset updates: $e');
      }
    }
  }

  // Get all bills for a state
  Future<List<BillModel>> getBillsByState(String stateCode) async {
    try {
      if (kDebugMode) {
        print('BillService.getBillsByState called for state: $stateCode');
      }

      // Check network connectivity
      if (!await _networkService.checkConnectivity()) {
        if (kDebugMode) {
          print('Network connectivity issue in BillService');
        }
        throw Exception('No network connectivity');
      }

      // Check if we have cached data
      if (_stateCache.containsKey(stateCode)) {
        if (kDebugMode) {
          print('Using cached data for state: $stateCode');
        }
        return _stateCache[stateCode]!;
      }

      // Check LegiScan API key
      if (kDebugMode) {
        print('LegiScan API key available in BillService: $hasLegiscanApiKey');
        if (_legiscanApiKey != null) {
          print(
              'Legiscan API key value: ${_legiscanApiKey!.substring(0, 3)}...');
        }
      }

      if (kDebugMode) {
        print('About to call _fetchStateAndLocalBills for state: $stateCode');
      }

      // Fetch bills from LegiScan
      final billsList = await _fetchStateAndLocalBills(stateCode);

      if (kDebugMode) {
        print(
            'Received ${billsList.length} bills from _fetchStateAndLocalBills');
      }

      // Cache the results
      _stateCache[stateCode] = billsList;

      // Also update persistent cache
      await _saveBillsToCache();

      return billsList;
    } catch (e) {
      if (kDebugMode) {
        print('Error in BillService.getBillsByState: $e');
      }
      // Return cached data if available, otherwise empty list
      return _stateCache[stateCode] ?? [];
    }
  }

  // Get bills by subject
  Future<List<BillModel>> getBillsBySubject(String subject,
      {String? stateCode}) async {
    try {
      // Check network connectivity
      if (!await _networkService.checkConnectivity()) {
        throw Exception('No network connectivity');
      }

      // Use LegiScan search with subject
      if (hasLegiscanApiKey) {
        final searchParams = <String, String>{
          'query': 'subject:"$subject"',
        };

        if (stateCode != null) {
          searchParams['state'] = stateCode;
        }

        // Call LegiScan API
        final searchResults =
            await _legiscanService.callApi('getSearch', searchParams);

        if (searchResults == null) {
          return [];
        }

        // Process the search results to get bill models
        return _processBillSearchResults(searchResults, stateCode ?? 'US');
      }

      // Fallback to simple keyword search in CSV data
      return searchBills(subject, stateCode: stateCode);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bills by subject "$subject": $e');
      }
      return [];
    }
  }

  // Get bills by representative
  Future<List<BillModel>> getBillsByRepresentative(Representative rep) async {
    try {
      // Convert existing RepresentativeBill objects to BillModel
      final bills = <BillModel>[];

      // First get bills from the representative provider
      // This logic would be better in a provider, but we're including it here for reference
      // Normally would inject the RepresentativeProvider

      // First, check if we have state-specific CSV data for this representative
      if (_csvBillService.availableStates.contains(rep.state)) {
        try {
          if (kDebugMode) {
            print('Using state-specific CSV data for representative: ${rep.name} in state ${rep.state}');
          }
          
          // Get sponsored bills from the state-specific CSV
          final csvBills = await _csvBillService.getSponsoredBills(rep);
          
          if (csvBills.isNotEmpty) {
            if (kDebugMode) {
              print('Adding ${csvBills.length} state-specific CSV bills for representative ${rep.name}');
            }
            
            // Convert RepresentativeBill to BillModel
            for (final bill in csvBills) {
              bills.add(BillModel.fromRepresentativeBill(bill, rep.state));
            }
          } else {
            if (kDebugMode) {
              print('No state-specific CSV bills found for representative ${rep.name}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading state-specific CSV bills for representative ${rep.name}: $e');
          }
        }
      } else {
        // If no state-specific data, try app-wide CSV data
        if (kDebugMode) {
          print('Using app-wide CSV data for representative: ${rep.name}');
        }
        
        // Use CSV service to get local bills from app-wide data
        final csvBills = await _csvBillService.getSponsoredBills(rep);

        if (csvBills.isNotEmpty) {
          if (kDebugMode) {
            print('Adding ${csvBills.length} app-wide CSV bills for representative ${rep.name}');
          }
          
          for (final bill in csvBills) {
            bills.add(BillModel.fromRepresentativeBill(bill, rep.state));
          }
        }
      }

      // Also try LegiScan as a supplementary source
      if (hasLegiscanApiKey) {
        try {
          if (kDebugMode) {
            print('Using LegiScan API for representative: ${rep.name}');
          }
          
          final legiscanBills =
              await _legiscanService.getSponsoredBills(rep.bioGuideId.hashCode);

          if (legiscanBills.isNotEmpty) {
            if (kDebugMode) {
              print('Adding ${legiscanBills.length} LegiScan bills for representative ${rep.name}');
            }
            
            for (final bill in legiscanBills) {
              bills.add(BillModel.fromRepresentativeBill(bill, rep.state));
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading LegiScan bills for representative ${rep.name}: $e');
          }
        }
      }

      return bills;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bills for representative ${rep.name}: $e');
      }
      return [];
    }
  }

  // Get detailed information about a specific bill
  Future<BillModel?> getBillDetails(int billId, String stateCode) async {
    try {
      if (kDebugMode) {
        print('Getting bill details for billId: $billId, stateCode: $stateCode');
      }
      
      // Check if we have it in the cache
      if (_billDetailsCache.containsKey(billId)) {
        if (kDebugMode) {
          print('Found bill details in cache for billId: $billId');
        }
        return _billDetailsCache[billId];
      }

      // Special handling for FL and GA bills
      if (stateCode == 'FL' || stateCode == 'GA') {
        if (kDebugMode) {
          print('Special handling for $stateCode bill details, billId: $billId');
        }
        
        // Try to find this bill in the state bills list first
        if (_stateCache.containsKey(stateCode)) {
          final stateBills = _stateCache[stateCode]!;
          final matchingBill = stateBills.firstWhere(
            (bill) => bill.billId == billId,
            orElse: () => BillModel(
              billId: -1, // Invalid ID to indicate not found
              billNumber: 'Unknown',
              title: 'Unknown',
              status: 'Unknown',
              type: 'state',
              state: stateCode,
              url: '',
            ),
          );
          
          if (matchingBill.billId != -1) {
            if (kDebugMode) {
              print('Found matching bill in state cache: ${matchingBill.billNumber}');
            }
            
            // Cache the details
            _billDetailsCache[billId] = matchingBill;
            
            return matchingBill;
          } else {
            if (kDebugMode) {
              print('Bill not found in state cache, trying CSV service directly');
            }
          }
        }
        
        // Try to find this bill in CSV data directly
        try {
          // Look for the bill in CSV data with the billId
          if (kDebugMode) {
            print('Looking for bill in CSV data with billId: $billId');
          }
          
          // Get all bills for this state
          final csvBills = await _csvBillService.getBillsByState(stateCode);
          
          // Find the matching bill by ID
          for (final csvBill in csvBills) {
            // Generate the same ID hash used in BillModel.fromRepresentativeBill
            final idHash = (csvBill.congress.hashCode ^ 
                csvBill.billType.hashCode ^ 
                csvBill.billNumber.hashCode ^ 
                stateCode.hashCode).abs();
                
            if (idHash == billId) {
              if (kDebugMode) {
                print('Found matching bill in CSV data: ${csvBill.billNumber}');
              }
              
              // Convert to BillModel
              final billModel = BillModel.fromRepresentativeBill(csvBill, stateCode);
              
              // Cache the details
              _billDetailsCache[billId] = billModel;
              
              return billModel;
            }
          }
          
          if (kDebugMode) {
            print('Bill not found in CSV data with billId: $billId');
          }
        } catch (csvError) {
          if (kDebugMode) {
            print('Error searching CSV data for bill: $csvError');
          }
        }
      }

      // Check network connectivity
      if (!await _networkService.checkConnectivity()) {
        throw Exception('No network connectivity');
      }

      // Get bill details from LegiScan
      if (hasLegiscanApiKey) {
        final params = <String, String>{
          'id': billId.toString(),
        };

        final billData = await _legiscanService.callApi('getBill', params);

        if (billData == null || !billData.containsKey('bill')) {
          if (kDebugMode) {
            print('No bill data returned from LegiScan API for billId: $billId');
            if (billData != null && billData.containsKey('alert') && 
                billData['alert'] is Map && billData['alert'].containsKey('message')) {
              print('API error message: ${billData['alert']['message']}');
              
              // If the specific error is "Unknown bill id", try to find the bill in other sources
              if (billData['alert']['message'] == 'Unknown bill id') {
                print('Attempting to find this bill through alternative sources...');
                
                // Check for this bill in state cache with a different ID format
                if (_stateCache.containsKey(stateCode)) {
                  // Try matching by bill number instead of ID
                  for (final cachedBill in _stateCache[stateCode]!) {
                    // If we find a bill with similar attributes, return it
                    if (cachedBill.billId != billId &&
                        (cachedBill.billNumber.contains(billId.toString()) || 
                         billId.toString().contains(cachedBill.billNumber))) {
                      print('Found potential match in state cache: ${cachedBill.billNumber}');
                      _billDetailsCache[billId] = cachedBill;
                      return cachedBill;
                    }
                  }
                }
              }
            }
          }
          return null;
        }

        // Process bill details
        final billDetails = _processBillDetails(billData, stateCode);
        if (kDebugMode) {
          print('Processed bill details from LegiScan: ${billDetails.billNumber}');
        }

        // Cache the details
        _billDetailsCache[billId] = billDetails;

        return billDetails;
      } else {
        if (kDebugMode) {
          print('No LegiScan API key available for bill details lookup');
        }
      }

      // If we get here, we haven't found the bill
      if (kDebugMode) {
        print('Bill details not found for billId: $billId, stateCode: $stateCode');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bill details for bill ID $billId: $e');
      }
      return null;
    }
  }
  

  // Get bill documents
  Future<List<BillDocument>> getBillDocuments(int billId) async {
    try {
      // Check network connectivity
      if (!await _networkService.checkConnectivity()) {
        throw Exception('No network connectivity');
      }

      // Get documents from LegiScan
      if (hasLegiscanApiKey) {
        final params = <String, String>{
          'id': billId.toString(),
        };

        final billData = await _legiscanService.callApi('getBill', params);

        if (billData == null || !billData.containsKey('bill')) {
          return [];
        }

        // Process documents
        return _processBillDocuments(billData);
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting documents for bill ID $billId: $e');
      }
      return [];
    }
  }

  // Private methods for data fetching and processing
  Future<List<BillModel>> _fetchStateAndLocalBills(String stateCode) async {
    if (kDebugMode) {
      print('_fetchStateAndLocalBills called for state: $stateCode');
    }

    final List<BillModel> bills = [];

    // First, check if this state has state-specific CSV data
    if (_csvBillService.availableStates.contains(stateCode)) {
      try {
        if (kDebugMode) {
          print('Using state-specific CSV data for state: $stateCode');
        }
        
        // Get bills from the state-specific CSV
        final csvBills = await _csvBillService.getBillsByState(stateCode);
        
        if (csvBills.isNotEmpty) {
          if (kDebugMode) {
            print('Adding ${csvBills.length} state-specific CSV bills for $stateCode');
          }
          
          // Convert RepresentativeBill to BillModel
          for (final bill in csvBills) {
            bills.add(BillModel.fromRepresentativeBill(bill, stateCode));
          }
        } else {
          if (kDebugMode) {
            print('No state-specific CSV bills found for $stateCode');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading state-specific CSV bills: $e');
          print('Exception details: ${e.toString()}');
          print('Falling back to other data sources');
        }
      }
    } else {
      if (kDebugMode) {
        print('State $stateCode is not in available states: ${_csvBillService.availableStates.join(', ')}');
        print('Available states: ${_csvBillService.availableStates}');
      }
    }

    // Try LegiScan API as a backup or additional source
    if (hasLegiscanApiKey) {
      if (kDebugMode) {
        print('Using LegiScan API for state: $stateCode');
      }

      try {
        // For FL and GA, use getSearch with a broad search instead of getMasterList
        if (stateCode == 'FL' || stateCode == 'GA') {
          if (kDebugMode) {
            print('Using getSearch for $stateCode instead of getMasterList');
          }

          // Use a search query that will return recent bills
          final searchParams = <String, String>{
            'state': stateCode,
            'query': '*', // Wildcard search
            'year': '2025', // Current year
          };

          // Get recent bills using search
          final searchResults =
              await _legiscanService.callApi('getSearch', searchParams);

          if (searchResults != null) {
            if (kDebugMode) {
              print('Search results received for $stateCode');
              if (searchResults.containsKey('searchresult')) {
                final keys =
                    (searchResults['searchresult'] as Map).keys.toList();
                print('Search result keys: $keys');
                print(
                    'Number of search results: ${keys.length - 1}'); // -1 for summary
              } else {
                print('No searchresult key found');
                print('Response keys: ${searchResults.keys.join(', ')}');
              }
            }

            // Process the search results to bills
            bills.addAll(_processBillSearchResults(searchResults, stateCode));
          } else {
            if (kDebugMode) {
              print('No search results returned for $stateCode');
            }
          }
        } else {
          // For other states, use the standard getMasterList approach
          final params = <String, String>{
            'state': stateCode,
          };

          final masterListData =
              await _legiscanService.callApi('getMasterList', params);

          if (masterListData != null &&
              masterListData.containsKey('masterlist')) {
            final masterList = masterListData['masterlist'];

            if (masterList is Map) {
              // Process the masterlist
              final stateBills = _processMasterList(
                  masterList as Map<String, dynamic>, stateCode);
              bills.addAll(stateBills);

              if (kDebugMode) {
                print(
                    'Processed ${stateBills.length} bills from masterlist for $stateCode');
              }
            } else {
              if (kDebugMode) {
                print('masterlist is not a Map: ${masterList.runtimeType}');
              }
            }
          } else {
            if (kDebugMode) {
              if (masterListData == null) {
                print('No response from getMasterList API call');
              } else {
                print(
                    'Missing masterlist key in response. Keys: ${masterListData.keys.join(', ')}');
              }
            }

            // Fallback to search if masterlist fails
            if (kDebugMode) {
              print('Falling back to search for $stateCode');
            }

            final searchParams = <String, String>{
              'state': stateCode,
              'query': '*', // Wildcard search
            };

            final searchResults =
                await _legiscanService.callApi('getSearch', searchParams);

            if (searchResults != null) {
              bills.addAll(_processBillSearchResults(searchResults, stateCode));
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching bills from LegiScan for $stateCode: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('LegiScan API key not available, skipping API call');
      }
    }

    // Also add general CSV data if available and if we don't already have state-specific data
    if (!_csvBillService.availableStates.contains(stateCode)) {
      try {
        if (kDebugMode) {
          print('Checking for app-wide CSV bills for $stateCode');
        }

        // Use getSponsoredBills with a placeholder representative to get all bills for the state
        // Since the CSVBillService doesn't have a getBillsByState method
        final Representative placeholderRep = Representative(
          name: 'State Placeholder',
          bioGuideId: 'state-${stateCode.toLowerCase()}',
          party: '',
          chamber: '',
          state: stateCode,
          district: null,
        );

        final csvBills = await _csvBillService.getSponsoredBills(placeholderRep);
        if (csvBills.isNotEmpty) {
          if (kDebugMode) {
            print('Adding ${csvBills.length} app-wide CSV bills for $stateCode');
          }

          // Convert RepresentativeBill to BillModel
          for (final bill in csvBills) {
            bills.add(BillModel.fromRepresentativeBill(bill, stateCode));
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading app-wide CSV bills: $e');
        }
      }
    }

    if (kDebugMode) {
      print('Returning total of ${bills.length} bills for $stateCode');
    }

    return bills;
  }

  // Process LegiScan masterlist data
  List<BillModel> _processMasterList(
      Map<String, dynamic> masterList, String stateCode) {
    final List<BillModel> bills = [];

    // The masterlist contains numeric keys for bills and 'session' for metadata
    // We need to iterate through all keys and filter out non-bill entries
    masterList.forEach((key, value) {
      // Skip the session metadata and any non-map entries
      if (key == 'session' || !(value is Map)) {
        return;
      }

      try {
        // Create a properly typed map for the bill data
        final Map<String, dynamic> billData = {};

        // Copy all entries with proper typing
        (value as Map).forEach((k, v) {
          billData[k.toString()] = v;
        });

        // Add state code
        billData['state'] = stateCode;

        // Add bill type
        billData['type'] = 'state';

        // Create and add the bill model
        bills.add(BillModel.fromMap(billData));

        if (kDebugMode && bills.length <= 2) {
          // Print details of first few bills for debugging
          print('Processed bill: ${billData['number']} - ${billData['title']}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing bill with key $key: $e');
        }
      }
    });

    if (kDebugMode) {
      print('Total bills processed: ${bills.length}');
    }

    return bills;
  }

  Future<List<BillModel>> searchBills(String query, {String? stateCode}) async {
    try {
      // Check network connectivity
      if (!await _networkService.checkConnectivity()) {
        throw Exception('No network connectivity');
      }

      // Use LegiScan search
      if (hasLegiscanApiKey) {
        final searchParams = <String, String>{
          'query': query,
        };

        if (stateCode != null) {
          searchParams['state'] = stateCode;
        }

        // Call LegiScan API
        final searchResults =
            await _legiscanService.callApi('getSearch', searchParams);

        if (searchResults == null) {
          return [];
        }

        // Process the search results to get bill models
        final bills =
            _processBillSearchResults(searchResults, stateCode ?? 'US');

        if (kDebugMode) {
          print('Processed ${bills.length} bills from search');
        }

        return bills;
      }

      // Fallback to CSV search if no API key
      if (stateCode != null) {
        // Get all bills for the state first
        final stateBills = await getBillsByState(stateCode);

        // Filter by query
        return stateBills.where((bill) {
          final title = bill.title.toLowerCase();
          final description = bill.description?.toLowerCase() ?? '';
          final searchTerms = query.toLowerCase().split(' ');

          // Check if all search terms are in the title or description
          return searchTerms.every(
              (term) => title.contains(term) || description.contains(term));
        }).toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error searching for bills with query "$query": $e');
      }
      return [];
    }
  }

  // Updated method to correctly process the LegiScan search results format
  List<BillModel> _processBillSearchResults(
      Map<String, dynamic> searchResults, String stateCode) {
    final List<BillModel> bills = [];

    // Check if this is the expected LegiScan format with "searchresult" key
    if (searchResults.containsKey('searchresult')) {
      final searchresult =
          searchResults['searchresult'] as Map<String, dynamic>;

      // Loop through the keys in the searchresult
      searchresult.forEach((key, value) {
        // Skip the "summary" key or any non-map entries
        if (key == 'summary' || !(value is Map)) {
          return;
        }

        try {
          // Convert the value to a properly typed Map
          final Map<String, dynamic> billData =
              Map<String, dynamic>.from(value as Map);

          // The LegiScan API returns bill_id as an integer, ensure it's treated as such
          if (billData.containsKey('bill_id') &&
              billData['bill_id'] is String) {
            billData['bill_id'] = int.parse(billData['bill_id']);
          }

          // Convert URL properties to correct format
          if (billData.containsKey('url') && billData['url'] is String) {
            billData['url'] = billData['url'].toString().replaceAll('\/', '/');
          }

          // Ensure required fields are present
          if (!billData.containsKey('state')) {
            billData['state'] = stateCode;
          }

          // Add bill type
          billData['type'] = 'state';

          // For status_desc field - copy from status if it exists
          if (!billData.containsKey('status_desc') &&
              billData.containsKey('last_action')) {
            billData['status_desc'] = billData['last_action'];
          }

          // Create standardized bill model fields
          final mappedBillData = {
            'bill_id': billData['bill_id'] ?? billData.hashCode,
            'bill_number': billData['bill_number'] ?? 'Unknown',
            'title': billData['title'] ?? 'Untitled Bill',
            'description':
                null, // LegiScan doesn't provide description in search results
            'status_desc': billData['status_desc'] ??
                billData['last_action'] ??
                'Unknown status',
            'status_date': null, // Not provided in search results
            'last_action_date': billData['last_action_date'] ?? null,
            'last_action': billData['last_action'] ?? null,
            'committee': null, // Not provided in search results
            'type': 'state',
            'state': billData['state'],
            'url': billData['url'] ?? billData['text_url'] ?? '',
          };

          // Create and add the bill model
          bills.add(BillModel.fromMap(mappedBillData));

          if (kDebugMode && bills.length <= 3) {
            // Print details of first few bills for debugging
            print(
                'Processed bill: ${mappedBillData['bill_number']} - ${mappedBillData['title']}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing bill with key $key: $e');
          }
        }
      });

      if (kDebugMode) {
        print('Total LegiScan bills processed: ${bills.length}');
      }

      return bills;
    }

    // Fallback to the original method for other API formats
    if (!searchResults.containsKey('results') ||
        !searchResults['results'].containsKey('bills') ||
        !(searchResults['results']['bills'] is List)) {
      return bills;
    }

    final billsList = searchResults['results']['bills'] as List;

    if (billsList.isEmpty) {
      return bills;
    }

    for (final item in billsList) {
      if (item is Map) {
        try {
          final billData = Map<String, dynamic>.from(item as Map);

          // Add state code
          billData['state'] = stateCode;

          // Add bill type
          billData['type'] = 'state';

          bills.add(BillModel.fromMap(billData));
        } catch (e) {
          if (kDebugMode) {
            print('Error processing search result: $e');
          }
          continue;
        }
      }
    }

    return bills;
  }

  BillModel _processBillDetails(
      Map<String, dynamic> billData, String stateCode) {
    if (!billData.containsKey('bill')) {
      throw Exception('Invalid bill data format');
    }

    final bill = billData['bill'];

    if (bill is! Map) {
      throw Exception('Invalid bill format');
    }

    final Map<String, dynamic> billMap = Map<String, dynamic>.from(bill as Map);

    // Add state code
    billMap['state'] = stateCode;

    // Add bill type
    billMap['type'] = 'state';

    // Handle fields that might be Lists before creating the model
    // This is to avoid the casting error
    if (billMap.containsKey('description') && billMap['description'] is List) {
      // If description is a List, convert it to a String
      billMap['description'] = (billMap['description'] as List).join(' ');
    }

    // Check other potential fields that might be Lists
    final fieldsToCheck = [
      'title',
      'status_desc',
      'status_date',
      'last_action'
    ];
    for (final field in fieldsToCheck) {
      if (billMap.containsKey(field) && billMap[field] is List) {
        if (kDebugMode) {
          print('Converting field $field from List to String');
        }
        billMap[field] = (billMap[field] as List).join(' ');
      }
    }

    // Create bill model
    final billModel = BillModel.fromMap(billMap);

    // Add sponsors if available
    List<RepresentativeSponsor> sponsors = [];

    if (bill.containsKey('sponsors') && bill['sponsors'] is List) {
      for (final sponsor in bill['sponsors']) {
        if (sponsor is Map) {
          try {
            final sponsorData = Map<String, dynamic>.from(sponsor as Map);

            // Ensure state is present in sponsor data
            if (!sponsorData.containsKey('state')) {
              sponsorData['state'] = stateCode;
            }

            // Handle List values in sponsor data
            sponsorData.forEach((key, value) {
              if (value is List) {
                sponsorData[key] = value.join(' ');
              }
            });

            sponsors.add(RepresentativeSponsor.fromMap(sponsorData));
          } catch (e) {
            if (kDebugMode) {
              print('Error processing sponsor: $e');
            }
          }
        }
      }
    }

    // Add history if available
    List<BillHistory> history = [];

    if (bill.containsKey('history') && bill['history'] is List) {
      for (final action in bill['history']) {
        if (action is Map) {
          try {
            final actionData = Map<String, dynamic>.from(action as Map);

            // Handle List values in action data
            actionData.forEach((key, value) {
              if (value is List) {
                actionData[key] = value.join(' ');
              }
            });

            // Make sure sequence is an int
            if (actionData.containsKey('sequence') &&
                actionData['sequence'] is! int) {
              if (actionData['sequence'] is String) {
                actionData['sequence'] =
                    int.tryParse(actionData['sequence'] as String) ?? 0;
              } else {
                actionData['sequence'] = 0;
              }
            } else if (!actionData.containsKey('sequence')) {
              actionData['sequence'] = 0;
            }

            history.add(BillHistory.fromMap(actionData));
          } catch (e) {
            if (kDebugMode) {
              print('Error processing history action: $e');
            }
          }
        }
      }
    }

    // Add subjects if available
    List<String> subjects = [];

    if (bill.containsKey('subjects') && bill['subjects'] is List) {
      for (final subject in bill['subjects']) {
        if (subject is String) {
          subjects.add(subject);
        } else if (subject is Map && subject.containsKey('subject')) {
          var subjectValue = subject['subject'];
          if (subjectValue is String) {
            subjects.add(subjectValue);
          } else if (subjectValue is List) {
            subjects.add(subjectValue.join(' '));
          }
        }
      }
    }

    // Return enhanced bill model
    return billModel.copyWith(
      sponsors: sponsors,
      history: history,
      subjects: subjects,
    );
  }

  // Process bill documents
  List<BillDocument> _processBillDocuments(Map<String, dynamic> billData) {
    final List<BillDocument> documents = [];

    if (!billData.containsKey('bill') ||
        !billData['bill'].containsKey('texts') ||
        !(billData['bill']['texts'] is List)) {
      return documents;
    }

    final texts = billData['bill']['texts'] as List;

    for (final text in texts) {
      if (text is Map) {
        try {
          final textData = Map<String, dynamic>.from(text as Map);
          documents.add(BillDocument.fromMap(textData));
        } catch (e) {
          if (kDebugMode) {
            print('Error processing bill document: $e');
          }
          continue;
        }
      }
    }

    return documents;
  }

  // Cache management methods
  Future<void> _loadBillsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache is still valid
      final lastUpdated = prefs.getInt(_billsLastUpdatedKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastUpdated > _cacheMaxAge.inMilliseconds) {
        // Cache is too old, clear it
        if (kDebugMode) {
          print('Bills cache is too old, clearing it');
        }
        return;
      }

      // Load bills from cache
      final billsCache = prefs.getString(_billsCacheKey);

      if (billsCache == null) {
        return;
      }

      final Map<String, dynamic> cacheData = json.decode(billsCache);

      // Load state cache
      if (cacheData.containsKey('states')) {
        final stateData = cacheData['states'] as Map<String, dynamic>;

        for (final entry in stateData.entries) {
          final stateCode = entry.key;
          final billsData = entry.value as List<dynamic>;

          _stateCache[stateCode] = billsData
              .map((data) =>
                  BillModel.fromMap(Map<String, dynamic>.from(data as Map)))
              .toList();
        }
      }

      // Load bill details cache
      if (cacheData.containsKey('details')) {
        final detailsData = cacheData['details'] as Map<String, dynamic>;

        for (final entry in detailsData.entries) {
          final billId = int.parse(entry.key);
          final billData = Map<String, dynamic>.from(entry.value as Map);

          _billDetailsCache[billId] = BillModel.fromMap(billData);
        }
      }

      if (kDebugMode) {
        print(
            'Loaded ${_stateCache.length} states and ${_billDetailsCache.length} bill details from cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading bills from cache: $e');
      }
      // Clear cache on error
      _stateCache.clear();
      _billDetailsCache.clear();
    }
  }

  Future<void> _saveBillsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> cacheData = {
        'states': {},
        'details': {},
      };

      // Save state cache
      for (final entry in _stateCache.entries) {
        final stateCode = entry.key;
        final billsList = entry.value;

        cacheData['states'][stateCode] =
            billsList.map((bill) => bill.toMap()).toList();
      }

      // Save bill details cache
      for (final entry in _billDetailsCache.entries) {
        final billId = entry.key;
        final bill = entry.value;

        cacheData['details'][billId.toString()] = bill.toMap();
      }

      // Save to shared preferences
      await prefs.setString(_billsCacheKey, json.encode(cacheData));
      await prefs.setInt(
          _billsLastUpdatedKey, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) {
        print(
            'Saved ${_stateCache.length} states and ${_billDetailsCache.length} bill details to cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving bills to cache: $e');
      }
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_billsCacheKey);
      await prefs.remove(_billsLastUpdatedKey);

      _stateCache.clear();
      _billDetailsCache.clear();

      if (kDebugMode) {
        print('Bills cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing bills cache: $e');
      }
    }
  }
  
  /// Manually triggers dataset updates for specified states
  /// If no states are provided, it will check all states for updates
  /// Returns a map of state codes to success/failure status
  Future<Map<String, bool>> updateDatasets({List<String>? stateCodes}) async {
    try {
      if (!hasLegiscanApiKey) {
        if (kDebugMode) {
          print('No LegiScan API key available for manual dataset updates');
        }
        return {};
      }
      
      if (kDebugMode) {
        print('Manually updating datasets for ${stateCodes != null ? stateCodes.join(', ') : 'all states'}');
      }
      
      // Get new datasets that need to be fetched
      final newDatasets = await _legiscanService.getNewDatasets(states: stateCodes);
      
      if (newDatasets.isEmpty) {
        if (kDebugMode) {
          print('No new datasets available for the specified states');
        }
        return {};
      }
      
      if (kDebugMode) {
        print('Found ${newDatasets.length} new/updated datasets');
      }
      
      // Process results map
      final Map<String, bool> results = {};
      
      // Fetch and process each dataset
      for (final dataset in newDatasets) {
        if (kDebugMode) {
          print('Fetching dataset for ${dataset.state}...');
        }
        
        try {
          // Download the dataset
          final datasetPath = await _legiscanService.getDataset(dataset.datasetId);
          
          if (datasetPath == null) {
            if (kDebugMode) {
              print('Failed to download dataset for ${dataset.state}');
            }
            results[dataset.state] = false;
            continue;
          }
          
          // Process the dataset
          if (kDebugMode) {
            print('Processing dataset for ${dataset.state}...');
          }
          
          final billCount = await _legiscanService.processDataset(datasetPath);
          
          if (kDebugMode) {
            print('Processed $billCount bills from ${dataset.state} dataset');
          }
          
          // Clear cached data for this state to force refresh
          _stateCache.remove(dataset.state);
          
          // Mark successful update
          results[dataset.state] = true;
          
        } catch (e) {
          if (kDebugMode) {
            print('Error updating dataset for ${dataset.state}: $e');
          }
          results[dataset.state] = false;
        }
      }
      
      // Update persistent cache with latest data
      await _saveBillsToCache();
      
      // Reset last check time to now
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastDatasetCheckKey, DateTime.now().millisecondsSinceEpoch);
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error in manual dataset update: $e');
      }
      return {};
    }
  }
  
  /// Gets the last date when datasets were checked for updates
  Future<DateTime?> getLastDatasetCheckDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastDatasetCheckKey);
      
      if (lastCheck == null) {
        return null;
      }
      
      return DateTime.fromMillisecondsSinceEpoch(lastCheck);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last dataset check date: $e');
      }
      return null;
    }
  }
}
