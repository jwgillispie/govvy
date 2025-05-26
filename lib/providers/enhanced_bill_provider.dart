// lib/providers/enhanced_bill_provider.dart
import 'package:flutter/foundation.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/models/enhanced_bill_details.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/api_exceptions.dart';
import 'package:govvy/services/enhanced_legiscan_service.dart';
import 'package:govvy/services/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Enhanced bill provider that uses the improved LegiScan service
class EnhancedBillProvider with ChangeNotifier {
  // Services
  final EnhancedLegiscanService _legiscanService = EnhancedLegiscanService();
  final NetworkService _networkService = NetworkService();

  // State for bill lists
  List<BillModel> _stateBills = [];
  List<BillModel> _searchResultBills = [];
  List<BillModel> _recentBills = [];  // For recently viewed bills
  
  // State for bill details
  EnhancedBillDetails? _selectedBillDetails;
  
  // Loading and error states
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;
  String? _errorMessageDetails;
  
  // Search state tracking
  String? _lastSearchQuery;
  String? _lastSearchType; // 'state', 'subject', 'keyword', etc.
  String? _lastStateCode;
  int? _lastBillId;
  
  // Pagination state
  int _currentPage = 1;
  final int _totalPages = 1;
  final int _resultsPerPage = 20;
  bool _hasMoreResults = false;
  
  // State-specific optimizations
  bool _isSpecialStateHandling = false;
  
  // Getters for the state
  List<BillModel> get stateBills => _stateBills;
  List<BillModel> get searchResultBills => _searchResultBills;
  List<BillModel> get recentBills => _recentBills;
  
  EnhancedBillDetails? get selectedBillDetails => _selectedBillDetails;
  BillModel? get selectedBill => _selectedBillDetails?.bill;
  List<BillDocument>? get selectedBillDocuments => _selectedBillDetails?.documents;
  
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;
  String? get errorMessageDetails => _errorMessageDetails;
  
  String? get lastSearchQuery => _lastSearchQuery;
  String? get lastSearchType => _lastSearchType;
  String? get lastStateCode => _lastStateCode;
  
  // Pagination getters
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMoreResults => _hasMoreResults;
  int get resultsPerPage => _resultsPerPage;
  
  // Constructor with initialization
  EnhancedBillProvider() {
    _initializeAndLoadCache();
  }
  
