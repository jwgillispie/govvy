// lib/services/bill_service.dart
import 'dart:convert';
// Removed unused import: import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';
// Removed: import 'package:govvy/services/csv_bill_service.dart';
import 'package:govvy/services/legiscan_service.dart';
// Removed unused import: import 'package:csv/csv.dart';
// Removed unused import: import 'package:path_provider/path_provider.dart';

class BillService {
  // Singleton pattern
  static final BillService _instance = BillService._internal();
  factory BillService() => _instance;
  BillService._internal();

  // Dependencies
  final NetworkService _networkService = NetworkService();
  final RemoteConfigService _configService = RemoteConfigService();
  // Removed: final CSVBillService _csvBillService = CSVBillService();
  final LegiscanService _legiscanService = LegiscanService();

  // API URLs
  // Removed unused API URL: _congressBaseUrl
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

  // Get key from Remote Config
  String? get _legiscanApiKey => _configService.getLegiscanApiKey;

  // Check if API key is available
  bool get hasLegiscanApiKey =>
      _legiscanApiKey != null && _legiscanApiKey!.isNotEmpty;

  // Initialize the service
  Future<void> initialize() async {
    try {
      // Removed: Initialize the CSV Bill Service
      // await _csvBillService.initialize();

      // Load cached bills from persistent storage
      await _loadBillsFromCache();
      
      // Check if we should update datasets
      await _checkForDatasetUpdates();
    } catch (e) {
      // Error handling remains but without logging
    }
  }
  
  /// Checks if we need to fetch new datasets and processes them if needed
  Future<void> _checkForDatasetUpdates() async {
    try {
      if (!hasLegiscanApiKey) {
        return;
      }
      
      // Check if we need to run the dataset update
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastDatasetCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // If it's been less than a week since our last check, skip
      if (now - lastCheck < _datasetCheckInterval.inMilliseconds) {
        return;
      }
      
      // Update the last check timestamp first (in case of failure, we still wait before trying again)
      await prefs.setInt(_lastDatasetCheckKey, now);
      
      // Get new datasets that need to be fetched
      final newDatasets = await _legiscanService.getNewDatasets();
      
      if (newDatasets.isEmpty) {
        return;
      }
      
      // Fetch and process datasets (limited to 5 to avoid excessive API usage)
      final datasetCount = newDatasets.length > 5 ? 5 : newDatasets.length;
      final processedDatasets = <String>[];
      
      for (int i = 0; i < datasetCount; i++) {
        final dataset = newDatasets[i];
        
        // Download the dataset
        final datasetPath = await _legiscanService.getDataset(dataset.datasetId);
        
        if (datasetPath == null) {
          continue;
        }
        
        // Process the dataset
        final billCount = await _legiscanService.processDataset(datasetPath);
        
        // Clear cached data for this state to force refresh
        _stateCache.remove(dataset.state);
        
        // Add to list of processed states
        processedDatasets.add(dataset.state);
      }
      
      if (processedDatasets.isNotEmpty) {
        // Update persistent cache with latest data
        await _saveBillsToCache();
      }
    } catch (e) {
      // Error handling remains but without logging
    }
  }

  // Get all bills for a state
  Future<List<BillModel>> getBillsByState(String stateCode) async {
    try {
      // Check network connectivity
      if (!await _networkService.checkConnectivity()) {
        throw Exception('No network connectivity');
      }

      // Check if we have cached data
      if (_stateCache.containsKey(stateCode)) {
        return _stateCache[stateCode]!;
      }

      // Fetch bills from LegiScan
      final billsList = await _fetchStateAndLocalBills(stateCode);

      // Cache the results
      _stateCache[stateCode] = billsList;

      // Also update persistent cache
      await _saveBillsToCache();

      return billsList;
    } catch (e) {
      // Return cached data if available, otherwise empty list
      return _stateCache[stateCode] ?? [];
    }
  }

  /// Get bills by subject with optional state filter
  /// 
  /// First tries the LegiScan API with a subject query if API key is available.
  /// Falls back to filtering state bills by subject if no API key or if API fails.
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

      // Fallback to local data if no API key
      if (stateCode != null) {
        // Get all bills for the state first
        final stateBills = await getBillsByState(stateCode);

        // Filter by subject
        return stateBills.where((bill) {
          final subjects = bill.subjects?.map((s) => s.toLowerCase()).toList() ?? [];
          final searchTerm = subject.toLowerCase();
          return subjects.any((s) => s.contains(searchTerm));
        }).toList();
      }

