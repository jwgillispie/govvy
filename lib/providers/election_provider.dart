import 'package:flutter/foundation.dart';
import 'package:govvy/models/election_model.dart';
import 'package:govvy/services/election_service.dart';

class ElectionProvider with ChangeNotifier {
  final ElectionService _electionService = ElectionService();

  List<Election> _elections = [];
  List<Election> _upcomingElections = [];
  List<PollingLocation> _pollingLocations = [];
  List<String> _availableStates = [];
  List<String> _citiesInState = [];
  
  Election? _selectedElection;
  String? _selectedState;
  String? _selectedCity;
  
  bool _isLoading = false;
  bool _isLoadingUpcoming = false;
  bool _isLoadingPolling = false;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  
  String? _error;
  String? _upcomingError;
  String? _pollingError;

  List<Election> get elections => _elections;
  List<Election> get upcomingElections => _upcomingElections;
  List<PollingLocation> get pollingLocations => _pollingLocations;
  List<String> get availableStates => _availableStates;
  List<String> get citiesInState => _citiesInState;
  
  Election? get selectedElection => _selectedElection;
  String? get selectedState => _selectedState;
  String? get selectedCity => _selectedCity;
  
  bool get isLoading => _isLoading;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  bool get isLoadingPolling => _isLoadingPolling;
  bool get isLoadingStates => _isLoadingStates;
  bool get isLoadingCities => _isLoadingCities;
  
  String? get error => _error;
  String? get upcomingError => _upcomingError;
  String? get pollingError => _pollingError;

  List<Election> get todayElections => _elections.where((e) => e.isToday).toList();
  List<Election> get thisWeekElections => _elections.where((e) => 
    e.isUpcoming && e.daysUntilElection <= 7
  ).toList();

  Future<void> loadElectionsByLocation({
    required String state,
    String? city,
    String? county,
    bool upcomingOnly = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _elections = await _electionService.getElectionsByLocation(
        state: state,
        city: city,
        county: county,
        upcomingOnly: upcomingOnly,
      );
      _selectedState = state;
      _selectedCity = city;
    } catch (e) {
      _error = e.toString();
      _elections = [];
      if (kDebugMode) {
        print('Error loading elections by location: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchElections(ElectionSearchFilters filters) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _elections = await _electionService.searchElections(filters);
    } catch (e) {
      _error = e.toString();
      _elections = [];
      if (kDebugMode) {
        print('Error searching elections: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUpcomingElections({String? state, int limit = 20}) async {
    _isLoadingUpcoming = true;
    _upcomingError = null;
    notifyListeners();

    try {
      _upcomingElections = await _electionService.getUpcomingElections(
        state: state,
        limit: limit,
      );
    } catch (e) {
      _upcomingError = e.toString();
      _upcomingElections = [];
      if (kDebugMode) {
        print('Error loading upcoming elections: $e');
      }
    } finally {
      _isLoadingUpcoming = false;
      notifyListeners();
    }
  }

  Future<void> loadElectionDetails(String electionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedElection = await _electionService.getElectionById(electionId);
    } catch (e) {
      _error = e.toString();
      _selectedElection = null;
      if (kDebugMode) {
        print('Error loading election details: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPollingLocations({
    required String address,
    String? electionId,
  }) async {
    _isLoadingPolling = true;
    _pollingError = null;
    notifyListeners();

    try {
      _pollingLocations = await _electionService.getPollingLocations(
        address: address,
        electionId: electionId,
      );
    } catch (e) {
      _pollingError = e.toString();
      _pollingLocations = [];
      if (kDebugMode) {
        print('Error loading polling locations: $e');
      }
    } finally {
      _isLoadingPolling = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailableStates() async {
    if (_availableStates.isNotEmpty) return;

    _isLoadingStates = true;
    notifyListeners();

    try {
      _availableStates = await _electionService.getAvailableStates();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading available states: $e');
      }
    } finally {
      _isLoadingStates = false;
      notifyListeners();
    }
  }

  Future<void> loadCitiesInState(String state) async {
    if (_selectedState == state && _citiesInState.isNotEmpty) return;

    _isLoadingCities = true;
    notifyListeners();

    try {
      _citiesInState = await _electionService.getCitiesInState(state);
      _selectedState = state;
    } catch (e) {
      _citiesInState = [];
      if (kDebugMode) {
        print('Error loading cities in state: $e');
      }
    } finally {
      _isLoadingCities = false;
      notifyListeners();
    }
  }

  void selectElection(Election election) {
    _selectedElection = election;
    notifyListeners();
  }

  void clearSelection() {
    _selectedElection = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _upcomingError = null;
    _pollingError = null;
    notifyListeners();
  }

  void clearElections() {
    _elections = [];
    _upcomingElections = [];
    _pollingLocations = [];
    _selectedElection = null;
    notifyListeners();
  }

  void reset() {
    _elections = [];
    _upcomingElections = [];
    _pollingLocations = [];
    _availableStates = [];
    _citiesInState = [];
    _selectedElection = null;
    _selectedState = null;
    _selectedCity = null;
    _isLoading = false;
    _isLoadingUpcoming = false;
    _isLoadingPolling = false;
    _isLoadingStates = false;
    _isLoadingCities = false;
    _error = null;
    _upcomingError = null;
    _pollingError = null;
    notifyListeners();
  }

  Future<bool> isElectionDay(DateTime date) async {
    return await _electionService.isElectionDay(date);
  }

  Future<void> loadElectionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? state,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _elections = await _electionService.getElectionsByDateRange(
        startDate: startDate,
        endDate: endDate,
        state: state,
      );
    } catch (e) {
      _error = e.toString();
      _elections = [];
      if (kDebugMode) {
        print('Error loading elections by date range: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}