  // Initialize the provider
  Future<void> _initializeAndLoadCache() async {
    try {
      // Initialize the legiscan service
      await _legiscanService.initialize();
      
      // Load recent bills from cache
      await _loadRecentBillsFromCache();
    } catch (e) {
      _errorMessage = 'Error initializing bill data: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Helper to check network before making requests
  Future<bool> _checkNetworkBeforeRequest() async {
    try {
      final isConnected = await _networkService.checkConnectivity();
      
      if (!isConnected) {
        _errorMessage = 'No internet connection available. Please check your network settings.';
        notifyListeners();
      }
      
      return isConnected;
    } catch (e) {
      return true; // Assume connected if check fails
    }
  }
  
  // Get bills by state with state-specific optimizations
  Future<void> fetchBillsByState(String stateCode) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastStateCode = stateCode;
      _lastSearchType = 'state';
      _currentPage = 1;
      _isSpecialStateHandling = _needsSpecialStateHandling(stateCode);
      notifyListeners();
      
      // Get bills for the selected state, with special handling for certain states
      if (_isSpecialStateHandling) {
        _stateBills = await _getStateSpecificBills(stateCode);
      } else {
        _stateBills = await _legiscanService.getBillsForState(stateCode);
      }
      
      if (_stateBills.isEmpty) {
        _errorMessage = 'No bills found for $stateCode. Please try a different state.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }
  
  // Search bills by subject
  Future<void> searchBillsBySubject(String subject, {String? stateCode}) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchQuery = subject;
      _lastSearchType = 'subject';
      _lastStateCode = stateCode;
      _currentPage = 1;
      notifyListeners();
      
      final results = await _legiscanService.searchBillsBySubject(
        subject, 
        stateCode: stateCode
      );
      
      _searchResultBills = results;
      
      if (_searchResultBills.isEmpty) {
        _errorMessage = 'No bills found for subject: $subject${stateCode != null ? ' in $stateCode' : ''}.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }
  
  // Search bills by keyword
  Future<void> searchBillsByKeyword(String keyword, {String? stateCode}) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchQuery = keyword;
      _lastSearchType = 'keyword';
      _lastStateCode = stateCode;
      _currentPage = 1;
      notifyListeners();
      
      final results = await _legiscanService.searchBills(
        query: keyword,
        stateCode: stateCode
      );
      
      _searchResultBills = results;
      
      if (_searchResultBills.isEmpty) {
        _errorMessage = 'No bills found for keyword: $keyword${stateCode != null ? ' in $stateCode' : ''}.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }
  
  // Search bills by representative
  Future<void> searchBillsBySponsor(String sponsorName, {String? stateCode}) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchQuery = sponsorName;
      _lastSearchType = 'sponsor';
      _lastStateCode = stateCode;
      _currentPage = 1;
      notifyListeners();
      
      final results = await _legiscanService.searchBillsBySponsor(
        sponsorName,
        stateCode: stateCode
      );
      
      _searchResultBills = results;
      
      if (_searchResultBills.isEmpty) {
        _errorMessage = 'No bills found for sponsor: $sponsorName${stateCode != null ? ' in $stateCode' : ''}.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }
  
  // Get bills by representative object - supports both Representative and RepresentativeDetails
  Future<void> fetchBillsByRepresentative(dynamic representative) async {
    // Validate the input type
    if (representative is! Representative && representative is! RepresentativeDetails) {
      _errorMessage = 'Invalid representative type provided';
      notifyListeners();
      return;
    }
    
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      
      // Use the appropriate properties based on the type
      String name;
      String state;
      
      if (representative is Representative) {
        name = representative.name;
        state = representative.state;
      } else {
        // It must be RepresentativeDetails based on our validation
        final repDetails = representative as RepresentativeDetails;
        name = repDetails.name;
        state = repDetails.state;
      }
      
      _lastSearchQuery = name;
      _lastSearchType = 'representative';
      _lastStateCode = state;
      _currentPage = 1;
      notifyListeners();
      
      final results = await _legiscanService.searchBillsBySponsor(
        name,
        stateCode: state
      );
      
      _searchResultBills = results;
      
      if (_searchResultBills.isEmpty) {
        _errorMessage = 'No bills found for representative: $name.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }
  
  // Get bill details with improved error recovery
  Future<void> fetchBillDetails(int billId, String stateCode) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoadingDetails = true;
      _errorMessageDetails = null;
      _lastBillId = billId;
      notifyListeners();
      
      // Check cache first for faster loading
      final billDetails = await _legiscanService.getBillDetails(billId, stateCode);
      
      _selectedBillDetails = billDetails;
      
      if (billDetails != null) {
        // Add to recent bills
        _addToRecentBills(billDetails.bill);
      }
      
      _isLoadingDetails = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDetails = false;
      _errorMessageDetails = _formatErrorMessage(e);
      
      // Enhanced error recovery strategies
      if (e is BillNotFoundException) {
        // First try to find in recent bills
        final foundInRecent = _recentBills.where((bill) => bill.billId == billId).toList();
        if (foundInRecent.isNotEmpty) {
          // Create a basic EnhancedBillDetails from the recent bill
          _selectedBillDetails = EnhancedBillDetails(
            bill: foundInRecent.first,
            sponsors: [],
            history: [],
            documents: [],
            subjects: [],
            votes: [],
            amendments: [],
            supplements: [],
            extraData: {
              'from_cache': true,
              'complete_data': false,
              'note': 'Limited data available - bill details could not be retrieved from API'
            },
          );
        } else if (stateCode.isNotEmpty) {
          // Try to search for the bill by ID as fallback
          _tryFallbackBillSearch(billId, stateCode);
        }
      } else if (e is ApiTimeoutException) {
        // For timeouts, let's create a placeholder and retry in background
        _createPlaceholderBillDetails(billId, stateCode);
        _retryLoadingBillDetailsInBackground(billId, stateCode);
      } else if (e is NetworkException) {
        // For network errors, check if we have any cached version
        _tryLoadingFromCache(billId, stateCode);
      }
      
      notifyListeners();
    }
  }
  
  // Add a bill to recently viewed bills with enhanced metadata
  void _addToRecentBills(BillModel bill) {
    // Check if already in recent bills
    final existingIndex = _recentBills.indexWhere((item) => item.billId == bill.billId);
    
    if (existingIndex != -1) {
      // Move to the top if already in list
      final existing = _recentBills.removeAt(existingIndex);
      _recentBills.insert(0, existing);
    } else {
      // Add to the beginning of the list
      _recentBills.insert(0, bill);
      
      // Limit to 15 recent bills - increased from 10 for better history
      if (_recentBills.length > 15) {
        _recentBills.removeLast();
      }
    }
    
    // Save to cache
    _saveRecentBillsToCache();
    
    notifyListeners();
  }
  
  // Load recent bills from cache with error handling
  Future<void> _loadRecentBillsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentBillsJson = prefs.getString('recent_bills');
      
      if (recentBillsJson != null) {
        final List<dynamic> recentBillsData = json.decode(recentBillsJson);
        
        _recentBills = recentBillsData
            .map((data) => BillModel.fromMap(Map<String, dynamic>.from(data)))
            .toList();
        
        // Filter out any malformed entries
        _recentBills = _recentBills.where((bill) => 
            bill.billId > 0 && 
            bill.billNumber.isNotEmpty &&
            bill.state.isNotEmpty).toList();
        
        if (_recentBills.isNotEmpty) {
          if (kDebugMode) {
            print('Loaded ${_recentBills.length} recent bills from cache');
          }
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recent bills from cache: $e');
      }
      // Clear on error
      _recentBills.clear();
    }
  }
  
  // Save recent bills to cache
  Future<void> _saveRecentBillsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final recentBillsData = _recentBills.map((bill) => bill.toMap()).toList();
      final recentBillsJson = json.encode(recentBillsData);
      
      await prefs.setString('recent_bills', recentBillsJson);
    } catch (e) {
      // Error handled silently
    }
  }
  
  // Clear error messages
  void clearErrors() {
    _errorMessage = null;
    _errorMessageDetails = null;
    notifyListeners();
  }
  
  // Clear selected bill
  void clearSelectedBill() {
    _selectedBillDetails = null;
    notifyListeners();
  }
  
  // Set selected bill directly
  void setSelectedBill(BillModel bill) {
    _selectedBillDetails = EnhancedBillDetails(
      bill: bill,
      sponsors: [],
      history: [],
      documents: [],
      subjects: [],
      votes: [],
      amendments: [],
      supplements: [],
      extraData: {},
    );
    _errorMessageDetails = null;
    _isLoadingDetails = false;
    
    // Add to recent bills
    _addToRecentBills(bill);
    
    notifyListeners();
    
    // Also fetch full details in the background if we have a bill ID
    if (bill.billId > 0) {
      fetchBillDetails(bill.billId, bill.state);
    }
  }
  
  // Get a reference to the enhanced bill details when other providers need it
  EnhancedBillDetails? getEnhancedBillDetailsForId(int billId) {
    if (_selectedBillDetails?.bill.billId == billId) {
      return _selectedBillDetails;
    }
    return null;
  }
  
  // Clear all bills data
  void clearAll() {
    _stateBills.clear();
    _searchResultBills.clear();
    _selectedBillDetails = null;
    _errorMessage = null;
    _errorMessageDetails = null;
    _lastSearchQuery = null;
    _lastSearchType = null;
    _lastStateCode = null;
    _lastBillId = null;
    _currentPage = 1;
    _isSpecialStateHandling = false;
    notifyListeners();
  }
  
  // Determine if a state needs special handling
  bool _needsSpecialStateHandling(String stateCode) {
    // States that need custom handling due to API limitations or data quirks
    const specialStates = ['FL', 'GA', 'LA', 'CA', 'NY', 'TX', 'IL', 'PA', 'OH'];
    return specialStates.contains(stateCode.toUpperCase());
  }
  
  // State-specific bill retrieval optimizations
  Future<List<BillModel>> _getStateSpecificBills(String stateCode) async {
    stateCode = stateCode.toUpperCase();
    
    switch (stateCode) {
      case 'FL':
        return _getFLBills();
      case 'GA':
        return _getGABills();
      case 'CA':
        return _getCABills(); 
      case 'NY':
        return _getNYBills();
      case 'TX':
        return _getTXBills();
      case 'IL':
        return _getILBills();
      case 'PA':
        return _getPABills();
      case 'OH':
        return _getOHBills();
      case 'LA':
        return _getLABills();
      default:
        // Fall back to standard method
        return _legiscanService.getBillsForState(stateCode);
    }
  }
  
  // Florida state-specific bill retrieval
  Future<List<BillModel>> _getFLBills() async {
    final keyword = 'florida';
    
    // Try multiple years: 2025, 2024, 2023
    final years = [2025, 2024, 2023];
    List<BillModel> allResults = [];
    
    for (final year in years) {
      final results = await _legiscanService.searchBills(
        query: keyword,
        stateCode: 'FL',
        year: year
      );
      
      allResults.addAll(results);
      
      // If we found bills, we can stop here
      if (results.isNotEmpty) {
        break;
      }
    }
    
    // If keyword search across years failed, try session-based search
    if (allResults.isEmpty) {
      final sessionResults = await _legiscanService.getBillsForState('FL');
      return sessionResults;
    }
    
    return allResults;
  }
  
  // Georgia state-specific bill retrieval
  Future<List<BillModel>> _getGABills() async {
    final keyword = 'georgia';
    
    // Try multiple years: 2025, 2024, 2023
    final years = [2025, 2024, 2023];
    List<BillModel> allResults = [];
    
    for (final year in years) {
      final results = await _legiscanService.searchBills(
        query: keyword,
        stateCode: 'GA',
        year: year
      );
      
      allResults.addAll(results);
      
      // If we found bills, we can stop here
      if (results.isNotEmpty) {
        break;
      }
    }
    
    // If keyword search across years failed, try session-based search
    if (allResults.isEmpty) {
      final sessionResults = await _legiscanService.getBillsForState('GA');
      return sessionResults;
    }
    
    return allResults;
  }
  
  // California state-specific bill retrieval
  Future<List<BillModel>> _getCABills() async {
    // California has many bills, so we use a more targeted approach
    final List<String> prioritySubjects = [
      'taxes', 'education', 'health', 'environment', 
      'housing', 'transportation', 'technology'
    ];
    
    List<BillModel> allBills = [];
    bool hasError = false;
    
    // Get some bills for each priority subject
    for (final subject in prioritySubjects) {
      try {
        final subjectBills = await _legiscanService.searchBillsBySubject(
          subject,
          stateCode: 'CA'
        );
        
        if (subjectBills.isNotEmpty) {
          // Take up to 10 bills per subject to avoid overwhelming results
          final billsToAdd = subjectBills.length > 10 
              ? subjectBills.sublist(0, 10) 
              : subjectBills;
          
          allBills.addAll(billsToAdd);
        }
      } catch (e) {
        hasError = true;
        continue; // Continue with next subject if error occurs
      }
      
      // Stop if we have enough bills or hit an error
      if (allBills.length >= 100 || hasError) {
        break;
      }
    }
    
    // If we couldn't get enough bills, fall back to standard method
    if (allBills.isEmpty) {
      return _legiscanService.getBillsForState('CA');
    }
    
    return allBills;
  }
  
  // New York state-specific bill retrieval
  Future<List<BillModel>> _getNYBills() async {
    // For NY we prioritize getting high-profile bills
    final List<String> highPriorityKeywords = [
      'budget', 'tax', 'education', 'transportation',
      'housing', 'health', 'employment'
    ];
    
    List<BillModel> allBills = [];
    
    // Try to get a mix of bills with different subjects
    for (final keyword in highPriorityKeywords) {
      try {
        final keywordBills = await _legiscanService.searchBills(
          query: keyword,
          stateCode: 'NY',
          year: DateTime.now().year,
          maxResults: 15
        );
        
        if (keywordBills.isNotEmpty) {
          allBills.addAll(keywordBills);
        }
        
        // Stop if we have enough bills
        if (allBills.length >= 50) {
          break;
        }
      } catch (e) {
        continue; // Continue with next keyword if error occurs
      }
    }
    
    // If we couldn't get enough bills, fall back to standard method
    if (allBills.isEmpty) {
      return _legiscanService.getBillsForState('NY');
    }
    
    // Remove duplicates
    final uniqueBills = <BillModel>[];
    final billIds = <int>{};
    
    for (final bill in allBills) {
      if (!billIds.contains(bill.billId)) {
        billIds.add(bill.billId);
        uniqueBills.add(bill);
      }
    }
    
    return uniqueBills;
  }
  
  // Texas state-specific bill retrieval
  Future<List<BillModel>> _getTXBills() async {
    return _getStateWithMultipleYears('TX', 'texas');
  }
  
  // Illinois state-specific bill retrieval
  Future<List<BillModel>> _getILBills() async {
    return _getStateWithMultipleYears('IL', 'illinois');
  }
  
  // Pennsylvania state-specific bill retrieval
  Future<List<BillModel>> _getPABills() async {
    return _getStateWithMultipleYears('PA', 'pennsylvania');
  }
  
  // Ohio state-specific bill retrieval
  Future<List<BillModel>> _getOHBills() async {
    return _getStateWithMultipleYears('OH', 'ohio');
  }
  
  // Louisiana state-specific bill retrieval
  Future<List<BillModel>> _getLABills() async {
    return _getStateWithMultipleYears('LA', 'louisiana');
  }
  
  // Generic multi-year search for states
  Future<List<BillModel>> _getStateWithMultipleYears(String stateCode, String keyword) async {
    // Try multiple years: 2025, 2024, 2023
    final years = [2025, 2024, 2023];
    List<BillModel> allResults = [];
    
    for (final year in years) {
      final results = await _legiscanService.searchBills(
        query: keyword,
        stateCode: stateCode,
        year: year
      );
      
      allResults.addAll(results);
      
      // If we found bills, we can stop here
      if (results.isNotEmpty) {
        break;
      }
    }
    
    // If keyword search across years failed, try session-based search
    if (allResults.isEmpty) {
      final sessionResults = await _legiscanService.getBillsForState(stateCode);
      return sessionResults;
    }
    
    return allResults;
  }
  
  // Try to search for a bill as a fallback (used in error recovery)
  Future<void> _tryFallbackBillSearch(int billId, String stateCode) async {
    try {
      // Search for the bill by ID as a keyword
      final searchResults = await _legiscanService.searchBills(
        query: billId.toString(),
        stateCode: stateCode,
        maxResults: 5
      );
      
      // See if we found a matching bill
      final matchingBills = searchResults.where((bill) => 
          bill.billId == billId || 
          bill.billNumber.contains(billId.toString())).toList();
      
      if (matchingBills.isNotEmpty) {
        // Create a basic bill details object from the matching bill
        _selectedBillDetails = EnhancedBillDetails(
          bill: matchingBills.first,
          sponsors: [],
          history: [],
          documents: [],
          subjects: [],
          votes: [],
          amendments: [],
          supplements: [],
          extraData: {
            'from_fallback_search': true,
            'complete_data': false,
            'note': 'Limited bill data - retrieved via fallback search'
          },
        );
        
        // Add to recent bills
        _addToRecentBills(matchingBills.first);
        
        notifyListeners();
      }
    } catch (e) {
      // Silently fail as this is just an attempt at recovery
      if (kDebugMode) {
        print('Fallback search failed: $e');
      }
    }
  }
  
  // Create a placeholder for bill details during loading/retrying
  void _createPlaceholderBillDetails(int billId, String stateCode) {
    final placeholder = BillModel(
      billId: billId,
      billNumber: 'Loading...',
      title: 'Loading bill details...',
      description: 'Please wait while we retrieve the bill information.',
      status: 'Loading', // Status field is required
      statusDate: null,
      lastActionDate: null,
      lastAction: 'Retrieving activity...',
      committee: null,
      type: 'state',
      state: stateCode,
      url: '',
    );
    
    _selectedBillDetails = EnhancedBillDetails(
      bill: placeholder,
      sponsors: [],
      history: [],
      documents: [],
      subjects: [],
      votes: [],
      amendments: [],
      supplements: [],
      extraData: {
        'is_placeholder': true,
        'loading': true,
        'bill_id': billId,
        'state_code': stateCode,
      },
    );
    
    notifyListeners();
  }
  
  // Try to retry loading bill details in the background
  Future<void> _retryLoadingBillDetailsInBackground(int billId, String stateCode) async {
    // Small delay to ensure UI updates first
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      final billDetails = await _legiscanService.getBillDetails(billId, stateCode);
      
      if (billDetails != null) {
        // Update the bill details
        _selectedBillDetails = billDetails;
        
        // Add to recent bills
        _addToRecentBills(billDetails.bill);
        
        // Clear error message as we succeeded
        _errorMessageDetails = null;
        
        notifyListeners();
      }
    } catch (e) {
      // Keep the placeholder but update the error state
      if (_selectedBillDetails != null && 
          _selectedBillDetails!.extraData.containsKey('is_placeholder')) {
        _selectedBillDetails = EnhancedBillDetails(
          bill: _selectedBillDetails!.bill,
          sponsors: [],
          history: [],
          documents: [],
          subjects: [],
          votes: [],
          amendments: [],
          supplements: [],
          extraData: {
            'is_placeholder': true,
            'loading': false,
            'retry_failed': true,
            'bill_id': billId,
            'state_code': stateCode,
            'error': e.toString(),
          },
        );
        
        notifyListeners();
      }
    }
  }
  
  // Try to load bill details from cache during network errors
  Future<void> _tryLoadingFromCache(int billId, String stateCode) async {
    try {
      // Try to directly access cached bill details
      final cacheKey = 'bill_details_$billId';
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cachePrefixData + cacheKey);
      
      if (cachedJson != null) {
        final cachedData = json.decode(cachedJson);
        
        if (cachedData != null) {
          // Create bill details from cache
          final cachedDetails = EnhancedBillDetails.fromMap(
              Map<String, dynamic>.from(cachedData));
          
          _selectedBillDetails = cachedDetails;
          
          // Mark as cached
          _selectedBillDetails!.extraData['from_offline_cache'] = true;
          _selectedBillDetails!.extraData['offline_mode'] = true;
          
          // Update error message
          _errorMessageDetails = 'Showing cached version due to network issues.';
          
          notifyListeners();
        }
      }
    } catch (e) {
      // Silently fail as this is just an attempt at recovery
      if (kDebugMode) {
        print('Failed to load from cache: $e');
      }
    }
  }
  
  // Cache prefix constant for consistency with CacheManager
  static const String _cachePrefixData = 'cache_data_';
  
  // Pagination support
  Future<void> loadNextPage() async {
    // Check if there are more results to load
    if (!_hasMoreResults || _isLoading) {
      return;
    }
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Increment page counter
      _currentPage++;
      
      // Determine what type of search to perform based on last search type
      switch (_lastSearchType) {
        case 'state':
          await _loadNextPageForState();
          break;
        case 'subject':
          await _loadNextPageForSubject();
          break;
        case 'keyword':
          await _loadNextPageForKeyword();
          break;
        case 'sponsor':
          await _loadNextPageForSponsor();
          break;
        default:
          // Unknown search type, reset loading state
          _isLoading = false;
          notifyListeners();
          return;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
    }
  }
  
  // Load next page for state bills
  Future<void> _loadNextPageForState() async {
    if (_lastStateCode == null) return;
    
    // For state bills, we need special handling because the API doesn't directly support pagination
    // Instead, we use offset-based "paging" by requesting more bills and skipping previously fetched ones
    
    // Skip count based on current page and results per page
    final skipCount = (_currentPage - 1) * _resultsPerPage;
    
    // Check if we need special state handling
    if (_isSpecialStateHandling) {
      // For special states, we need to use our custom methods with paging
      List<BillModel> additionalBills = [];
      switch (_lastStateCode!.toUpperCase()) {
        case 'FL':
          additionalBills = await _getFLBillsWithOffset(skipCount, _resultsPerPage);
          break;
        case 'GA':
          additionalBills = await _getGABillsWithOffset(skipCount, _resultsPerPage);
          break;
        case 'CA':
          additionalBills = await _getCABillsWithOffset(skipCount, _resultsPerPage);
          break;
        case 'NY':
          additionalBills = await _getNYBillsWithOffset(skipCount, _resultsPerPage);
          break;
        default:
          additionalBills = [];
      }
      
      // If we got fewer results than requested, there are no more results
      _hasMoreResults = additionalBills.length >= _resultsPerPage;
      
      // Add new bills to the state bills list
      if (additionalBills.isNotEmpty) {
        _stateBills.addAll(additionalBills);
      }
    } else {
      // For regular states, we can use the standard API with a different approach
      
      // Try to get bills from a search with year parameter to get more results
      final additionalBills = await _legiscanService.searchBills(
        query: '*', // Wildcard search
        stateCode: _lastStateCode,
        year: DateTime.now().year,
        maxResults: _resultsPerPage
      );
      
      // Filter out bills we already have
      final existingIds = _stateBills.map((bill) => bill.billId).toSet();
      final newBills = additionalBills.where((bill) => !existingIds.contains(bill.billId)).toList();
      
      // If we got fewer new bills than requested, there are likely no more results
      _hasMoreResults = newBills.length >= _resultsPerPage;
      
      // Add new bills to the state bills list
      if (newBills.isNotEmpty) {
        _stateBills.addAll(newBills);
      }
    }
  }
  
  // Load next page for subject search
  Future<void> _loadNextPageForSubject() async {
    if (_lastSearchQuery == null) return;
    
    // For subject searches, we can use more targeted pagination
    final additionalBills = await _legiscanService.searchBillsBySubject(
      _lastSearchQuery!,
      stateCode: _lastStateCode,
    );
    
    // Filter out bills we already have
    final existingIds = _searchResultBills.map((bill) => bill.billId).toSet();
    final newBills = additionalBills.where((bill) => !existingIds.contains(bill.billId)).toList();
    
    // Take only the bills for the current page
    final startIndex = 0;
    final endIndex = min(newBills.length, _resultsPerPage);
    final pageResults = newBills.length > startIndex 
        ? newBills.sublist(startIndex, endIndex) 
        : <BillModel>[];
    
    // If we got fewer new bills than requested, there are no more results
    _hasMoreResults = pageResults.length >= _resultsPerPage;
    
    // Add new bills to the search results
    if (pageResults.isNotEmpty) {
      _searchResultBills.addAll(pageResults);
    }
  }
  
  // Load next page for keyword search
  Future<void> _loadNextPageForKeyword() async {
    if (_lastSearchQuery == null) return;
    
    // For keyword searches, we can use similar approach as subject
    final additionalBills = await _legiscanService.searchBills(
      query: _lastSearchQuery!,
      stateCode: _lastStateCode,
      maxResults: _resultsPerPage * 2 // Get more to ensure we have enough after filtering
    );
    
    // Filter out bills we already have
    final existingIds = _searchResultBills.map((bill) => bill.billId).toSet();
    final newBills = additionalBills.where((bill) => !existingIds.contains(bill.billId)).toList();
    
    // Take only the bills for the current page
    final startIndex = 0;
    final endIndex = min(newBills.length, _resultsPerPage);
    final pageResults = newBills.length > startIndex 
        ? newBills.sublist(startIndex, endIndex) 
        : <BillModel>[];
    
    // If we got fewer new bills than requested, there are no more results
    _hasMoreResults = pageResults.length >= _resultsPerPage;
    
    // Add new bills to the search results
    if (pageResults.isNotEmpty) {
      _searchResultBills.addAll(pageResults);
    }
  }
  
  /// Search bills with comprehensive filters
  Future<void> searchBillsWithFilters({
    String? query,
    String? stateCode,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? year,
    String? governmentLevel,
  }) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchType = 'advanced';
      _lastStateCode = stateCode;
      _lastSearchQuery = query ?? '';
      _currentPage = 1;
      notifyListeners();
      
      // Prepare parameters for enhanced search
      final searchParams = <String, dynamic>{};
      
      // Add query if provided
      if (query != null && query.isNotEmpty) {
        searchParams['query'] = query;
      }
      
      // Add state code if provided
      if (stateCode != null) {
        searchParams['state'] = stateCode;
      }
      
      // Add year if provided
      if (year != null) {
        searchParams['year'] = year;
      }
      
      // Add date range filters if provided
      if (startDate != null) {
        searchParams['start_date'] = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      }
      
      if (endDate != null) {
        searchParams['end_date'] = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      }
      
      // Add status filter if provided
      if (status != null) {
        // Convert status to LegiScan format
        if (status == 'Introduced') {
          searchParams['status'] = 'introduced';
        } else if (status == 'In Committee') {
          searchParams['status'] = 'committee';
        } else if (status == 'Passed') {
          searchParams['status'] = 'passed';
        } else if (status == 'Failed') {
          searchParams['status'] = 'failed';
        } else if (status == 'Vetoed') {
          searchParams['status'] = 'vetoed';
        } else if (status == 'Enacted') {
          searchParams['status'] = 'enacted';
        }
      }
      
      // Government level filter is passed as parameter
      
      // Execute the search with all filters
      List<BillModel> results;
      
      // For empty queries with only filters, use special handling
      if (query == null || query.isEmpty) {
        if (stateCode != null) {
          // If we have a state, start with state bills
          results = await _legiscanService.getBillsForState(stateCode);
          
          // Apply client-side filtering
          results = _applyClientSideFilters(results, status, startDate, endDate, year, governmentLevel: governmentLevel);
        } else {
          // Without a state, use a broader search
          results = await _legiscanService.searchBills(
            query: '*', // Wildcard search
            stateCode: stateCode,
            year: year,
            maxResults: 40
          );
          
          // Apply client-side filtering
          results = _applyClientSideFilters(results, status, startDate, endDate, year, governmentLevel: governmentLevel);
        }
      } else {
        // Normal keyword search with filters
        results = await _legiscanService.searchBills(
          query: query,
          stateCode: stateCode,
          year: year,
          maxResults: 40
        );
        
        // Apply client-side filtering
        results = _applyClientSideFilters(results, status, startDate, endDate, year, governmentLevel: governmentLevel);
      }
      
      _searchResultBills = results;
      
      if (_searchResultBills.isEmpty) {
        _errorMessage = 'No bills found matching your filters.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
      
      if (kDebugMode) {
        print('Error in searchBillsWithFilters: $e');
      }
    }
  }
  
