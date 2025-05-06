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
  bool get hasCongressApiKey => _congressApiKey != null && _congressApiKey!.isNotEmpty;
  bool get hasLegiscanApiKey => _legiscanApiKey != null && _legiscanApiKey!.isNotEmpty;
  
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

  // Get bills by keyword search
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
        final searchResults = await _legiscanService.callApi('getSearch', searchParams);
        
        if (searchResults == null) {
          return [];
        }
        
        // Process the search results to get bill models
        return _processBillSearchResults(searchResults, stateCode ?? 'US');
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
          return searchTerms.every((term) => 
            title.contains(term) || description.contains(term));
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

  // Get bills by subject
  Future<List<BillModel>> getBillsBySubject(String subject, {String? stateCode}) async {
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
        final searchResults = await _legiscanService.callApi('getSearch', searchParams);
        
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
        final legiscanBills = await _legiscanService.getSponsoredBills(rep.bioGuideId.hashCode);
        
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
      
      final masterListData = await _legiscanService.callApi('getMasterList', params);
      
      if (masterListData != null && masterListData.containsKey('masterlist')) {
        final masterList = masterListData['masterlist'];
        
        if (masterList is Map) {
          bills.addAll(_processMasterList(masterList, stateCode));
        }
      }
    }
    
    // Use CSV data for local bills (if available)
    // This would involve filtering CSV bills by state
    // TODO: Implement CSV bill filtering by state
    
    return bills;
  }

  // Process LegiScan masterlist data
  List<BillModel> _processMasterList(Map<String, dynamic> masterList, String stateCode) {
    final List<BillModel> bills = [];
    
    // LegiScan masterlist contains items which are the bills
    if (!masterList.containsKey('items')) {
      return bills;
    }
    
    final items = masterList['items'];
    
    if (items is! List) {
      return bills;
    }
    
    for (final item in items) {
      if (item is Map) {
        try {
          final billData = item is Map<dynamic, dynamic> 
    ? Map<String, dynamic>.from(item) 
    : <String, dynamic>{};
          
          // Add state code
          billData['state'] = stateCode;
          
          // Add bill type
          billData['type'] = 'state';
          
          bills.add(BillModel.fromMap(billData));
        } catch (e) {
          if (kDebugMode) {
            print('Error processing bill data: $e');
          }
          continue;
        }
      }
    }
    
    return bills;
  }

  // Process bill search results
  List<BillModel> _processBillSearchResults(Map<String, dynamic> searchResults, String stateCode) {
    final List<BillModel> bills = [];
    
    if (!searchResults.containsKey('results') || 
        !searchResults['results'].containsKey('bills')) {
      return bills;
    }
    
    final billResults = searchResults['results']['bills'];
    
    if (billResults is! List) {
      return bills;
    }
    
    for (final item in billResults) {
      if (item is Map) {
        try {
          final billData = Map<String, dynamic>.from(item);
          
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
  BillModel _processBillDetails(Map<String, dynamic> billData, String stateCode) {
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
    
    // Create bill model
    final billModel = BillModel.fromMap(billMap);
    
    // Add sponsors if available
    List<RepresentativeSponsor> sponsors = [];
    
    if (bill.containsKey('sponsors') && bill['sponsors'] is List) {
      for (final sponsor in bill['sponsors']) {
        if (sponsor is Map) {
          final sponsorData = Map<String, dynamic>.from(sponsor);
          sponsors.add(RepresentativeSponsor.fromMap(sponsorData));
        }
      }
    }
    
    // Add history if available
    List<BillHistory> history = [];
    
    if (bill.containsKey('history') && bill['history'] is List) {
      for (final action in bill['history']) {
        if (action is Map) {
          final actionData = Map<String, dynamic>.from(action);
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
          final textData = Map<String, dynamic>.from(text);
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
              .map((data) => BillModel.fromMap(Map<String, dynamic>.from(data)))
              .toList();
        }
      }
      
      // Load bill details cache
      if (cacheData.containsKey('details')) {
        final detailsData = cacheData['details'] as Map<String, dynamic>;
        
        for (final entry in detailsData.entries) {
          final billId = int.parse(entry.key);
          final billData = Map<String, dynamic>.from(entry.value);
          
          _billDetailsCache[billId] = BillModel.fromMap(billData);
        }
      }
      
      if (kDebugMode) {
        print('Loaded ${_stateCache.length} states and ${_billDetailsCache.length} bill details from cache');
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
        
        cacheData['states'][stateCode] = billsList.map((bill) => bill.toMap()).toList();
      }
      
      // Save bill details cache
      for (final entry in _billDetailsCache.entries) {
        final billId = entry.key;
        final bill = entry.value;
        
        cacheData['details'][billId.toString()] = bill.toMap();
      }
      
      // Save to shared preferences
      await prefs.setString(_billsCacheKey, json.encode(cacheData));
      await prefs.setInt(_billsLastUpdatedKey, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('Saved ${_stateCache.length} states and ${_billDetailsCache.length} bill details to cache');
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