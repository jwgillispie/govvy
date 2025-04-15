// lib/providers/representative_provider.dart
import 'package:flutter/foundation.dart';
import 'package:govvy/services/representative_service.dart';
import 'package:govvy/models/representative_model.dart';

class RepresentativeProvider with ChangeNotifier {
  final RepresentativeService _representativeService;
  
  List<Representative> _representatives = [];
  bool _isLoading = false;
  String? _errorMessage;
  RepresentativeDetails? _selectedRepresentative;
  bool _isLoadingDetails = false;
  
  // Getters
  List<Representative> get representatives => _representatives;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RepresentativeDetails? get selectedRepresentative => _selectedRepresentative;
  bool get isLoadingDetails => _isLoadingDetails;
  
  RepresentativeProvider(this._representativeService);
  
  // Fetch representatives by address
  Future<void> fetchRepresentativesByAddress(String address) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      _representatives = await _representativeService.getRepresentativesByAddress(address);
      
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
  
  // Fetch representative details
  Future<void> fetchRepresentativeDetails(String bioGuideId) async {
    try {
      _isLoadingDetails = true;
      notifyListeners();
      
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
}