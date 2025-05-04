// lib/services/legiscan_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:govvy/services/network_service.dart';
import 'package:http/http.dart' as http;

class LegiscanService {
  final String _baseUrl = 'https://api.legiscan.com/';
  final NetworkService _networkService = NetworkService();
  
  // Get API key from Remote Config
  String? get _apiKey => RemoteConfigService().getLegiscanApiKey;
  
  // Check if API key is available
  bool get hasApiKey {
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;
    if (kDebugMode && !hasKey) {
      print('Using mock data because LegiScan API key is not available');
    }
    return hasKey;
  }
  
  // Find a person by name and state in LegiScan
  Future<Map<String, dynamic>?> findPersonByName(String name, String state) async {
    if (!hasApiKey) {
      return null;
    }
    
    try {
      // First, get the session list for the state to find current session ID
      final sessionData = await _callApi('getSessionList', {'state': state});
      
      if (sessionData == null || !sessionData.containsKey('sessions')) {
        if (kDebugMode) {
          print('No session data found for state: $state');
        }
        return null;
      }
      
      // Find the most recent (active or prefiled) session
      int? sessionId;
      for (var session in sessionData['sessions']) {
        if (session['session_status'] == 'active' || session['session_status'] == 'prefiled') {
          sessionId = session['session_id'];
          break;
        }
      }
      
      if (sessionId == null && sessionData['sessions'].isNotEmpty) {
        // If no active session, use the most recent one
        sessionId = sessionData['sessions'][0]['session_id'];
      }
      
      if (sessionId == null) {
        if (kDebugMode) {
          print('No valid session ID found for state: $state');
        }
        return null;
      }
      
      // Get people in this session
      final peopleData = await _callApi('getSessionPeople', {'id': sessionId.toString()});
      
      if (peopleData == null || !peopleData.containsKey('people') || peopleData['people'] is! Map) {
        if (kDebugMode) {
          print('No people data found for session ID: $sessionId');
        }
        return null;
      }
      
      // Search for the person by name
      final String lowercaseName = name.toLowerCase();
      final Map<String, dynamic> people = peopleData['people'];
      
      // First try exact match
      for (var personId in people.keys) {
        var person = people[personId];
        if (person is! Map) continue;
        
        final String fullName = '${person['first_name']} ${person['last_name']}'.toLowerCase();
        if (fullName == lowercaseName) {
          if (kDebugMode) {
            print('Found exact name match for $name: ${person['people_id']}');
          }
          return Map<String, dynamic>.from(person);
        }
      }
      
      // Then try partial match
      for (var personId in people.keys) {
        var person = people[personId];
        if (person is! Map) continue;
        
        final String firstName = '${person['first_name']}'.toLowerCase();
        final String lastName = '${person['last_name']}'.toLowerCase();
        final String fullName = '$firstName $lastName';
        
        // Check if the representative name contains the legiscan name or vice versa
        if (lowercaseName.contains(lastName) || 
            fullName.contains(lowercaseName) || 
            lowercaseName.contains(fullName)) {
          if (kDebugMode) {
            print('Found partial name match for $name: ${person['people_id']} ($fullName)');
          }
          return Map<String, dynamic>.from(person);
        }
      }
      
      if (kDebugMode) {
        print('No matching person found for: $name in $state');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error finding person in LegiScan: $e');
      }
      return null;
    }
  }
  