  /// Apply client-side filters to bills list
  List<BillModel> _applyClientSideFilters(
    List<BillModel> bills,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? year,
    {String? governmentLevel}
  ) {
    // If no filters, return original list
    if (status == null && startDate == null && endDate == null && year == null && governmentLevel == null) {
      return bills;
    }
    
    return bills.where((bill) {
      // Filter by government level
      if (governmentLevel != null) {
        final billType = bill.type.toLowerCase();
        final targetLevel = governmentLevel.toLowerCase();
        
        if (targetLevel != billType) {
          return false;
        }
      }
      
      // Filter by status
      if (status != null) {
        final billStatus = bill.status.toLowerCase();
        
        switch (status) {
          case 'Introduced':
            if (!billStatus.contains('introduced') && 
                !billStatus.contains('first reading')) {
              return false;
            }
            break;
          case 'In Committee':
            if (!billStatus.contains('committee') && 
                !billStatus.contains('referred')) {
              return false;
            }
            break;
          case 'Passed':
            if (!billStatus.contains('passed') && 
                !billStatus.contains('approved')) {
              return false;
            }
            break;
          case 'Failed':
            if (!billStatus.contains('failed') && 
                !billStatus.contains('defeated')) {
              return false;
            }
            break;
          case 'Vetoed':
            if (!billStatus.contains('vetoed')) {
              return false;
            }
            break;
          case 'Enacted':
            if (!billStatus.contains('enacted') && 
                !billStatus.contains('signed')) {
              return false;
            }
            break;
        }
      }
      
      // Filter by date range
      if (startDate != null || endDate != null) {
        // Try to parse the bill date
        final dateString = bill.lastActionDate ?? bill.statusDate ?? bill.introducedDate;
        
        if (dateString != null && dateString.isNotEmpty) {
          try {
            final billDate = DateTime.parse(dateString.contains('T') ? 
                dateString : dateString.replaceAll(' ', 'T'));
            
            // Check against start date
            if (startDate != null && billDate.isBefore(startDate)) {
              return false;
            }
            
            // Check against end date
            if (endDate != null && billDate.isAfter(endDate)) {
              return false;
            }
          } catch (e) {
            // Date parsing failed, but still include the bill
          }
        }
      }
      
      // Filter by year
      if (year != null) {
        final dateString = bill.lastActionDate ?? bill.statusDate ?? bill.introducedDate;
        
        if (dateString != null && dateString.isNotEmpty) {
          try {
            final billDate = DateTime.parse(dateString.contains('T') ? 
                dateString : dateString.replaceAll(' ', 'T'));
            
            if (billDate.year != year) {
              return false;
            }
          } catch (e) {
            // Date parsing failed, but still include the bill
          }
        }
      }
      
      // Bill passed all filters
      return true;
    }).toList();
  }
  
