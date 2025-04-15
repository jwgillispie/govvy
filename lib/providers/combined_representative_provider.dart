// lib/providers/combined_representative_provider.dart
import 'package:flutter/foundation.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/models/local_representative_model.dart';
import 'package:govvy/services/representative_service.dart';
import 'package:govvy/services/cicero_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CombinedRepresentativeProvider with ChangeNotifier {
  final RepresentativeService _federalService;
  final CiceroService _localService = CiceroService();
  
  List<Representative> _federalRepresentatives = [];
  List<LocalRepresentative> _localRepresentativesRaw = [];
  bool _isLoadingFederal = false;
  bool _isLoadingLocal = false;
  String? _errorMessageFederal;
  String? _errorMessageLocal;
  String? _lastSearchedAddress;
  
  // Getters
  List<Representative> get federalRepresentatives => _federalRepresentatives;
  List<LocalRepresentative> get localRepresentativesRaw => _localRepresentativesRaw;
  List<Representative> get localRepresentatives => 
      _localRepresentativesRaw.map((local) => local.toRepresentative()).toList();
  
  List<Representative> get allRepresentatives => 
      [..._federalRepresentatives, ...localRepresentatives];
  
  bool get isLoading => _isLoadingFederal || _isLoadingLocal;
  bool get isLoadingFederal => _isLoadingFederal;
  bool get isLoadingLocal => _isLoadingLocal;
  
  String? get errorMessage => _errorMessageFederal ?? _errorMessageLocal;
  String? get errorMessageFederal => _errorMessageFederal;
  String? get errorMessageLocal => _errorMessageLocal;
  
  String? get lastSearchedAddress => _lastSearchedAddress;
  
  CombinedRepresentativeProvider(this._federalService);
  
  // Fetch both federal and local representatives
  Future<void> fetchAllRepresentativesByAddress(String address) async {
    _lastSearchedAddress = address;
    notifyListeners();
    
    // Start both fetches in parallel
    await Future.wait([
      fetchFederalRepresentativesByAddress(address),
      fetchLocalRepresentativesByAddress(address),
    ]);
    
    // Save results to cache
    _saveToCache();
  }
  
  // Fetch only federal representatives
  Future<void> fetchFederalRepresentativesByAddress(String address) async {
    try {
      _isLoadingFederal = true;
      _errorMessageFederal = null;
      notifyListeners();
      
      // Clear existing federal representatives
      _federalRepresentatives = [];
      
      // Add a small delay to make loading state visible
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Fetch from RepresentativeService
      _federalRepresentatives = await _federalService.getRepresentativesByAddress(address);
      
      _isLoadingFederal = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFederal = false;
      _errorMessageFederal = 'Error loading federal representatives: ${e.toString()}';
      if (kDebugMode) {
        print(_errorMessageFederal);
      }
      notifyListeners();
    }
  }
  
  // Fetch only local representatives
  Future<void> fetchLocalRepresentativesByAddress(String address) async {
    try {
      _isLoadingLocal = true;
      _errorMessageLocal = null;
      notifyListeners();
      
      // Clear existing local representatives
      _localRepresentativesRaw = [];
      
      // Add a small delay to make loading state visible
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Fetch from CiceroService
      _localRepresentativesRaw = await _localService.getLocalRepresentativesByAddress(address);
      
      _isLoadingLocal = false;
      notifyListeners();
    } catch (e) {
      _isLoadingLocal = false;
      _errorMessageLocal = 'Error loading local representatives: ${e.toString()}';
      if (kDebugMode) {
        print(_errorMessageLocal);
      }
      notifyListeners();
    }
  }
  
  // Cache results to reduce API calls
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save address and timestamp
      if (_lastSearchedAddress != null) {
        await prefs.setString('last_address', _lastSearchedAddress!);
        await prefs.setInt('last_search_time', DateTime.now().millisecondsSinceEpoch);
        
        // Save federal representatives
        if (_federalRepresentatives.isNotEmpty) {
          final fedData = _federalRepresentatives.map((rep) => rep.toMap()).toList();
          await prefs.setString('federal_reps_cache', json.encode(fedData));
        }
        
        // Save local representatives
        if (_localRepresentativesRaw.isNotEmpty) {
          final localData = _localRepresentativesRaw.map((rep) => rep.toMap()).toList();
          await prefs.setString('local_reps_cache', json.encode(localData));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cache: $e');
      }
    }
  }
  
  // Load cache to avoid unnecessary API calls
  Future<bool> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have cached data
      final lastAddress = prefs.getString('last_address');
      final lastSearchTime = prefs.getInt('last_search_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Only use cache if it's less than 24 hours old
      if (lastAddress != null && (currentTime - lastSearchTime) < 86400000) {
        _lastSearchedAddress = lastAddress;
        
        // Load federal representatives
        final fedCache = prefs.getString('federal_reps_cache');
        if (fedCache != null) {
          final fedData = json.decode(fedCache) as List<dynamic>;
          _federalRepresentatives = fedData
              .map((item) => Representative.fromMap('', Map<String, dynamic>.from(item)))
              .toList();
        }
        
        // Load local representatives
        final localCache = prefs.getString('local_reps_cache');
        if (localCache != null) {
          final localData = json.decode(localCache) as List<dynamic>;
          _localRepresentativesRaw = localData
              .map((item) => LocalRepresentative.fromMap(Map<String, dynamic>.from(item)))
              .toList();
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cache: $e');
      }
      return false;
    }
  }
  
  // Get details for a specific representative
  Future<Representative?> getRepresentativeDetails(String bioGuideId) async {
    // First check if it's a federal rep
    final fedRep = _federalRepresentatives.cast<Representative?>().firstWhere(
      (rep) => rep?.bioGuideId == bioGuideId,
      orElse: () => null,
    );
    
    if (fedRep != null) {
      return fedRep;
    }
    
    // Then check if it's a local rep
    final localRep = _localRepresentativesRaw.cast<LocalRepresentative?>().firstWhere(
      (rep) => rep?.bioGuideId == bioGuideId,
      orElse: () => null,
    );
    
    if (localRep != null) {
      return localRep.toRepresentative();
    }
    
    return null;
  }
  
  // Clear errors
  void clearErrors() {
    _errorMessageFederal = null;
    _errorMessageLocal = null;
    notifyListeners();
  }
  
  // Clear all data
  void clearAll() {
    _federalRepresentatives = [];
    _localRepresentativesRaw = [];
    _errorMessageFederal = null;
    _errorMessageLocal = null;
    _lastSearchedAddress = null;
    notifyListeners();
  }
}