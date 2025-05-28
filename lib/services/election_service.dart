import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:govvy/models/election_model.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';

class ElectionService {
  static final ElectionService _instance = ElectionService._internal();
  factory ElectionService() => _instance;
  ElectionService._internal();

  final NetworkService _networkService = NetworkService();
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

      final response = await _getFromElectionApi('/elections', queryParams: params);
      final elections = (response['elections'] as List<dynamic>?)
          ?.map((json) => Election.fromJson(json))
          .toList() ?? [];

      return elections;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching elections by location: $e');
      }
      throw Exception('Failed to fetch election data: $e');
    }
  }

  Future<List<Election>> searchElections(ElectionSearchFilters filters) async {
    try {
      final params = filters.toQueryParams().map((key, value) => MapEntry(key, value.toString()));
      final response = await _getFromElectionApi('/elections/search', queryParams: params);
      
      final elections = (response['elections'] as List<dynamic>?)
          ?.map((json) => Election.fromJson(json))
          .toList() ?? [];

      return elections;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching elections: $e');
      }
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
      if (kDebugMode) {
        print('Error fetching election by ID: $e');
      }
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

      final response = await _getFromElectionApi('/elections/upcoming', queryParams: params);
      final elections = (response['elections'] as List<dynamic>?)
          ?.map((json) => Election.fromJson(json))
          .toList() ?? [];

      return elections;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching upcoming elections: $e');
      }
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

      final response = await _getFromElectionApi('/polling-locations', queryParams: params);
      final locations = (response['polling_locations'] as List<dynamic>?)
          ?.map((json) => PollingLocation.fromJson(json))
          .toList() ?? [];

      return locations;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching polling locations: $e');
      }
      throw Exception('Failed to fetch polling locations: $e');
    }
  }

  Future<List<String>> getAvailableStates() async {
    try {
      final response = await _getFromElectionApi('/states');
      return List<String>.from(response['states'] ?? []);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching available states: $e');
      }
      return _getDefaultStates();
    }
  }

  Future<List<String>> getCitiesInState(String state) async {
    try {
      final params = {'state': state.toUpperCase()};
      final response = await _getFromElectionApi('/cities', queryParams: params);
      return List<String>.from(response['cities'] ?? []);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching cities in state: $e');
      }
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
      if (kDebugMode) {
        print('Election API request failed: $e');
      }
      return _getMockElectionData(endpoint, queryParams);
    }
  }

  Map<String, dynamic> _getMockElectionData(String endpoint, Map<String, String>? params) {
    if (endpoint.contains('/elections')) {
      return {
        'elections': [
          {
            'id': 'mock-1',
            'name': 'Mock Municipal Election 2024',
            'description': 'Local municipal elections for mayor and city council',
            'electionDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'state': params?['state'] ?? 'CA',
            'city': params?['city'] ?? 'San Francisco',
            'county': 'San Francisco County',
            'electionType': 'Municipal',
            'status': 'scheduled',
            'contests': [
              {
                'id': 'contest-1',
                'office': 'Mayor',
                'district': 'City-wide',
                'level': 'Municipal',
                'contestType': 'General',
                'numberToElect': 1,
                'candidates': [
                  {
                    'id': 'candidate-1',
                    'name': 'Jane Smith',
                    'party': 'Democratic',
                    'isIncumbent': true,
                  },
                  {
                    'id': 'candidate-2',
                    'name': 'John Doe',
                    'party': 'Republican',
                    'isIncumbent': false,
                  },
                ],
              },
            ],
            'pollingLocations': [
              {
                'id': 'location-1',
                'name': 'City Hall',
                'address': '1 Dr Carlton B Goodlett Pl',
                'city': 'San Francisco',
                'state': 'CA',
                'zipCode': '94102',
                'hours': '7:00 AM - 8:00 PM',
                'notes': ['Accessible entrance available'],
              },
            ],
          },
        ],
      };
    } else if (endpoint.contains('/states')) {
      return {
        'states': _getDefaultStates(),
      };
    } else if (endpoint.contains('/cities')) {
      return {
        'cities': ['San Francisco', 'Los Angeles', 'Sacramento', 'San Diego'],
      };
    }
    
    return {};
  }

  List<String> _getDefaultStates() {
    return [
      'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
      'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
      'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
      'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
      'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
    ];
  }

  Future<bool> isElectionDay(DateTime date) async {
    try {
      final elections = await getUpcomingElections();
      return elections.any((election) => 
        election.electionDate.year == date.year &&
        election.electionDate.month == date.month &&
        election.electionDate.day == date.day
      );
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
}