  // Load next page for sponsor search
  Future<void> _loadNextPageForSponsor() async {
    if (_lastSearchQuery == null) return;
    
    // For sponsor searches, we use a targeted approach
    final additionalBills = await _legiscanService.searchBillsBySponsor(
      _lastSearchQuery!,
      stateCode: _lastStateCode,
    );
    
    // Filter out bills we already have
    final existingIds = _searchResultBills.map((bill) => bill.billId).toSet();
    final newBills = additionalBills.where((bill) => !existingIds.contains(bill.billId)).toList();
    
    // Take only the bills for the current page
    final startIndex = 0;
    final endIndex = min(newBills.length, _resultsPerPage);
    final pageResults = newBills.length > startIndex 
        ? newBills.sublist(startIndex, endIndex) 
        : <BillModel>[];
    
    // If we got fewer new bills than requested, there are no more results
    _hasMoreResults = pageResults.length >= _resultsPerPage;
    
    // Add new bills to the search results
    if (pageResults.isNotEmpty) {
      _searchResultBills.addAll(pageResults);
    }
  }
  
  // Helper methods for state-specific pagination
  
  // Florida with pagination support
  Future<List<BillModel>> _getFLBillsWithOffset(int skipCount, int limit) async {
    // For Florida, we search by different keywords to get more variety
    final List<String> keywordVariations = [
      'florida', 'education', 'tax', 'healthcare', 
      'transportation', 'environment'
    ];
    
    // Pick a variation based on the current page
    final keywordIndex = (_currentPage - 1) % keywordVariations.length;
    final keyword = keywordVariations[keywordIndex];
    
    final results = await _legiscanService.searchBills(
      query: keyword,
      stateCode: 'FL',
      year: DateTime.now().year,
      maxResults: limit * 2 // Get more to ensure we have enough after filtering
    );
    
    // Filter out bills we already have
    final existingIds = _stateBills.map((bill) => bill.billId).toSet();
    return results.where((bill) => !existingIds.contains(bill.billId)).take(limit).toList();
  }
  
