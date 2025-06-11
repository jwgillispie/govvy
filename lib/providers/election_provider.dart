import 'package:flutter/foundation.dart';
import 'package:govvy/models/election_model.dart';
import 'package:govvy/models/campaign_finance_model.dart';
import 'package:govvy/services/election_service.dart';

class ElectionProvider with ChangeNotifier {
  final ElectionService _electionService = ElectionService();

  List<Election> _elections = [];
  List<Election> _upcomingElections = [];
  List<PollingLocation> _pollingLocations = [];
  List<String> _availableStates = [];
  List<String> _citiesInState = [];
  
  // Enhanced FEC data
  List<FECCalendarEvent> _federalEvents = [];
  List<FECCandidate> _federalCandidates = [];
  Map<String, dynamic>? _electionSummary;
  
  Election? _selectedElection;
  String? _selectedState;
  String? _selectedCity;
  
  bool _isLoading = false;
  bool _isLoadingUpcoming = false;
  bool _isLoadingPolling = false;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  bool _isLoadingFederalEvents = false;
  bool _isLoadingFederalCandidates = false;
  bool _isLoadingSummary = false;
  
  String? _error;
  String? _upcomingError;
  String? _pollingError;
  String? _federalEventsError;
  String? _federalCandidatesError;
  String? _summaryError;

  List<Election> get elections => _elections;
  List<Election> get upcomingElections => _upcomingElections;
  List<PollingLocation> get pollingLocations => _pollingLocations;
  List<String> get availableStates => _availableStates;
  List<String> get citiesInState => _citiesInState;
  
  // Enhanced FEC getters
  List<FECCalendarEvent> get federalEvents => _federalEvents;
  List<FECCandidate> get federalCandidates => _federalCandidates;
  Map<String, dynamic>? get electionSummary => _electionSummary;
  
  Election? get selectedElection => _selectedElection;
  String? get selectedState => _selectedState;
  String? get selectedCity => _selectedCity;
  
  bool get isLoading => _isLoading;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  bool get isLoadingPolling => _isLoadingPolling;
  bool get isLoadingStates => _isLoadingStates;
  bool get isLoadingCities => _isLoadingCities;
  bool get isLoadingFederalEvents => _isLoadingFederalEvents;
  bool get isLoadingFederalCandidates => _isLoadingFederalCandidates;
  bool get isLoadingSummary => _isLoadingSummary;
  
  String? get error => _error;
  String? get upcomingError => _upcomingError;
  String? get pollingError => _pollingError;
  String? get federalEventsError => _federalEventsError;
  String? get federalCandidatesError => _federalCandidatesError;
  String? get summaryError => _summaryError;

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
    _federalEventsError = null;
    _federalCandidatesError = null;
    _summaryError = null;
    notifyListeners();
  }

  void clearElections() {
    _elections = [];
    _upcomingElections = [];
    _pollingLocations = [];
    _federalEvents = [];
    _federalCandidates = [];
    _electionSummary = null;
    _selectedElection = null;
    notifyListeners();
  }

  void reset() {
    _elections = [];
    _upcomingElections = [];
    _pollingLocations = [];
    _availableStates = [];
    _citiesInState = [];
    _federalEvents = [];
    _federalCandidates = [];
    _electionSummary = null;
    _selectedElection = null;
    _selectedState = null;
    _selectedCity = null;
    _isLoading = false;
    _isLoadingUpcoming = false;
    _isLoadingPolling = false;
    _isLoadingStates = false;
    _isLoadingCities = false;
    _isLoadingFederalEvents = false;
    _isLoadingFederalCandidates = false;
    _isLoadingSummary = false;
    _error = null;
    _upcomingError = null;
    _pollingError = null;
    _federalEventsError = null;
    _federalCandidatesError = null;
    _summaryError = null;
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

  // Enhanced FEC methods

  Future<void> loadFederalEvents({
    int? year,
    List<int>? categoryIds,
    String? state,
  }) async {
    _isLoadingFederalEvents = true;
    _federalEventsError = null;
    notifyListeners();

    try {
      _federalEvents = await _electionService.getFederalElectionEvents(
        year: year,
        categoryIds: categoryIds,
        state: state,
      );
    } catch (e) {
      _federalEventsError = e.toString();
      _federalEvents = [];
      if (kDebugMode) {
        print('Error loading federal events: $e');
      }
    } finally {
      _isLoadingFederalEvents = false;
      notifyListeners();
    }
  }

  Future<void> loadFederalCandidates({
    String? name,
    String? state,
    String? office,
    int? cycle,
    String? party,
    int perPage = 50,
  }) async {
    _isLoadingFederalCandidates = true;
    _federalCandidatesError = null;
    notifyListeners();

    try {
      _federalCandidates = await _electionService.searchFederalCandidates(
        name: name,
        state: state,
        office: office,
        cycle: cycle,
        party: party,
        perPage: perPage,
      );
    } catch (e) {
      _federalCandidatesError = e.toString();
      _federalCandidates = [];
      if (kDebugMode) {
        print('Error loading federal candidates: $e');
      }
    } finally {
      _isLoadingFederalCandidates = false;
      notifyListeners();
    }
  }

  Future<void> loadElectionSummary({
    String? state,
    int? year,
  }) async {
    _isLoadingSummary = true;
    _summaryError = null;
    notifyListeners();

    try {
      _electionSummary = await _electionService.getElectionSummary(
        state: state,
        year: year,
      );
    } catch (e) {
      _summaryError = e.toString();
      _electionSummary = null;
      if (kDebugMode) {
        print('Error loading election summary: $e');
      }
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> loadEnrichedElections({
    String? state,
    String? city,
    bool includeFederal = true,
    bool includeLocal = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _elections = await _electionService.getEnrichedElections(
        state: state,
        city: city,
        includeFederal: includeFederal,
        includeLocal: includeLocal,
      );
      _selectedState = state;
      _selectedCity = city;
    } catch (e) {
      _error = e.toString();
      _elections = [];
      if (kDebugMode) {
        print('Error loading enriched elections: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Enhanced convenience methods

  Future<void> loadElectionDatesByState(String state, {int? year}) async {
    await loadFederalEvents(
      state: state,
      year: year,
      categoryIds: [36], // Election dates only
    );
  }

  Future<void> loadReportingDeadlines({String? state, int? year}) async {
    await loadFederalEvents(
      state: state,
      year: year,
      categoryIds: [21], // Reporting deadlines only
    );
  }

  Future<void> loadCandidatesByState(String state, {
    String? office,
    int? cycle,
  }) async {
    await loadFederalCandidates(
      state: state,
      office: office,
      cycle: cycle,
      perPage: 100,
    );
  }

  // Enhanced getters

  List<FECCalendarEvent> get upcomingFederalEvents => 
    _federalEvents.where((e) => e.startDate.isAfter(DateTime.now())).toList();

  List<FECCalendarEvent> get electionDates => 
    _federalEvents.where((e) => e.isElectionDate).toList();

  List<FECCalendarEvent> get reportingDeadlines => 
    _federalEvents.where((e) => !e.isElectionDate).toList();

  List<FECCandidate> get presidentialCandidates => 
    _federalCandidates.where((c) => c.office == 'P').toList();

  List<FECCandidate> get senateCandidates => 
    _federalCandidates.where((c) => c.office == 'S').toList();

  List<FECCandidate> get houseCandidates => 
    _federalCandidates.where((c) => c.office == 'H').toList();

  List<FECCandidate> get incumbentCandidates => 
    _federalCandidates.where((c) => c.isIncumbent == true).toList();
}