import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:govvy/models/election_model.dart';
import 'package:govvy/models/campaign_finance_model.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:govvy/services/fec_service.dart';

class ElectionService {
  static final ElectionService _instance = ElectionService._internal();
  factory ElectionService() => _instance;
  ElectionService._internal();

  final NetworkService _networkService = NetworkService();
  final FECService _fecService = FECService();
  Future<List<Election>> getElectionsByLocation({
    required String state,
    String? city,
    String? county,
    bool upcomingOnly = true,
  }) async {
    try {
      final params = <String, String>{
        'state': state.toUpperCase(),
        if (city != null) 'city': city,
        if (county != null) 'county': county,
        'upcoming_only': upcomingOnly.toString(),
      };

      final response =
          await _getFromElectionApi('/elections', queryParams: params);
      final elections = (response['elections'] as List<dynamic>?)
              ?.map((json) => Election.fromJson(json))
              .toList() ??
          [];

      return elections;
    } catch (e) {
      throw Exception('Failed to fetch election data: $e');
    }
  }

  Future<List<Election>> searchElections(ElectionSearchFilters filters) async {
    try {
      final params = filters
          .toQueryParams()
          .map((key, value) => MapEntry(key, value.toString()));
      final response =
          await _getFromElectionApi('/elections/search', queryParams: params);

      final elections = (response['elections'] as List<dynamic>?)
              ?.map((json) => Election.fromJson(json))
              .toList() ??
          [];

      return elections;
    } catch (e) {
      throw Exception('Failed to search elections: $e');
    }
  }