  // Georgia with pagination support
  Future<List<BillModel>> _getGABillsWithOffset(int skipCount, int limit) async {
    // Similar approach as Florida but with Georgia-specific keywords
    final List<String> keywordVariations = [
      'georgia', 'tax', 'education', 'health', 
      'crime', 'transportation'
    ];
    
    final keywordIndex = (_currentPage - 1) % keywordVariations.length;
    final keyword = keywordVariations[keywordIndex];
    
    final results = await _legiscanService.searchBills(
      query: keyword,
      stateCode: 'GA',
      year: DateTime.now().year,
      maxResults: limit * 2
    );
    
    final existingIds = _stateBills.map((bill) => bill.billId).toSet();
    return results.where((bill) => !existingIds.contains(bill.billId)).take(limit).toList();
  }
  
  // California with pagination support
  Future<List<BillModel>> _getCABillsWithOffset(int skipCount, int limit) async {
    // For California, we use different subjects for each page
    final List<String> subjects = [
      'taxes', 'education', 'health', 'environment', 
      'housing', 'transportation', 'technology', 'finance',
      'labor', 'agriculture', 'water', 'energy'
    ];
    
    // Calculate which subjects to use for this page
    final startIndex = (_currentPage - 1) % subjects.length;
    final endIndex = min(startIndex + 2, subjects.length); // Use 2 subjects per page
    final pageSubjects = subjects.sublist(startIndex, endIndex);
    
    List<BillModel> allBills = [];
    
    // Get bills for each subject for this page
    for (final subject in pageSubjects) {
      try {
        final subjectBills = await _legiscanService.searchBillsBySubject(
          subject,
          stateCode: 'CA'
        );
        
        if (subjectBills.isNotEmpty) {
          allBills.addAll(subjectBills);
        }
      } catch (e) {
        continue; // Continue with next subject if error occurs
      }
    }
    
    // Filter out bills we already have
    final existingIds = _stateBills.map((bill) => bill.billId).toSet();
    return allBills.where((bill) => !existingIds.contains(bill.billId)).take(limit).toList();
  }
  
