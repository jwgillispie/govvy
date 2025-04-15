// lib/providers/representative_provider.dart
import 'package:flutter/foundation.dart';
import 'package:govvy/services/cicero_service.dart';
import 'package:govvy/services/representative_service.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/models/local_representative_model.dart';

class RepresentativeProvider with ChangeNotifier {
  final RepresentativeService _representativeService;
  final CiceroService _ciceroService = CiceroService();

  List<Representative> _representatives = [];
  bool _isLoading = false;
  String? _errorMessage;
  RepresentativeDetails? _selectedRepresentative;
  bool _isLoadingDetails = false;
  String? _lastSearchedAddress;
  
  // Getters
  List<Representative> get representatives => _representatives;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RepresentativeDetails? get selectedRepresentative => _selectedRepresentative;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get lastSearchedAddress => _lastSearchedAddress;
  
  RepresentativeProvider(this._representativeService);
  
  // Fetch representatives by address
  Future<void> fetchRepresentativesByAddress(String address) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchedAddress = address;
      notifyListeners();
      
      // Clear existing representatives before new search
      _representatives = [];
      
      // Add a small delay to make loading state visible to users
      await Future.delayed(const Duration(milliseconds: 800));
      
      _representatives = await _representativeService.getRepresentativesByAddress(address);
      
      if (_representatives.isEmpty) {
        _errorMessage = 'No representatives found for this address. Please check the address and try again.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading representatives: ${e.toString()}';
      if (kDebugMode) {
        print(_errorMessage);
      }
      notifyListeners();
    }
  }
  
  // Add this new method to fetch only local representatives
  Future<void> fetchLocalRepresentativesByAddress(String address) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _lastSearchedAddress = address;
      notifyListeners();
      
      // Clear existing representatives before new search
      _representatives = [];
      
      // Add a small delay to make loading state visible to users
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Use the new Cicero service for local data
      // Convert LocalRepresentative to Representative
      final localReps = await _ciceroService.getLocalRepresentativesByAddress(address);
      _representatives = localReps.map((local) => local.toRepresentative()).toList();
      
      if (_representatives.isEmpty) {
        _errorMessage = 'No local representatives found for this address. Please check the address and try again.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error loading local representatives: ${e.toString()}';
      if (kDebugMode) {
        print(_errorMessage);
      }
      notifyListeners();
    }
  }

  // Fetch representative details
  Future<void> fetchRepresentativeDetails(String bioGuideId) async {
    try {
      _isLoadingDetails = true;
      _errorMessage = null;
      notifyListeners();
      
      // Add a small delay to make loading state visible to users
      await Future.delayed(const Duration(milliseconds: 800));
      
      final detailsResponse = await _representativeService.getRepresentativeDetails(bioGuideId);
      
      _selectedRepresentative = RepresentativeDetails.fromMap(
        details: detailsResponse['details'], 
        sponsoredBills: detailsResponse['sponsoredBills'], 
        cosponsoredBills: detailsResponse['cosponsoredBills']
      );
      
      _isLoadingDetails = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDetails = false;
      _errorMessage = 'Error loading representative details: ${e.toString()}';
      if (kDebugMode) {
        print(_errorMessage);
      }
      notifyListeners();
    }
  }
  
  // Clear selected representative
  void clearSelectedRepresentative() {
    _selectedRepresentative = null;
    notifyListeners();
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Clear all data (for use when signing out)
  void clearAll() {
    _representatives = [];
    _errorMessage = null;
    _selectedRepresentative = null;
    _lastSearchedAddress = null;
    notifyListeners();
  }
}