  Future<Election?> getElectionById(String electionId) async {
    try {
      final response = await _getFromElectionApi('/elections/$electionId');

      if (response['election'] != null) {
        return Election.fromJson(response['election']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch election details: $e');
    }
  }

  Future<List<Election>> getUpcomingElections({
    String? state,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        'upcoming_only': 'true',
        'limit': limit.toString(),
        if (state != null) 'state': state.toUpperCase(),
      };

      final response =
          await _getFromElectionApi('/elections/upcoming', queryParams: params);
      final elections = (response['elections'] as List<dynamic>?)
              ?.map((json) => Election.fromJson(json))
              .toList() ??
          [];

      return elections;
    } catch (e) {
      throw Exception('Failed to fetch upcoming elections: $e');
    }
  }

  Future<List<PollingLocation>> getPollingLocations({
    required String address,
    String? electionId,
  }) async {
    try {
      final params = <String, String>{
        'address': address,
        if (electionId != null) 'election_id': electionId,
      };

      final response =
          await _getFromElectionApi('/polling-locations', queryParams: params);
      final locations = (response['polling_locations'] as List<dynamic>?)
              ?.map((json) => PollingLocation.fromJson(json))
              .toList() ??
          [];

      return locations;
    } catch (e) {
      throw Exception('Failed to fetch polling locations: $e');
    }
  }

  Future<List<String>> getAvailableStates() async {
    try {
      final response = await _getFromElectionApi('/states');
      return List<String>.from(response['states'] ?? []);
    } catch (e) {
      return _getDefaultStates();
    }
  }

  Future<List<String>> getCitiesInState(String state) async {
    try {
      final params = {'state': state.toUpperCase()};
      final response =
          await _getFromElectionApi('/cities', queryParams: params);
      return List<String>.from(response['cities'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _getFromElectionApi(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final params = queryParams ?? {};
    params['format'] = 'json';

    final url = Uri.parse('https://api.vote.gov/v1$endpoint')
        .replace(queryParameters: params);

    try {
      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {'elections': []};
      } else {
        throw Exception('Election API error: ${response.statusCode}');
      }
    } catch (e) {
      // Instead of falling back to mock data, try FEC API for elections
      return await _getFromFECElectionsApi(endpoint, queryParams);
    }
  }

  Future<Map<String, dynamic>> _getFromFECElectionsApi(
    String endpoint,
    Map<String, String>? queryParams,
  ) async {
    try {
      // Try to get FEC election data using the FEC elections endpoints
      if (endpoint.contains('/elections')) {
        // First try the dedicated FEC elections endpoint
        final fecElections = await _fecService.getElections(
          state: queryParams?['state'],
          cycle: DateTime.now().year,
        );

        if (fecElections.isNotEmpty) {
          // Convert FEC elections to Election objects
          final electionList = fecElections
              .map((fecElection) => {
                    'id': 'fec-election-${fecElection.electionId}',
                    'name':
                        '${fecElection.officeName} Election ${fecElection.electionTypeName}',
                    'description':
                        '${fecElection.electionTypeName} election for ${fecElection.officeName} in ${fecElection.state}${fecElection.district != null ? " District ${fecElection.district}" : ""}',
                    'electionDate':
                        fecElection.electionDate?.toIso8601String() ??
                            DateTime.now().toIso8601String(),
                    'state': fecElection.state,
                    'city': '',
                    'county': '',
                    'electionType': 'Federal',
                    'status': fecElection.isUpcoming ? 'upcoming' : 'completed',
                    'contests': [],
                    'pollingLocations': [],
                  })
              .toList();

          return {'elections': electionList};
        }

        // Fallback to calendar events if no elections found
        final elections = await _fecService.getElectionDates(
          state: queryParams?['state'],
          year: DateTime.now().year,
        );

        // Convert FEC calendar events to Election objects
        final electionList = elections
            .map((event) => {
                  'id': 'fec-calendar-${event.eventId}',
                  'name': event.summary,
                  'description': event.description,
                  'electionDate': event.startDate.toIso8601String(),
                  'state': queryParams?['state'] ??
                      (event.states?.isNotEmpty == true
                          ? event.states!.first
                          : 'US'),
                  'city': event.location ?? '',
                  'county': '',
                  'electionType': 'Federal',
                  'status': event.startDate.isAfter(DateTime.now())
                      ? 'upcoming'
                      : 'completed',
                  'contests': [],
                  'pollingLocations': [],
                })
            .toList();

        return {'elections': electionList};
      }

      // For other endpoints, return empty data
      return {'elections': [], 'cities': [], 'states': _getDefaultStates()};
    } catch (e) {
      return {'elections': [], 'cities': [], 'states': _getDefaultStates()};
    }
  }

  List<String> _getDefaultStates() {
    return [
      'AL',
      'AK',
      'AZ',
      'AR',
      'CA',
      'CO',
      'CT',
      'DE',
      'FL',
      'GA',
      'HI',
      'ID',
      'IL',
      'IN',
      'IA',
      'KS',
      'KY',
      'LA',
      'ME',
      'MD',
      'MA',
      'MI',
      'MN',
      'MS',
      'MO',
      'MT',
      'NE',
      'NV',
      'NH',
      'NJ',
      'NM',
      'NY',
      'NC',
      'ND',
      'OH',
      'OK',
      'OR',
      'PA',
      'RI',
      'SC',
      'SD',
      'TN',
      'TX',
      'UT',
      'VT',
      'VA',
      'WA',
      'WV',
      'WI',
      'WY'
    ];
  }

  Future<bool> isElectionDay(DateTime date) async {
    try {
      final elections = await getUpcomingElections();
      return elections.any((election) =>
          election.electionDate.year == date.year &&
          election.electionDate.month == date.month &&
          election.electionDate.day == date.day);
    } catch (e) {
      return false;
    }
  }

  Future<List<Election>> getElectionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? state,
  }) async {
    final filters = ElectionSearchFilters(
      startDate: startDate,
      endDate: endDate,
      state: state,
      upcomingOnly: false,
    );

    return await searchElections(filters);
  }

  // Enhanced FEC Integration Methods

  Future<List<FECCalendarEvent>> getFederalElectionEvents({
    int? year,
    List<int>? categoryIds,
    String? state,
  }) async {
    try {
      final events = await _fecService.getElectionCalendar(
        year: year ?? DateTime.now().year,
        categoryIds:
            categoryIds ?? [36, 21], // Election dates and reporting deadlines
        state: state,
      );

      return events;
    } catch (e) {
      throw Exception('Failed to fetch federal election events: $e');
    }
  }

  Future<List<FECCandidate>> searchFederalCandidates({
    String? name,
    String? state,
    String? office,
    int? cycle,
    String? party,
    int perPage = 50,
  }) async {
    try {
      final candidates = await _fecService.searchCandidates(
        name: name,
        state: state,
        office: office,
        cycle: cycle ?? DateTime.now().year,
        party: party,
        perPage: perPage,
      );

      return candidates;
    } catch (e) {
      throw Exception('Failed to search federal candidates: $e');
    }
  }

  Future<List<FECCandidate>> getCandidatesByState(
    String state, {
    String? office,
    int? cycle,
  }) async {
    try {
      final candidates = await searchFederalCandidates(
        state: state,
        office: office,
        cycle: cycle ?? DateTime.now().year,
        perPage: 100,
      );

      return candidates;
    } catch (e) {
      return [];
    }
  }

  Future<List<FECCalendarEvent>> getElectionDatesByState(
    String state, {
    int? year,
  }) async {
    return await getFederalElectionEvents(
      year: year ?? DateTime.now().year,
      categoryIds: [36], // Only election dates
      state: state,
    );
  }

  Future<List<FECCalendarEvent>> getReportingDeadlines({
    int? year,
    String? state,
  }) async {
    return await getFederalElectionEvents(
      year: year ?? DateTime.now().year,
      categoryIds: [21], // Only reporting deadlines
      state: state,
    );
  }

  Future<Map<String, dynamic>> getElectionSummary({
    String? state,
    int? year,
  }) async {
    try {
      final currentYear = year ?? DateTime.now().year;

      // Get federal election events
      final electionEvents = await getElectionDatesByState(
        state ?? 'US',
        year: currentYear,
      );

      // Get federal candidates for the state
      final federalCandidates = state != null
          ? await getCandidatesByState(state, cycle: currentYear)
          : <FECCandidate>[];

      // Get local elections from existing service
      final localElections = state != null
          ? await getElectionsByLocation(state: state)
          : <Election>[];

      return {
        'federal_election_events': electionEvents,
        'federal_candidates': federalCandidates,
        'local_elections': localElections,
        'summary': {
          'federal_events_count': electionEvents.length,
          'federal_candidates_count': federalCandidates.length,
          'local_elections_count': localElections.length,
          'upcoming_federal_events': electionEvents
              .where((e) => e.startDate.isAfter(DateTime.now()))
              .length,
          'upcoming_local_elections':
              localElections.where((e) => e.isUpcoming).length,
        },
      };
    } catch (e) {
      throw Exception('Failed to get election summary: $e');
    }
  }

  Future<List<Election>> getEnrichedElections({
    String? state,
    String? city,
    bool includeFederal = true,
    bool includeLocal = true,
  }) async {
    final enrichedElections = <Election>[];

    try {
      // Get local elections (with fallback for api.vote.gov issues)
      if (includeLocal && state != null) {
        try {
          final localElections = await getElectionsByLocation(
            state: state,
            city: city,
          );
          enrichedElections.addAll(localElections);
        } catch (e) {}
      }

      // Convert federal election events to Election objects
      if (includeFederal) {
        // First try to get dedicated FEC elections
        try {
          final fecElections = await _fecService.getElections(
            state: state,
            cycle: DateTime.now().year,
          );

          if (fecElections.isNotEmpty) {
            for (final fecElection in fecElections) {
              final election = Election(
                id: 'fec-election-${fecElection.electionId}',
                name:
                    '${fecElection.officeName} Election ${fecElection.electionTypeName}',
                description:
                    '${fecElection.electionTypeName} election for ${fecElection.officeName} in ${fecElection.state}${fecElection.district != null ? " District ${fecElection.district}" : ""}',
                electionDate: fecElection.electionDate ?? DateTime.now(),
                state: fecElection.state,
                city: '',
                county: '',
                electionType: 'Federal',
                contests: [],
                status: fecElection.isUpcoming ? 'upcoming' : 'completed',
                pollingLocations: [],
              );
              enrichedElections.add(election);
            }
          }
        } catch (e) {}

        // Also get calendar events for additional context - include current year and next year
        List<FECCalendarEvent> federalEvents = [];

        if (state != null) {
          // For specific states, get state-specific events for current and next year
          final currentYearEvents = await getFederalElectionEvents(
            categoryIds: [36], // Election dates only
            state: state,
            year: DateTime.now().year,
          );
          final nextYearEvents = await getFederalElectionEvents(
            categoryIds: [36], // Election dates only
            state: state,
            year: DateTime.now().year + 1,
          );
          federalEvents.addAll(currentYearEvents);
          federalEvents.addAll(nextYearEvents);
        } else {
          // For "all states", get events from current and next year and filter out state-specific ones
          final currentYearEvents =
              await _getFederalNationalEvents(DateTime.now().year);
          final nextYearEvents =
              await _getFederalNationalEvents(DateTime.now().year + 1);

          final allEvents = [...currentYearEvents, ...nextYearEvents];
          federalEvents = allEvents.where((event) {
            // Only include truly national events or events without state specificity
            return _isNationalEvent(event) ||
                event.states == null ||
                event.states!.isEmpty ||
                event.states!.length > 1; // Multi-state events
          }).toList();

          // Log the filtering results
        }

        if (federalEvents.isNotEmpty) {
          for (final event in federalEvents) {
            // For specific state searches, filter by state
            if (state != null &&
                event.states != null &&
                event.states!.isNotEmpty) {
              if (!event.states!.contains(state) && !_isNationalEvent(event)) {
                continue; // Skip events that don't match the selected state
              }
            }

            // Skip obviously state-specific events when no state is selected
            if (state == null &&
                !_isNationalEvent(event) &&
                event.states != null &&
                event.states!.length == 1) {
              continue;
            }

            final election = Election(
              id: 'federal-${event.eventId}',
              name: event.summary,
              description: event.description,
              electionDate: event.startDate,
              state: state ??
                  (event.states?.isNotEmpty == true
                      ? event.states!.first
                      : 'US'),
              city: event.location ?? '',
              county: '',
              electionType: 'Federal',
              contests: [], // Federal contests would need separate API calls
              status: event.startDate.isAfter(DateTime.now())
                  ? 'upcoming'
                  : 'completed',
              pollingLocations: [],
            );
            enrichedElections.add(election);
          }

          // If we have a specific state, also get truly national federal elections
          if (state != null) {
            final nationalEvents = await _getFederalNationalEvents();

            for (final event in nationalEvents) {
              // Only include truly national events (presidential elections, etc.)
              if (_isNationalEvent(event)) {
                final election = Election(
                  id: 'federal-national-${event.eventId}',
                  name: '${event.summary} (National)',
                  description: event.description,
                  electionDate: event.startDate,
                  state: state,
                  city: event.location ?? '',
                  county: '',
                  electionType: 'Federal',
                  contests: [],
                  status: event.startDate.isAfter(DateTime.now())
                      ? 'upcoming'
                      : 'completed',
                  pollingLocations: [],
                );
                enrichedElections.add(election);
              }
            }
          }
        }
      }

      // Remove duplicates and sort by election date
      final uniqueElections = <String, Election>{};
      for (final election in enrichedElections) {
        uniqueElections[election.id] = election;
      }

      final finalElections = uniqueElections.values.toList();
      finalElections.sort((a, b) => a.electionDate.compareTo(b.electionDate));

      return finalElections;
    } catch (e) {
      // Fallback to local elections only, then federal only, then mock data
      if (state != null) {
        try {
          return await getElectionsByLocation(state: state, city: city);
        } catch (localError) {
          // Return federal elections only as fallback
          try {
            final federalEvents = await getFederalElectionEvents(
              categoryIds: [36],
              state: state,
            );

            return federalEvents
                .map((event) => Election(
                      id: 'federal-${event.eventId}',
                      name: event.summary,
                      description: event.description,
                      electionDate: event.startDate,
                      state: state,
                      city: event.location ?? '',
                      county: '',
                      electionType: 'Federal',
                      contests: [],
                      status: event.startDate.isAfter(DateTime.now())
                          ? 'upcoming'
                          : 'completed',
                      pollingLocations: [],
                    ))
                .toList();
          } catch (federalError) {
            return [];
          }
        }
      }
      return [];
    }
  }

  // Helper methods for better federal election handling

  Future<List<FECCalendarEvent>> _getFederalNationalEvents([int? year]) async {
    try {
      // Get events without state filter to find truly national events
      final allEvents = await _fecService.getElectionCalendar(
        year: year ?? DateTime.now().year,
        categoryIds: [36], // Election dates only
        state: null, // No state filter
      );

      return allEvents;
    } catch (e) {
      return [];
    }
  }

  bool _isNationalEvent(FECCalendarEvent event) {
    // Check if this is a truly national event based on summary patterns
    final summary = event.summary.toLowerCase();
    final originalSummary = event.summary;

    // First, explicitly exclude state/district-specific patterns
    // Pattern: STATE/DISTRICT like FL/01, CA/12, TX/18, etc.
    if (RegExp(r'[A-Z]{2}/\d+').hasMatch(originalSummary)) {
      return false;
    }

    // Exclude events with "special" or "primary" - these are usually state-specific
    if (summary.contains('special') || summary.contains('primary')) {
      return false;
    }

    // Exclude events that mention specific states in common patterns
    final statePatterns = [
      'florida', 'california', 'texas', 'new york', 'arizona',
      'fl ', 'ca ', 'tx ', 'ny ', 'az ', // with space to avoid false positives
    ];

    for (final pattern in statePatterns) {
      if (summary.contains(pattern)) {
        return false;
      }
    }

    // Include clearly national events
    if (summary.contains('presidential') ||
        summary.contains('president') ||
        (summary.contains('general election') &&
            !summary.contains('special')) ||
        summary.contains('federal election') ||
        summary.contains('midterm') ||
        summary.contains('congressional election')) {
      return true;
    }

    // Events that apply to many states (>= 45) are likely national
    if (event.states != null && event.states!.length >= 45) {
      return true;
    }

    // If we can't clearly identify it as national, exclude it
    return false;
  }
}