  // New York with pagination support
  Future<List<BillModel>> _getNYBillsWithOffset(int skipCount, int limit) async {
    // For NY, we use different keywords for each page
    final List<String> keywords = [
      'budget', 'tax', 'education', 'transportation',
      'housing', 'health', 'employment', 'environment',
      'criminal', 'government', 'energy', 'agriculture',
      'commerce', 'finance', 'insurance', 'banking'
    ];
    
    // Calculate which keywords to use for this page
    final startIndex = (_currentPage - 1) % keywords.length;
    final endIndex = min(startIndex + 2, keywords.length); // Use 2 keywords per page
    final pageKeywords = keywords.sublist(startIndex, endIndex);
    
    List<BillModel> allBills = [];
    
    // Get bills for each keyword for this page
    for (final keyword in pageKeywords) {
      try {
        final keywordBills = await _legiscanService.searchBills(
          query: keyword,
          stateCode: 'NY',
          year: DateTime.now().year,
          maxResults: limit
        );
        
        if (keywordBills.isNotEmpty) {
          allBills.addAll(keywordBills);
        }
      } catch (e) {
        continue; // Continue with next keyword if error occurs
      }
    }
    
    // Filter out bills we already have and remove duplicates
    final existingIds = _stateBills.map((bill) => bill.billId).toSet();
    final newBillsList = <BillModel>[];
    final seenIds = <int>{};
    
    for (final bill in allBills) {
      if (!existingIds.contains(bill.billId) && !seenIds.contains(bill.billId)) {
        seenIds.add(bill.billId);
        newBillsList.add(bill);
        
        if (newBillsList.length >= limit) {
          break;
        }
      }
    }
    
    return newBillsList;
  }
  