      return [];
    } catch (e) {
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

      // Removed: CSV data loading for representatives
      // if (_csvBillService.availableStates.contains(rep.state)) {
      //   try {
      //     // Get sponsored bills from the state-specific CSV
      //     final csvBills = await _csvBillService.getSponsoredBills(rep);
      //     
      //     if (csvBills.isNotEmpty) {
      //       // Convert RepresentativeBill to BillModel
      //       for (final bill in csvBills) {
      //         bills.add(BillModel.fromRepresentativeBill(bill, rep.state));
      //       }
      //     }
      //   } catch (e) {
      //     // Error handling remains but without logging
      //   }
      // } else {
      //   // If no state-specific data, try app-wide CSV data
      //   
      //   // Use CSV service to get local bills from app-wide data
      //   final csvBills = await _csvBillService.getSponsoredBills(rep);

      //   if (csvBills.isNotEmpty) {
      //     for (final bill in csvBills) {
      //       bills.add(BillModel.fromRepresentativeBill(bill, rep.state));
      //     }
      //   }
      // }

      // Also try LegiScan as a supplementary source
      if (hasLegiscanApiKey) {
        try {
          final legiscanBills =
              await _legiscanService.getSponsoredBills(rep.bioGuideId.hashCode);

          if (legiscanBills.isNotEmpty) {
            for (final bill in legiscanBills) {
              bills.add(BillModel.fromRepresentativeBill(bill, rep.state));
            }
          }
        } catch (e) {
          // Error handling remains but without logging
        }
      }

      return bills;
    } catch (e) {
      return [];
    }
  }

  // Get detailed information about a specific bill
  Future<BillModel?> getBillDetails(int billId, String stateCode) async {
    try {
      // Check if we have it in the cache
      if (_billDetailsCache.containsKey(billId)) {
        return _billDetailsCache[billId];
      }

      // Special handling for FL and GA bills
      if (stateCode == 'FL' || stateCode == 'GA') {
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
            // Cache the details
            _billDetailsCache[billId] = matchingBill;
            
            return matchingBill;
          }
        }
        
        // Removed: CSV data lookup
        // try {
        //   // Look for the bill in CSV data with the billId
        //   
        //   // Get all bills for this state
        //   final csvBills = await _csvBillService.getBillsByState(stateCode);
        //   
        //   // Find the matching bill by ID
        //   for (final csvBill in csvBills) {
        //     // Generate the same ID hash used in BillModel.fromRepresentativeBill
        //     final idHash = (csvBill.congress.hashCode ^ 
        //         csvBill.billType.hashCode ^ 
        //         csvBill.billNumber.hashCode ^ 
        //         stateCode.hashCode).abs();
        //         
        //     if (idHash == billId) {
        //       // Convert to BillModel
        //       final billModel = BillModel.fromRepresentativeBill(csvBill, stateCode);
        //       
        //       // Cache the details
        //       _billDetailsCache[billId] = billModel;
        //       
        //       return billModel;
        //     }
        //   }
        // } catch (csvError) {
        //   // Error handling remains but without logging
        // }
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
          // If the specific error is "Unknown bill id", try to find the bill in other sources
          if (billData != null && billData.containsKey('alert') && 
              billData['alert'] is Map && billData['alert'].containsKey('message')) {
            
            if (billData['alert']['message'] == 'Unknown bill id') {
              // Check for this bill in state cache with a different ID format
              if (_stateCache.containsKey(stateCode)) {
                // Try matching by bill number instead of ID
                for (final cachedBill in _stateCache[stateCode]!) {
                  // If we find a bill with similar attributes, return it
                  if (cachedBill.billId != billId &&
                      (cachedBill.billNumber.contains(billId.toString()) || 
                       billId.toString().contains(cachedBill.billNumber))) {
                    _billDetailsCache[billId] = cachedBill;
                    return cachedBill;
                  }
                }
              }
            }
          }
          return null;
        }

        // Process bill details
        final billDetails = _processBillDetails(billData, stateCode);

        // Cache the details
        _billDetailsCache[billId] = billDetails;

        return billDetails;
      }

      // If we get here, we haven't found the bill
      return null;
    } catch (e) {
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
      return [];
    }
  }

  // Private methods for data fetching and processing
  Future<List<BillModel>> _fetchStateAndLocalBills(String stateCode) async {
    final List<BillModel> bills = [];

    // Removed: CSV data loading
    // if (_csvBillService.availableStates.contains(stateCode)) {
    //   try {
    //     // Get bills from the state-specific CSV
    //     final csvBills = await _csvBillService.getBillsByState(stateCode);
    //     
    //     if (csvBills.isNotEmpty) {
    //       // Convert RepresentativeBill to BillModel
    //       for (final bill in csvBills) {
    //         bills.add(BillModel.fromRepresentativeBill(bill, stateCode));
    //       }
    //     }
    //   } catch (e) {
    //     // Error handling remains but without logging
    //   }
    // }

    // Try LegiScan API as a backup or additional source
    if (hasLegiscanApiKey) {
      try {
        // For FL and GA, use getSearch with a broad search instead of getMasterList
        if (stateCode == 'FL' || stateCode == 'GA') {
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
            // Process the search results to bills
            bills.addAll(_processBillSearchResults(searchResults, stateCode));
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
            }
          } else {
            // Fallback to search if masterlist fails
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
        // Error handling remains but without logging
      }
    }

    // Removed: General CSV data loading
    // if (!_csvBillService.availableStates.contains(stateCode)) {
    //   try {
    //     // Use getSponsoredBills with a placeholder representative to get all bills for the state
    //     // Since the CSVBillService doesn't have a getBillsByState method
    //     final Representative placeholderRep = Representative(
    //       name: 'State Placeholder',
    //       bioGuideId: 'state-${stateCode.toLowerCase()}',
    //       party: '',
    //       chamber: '',
    //       state: stateCode,
    //       district: null,
    //     );

    //     final csvBills = await _csvBillService.getSponsoredBills(placeholderRep);
    //     if (csvBills.isNotEmpty) {
    //       // Convert RepresentativeBill to BillModel
    //       for (final bill in csvBills) {
    //         bills.add(BillModel.fromRepresentativeBill(bill, stateCode));
    //       }
    //     }
    //   } catch (e) {
    //     // Error handling remains but without logging
    //   }
    // }

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
      if (key == 'session' || value is! Map) {
        return;
      }

      try {
        // Create a properly typed map for the bill data
        final Map<String, dynamic> billData = {};

        // Copy all entries with proper typing
        (value).forEach((k, v) {
          billData[k.toString()] = v;
        });

        // Add state code
        billData['state'] = stateCode;

        // Add bill type
        billData['type'] = 'state';

        // Create and add the bill model
        bills.add(BillModel.fromMap(billData));
      } catch (e) {
        // Error handling remains but without logging
      }
    });

    return bills;
  }

  // Removed deprecated searchBills method

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
        if (key == 'summary' || value is! Map) {
          return;
        }

        try {
          // Convert the value to a properly typed Map
          final Map<String, dynamic> billData =
              Map<String, dynamic>.from(value);

          // The LegiScan API returns bill_id as an integer, ensure it's treated as such
          if (billData.containsKey('bill_id') &&
              billData['bill_id'] is String) {
            billData['bill_id'] = int.parse(billData['bill_id']);
          }

          // Convert URL properties to correct format
          if (billData.containsKey('url') && billData['url'] is String) {
            billData['url'] = billData['url'].toString().replaceAll('/', '/');
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
            'last_action_date': billData['last_action_date'],
            'last_action': billData['last_action'],
            'committee': null, // Not provided in search results
            'type': 'state',
            'state': billData['state'],
            'url': billData['url'] ?? billData['text_url'] ?? '',
          };

          // Create and add the bill model
          bills.add(BillModel.fromMap(mappedBillData));
        } catch (e) {
          // Error handling remains but without logging
        }
      });

      return bills;
    }

    // Fallback to the original method for other API formats
    if (!searchResults.containsKey('results') ||
        !searchResults['results'].containsKey('bills') ||
        searchResults['results']['bills'] is! List) {
      return bills;
    }

    final billsList = searchResults['results']['bills'] as List;

    if (billsList.isEmpty) {
      return bills;
    }

    for (final item in billsList) {
      if (item is Map) {
        try {
          final billData = Map<String, dynamic>.from(item);

          // Add state code
          billData['state'] = stateCode;

          // Add bill type
          billData['type'] = 'state';

          bills.add(BillModel.fromMap(billData));
        } catch (e) {
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

    final Map<String, dynamic> billMap = Map<String, dynamic>.from(bill);

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
            final sponsorData = Map<String, dynamic>.from(sponsor);

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
            // Error handling remains but without logging
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
            final actionData = Map<String, dynamic>.from(action);

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
            // Error handling remains but without logging
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
        billData['bill']['texts'] is! List) {
      return documents;
    }

    final texts = billData['bill']['texts'] as List;

    for (final text in texts) {
      if (text is Map) {
        try {
          final textData = Map<String, dynamic>.from(text);
          documents.add(BillDocument.fromMap(textData));
        } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      // Error handling remains but without logging
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
    } catch (e) {
      // Error handling remains but without logging
    }
  }
  
  /// Manually triggers dataset updates for specified states
  /// If no states are provided, it will check all states for updates
  /// Returns a map of state codes to success/failure status
  Future<Map<String, bool>> updateDatasets({List<String>? stateCodes}) async {
    try {
      if (!hasLegiscanApiKey) {
        return {};
      }
      
      // Get new datasets that need to be fetched
      final newDatasets = await _legiscanService.getNewDatasets(states: stateCodes);
      
      if (newDatasets.isEmpty) {
        return {};
      }
      
      // Process results map
      final Map<String, bool> results = {};
      
      // Fetch and process each dataset
      for (final dataset in newDatasets) {
        try {
          // Download the dataset
          final datasetPath = await _legiscanService.getDataset(dataset.datasetId);
          
          if (datasetPath == null) {
            results[dataset.state] = false;
            continue;
          }
          
          // Process the dataset
          final billCount = await _legiscanService.processDataset(datasetPath);
          
          // Clear cached data for this state to force refresh
          _stateCache.remove(dataset.state);
          
          // Mark successful update
          results[dataset.state] = true;
          
        } catch (e) {
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
      return null;
    }
  }
}