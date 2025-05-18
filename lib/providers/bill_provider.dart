// lib/providers/bill_provider.dart
import 'package:flutter/foundation.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/bill_service.dart';
import 'package:govvy/services/csv_bill_service.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BillProvider with ChangeNotifier {
  final BillService _billService = BillService();
  final NetworkService _networkService = NetworkService();

  // State for bill lists
  List<BillModel> _stateBills = [];
  List<BillModel> _searchResultBills = [];
  List<BillModel> _recentBills = [];  // For recently viewed bills
  
  // State for bill details
  BillModel? _selectedBill;
  List<BillDocument>? _selectedBillDocuments;
  
  // Loading and error states
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  bool _isLoadingDocuments = false;
  String? _errorMessage;
  String? _errorMessageDetails;
  
  // Last search parameters (for caching/persistence)
  String? _lastSearchQuery;
  String? _lastStateCode;
  int? _lastBillId;
  
  // Getters for the state
  List<BillModel> get stateBills => _stateBills;
  List<BillModel> get searchResultBills => _searchResultBills;
  List<BillModel> get recentBills => _recentBills;
  
  BillModel? get selectedBill => _selectedBill;
  List<BillDocument>? get selectedBillDocuments => _selectedBillDocuments;
  
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isLoadingDocuments => _isLoadingDocuments;
  String? get errorMessage => _errorMessage;
  String? get errorMessageDetails => _errorMessageDetails;
  
  String? get lastSearchQuery => _lastSearchQuery;
  String? get lastStateCode => _lastStateCode;
  
  // Constructor with initialization
  BillProvider() {
    _initializeAndLoadCache();
  }
  
  // Initialize the provider
  Future<void> _initializeAndLoadCache() async {
    try {
      // Initialize the bill service
      await _billService.initialize();
      
      // Load recent bills from cache
      await _loadRecentBillsFromCache();
      
      if (kDebugMode) {
        print('Bill Provider initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Bill Provider: $e');
      }
      _errorMessage = 'Failed to initialize bill data';
      notifyListeners();
    }
  }
  
  // Helper to check network before making requests
  Future<bool> _checkNetworkBeforeRequest() async {
    try {
      final isConnected = await _networkService.checkConnectivity();
      
      if (!isConnected) {
        _errorMessage = 'Network connection unavailable. Please check your internet connection.';
        notifyListeners();
      }
      
      return isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking network: $e');
      }
      return true; // Assume connected if check fails
    }
  }
  
  // Get bills by state
  Future<void> fetchBillsByState(String stateCode) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastStateCode = stateCode;
      notifyListeners();
      
      // Special debug handling for FL and GA
      if (stateCode == 'FL' || stateCode == 'GA') {
        if (kDebugMode) {
          print('Special handling enabled for $stateCode bills');
          print('Forcing fresh load for $stateCode with special handling');
        }
        
        // Clear bills cache by calling _billService.clearCache()
        await _billService.clearCache();
        
        // Create our own direct CSV service instance for testing
        final csvService = CSVBillService();
        await csvService.initialize();
        
        // Attempt to load bills directly from CSV service
        try {
          final csvBills = await csvService.getBillsByState(stateCode);
          
          if (kDebugMode) {
            print('Directly loaded ${csvBills.length} bills from CSV for $stateCode');
          }
          
          if (csvBills.isNotEmpty) {
            // Convert to BillModel format
            final bills = csvBills.map((bill) => 
                BillModel.fromRepresentativeBill(bill, stateCode)).toList();
            
            if (kDebugMode) {
              print('Converted ${bills.length} CSV bills to BillModel format for $stateCode');
              
              if (bills.isNotEmpty) {
                print('Sample bill from $stateCode:');
                print('  Bill Number: ${bills.first.billNumber}');
                print('  Title: ${bills.first.title}');
                print('  Status: ${bills.first.status}');
              }
            }
            
            _stateBills = bills;
          } else {
            // Fallback to standard method if no CSV bills found
            _stateBills = await _billService.getBillsByState(stateCode);
          }
        } catch (csvError) {
          if (kDebugMode) {
            print('Error loading CSV data directly: $csvError');
            print('Falling back to standard bill loading method');
          }
          
          // Fallback to standard method
          _stateBills = await _billService.getBillsByState(stateCode);
        }
      } else {
        // Standard path for other states
        _stateBills = await _billService.getBillsByState(stateCode);
      }
      
      if (_stateBills.isEmpty && (stateCode == 'FL' || stateCode == 'GA')) {
        _errorMessage = 'No bills found for $stateCode. Possible CSV loading issue. Please try a different state.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading bills for $stateCode: ${e.toString()}';
      notifyListeners();
      
      if (kDebugMode) {
        print(_errorMessage);
      }
    }
  }
  
  // Search for bills
  Future<void> searchBills(String query, {String? stateCode}) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchQuery = query;
      notifyListeners();
      
      _searchResultBills = await _billService.searchBills(query, stateCode: stateCode);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error searching for bills: ${e.toString()}';
      notifyListeners();
      
      if (kDebugMode) {
        print(_errorMessage);
      }
    }
  }
  
  // Get bills by subject
  Future<void> fetchBillsBySubject(String subject, {String? stateCode}) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchQuery = 'subject:$subject';
      notifyListeners();
      
      _searchResultBills = await _billService.getBillsBySubject(subject, stateCode: stateCode);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching bills by subject: ${e.toString()}';
      notifyListeners();
      
      if (kDebugMode) {
        print(_errorMessage);
      }
    }
  }
  
  // Get bills by representative
  Future<void> fetchBillsByRepresentative(Representative rep) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchQuery = 'representative:${rep.name}';
      notifyListeners();
      
      _searchResultBills = await _billService.getBillsByRepresentative(rep);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching bills for representative: ${e.toString()}';
      notifyListeners();
      
      if (kDebugMode) {
        print(_errorMessage);
      }
    }
  }
  
  // Get bill details
  Future<void> fetchBillDetails(int billId, String stateCode) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoadingDetails = true;
      _errorMessageDetails = null;
      _lastBillId = billId;
      notifyListeners();
      
      final bill = await _billService.getBillDetails(billId, stateCode);
      
      _selectedBill = bill;
      
      if (bill != null) {
        // Add to recent bills
        _addToRecentBills(bill);
      }
      
      _isLoadingDetails = false;
      notifyListeners();
      
      // Also fetch documents in the background
      fetchBillDocuments(billId);
    } catch (e) {
      _isLoadingDetails = false;
      
      // Handle specific known errors with more user-friendly messages
      if (e.toString().contains('Unknown bill id')) {
        _errorMessageDetails = 'This bill could not be found. It may have been removed or its ID may have changed.';
      } else {
        _errorMessageDetails = 'Error getting bill details: ${e.toString()}';
      }
      
      notifyListeners();
      
      if (kDebugMode) {
        print(_errorMessageDetails);
        print('Error details: $e');
        
        // Try to find the bill in recent bills as a fallback
        final foundInRecent = _recentBills.where((bill) => bill.billId == billId).toList();
        if (foundInRecent.isNotEmpty) {
          print('Found bill in recent bills, using cached data');
          _selectedBill = foundInRecent.first;
          notifyListeners();
        }
      }
    }
  }
  
  // Get bill documents
  Future<void> fetchBillDocuments(int billId) async {
    if (!await _checkNetworkBeforeRequest()) {
      return;
    }
    
    try {
      _isLoadingDocuments = true;
      notifyListeners();
      
      _selectedBillDocuments = await _billService.getBillDocuments(billId);
      
      _isLoadingDocuments = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDocuments = false;
      
      if (kDebugMode) {
        print('Error fetching bill documents: $e');
      }
      
      notifyListeners();
    }
  }
  
  // Add a bill to recently viewed bills
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
      
      // Limit to 10 recent bills
      if (_recentBills.length > 10) {
        _recentBills.removeLast();
      }
    }
    
    // Save to cache
    _saveRecentBillsToCache();
    
    notifyListeners();
  }
  
  // Load recent bills from cache
  Future<void> _loadRecentBillsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentBillsJson = prefs.getString('recent_bills');
      
      if (recentBillsJson != null) {
        final List<dynamic> recentBillsData = json.decode(recentBillsJson);
        
        _recentBills = recentBillsData
            .map((data) => BillModel.fromMap(Map<String, dynamic>.from(data)))
            .toList();
        
        notifyListeners();
        
        if (kDebugMode) {
          print('Loaded ${_recentBills.length} recent bills from cache');
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
      
      if (kDebugMode) {
        print('Saved ${_recentBills.length} recent bills to cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving recent bills to cache: $e');
      }
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
    _selectedBill = null;
    _selectedBillDocuments = null;
    notifyListeners();
  }
  
  // Set selected bill directly (for bill data passed directly to details screen)
  void setSelectedBill(BillModel bill) {
    _selectedBill = bill;
    _errorMessageDetails = null;
    _isLoadingDetails = false;
    
    // Add to recent bills
    _addToRecentBills(bill);
    
    notifyListeners();
    
    // Also fetch documents in the background if we have a bill ID
    if (bill.billId > 0) {
      fetchBillDocuments(bill.billId);
    }
  }
  
  // Clear all bills data
  void clearAll() {
    _stateBills.clear();
    _searchResultBills.clear();
    _selectedBill = null;
    _selectedBillDocuments = null;
    _errorMessage = null;
    _errorMessageDetails = null;
    _lastSearchQuery = null;
    _lastStateCode = null;
    _lastBillId = null;
    notifyListeners();
  }
}