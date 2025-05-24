// lib/services/enhanced_legiscan_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/models/enhanced_bill_details.dart';
import 'package:govvy/models/session_model.dart';
import 'package:govvy/services/api_exceptions.dart';
import 'package:govvy/services/cache_manager.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';

/// Enhanced LegiScan API service with optimized endpoint usage
class EnhancedLegiscanService {
  // Base API URL
  final String _baseUrl = 'https://api.legiscan.com/';
  
  // Dependencies
  final NetworkService _networkService = NetworkService();
  final CacheManager _cacheManager = CacheManager();
  
  // Session cache with longer TTL
  final Map<String, SessionData> _sessionsCache = {};
  
  // Get API key from Remote Config
  final RemoteConfigService _configService = RemoteConfigService();
  String? get _apiKey => _configService.getLegiscanApiKey;
  bool get hasApiKey {
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;
    if (kDebugMode && !hasKey) {
      print('Enhanced LegiScan service: API key is not available');
    }
    return hasKey;
  }
  
  // Singleton pattern
  static final EnhancedLegiscanService _instance = EnhancedLegiscanService._internal();
  factory EnhancedLegiscanService() => _instance;
  EnhancedLegiscanService._internal();
  
  /// Initialize with session data
  Future<void> initialize() async {
    if (!hasApiKey) {
      if (kDebugMode) {
        print('No LegiScan API key available');
      }
      return;
    }
    
    try {
      // First load from cache
      await _loadSessionsFromCache();
      
      // Then refresh if needed
      final lastSessionUpdate = await _cacheManager.getLastUpdateTime('sessions');
      final now = DateTime.now();
      
      // Only refresh session data weekly
      if (lastSessionUpdate == null || 
          now.difference(lastSessionUpdate).inDays > 7) {
        await refreshSessionData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing enhanced LegiScan service: $e');
      }
    }
  }
  
  /// Load session data from cache
  Future<void> _loadSessionsFromCache() async {
    try {
      final sessionsData = await _cacheManager.getData('sessions');
      
      if (sessionsData == null) {
        return;
      }
      
      // Handle either map format (grouped by state) or list format (flat list of sessions)
      if (sessionsData is Map) {
        // Map format - process by state
        sessionsData.forEach((stateCode, sessions) {
          if (sessions is List) {
            for (final sessionJson in sessions) {
              try {
                final session = SessionData.fromJson(sessionJson);
                _sessionsCache[session.sessionId.toString()] = session;
              } catch (e) {
                if (kDebugMode) {
                  print('Error loading cached session: $e');
                }
              }
            }
          }
        });
      } else if (sessionsData is List) {
        // List format - process directly
        for (final sessionJson in sessionsData) {
          try {
            final session = SessionData.fromJson(sessionJson);
            _sessionsCache[session.sessionId.toString()] = session;
          } catch (e) {
            if (kDebugMode) {
              print('Error loading cached session: $e');
            }
          }
        }
      }
      
      if (kDebugMode) {
        print('Loaded ${_sessionsCache.length} sessions from cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sessions from cache: $e');
      }
    }
  }
  
