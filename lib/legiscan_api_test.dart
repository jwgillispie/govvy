// legiscan_api_test.dart
// A temporary test script to check for bills with history, sponsors, and votes data

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// API endpoint for LegiScan
const String baseUrl = 'https://api.legiscan.com/';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load API key from .env file
  await dotenv.load(fileName: ".env");
  
  // Run the test app
  runApp(const LegiscanApiTestApp());
}

class LegiscanApiTestApp extends StatelessWidget {
  const LegiscanApiTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LegiScan API Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LegiscanTestScreen(),
    );
  }
}

class LegiscanTestScreen extends StatefulWidget {
  const LegiscanTestScreen({Key? key}) : super(key: key);

  @override
  State<LegiscanTestScreen> createState() => _LegiscanTestScreenState();
}

class _LegiscanTestScreenState extends State<LegiscanTestScreen> {
  // State variables
  bool _isLoading = false;
  String _testResults = 'Tap a button to run API tests';
  final ScrollController _scrollController = ScrollController();
  String? _apiKey;
  
  // List of states to test
  final List<String> _testStates = ['NY', 'CA', 'TX', 'FL', 'IL'];
  
  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }
  
  // Check if API key is available
  Future<void> _checkApiKey() async {
    await Future.delayed(const Duration(seconds: 1));
    
    _apiKey = dotenv.env['LEGISCAN_API_KEY'];
    
    setState(() {
      _testResults = _apiKey != null && _apiKey!.isNotEmpty
          ? 'API key is available. Ready to run tests.'
          : 'API key not available. Tests will not work.';
    });
  }
  
  // API call helper
  Future<Map<String, dynamic>?> callApi(String operation, Map<String, String> params) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _appendResult('No API key available');
      return null;
    }
    
    try {
      // Build URL parameters
      final Map<String, String> queryParams = {
        'key': _apiKey!,
        'op': operation,
        ...params,
      };
      
      final url = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      
      // Configure timeout based on operation
      final Duration timeout = Duration(seconds: operation == 'getBill' ? 30 : 15);
      
      // Make the API call
      final response = await http.get(url).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for API error status
        if (data.containsKey('status')) {
          if (data['status'] == 'OK') {
            return data;
          } else {
            // Special handling for specific operations
            if (operation == 'getSearch' || operation == 'getBill') {
              return data; // Return error data for proper handling
            }
            
            _appendResult('API returned error status: ${data['status']}');
            if (data.containsKey('alert')) {
              _appendResult('Alert: ${data['alert']}');
            }
            return null;
          }
        } else {
          // Missing status field - return anyway in case it's usable
          return data;
        }
      } else {
        _appendResult('API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _appendResult('Error in API call: $e');
      return null;
    }
  }
  
  // Test bill details
  Future<void> _testBillDetails() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing bill details for multiple states...\n';
    });
    
    try {
      for (final state in _testStates) {
        _appendResult('Testing state: $state\n');
        
        // Test search in the state to find some bills
        _appendResult('Searching for bills in $state...');
        final searchParams = {'state': state, 'query': '*'};
        final searchResults = await callApi('getSearch', searchParams);
        
        if (searchResults == null) {
          _appendResult('No search results returned for $state\n');
          continue;
        }
        
        // Extract bill IDs from search results
        final List<int> billIds = [];
        
        if (searchResults.containsKey('results') && 
            searchResults['results'].containsKey('bills')) {
          final bills = searchResults['results']['bills'] as List;
          
          _appendResult('Found ${bills.length} bills in search results');
          
          // Take only first 3 bills to avoid too many API calls
          final billsToTest = bills.take(3).toList();
          
          for (final bill in billsToTest) {
            if (bill is Map && bill.containsKey('bill_id')) {
              billIds.add(bill['bill_id']);
            }
          }
        }
        
        // Test each bill for details
        for (final billId in billIds) {
          _appendResult('Checking bill ID: $billId');
          
          final billParams = {'id': billId.toString()};
          final billData = await callApi('getBill', billParams);
          
          if (billData == null || !billData.containsKey('bill')) {
            _appendResult('Failed to get details for bill $billId\n');
            continue;
          }
          
          final bill = billData['bill'];
          
          // Check for history
          bool hasHistory = false;
          if (bill.containsKey('history') && bill['history'] is List) {
            final history = bill['history'] as List;
            hasHistory = history.isNotEmpty;
            _appendResult('History data: ${hasHistory ? "YES (${history.length} items)" : "NO"}');
          } else {
            _appendResult('History data: NO');
          }
          
          // Check for sponsors
          bool hasSponsors = false;
          if (bill.containsKey('sponsors') && bill['sponsors'] is List) {
            final sponsors = bill['sponsors'] as List;
            hasSponsors = sponsors.isNotEmpty;
            _appendResult('Sponsors data: ${hasSponsors ? "YES (${sponsors.length} sponsors)" : "NO"}');
          } else {
            _appendResult('Sponsors data: NO');
          }
          
          // Check for votes
          bool hasVotes = false;
          if (bill.containsKey('votes') && bill['votes'] is List) {
            final votes = bill['votes'] as List;
            hasVotes = votes.isNotEmpty;
            _appendResult('Votes data: ${hasVotes ? "YES (${votes.length} votes)" : "NO"}');
            
            // If has votes, check one vote in detail
            if (hasVotes && votes.isNotEmpty) {
              final vote = votes.first;
              if (vote is Map && vote.containsKey('roll_call_id')) {
                final rollCallId = vote['roll_call_id'];
                _appendResult('Checking roll call vote: $rollCallId');
                
                final rollCallParams = {'id': rollCallId.toString()};
                final rollCallData = await callApi('getRollCall', rollCallParams);
                
                if (rollCallData != null && rollCallData.containsKey('roll_call')) {
                  _appendResult('Roll call data exists: YES');
                  
                  // Check for individual legislator votes
                  if (rollCallData['roll_call'].containsKey('votes') && 
                      rollCallData['roll_call']['votes'] is Map) {
                    final voteMap = rollCallData['roll_call']['votes'] as Map;
                    _appendResult('Individual votes data: YES (${voteMap.length} votes)');
                  } else {
                    _appendResult('Individual votes data: NO');
                  }
                } else {
                  _appendResult('Roll call data exists: NO');
                }
              }
            }
          } else {
            _appendResult('Votes data: NO');
          }
          
          _appendResult(''); // Add spacing between bills
        }
        
        _appendResult('\n'); // Add spacing between states
      }
    } catch (e) {
      _appendResult('Error running tests: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Test session data to see what states are active
  Future<void> _testActiveSessions() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing active sessions...\n';
    });
    
    try {
      // Get session list
      _appendResult('Getting session list...');
      final sessionData = await callApi('getSessionList', {});
      
      if (sessionData == null || !sessionData.containsKey('sessions')) {
        _appendResult('No session data returned');
        return;
      }
      
      final sessions = sessionData['sessions'];
      
      // Count active sessions by state
      final Map<String, int> activeSessionsByState = {};
      int totalActive = 0;
      
      if (sessions is Map) {
        // Process map format
        sessions.forEach((stateCode, stateSessions) {
          if (stateSessions is List) {
            int activeCount = 0;
            
            for (final session in stateSessions) {
              if (session is Map && 
                  session.containsKey('session_active') && 
                  (session['session_active'] == 1 || session['session_active'] == true)) {
                activeCount++;
                totalActive++;
              }
            }
            
            if (activeCount > 0) {
              activeSessionsByState[stateCode] = activeCount;
            }
          }
        });
      } else if (sessions is List) {
        // Process list format
        for (final session in sessions) {
          if (session is Map && 
              session.containsKey('state') && 
              session.containsKey('session_active') && 
              (session['session_active'] == 1 || session['session_active'] == true)) {
            
            final stateCode = session['state'];
            if (!activeSessionsByState.containsKey(stateCode)) {
              activeSessionsByState[stateCode] = 0;
            }
            
            activeSessionsByState[stateCode] = activeSessionsByState[stateCode]! + 1;
            totalActive++;
          }
        }
      }
      
      // Display results
      _appendResult('Total active sessions: $totalActive');
      _appendResult('States with active sessions:');
      
      activeSessionsByState.forEach((state, count) {
        _appendResult('$state: $count active sessions');
      });
      
      // Test a few active states more deeply
      if (activeSessionsByState.isNotEmpty) {
        final activeStates = activeSessionsByState.keys.take(3).toList();
        
        for (final state in activeStates) {
          _appendResult('\nTesting active state: $state');
          
          // Get master list for the state
          final masterListParams = {'state': state};
          final masterList = await callApi('getMasterList', masterListParams);
          
          if (masterList == null || !masterList.containsKey('masterlist')) {
            _appendResult('No master list returned for $state');
            continue;
          }
          
          final bills = masterList['masterlist'];
          int billCount = 0;
          
          // Count bills
          bills.forEach((key, value) {
            if (key != 'session' && value is Map) {
              billCount++;
            }
          });
          
          _appendResult('Bills in master list: $billCount');
          
          // Test a few bills
          int withHistory = 0;
          int withSponsors = 0;
          int withVotes = 0;
          
          int testCount = 0;
          bills.forEach((key, value) {
            if (key != 'session' && value is Map && testCount < 5) {
              if (value.containsKey('bill_id')) {
                testCount++;
                
                // Test the bill details
                getAndCheckBillDetails(value['bill_id'], state).then((results) {
                  // Check for null before using as a condition
                  if (results['hasHistory'] == true) withHistory++;
                  if (results['hasSponsors'] == true) withSponsors++;
                  if (results['hasVotes'] == true) withVotes++;
                  
                  // Update summary when done
                  if (testCount == 5) {
                    _appendResult('Bills with history: $withHistory/5');
                    _appendResult('Bills with sponsors: $withSponsors/5');
                    _appendResult('Bills with votes: $withVotes/5');
                  }
                });
              }
            }
          });
        }
      }
    } catch (e) {
      _appendResult('Error testing sessions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Helper to get and check bill details asynchronously
  Future<Map<String, bool>> getAndCheckBillDetails(int billId, String state) async {
    final result = {
      'hasHistory': false,
      'hasSponsors': false,
      'hasVotes': false,
    };
    
    try {
      final billParams = {'id': billId.toString()};
      final billData = await callApi('getBill', billParams);
      
      if (billData == null || !billData.containsKey('bill')) {
        return result;
      }
      
      final bill = billData['bill'];
      
      // Check for history
      if (bill.containsKey('history') && bill['history'] is List) {
        final history = bill['history'] as List;
        result['hasHistory'] = history.isNotEmpty;
      }
      
      // Check for sponsors
      if (bill.containsKey('sponsors') && bill['sponsors'] is List) {
        final sponsors = bill['sponsors'] as List;
        result['hasSponsors'] = sponsors.isNotEmpty;
      }
      
      // Check for votes
      if (bill.containsKey('votes') && bill['votes'] is List) {
        final votes = bill['votes'] as List;
        result['hasVotes'] = votes.isNotEmpty;
      }
    } catch (e) {
      // Ignore errors
    }
    
    return result;
  }
  
  // Append text to the results
  void _appendResult(String text) {
    setState(() {
      _testResults += '$text\n';
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LegiScan API Test'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testBillDetails,
                  child: const Text('Test Bill Details'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testActiveSessions,
                  child: const Text('Test Active Sessions'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      child: Text(_testResults),
                    ),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}