// lib/services/bill_service.dart
import 'dart:convert';
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
  static const Duration _cacheMaxAge = Duration(hours: 24);

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

      if (kDebugMode) {
        print('Bill Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Bill Service: $e');
      }
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
      if (kDebugMode) {
        print('Error getting bills for state $stateCode: $e');
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

      // Use LegiScan to get bills by representative
      if (hasLegiscanApiKey) {
        final legiscanBills =
            await _legiscanService.getSponsoredBills(rep.bioGuideId.hashCode);

        for (final bill in legiscanBills) {
          bills.add(BillModel.fromRepresentativeBill(bill, rep.state));
        }
      }

      // Use CSV service to get local bills
      final csvBills = await _csvBillService.getSponsoredBills(rep);

      for (final bill in csvBills) {
        bills.add(BillModel.fromRepresentativeBill(bill, rep.state));
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
      // Check if we have it in the cache
      if (_billDetailsCache.containsKey(billId)) {
        return _billDetailsCache[billId];
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
          return null;
        }

        // Process bill details
        final billDetails = _processBillDetails(billData, stateCode);

        // Cache the details
        _billDetailsCache[billId] = billDetails;

        return billDetails;
      }

      // Fallback to checking CSV data
      // TODO: Implement CSV bill details lookup by ID

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
    final List<BillModel> bills = [];

    // Use LegiScan to get state bills
    if (hasLegiscanApiKey) {
      final params = <String, String>{
        'state': stateCode,
      };

      final masterListData =
          await _legiscanService.callApi('getMasterList', params);

      if (masterListData != null && masterListData.containsKey('masterlist')) {
        final masterList = masterListData['masterlist'];

        if (masterList is Map) {
          // Use the _processMasterList method to extract bills
          final extractedBills =
              _processMasterList(masterList as Map<String, dynamic>, stateCode);

          // Add the extracted bills to our list
          bills.addAll(extractedBills);

          // Add debug logging
          if (kDebugMode) {
            print(
                'Extracted ${extractedBills.length} bills from masterlist for $stateCode');
          }
        }
      } else {
        if (kDebugMode) {
          print('No masterlist found in response for $stateCode');
          print('Response keys: ${masterListData?.keys.join(', ')}');
        }
      }
    }

    // Use CSV data for local bills (if available)
    // TODO: Implement CSV bill filtering by state

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

  // Process detailed bill data
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

    // Create bill model
    final billModel = BillModel.fromMap(billMap);

    // Add sponsors if available
    List<RepresentativeSponsor> sponsors = [];

    if (bill.containsKey('sponsors') && bill['sponsors'] is List) {
      for (final sponsor in bill['sponsors']) {
        if (sponsor is Map) {
          final sponsorData = Map<String, dynamic>.from(sponsor as Map);
          sponsors.add(RepresentativeSponsor.fromMap(sponsorData));
        }
      }
    }

    // Add history if available
    List<BillHistory> history = [];

    if (bill.containsKey('history') && bill['history'] is List) {
      for (final action in bill['history']) {
        if (action is Map) {
          final actionData = Map<String, dynamic>.from(action as Map);
          history.add(BillHistory.fromMap(actionData));
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
          subjects.add(subject['subject'] as String);
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
}
