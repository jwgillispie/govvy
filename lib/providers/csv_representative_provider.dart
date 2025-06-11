// lib/providers/csv_representative_provider.dart
import 'package:flutter/foundation.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/models/local_representative_model.dart';
import 'package:govvy/services/csv_bill_service.dart';

class CSVRepresentativeProvider with ChangeNotifier {
  // Singleton instance
  static final CSVRepresentativeProvider _instance = CSVRepresentativeProvider._internal();
  factory CSVRepresentativeProvider() => _instance;
  CSVRepresentativeProvider._internal();

  final CSVBillService _csvBillService = CSVBillService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Initialize the provider and load CSV data
  Future<void> initialize() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _csvBillService.initialize();
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _errorMessage = 'Failed to initialize CSV data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('Error initializing CSV Representative Provider: $e');
      }
    }
  }
  
  // Add sponsored bills to a RepresentativeDetails object
  Future<void> addCSVBillsToRepresentative(RepresentativeDetails representative) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Create a Representative object from the details
      final rep = Representative(
        name: representative.name,
        bioGuideId: representative.bioGuideId,
        party: representative.party,
        chamber: representative.chamber,
        state: representative.state,
        district: representative.district,
      );
      
      // Get sponsored bills from CSV data
      final bills = await _csvBillService.getSponsoredBills(rep);
      
      if (bills.isNotEmpty) {
        // Add the bills to the representative
        representative.addLegiscanBills(bills);
        
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error adding CSV bills: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('Error adding CSV bills to representative: $e');
      }
    }
  }
  
  // Get sponsored bills for a local representative
  Future<List<RepresentativeBill>> getSponsoredBillsForLocalRep(LocalRepresentative rep) async {
    if (_isLoading) return [];
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Get sponsored bills from CSV data
      final bills = await _csvBillService.getSponsoredBillsForLocalRep(rep);
      
      _isLoading = false;
      notifyListeners();
      
      return bills;
    } catch (e) {
      _errorMessage = 'Error getting bills: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('Error getting sponsored bills for local rep: $e');
      }
      
      return [];
    }
  }
  
  // Check if a representative has sponsored bills in the CSV data
  Future<bool> hasSponsoredBills(String name) async {
    try {
      // Try to find person ID by name
      final peopleId = _csvBillService.findPersonIdByName(name);
      
      if (peopleId == null) {
        return false;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for sponsored bills: $e');
      }
      return false;
    }
  }
}