  // Get sponsored bills for a person
  Future<List<RepresentativeBill>> getSponsoredBills(int personId) async {
    if (!hasApiKey) {
      return [];
    }
    
    try {
      // Get person details including sponsored bills
      final personData = await _callApi('getPerson', {'id': personId.toString()});
      
      if (personData == null || !personData.containsKey('person')) {
        if (kDebugMode) {
          print('No person data found for ID: $personId');
        }
        return [];
      }
      
      final person = personData['person'];
      
      if (!person.containsKey('sponsor_bills') || person['sponsor_bills'] is! List) {
        if (kDebugMode) {
          print('No sponsored bills found for person ID: $personId');
        }
        return [];
      }
      
      final bills = person['sponsor_bills'] as List;
      final List<RepresentativeBill> result = [];
      
      // Limit to 10 most recent bills to avoid too many API calls
      final billsToProcess = bills.length > 10 ? bills.sublist(0, 10) : bills;
      
      for (var bill in billsToProcess) {
        if (bill is! Map) continue;
        
        try {
          // Get more details about the bill
          final billData = await _callApi('getBill', {'id': bill['bill_id'].toString()});
          
          if (billData != null && billData.containsKey('bill')) {
            final billDetails = billData['bill'];
            if (billDetails is! Map) continue;
            
            // Parse bill number to extract type and number
            String billNumber = billDetails['bill_number']?.toString() ?? '';
            String billType = '';
            String number = '';
            
            // Handle different bill number formats
            final RegExp regex = RegExp(r'([A-Za-z]+)(\s*)(\d+)');
            final match = regex.firstMatch(billNumber);
            
            if (match != null) {
              billType = match.group(1) ?? '';
              number = match.group(3) ?? '';
            } else {
              // Fallback: try to extract type from bill_type
              billType = billDetails['bill_type'] ?? '';
              number = billNumber;
            }
            
            // Get latest action
            String latestAction = '';
            if (billDetails.containsKey('history') && billDetails['history'] is List && (billDetails['history'] as List).isNotEmpty) {
              final history = billDetails['history'] as List;
              final latestEvent = history.first;
              if (latestEvent is Map) {
                latestAction = latestEvent['action'] ?? '';
              }
            } else if (billDetails.containsKey('status')) {
              latestAction = 'Status: ${billDetails['status']}';
            }
            
            result.add(RepresentativeBill(
              congress: billDetails['session']['session_name'] ?? '',
              billType: billType,
              billNumber: number,
              title: billDetails['title'] ?? 'Untitled Bill',
              introducedDate: billDetails['date'] ?? '',
              latestAction: latestAction,
            ));
          }
        } catch (billError) {
          if (kDebugMode) {
            print('Error fetching bill details: $billError');
          }
          // Continue to next bill rather than failing the whole request
          continue;
        }
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sponsored bills from LegiScan: $e');
      }
      return [];
    }
  }
  
  // Helper method to call the LegiScan API
  Future<Map<String, dynamic>?> _callApi(String operation, Map<String, String> params) async {
    try {
      if (!await _networkService.checkConnectivity()) {
        throw Exception('No network connectivity');
      }
      
      // Build URL parameters
      final Map<String, String> queryParams = {
        'key': _apiKey!,
        'op': operation,
        ...params,
      };
      
      final url = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      
      if (kDebugMode) {
        final redactedUrl = url.toString().replaceAll(_apiKey!, '[REDACTED]');
        print('LegiScan API call: $redactedUrl');
      }
      
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // LegiScan API uses 'status' field to indicate success/failure
        if (data.containsKey('status') && data['status'] == 'OK') {
          return data;
        } else {
          if (kDebugMode) {
            print('LegiScan API returned error status: ${data['status']}');
            if (data.containsKey('alert')) {
              print('Alert: ${data['alert']}');
            }
          }
          return null;
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LegiScan API error: $e');
      }
      return null;
    }
  }
  
  // Generate mock data for testing when API key is not available
  Future<List<RepresentativeBill>> getMockSponsoredBills() async {
    return [
      RepresentativeBill(
        congress: '2023-2024',
        billType: 'HB',
        billNumber: '123',
        title: 'An Act to Improve Local Infrastructure',
        introducedDate: '2023-02-15',
        latestAction: 'Referred to Committee on Transportation',
      ),
      RepresentativeBill(
        congress: '2023-2024',
        billType: 'HB',
        billNumber: '456',
        title: 'Education Reform and Funding Act',
        introducedDate: '2023-03-10',
        latestAction: 'Passed House, Sent to Senate',
      ),
      RepresentativeBill(
        congress: '2022-2023',
        billType: 'SB',
        billNumber: '789',
        title: 'Tax Relief for Small Businesses',
        introducedDate: '2022-11-05',
        latestAction: 'Signed by Governor',
      ),
    ];
  }
  
  // Check network connectivity
  Future<bool> checkNetworkConnectivity() async {
    return await _networkService.checkConnectivity();
  }
}