  // Helper function for min value since we're not importing dart:math
  int min(int a, int b) => a < b ? a : b;
  
  // Helper to format error messages with more specific error handling
  String _formatErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return 'Network error: Please check your internet connection and try again.';
    } else if (error is LegiscanApiException) {
      if (error.message.contains('API key')) {
        return 'API key error: The LegiScan API key is invalid or missing. Please check the application settings.';
      } else if (error.message.contains('rate limit')) {
        return 'Rate limit exceeded: Too many requests to the legislative data service. Please try again later.';
      }
      return 'API error: ${error.message}';
    } else if (error is ServerException) {
      if (error.statusCode == 404) {
        return 'Resource not found: The requested legislative data could not be found.';
      } else if (error.statusCode == 403) {
        return 'Access denied: You do not have permission to access this legislative data.';
      }
      return 'Server error: The legislative data service is currently unavailable. Please try again later.';
    } else if (error is ApiTimeoutException) {
      if (error.timeoutMs >= 30000) {
        return 'Request timed out: The search is taking longer than expected. Try refining your search criteria.';
      }
      return 'Request timed out: The server took too long to respond. Please try again.';
    } else if (error is BillNotFoundException) {
      if (error.stateCode != null) {
        return 'Bill not found: Bill ID ${error.billId} could not be found in ${error.stateCode}.';
      }
      return 'Bill not found: The requested bill could not be found in the legislative database.';
    } else if (error is DataParsingException) {
      return 'Data error: The legislative data could not be properly processed. Please try again.';
    } else if (error is RateLimitException) {
      final retryText = error.retryAfterSeconds != null 
          ? ' Please try again in ${error.retryAfterSeconds} seconds.' 
          : ' Please try again later.';
      return 'Rate limit exceeded: Too many requests to the legislative data service.$retryText';
    } else {
      return 'An error occurred: ${error.toString()}';
    }
  }
}