  /// Get all available legislative sessions
  Future<Map<String, List<SessionData>>> refreshSessionData() async {
    if (!hasApiKey) return {};
    
    try {
      final result = await callApi('getSessionList', {});
      
      if (result == null || !result.containsKey('sessions')) {
        return {};
      }
      
      final Map<String, List<SessionData>> stateSessionsMap = {};
      
      // Handle different response formats - the API can return either a Map or a List
      final sessions = result['sessions'];
      
      if (sessions is Map<String, dynamic>) {
        // Original format - map of state codes to session lists
        sessions.forEach((stateCode, stateSessions) {
          if (stateSessions is List) {
            final sessionDataList = stateSessions
                .map((session) => SessionData.fromJson(session))
                .toList();
            
            stateSessionsMap[stateCode] = sessionDataList;
            
            // Update sessions cache
            for (final session in sessionDataList) {
              _sessionsCache[session.sessionId.toString()] = session;
            }
          }
        });
      } else if (sessions is List) {
        // New format - list of session objects
        for (final session in sessions) {
          if (session is Map<String, dynamic>) {
            try {
              final sessionData = SessionData.fromJson(session);
              
              // Group by state code
              if (sessionData.stateCode.isNotEmpty) {
                if (!stateSessionsMap.containsKey(sessionData.stateCode)) {
                  stateSessionsMap[sessionData.stateCode] = [];
                }
                
                stateSessionsMap[sessionData.stateCode]!.add(sessionData);
                
                // Update sessions cache
                _sessionsCache[sessionData.sessionId.toString()] = sessionData;
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing session data: $e');
              }
            }
          }
        }
      }
      
      // Save to cache with timestamp
      await _cacheManager.saveData(
        'sessions', 
        stateSessionsMap, 
        DateTime.now()
      );
      
      return stateSessionsMap;
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing session data: $e');
      }
      return {};
    }
  }
  
  /// Get bills for a state using the optimal approach
  Future<List<BillModel>> getBillsForState(String stateCode) async {
    if (!hasApiKey) return [];
    
    try {
      // First check cache
      final cachedBills = await _cacheManager.getBills(stateCode);
      final lastUpdate = await _cacheManager.getLastUpdateTime('bills_$stateCode');
      final now = DateTime.now();
      
      // Return cached data if it's less than 24 hours old
      if (cachedBills.isNotEmpty && 
          lastUpdate != null && 
          now.difference(lastUpdate).inHours < 24) {
        return cachedBills;
      }
      
      // Get active session for state
      final sessionId = await _getActiveSessionForState(stateCode);
      
      if (sessionId == null) {
        if (kDebugMode) {
          print('No active session found for state: $stateCode');
        }
        return [];
      }
      
      // Try master list first (fastest for most use cases)
      final masterListParams = {
        'state': stateCode,
        'id': sessionId.toString(),
      };
      
      final masterList = await callApi('getMasterList', masterListParams);
      
      if (masterList != null && masterList.containsKey('masterlist')) {
        final bills = _processMasterList(masterList['masterlist'], stateCode);
        
        // Cache the results
        await _cacheManager.saveBills(stateCode, bills);
        
        return bills;
      }
      
      // Fallback to search
      return _fallbackToSearch(stateCode);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bills for state: $e');
      }
      return [];
    }
  }
  
  /// Fallback to search when getMasterList fails
  Future<List<BillModel>> _fallbackToSearch(String stateCode) async {
    try {
      // Use a search query that will return recent bills
      final searchParams = <String, String>{
        'state': stateCode,
        'query': '*', // Wildcard search
        'year': DateTime.now().year.toString(), // Current year
      };
      
      final searchResults = await callApi('getSearch', searchParams);
      
      if (searchResults != null) {
        final List<BillModel> bills = [];
        
        // Handle different search result formats
        if (searchResults.containsKey('searchresult')) {
          bills.addAll(_processSearchResult(
            searchResults['searchresult'], 
            stateCode
          ));
        } else if (searchResults.containsKey('results') && 
                  searchResults['results'].containsKey('bills')) {
          bills.addAll(_processResultsBills(
            searchResults['results']['bills'], 
            stateCode
          ));
        }
        
        // Cache the results
        await _cacheManager.saveBills(stateCode, bills);
        
        return bills;
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error in fallback search: $e');
      }
      return [];
    }
  }
  
  /// Search bills with optimized query format
  Future<List<BillModel>> searchBills({
    required String query,
    String? stateCode,
    int? year,
    int maxResults = 50
  }) async {
    if (!hasApiKey) return [];
    
    try {
      // Build optimized search parameters
      final searchParams = <String, String>{
        'query': query,
      };
      
      if (stateCode != null) {
        searchParams['state'] = stateCode;
      }
      
      if (year != null) {
        searchParams['year'] = year.toString();
      }
      
      // Cache key based on params
      final cacheKey = 'search_${searchParams.toString().hashCode}';
      final cachedResults = await _cacheManager.getData(cacheKey);
      final lastUpdate = await _cacheManager.getLastUpdateTime(cacheKey);
      final now = DateTime.now();
      
      // Return cached results if less than 1 hour old
      if (cachedResults != null && 
          lastUpdate != null && 
          now.difference(lastUpdate).inHours < 1) {
        return (cachedResults as List).map((item) => 
            BillModel.fromMap(Map<String, dynamic>.from(item))).toList();
      }
      
      // For subject searches, use master list filtering for better performance
      if (stateCode != null && query.length > 3) {
        final stateBills = await getBillsForState(stateCode);
        final filteredBills = stateBills.where((bill) {
          final searchTerm = query.toLowerCase();
          return bill.title.toLowerCase().contains(searchTerm) ||
                 bill.description!.toLowerCase().contains(searchTerm) ||
                 (bill.subjects?.any((subject) => 
                    subject.toLowerCase().contains(searchTerm)) ?? false);
        }).take(maxResults).toList();
        
        if (filteredBills.isNotEmpty) {
          // Cache results
          await _cacheManager.saveData(
            cacheKey, 
            filteredBills.map((b) => b.toMap()).toList(), 
            DateTime.now()
          );
          return filteredBills;
        }
      }
      
      // Fallback to regular search
      final searchResults = await callApi('getSearch', searchParams);
      
      if (searchResults == null) {
        return [];
      }
      
      // Process results
      final List<BillModel> bills = [];
      
      if (searchResults.containsKey('searchresult')) {
        bills.addAll(_processSearchResult(
          searchResults['searchresult'], 
          stateCode ?? 'US'
        ));
      }
      
      // Apply limit
      final limitedBills = bills.length > maxResults 
          ? bills.sublist(0, maxResults) 
          : bills;
      
      // Cache results
      await _cacheManager.saveData(
        cacheKey, 
        limitedBills.map((b) => b.toMap()).toList(), 
        DateTime.now()
      );
      
      return limitedBills;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching bills: $e');
      }
      return [];
    }
  }
  
  /// Search bills by subject using multiple strategies for best results
  Future<List<BillModel>> searchBillsBySubject(
    String subject, {
    String? stateCode
  }) async {
    // Strategy 1: Direct keyword search using master list filtering
    final keywordResults = await searchBills(
      query: subject.toLowerCase(),
      stateCode: stateCode,
    );
    
    if (keywordResults.isNotEmpty) {
      return keywordResults;
    }
    
    // Strategy 2: Try expanded keyword search across multiple years
    final multiYearResults = await searchBillsWithMultipleYears(
      query: subject.toLowerCase(),
      stateCode: stateCode,
    );
    
    if (multiYearResults.isNotEmpty) {
      return multiYearResults;
    }
    
    // Strategy 3: Try subject-specific format as final fallback
    final formattedQuery = subject.contains(' ') ? 'subject:"$subject"' : 'subject:$subject';
    return searchBills(
      query: formattedQuery,
      stateCode: stateCode,
    );
  }
  
  /// Search bills across multiple years for better coverage
  Future<List<BillModel>> searchBillsWithMultipleYears({
    required String query,
    String? stateCode,
    int maxResults = 50
  }) async {
    final years = [2025, 2024, 2023];
    List<BillModel> allResults = [];
    
    for (final year in years) {
      final results = await searchBills(
        query: query,
        stateCode: stateCode,
        year: year,
        maxResults: maxResults
      );
      
      allResults.addAll(results);
      
      // If we found good results in this year, stop searching older years
      if (results.length >= 20) {
        break;
      }
    }
    
    // Remove duplicates based on bill_id
    final uniqueBills = <BillModel>[];
    final seenIds = <int>{};
    
    for (final bill in allResults) {
      if (!seenIds.contains(bill.billId)) {
        seenIds.add(bill.billId);
        uniqueBills.add(bill);
      }
    }
    
    return uniqueBills;
  }
  
  /// Search bills by sponsor
  Future<List<BillModel>> searchBillsBySponsor(
    String sponsorName, {
    String? stateCode
  }) async {
    // Format sponsor query correctly for LegiScan API
    final formattedQuery = sponsorName.contains(' ') ? 'sponsor:"$sponsorName"' : 'sponsor:$sponsorName';
    
    return searchBills(
      query: formattedQuery,
      stateCode: stateCode,
    );
  }
  
  /// Get comprehensive bill details with all related data using multiple API calls
  Future<EnhancedBillDetails?> getBillDetails(int billId, String stateCode) async {
    if (!hasApiKey) return null;
    
    try {
      // Check cache
      final cacheKey = 'bill_details_$billId';
      final cachedDetails = await _cacheManager.getData(cacheKey);
      final lastUpdate = await _cacheManager.getLastUpdateTime(cacheKey);
      final now = DateTime.now();
      
      // Return cached data if less than 2 hours old
      if (cachedDetails != null && 
          lastUpdate != null && 
          now.difference(lastUpdate).inHours < 2) {
        return EnhancedBillDetails.fromMap(Map<String, dynamic>.from(cachedDetails));
      }
      
      // Fetch fresh data
      final params = {'id': billId.toString()};
      final billData = await callApi('getBill', params);
      
      if (billData == null || !billData.containsKey('bill')) {
        if (billData != null && 
            billData.containsKey('alert') &&
            billData['alert'].toString().contains('Unknown bill id')) {
          throw BillNotFoundException('Bill not found', billId, stateCode: stateCode);
        }
        return null;
      }
      
      // Process the enhanced bill details
      final enhancedDetails = EnhancedBillDetails.fromApiResponse(billData, stateCode);
      
      // Enhance with additional API calls for comprehensive data
      await _enrichBillWithAdditionalData(enhancedDetails);
      
      // Cache the details
      await _cacheManager.saveData(
        cacheKey, 
        enhancedDetails.toMap(), 
        DateTime.now()
      );
      
      return enhancedDetails;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bill details: $e');
      }
      if (e is BillNotFoundException) {
        rethrow;
      }
      return null;
    }
  }
  
  /// Get active session ID for a state
  Future<int?> _getActiveSessionForState(String stateCode) async {
    try {
      // Check if we have sessions cached
      if (_sessionsCache.isEmpty) {
        // Get sessions
        final sessions = await refreshSessionData();
        
        if (!sessions.containsKey(stateCode) || 
            sessions[stateCode]!.isEmpty) {
          return null;
        }
        
        // Find active session
        final stateSessions = sessions[stateCode]!;
        for (final session in stateSessions) {
          if (session.isActive) {
            return session.sessionId;
          }
        }
        
        // If no active session, return most recent
        stateSessions.sort((a, b) => 
            b.sessionStartDate.compareTo(a.sessionStartDate));
        return stateSessions.first.sessionId;
      } else {
        // Find session for state in cache
        final stateSessions = _sessionsCache.values
            .where((s) => s.stateCode == stateCode)
            .toList();
            
        if (stateSessions.isEmpty) {
          return null;
        }
        
        // Find active session
        for (final session in stateSessions) {
          if (session.isActive) {
            return session.sessionId;
          }
        }
        
        // If no active session, return most recent
        stateSessions.sort((a, b) => 
            b.sessionStartDate.compareTo(a.sessionStartDate));
        return stateSessions.first.sessionId;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active session: $e');
      }
      return null;
    }
  }
  
  /// Process LegiScan masterlist data
  List<BillModel> _processMasterList(Map<String, dynamic> masterList, String stateCode) {
    final List<BillModel> bills = [];

    // Debug logging to understand the structure
    if (kDebugMode) {
      print('LegiScan: Processing master list for state $stateCode');
      print('LegiScan: Master list keys: ${masterList.keys.take(10).toList()}'); // First 10 keys
      
      // Log first bill entry to understand structure
      masterList.forEach((key, value) {
        if (key != 'session' && value is Map) {
          print('LegiScan: Sample master list bill $key fields: ${(value as Map).keys.toList()}');
          if ((value as Map).containsKey('bill_number')) {
            print('LegiScan: Master list bill number found: ${value['bill_number']}');
          } else if ((value as Map).containsKey('number')) {
            print('LegiScan: Master list number found: ${value['number']}');
          } else {
            print('LegiScan: No bill_number or number field found in master list');
          }
          return; // Only log first bill
        }
      });
    }

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
        if (kDebugMode) {
          print('Error processing bill from masterlist: $e');
        }
      }
    });

    return bills;
  }
  
  /// Process results bills format from getSearch API
  List<BillModel> _processResultsBills(List<dynamic> billsList, String stateCode) {
    final List<BillModel> bills = [];

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
          if (kDebugMode) {
            print('Error processing bill from results: $e');
          }
          continue;
        }
      }
    }

    return bills;
  }
  
  /// Get detailed information for a roll call vote
  Future<Map<String, dynamic>?> getRollCallDetails(int rollCallId) async {
    if (!hasApiKey) return null;
    
    try {
      // Check cache
      final cacheKey = 'roll_call_$rollCallId';
      final cachedDetails = await _cacheManager.getData(cacheKey);
      final lastUpdate = await _cacheManager.getLastUpdateTime(cacheKey);
      final now = DateTime.now();
      
      // Return cached data if less than 24 hours old
      if (cachedDetails != null && 
          lastUpdate != null && 
          now.difference(lastUpdate).inHours < 24) {
        return Map<String, dynamic>.from(cachedDetails);
      }
      
      // Fetch fresh data
      final params = {'id': rollCallId.toString()};
      final rollCallData = await callApi('getRollCall', params);
      
      if (rollCallData == null || !rollCallData.containsKey('roll_call')) {
        return null;
      }
      
      // Cache the details
      await _cacheManager.saveData(
        cacheKey, 
        rollCallData['roll_call'], 
        DateTime.now()
      );
      
      return rollCallData['roll_call'];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting roll call details: $e');
      }
      return null;
    }
  }
  
  /// Get amendment details
  Future<Map<String, dynamic>?> getAmendmentDetails(int amendmentId) async {
    if (!hasApiKey) return null;
    
    try {
      // Check cache
      final cacheKey = 'amendment_$amendmentId';
      final cachedDetails = await _cacheManager.getData(cacheKey);
      final lastUpdate = await _cacheManager.getLastUpdateTime(cacheKey);
      final now = DateTime.now();
      
      // Return cached data if less than 24 hours old
      if (cachedDetails != null && 
          lastUpdate != null && 
          now.difference(lastUpdate).inHours < 24) {
        return Map<String, dynamic>.from(cachedDetails);
      }
      
      // Fetch fresh data
      final params = {'id': amendmentId.toString()};
      final amendmentData = await callApi('getAmendment', params);
      
      if (amendmentData == null || !amendmentData.containsKey('amendment')) {
        return null;
      }
      
      // Cache the details
      await _cacheManager.saveData(
        cacheKey, 
        amendmentData['amendment'], 
        DateTime.now()
      );
      
      return amendmentData['amendment'];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting amendment details: $e');
      }
      return null;
    }
  }
  
  /// Get supplement details (fiscal notes, analyses, etc.)
  Future<Map<String, dynamic>?> getSupplementDetails(int supplementId) async {
    if (!hasApiKey) return null;
    
    try {
      // Check cache
      final cacheKey = 'supplement_$supplementId';
      final cachedDetails = await _cacheManager.getData(cacheKey);
      final lastUpdate = await _cacheManager.getLastUpdateTime(cacheKey);
      final now = DateTime.now();
      
      // Return cached data if less than 24 hours old
      if (cachedDetails != null && 
          lastUpdate != null && 
          now.difference(lastUpdate).inHours < 24) {
        return Map<String, dynamic>.from(cachedDetails);
      }
      
      // Fetch fresh data
      final params = {'id': supplementId.toString()};
      final supplementData = await callApi('getSupplement', params);
      
      if (supplementData == null || !supplementData.containsKey('supplement')) {
        return null;
      }
      
      // Cache the details
      await _cacheManager.saveData(
        cacheKey, 
        supplementData['supplement'], 
        DateTime.now()
      );
      
      return supplementData['supplement'];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting supplement details: $e');
      }
      return null;
    }
  }
  
  /// Comprehensive method to enrich bill with all available API data
  Future<void> _enrichBillWithAdditionalData(EnhancedBillDetails billDetails) async {
    // Enrich with roll call data
    await _enrichRollCallData(billDetails);
    
    // Enrich with sponsor details
    await _enrichSponsorData(billDetails);
    
    // Enrich with bill text documents
    await _enrichBillTextData(billDetails);
    
    // Enrich with amendments if available
    if (billDetails.amendments != null && billDetails.amendments!.isNotEmpty) {
      await _enrichAmendmentData(billDetails);
    }
    
    // Enrich with supplements if available
    if (billDetails.supplements != null && billDetails.supplements!.isNotEmpty) {
      await _enrichSupplementData(billDetails);
    }
  }
  
  /// Helper method to enrich roll call data with vote details
  Future<void> _enrichRollCallData(EnhancedBillDetails billDetails) async {
    // Only process if we have votes
    if (billDetails.votes == null || billDetails.votes!.isEmpty) {
      return;
    }
    
    // Create a map to store the enriched vote data
    final Map<int, Map<String, dynamic>> enrichedVotes = {};
    
    // Process each vote to get detailed roll call data
    for (final vote in billDetails.votes!) {
      try {
        final rollCallData = await getRollCallDetails(vote.rollCallId);
        if (rollCallData != null) {
          enrichedVotes[vote.rollCallId] = rollCallData;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error enriching roll call ${vote.rollCallId}: $e');
        }
      }
    }
    
    // Store the enriched data in the extraData map for access in the UI
    if (enrichedVotes.isNotEmpty) {
      billDetails.extraData['enriched_votes'] = enrichedVotes;
    }
  }
  
  /// Enrich sponsor data with detailed representative information
  Future<void> _enrichSponsorData(EnhancedBillDetails billDetails) async {
    if (billDetails.sponsors.isEmpty) {
      return;
    }
    
    final Map<int, Map<String, dynamic>> enrichedSponsors = {};
    
    // Process each sponsor to get detailed information
    for (final sponsor in billDetails.sponsors) {
      try {
        final sponsorDetails = await getPersonDetails(sponsor.peopleId);
        if (sponsorDetails != null) {
          enrichedSponsors[sponsor.peopleId] = sponsorDetails;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error enriching sponsor ${sponsor.peopleId}: $e');
        }
      }
    }
    
    // Store the enriched sponsor data
    if (enrichedSponsors.isNotEmpty) {
      billDetails.extraData['enriched_sponsors'] = enrichedSponsors;
    }
  }
  
  /// Enrich bill with text documents using getBillText API
  Future<void> _enrichBillTextData(EnhancedBillDetails billDetails) async {
    if (billDetails.documents.isEmpty) {
      return;
    }
    
    final Map<int, Map<String, dynamic>> enrichedTexts = {};
    
    // Process each document to get full text
    for (final document in billDetails.documents) {
      try {
        final textDetails = await getBillTextDetails(document.documentId);
        if (textDetails != null) {
          enrichedTexts[document.documentId] = textDetails;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error enriching bill text ${document.documentId}: $e');
        }
      }
    }
    
    // Store the enriched text data
    if (enrichedTexts.isNotEmpty) {
      billDetails.extraData['enriched_texts'] = enrichedTexts;
    }
  }
  
  /// Enrich amendment data with detailed amendment information
  Future<void> _enrichAmendmentData(EnhancedBillDetails billDetails) async {
    if (billDetails.amendments == null || billDetails.amendments!.isEmpty) {
      return;
    }
    
    final Map<int, Map<String, dynamic>> enrichedAmendments = {};
    
    // Process each amendment to get detailed information
    for (final amendment in billDetails.amendments!) {
      try {
        final amendmentDetails = await getAmendmentDetails(amendment.amendmentId);
        if (amendmentDetails != null) {
          enrichedAmendments[amendment.amendmentId] = amendmentDetails;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error enriching amendment ${amendment.amendmentId}: $e');
        }
      }
    }
    
    // Store the enriched amendment data
    if (enrichedAmendments.isNotEmpty) {
      billDetails.extraData['enriched_amendments'] = enrichedAmendments;
    }
  }
  
  /// Enrich supplement data with detailed supplement information
  Future<void> _enrichSupplementData(EnhancedBillDetails billDetails) async {
    if (billDetails.supplements == null || billDetails.supplements!.isEmpty) {
      return;
    }
    
    final Map<int, Map<String, dynamic>> enrichedSupplements = {};
    
    // Process each supplement to get detailed information
    for (final supplement in billDetails.supplements!) {
      try {
        final supplementDetails = await getSupplementDetails(supplement.supplementId);
        if (supplementDetails != null) {
          enrichedSupplements[supplement.supplementId] = supplementDetails;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error enriching supplement ${supplement.supplementId}: $e');
        }
      }
    }
    
    // Store the enriched supplement data
    if (enrichedSupplements.isNotEmpty) {
      billDetails.extraData['enriched_supplements'] = enrichedSupplements;
    }
  }
  
  /// Get detailed person information using getPerson API
  Future<Map<String, dynamic>?> getPersonDetails(int personId) async {
    if (!hasApiKey) return null;
    
    try {
      // Check cache
      final cacheKey = 'person_$personId';
      final cachedDetails = await _cacheManager.getData(cacheKey);
      final lastUpdate = await _cacheManager.getLastUpdateTime(cacheKey);
      final now = DateTime.now();
      
      // Return cached data if less than 7 days old (person data changes infrequently)
      if (cachedDetails != null && 
          lastUpdate != null && 
          now.difference(lastUpdate).inDays < 7) {
        return Map<String, dynamic>.from(cachedDetails);
      }
      
      // Fetch fresh data
      final params = {'id': personId.toString()};
      final personData = await callApi('getPerson', params);
      
      if (personData == null || !personData.containsKey('person')) {
        return null;
      }
      
      // Cache the details
      await _cacheManager.saveData(
        cacheKey, 
        personData['person'], 
        DateTime.now()
      );
      
      return personData['person'];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting person details: $e');
      }
      return null;
    }
  }
  
  /// Get bill text details using getBillText API
  Future<Map<String, dynamic>?> getBillTextDetails(int textId) async {
    if (!hasApiKey) return null;
    
    try {
      // Check cache
      final cacheKey = 'bill_text_$textId';
      final cachedDetails = await _cacheManager.getData(cacheKey);
      final lastUpdate = await _cacheManager.getLastUpdateTime(cacheKey);
      final now = DateTime.now();
      
      // Return cached data if less than 24 hours old
      if (cachedDetails != null && 
          lastUpdate != null && 
          now.difference(lastUpdate).inHours < 24) {
        return Map<String, dynamic>.from(cachedDetails);
      }
      
      // Fetch fresh data
      final params = {'id': textId.toString()};
      final textData = await callApi('getBillText', params);
      
      if (textData == null || !textData.containsKey('text')) {
        return null;
      }
      
      // Cache the details
      await _cacheManager.saveData(
        cacheKey, 
        textData['text'], 
        DateTime.now()
      );
      
      return textData['text'];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bill text details: $e');
      }
      return null;
    }
  }
  
  /// Process search result format from getSearch API
  List<BillModel> _processSearchResult(Map<String, dynamic> searchresult, String stateCode) {
    final List<BillModel> bills = [];
    
    // Debug logging to understand the structure
    if (kDebugMode) {
      print('LegiScan: Processing search result for state $stateCode');
      print('LegiScan: Search result keys: ${searchresult.keys.toList()}');
      
      // Log first few bill entries to understand structure
      var billCount = 0;
      searchresult.forEach((key, value) {
        if (key != 'summary' && value is Map && billCount < 2) {
          print('LegiScan: Sample bill $key fields: ${(value as Map).keys.toList()}');
          if ((value as Map).containsKey('bill_number')) {
            print('LegiScan: Bill number found: ${value['bill_number']}');
          } else {
            print('LegiScan: No bill_number field found');
          }
          billCount++;
        }
      });
    }

    // Loop through the keys in the searchresult
    searchresult.forEach((key, value) {
      // Skip the "summary" key or any non-map entries
      if (key == 'summary' || value is! Map) {
        return;
      }

      try {
        // Convert the value to a properly typed Map
        final Map<String, dynamic> billData = Map<String, dynamic>.from(value);

        // The LegiScan API returns bill_id as an integer, ensure it's treated as such
        if (billData.containsKey('bill_id') && billData['bill_id'] is String) {
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
        if (!billData.containsKey('status_desc') && billData.containsKey('last_action')) {
          billData['status_desc'] = billData['last_action'];
        }

        // Try to extract bill number from various possible field names
        String billNumber = 'Unknown';
        
        // Check for various field names the API might use
        final possibleBillNumberFields = [
          'bill_number', 'number', 'bill_num', 'bill_no', 
          'bill', 'doc_id', 'measure_number'
        ];
        
        for (final fieldName in possibleBillNumberFields) {
          if (billData.containsKey(fieldName) && billData[fieldName] != null) {
            if (billData[fieldName] is String && (billData[fieldName] as String).isNotEmpty) {
              billNumber = billData[fieldName] as String;
              break;
            } else if (billData[fieldName] is List && (billData[fieldName] as List).isNotEmpty) {
              billNumber = (billData[fieldName] as List).join(' ');
              break;
            }
          }
        }
        
        // If still no bill number found, try to construct from other fields
        if (billNumber == 'Unknown') {
          // Check if we have title that might contain bill number
          final title = billData['title'] as String?;
          if (title != null && title.isNotEmpty) {
            // Try to extract bill number from title (e.g., "HB 123 - Some Title")
            final billNumberMatch = RegExp(r'^([A-Z]{1,3}[\s]*\d+)').firstMatch(title);
            if (billNumberMatch != null) {
              billNumber = billNumberMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' ');
            }
          }
        }
        
        // Debug logging to help identify the issue
        if (kDebugMode && billNumber == 'Unknown') {
          print('LegiScan: Could not find bill number in search result. Available fields: ${billData.keys.toList()}');
          print('LegiScan: Sample data: ${billData.toString().substring(0, min(200, billData.toString().length))}...');
        }
        
        // Create standardized bill model fields
        final mappedBillData = {
          'bill_id': billData['bill_id'] ?? billData.hashCode,
          'bill_number': billNumber,
          'title': billData['title'] ?? 'Untitled Bill',
          'description': null, // LegiScan doesn't provide description in search results
          'status_desc': billData['status_desc'] ?? billData['last_action'] ?? 'Unknown status',
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
        if (kDebugMode) {
          print('Error processing bill from searchresult: $e');
        }
      }
    });

    return bills;
  }
  
  /// Get timeout duration based on operation
  Duration _getTimeoutForOperation(String operation) {
    switch (operation) {
      case 'getBill':
        return const Duration(seconds: 30); // Longer timeout for bill details
      case 'getMasterList':
        return const Duration(seconds: 30); // Longer timeout for master list
      case 'getDataset':
        return const Duration(minutes: 2); // Much longer for dataset download
      default:
        return const Duration(seconds: 15); // Standard timeout
    }
  }
  
  /// Determine if we should retry based on status code
  bool _shouldRetry(int statusCode) {
    // Retry server errors (5xx) but not client errors (4xx)
    return statusCode >= 500 && statusCode < 600;
  }
  
  /// Enhanced API call with better error handling and retry logic
  Future<Map<String, dynamic>?> callApi(
    String operation, 
    Map<String, String> params, 
    {int maxRetries = 3}
  ) async {
    if (!hasApiKey) return null;
    
    try {
      if (!await _networkService.checkConnectivity()) {
        throw NetworkException('No network connectivity');
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
      
      // Configure timeout based on operation
      final Duration timeout = _getTimeoutForOperation(operation);
      
      // Add retry logic with exponential backoff
      int retryCount = 0;
      Exception? lastError;
      
      while (retryCount < maxRetries) {
        try {
          final response = await http.get(url).timeout(timeout);
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            
            // Check for API error status
            if (data.containsKey('status')) {
              if (data['status'] == 'OK') {
                return data;
              } else {
                // Special handling for specific errors
                if (data.containsKey('alert')) {
                  final errorMessage = data['alert'] is String 
                      ? data['alert'] 
                      : data['alert']['message'];
                      
                  if (operation == 'getBill' || 
                      operation == 'getSearch') {
                    // Return error response for special handling
                    return data;
                  }
                  
                  throw LegiscanApiException(errorMessage);
                }
              }
            } else {
              // Missing status field - return anyway in case it's usable
              return data;
            }
          } else if (_shouldRetry(response.statusCode)) {
            // Server error, try again
            lastError = ServerException(
                'Server error', 
                statusCode: response.statusCode);
            retryCount++;
            
            if (kDebugMode) {
              print('Retry $retryCount after server error (${response.statusCode})');
            }
            
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          } else {
            throw ServerException(
                'API error', 
                statusCode: response.statusCode);
          }
        } on TimeoutException {
          lastError = ApiTimeoutException(
              'API call timed out', 
              timeout.inMilliseconds);
          
          retryCount++;
          
          if (kDebugMode) {
            print('Retry $retryCount after timeout (${timeout.inSeconds}s)');
          }
          
          if (retryCount >= maxRetries) break;
          
          // Exponential backoff
          await Future.delayed(Duration(seconds: retryCount * 2));
        } catch (e) {
          // Handle other errors
          lastError = e is Exception ? e : Exception(e.toString());
          
          retryCount++;
          
          if (kDebugMode) {
            print('Retry $retryCount after error: $e');
          }
          
          if (retryCount >= maxRetries) break;
          
          // Exponential backoff
          await Future.delayed(Duration(seconds: retryCount * 2));
        }
      }
      
      // All retries failed
      throw lastError ?? Exception('API call failed after $maxRetries retries');
    } catch (e) {
      if (kDebugMode) {
        print('Error in LegiScan API call: $e');
      }
      
      if (e is ApiErrorException) {
        rethrow;
      }
      
      return null;
    }
  }
}