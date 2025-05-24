// lib/providers/bill_provider.dart
import 'package:flutter/foundation.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/models/enhanced_bill_details.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/bill_service.dart';
import 'package:govvy/services/enhanced_legiscan_service.dart';
import 'package:govvy/services/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BillProvider with ChangeNotifier {
  final BillService _billService = BillService();
  final EnhancedLegiscanService _enhancedService = EnhancedLegiscanService();
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
  int? _lastBillId; // Needed for bill details tracking
  
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
      
    } catch (e) {
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
      
      // Get bills for the selected state
      _stateBills = await _billService.getBillsByState(stateCode);
      
      if (_stateBills.isEmpty) {
        _errorMessage = 'No bills found for $stateCode. Please try a different state.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading bills for $stateCode: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Removed deprecated searchBills method
  
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
      
      // Try the enhanced LegiScan service first
      EnhancedBillDetails? enhancedDetails;
      try {
        enhancedDetails = await _enhancedService.getBillDetails(billId, stateCode);
      } catch (enhancedError) {
        if (kDebugMode) {
          print('Enhanced bill details error: $enhancedError');
        }
        // We'll fall back to regular service, no need to handle here
      }
      
      if (enhancedDetails != null) {
        // We got enhanced details
        _selectedBill = enhancedDetails.bill;
        _selectedBillDocuments = enhancedDetails.documents;
        
        // Add to recent bills
        _addToRecentBills(enhancedDetails.bill);
        
        _isLoadingDetails = false;
        notifyListeners();
      } else {
        // Fall back to regular bill service
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
      }
    } catch (e) {
      _isLoadingDetails = false;
      
      // Handle specific known errors with more user-friendly messages
      if (e.toString().contains('Unknown bill id')) {
        _errorMessageDetails = 'This bill could not be found. It may have been removed or its ID may have changed.';
      } else {
        _errorMessageDetails = 'Error getting bill details: ${e.toString()}';
      }
      
      notifyListeners();
      
      // Try to find the bill in recent bills as a fallback
      final foundInRecent = _recentBills.where((bill) => bill.billId == billId).toList();
      if (foundInRecent.isNotEmpty) {
        _selectedBill = foundInRecent.first;
        notifyListeners();
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
      }
    } catch (e) {
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