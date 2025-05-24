import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load API key from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: Failed to load .env file. You'll need to enter API key manually.");
  }
  
  runApp(const LegiscanTestApp());
}

class LegiscanTestApp extends StatelessWidget {
  const LegiscanTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legiscan API Test',
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
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _results = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if API key is already available from .env
    final envApiKey = dotenv.env['LEGISCAN_API_KEY'];
    if (envApiKey != null && envApiKey.isNotEmpty) {
      _apiKeyController.text = envApiKey;
      _results = 'API key loaded from .env file. Ready to run tests.\n';
    } else {
      _results = 'Please enter a Legiscan API key\n';
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runTests() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _results = 'Please enter a Legiscan API key';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _results = 'Running tests...\n';
    });

    try {
      // Test states that are likely to have bills with detailed data
      const testStates = ['CA', 'NY', 'TX', 'FL', 'IL'];
      
      // First test: Fetch state bills and check for detailed data
      for (final state in testStates) {
        _appendResult('\n--- Testing state: $state ---\n');
        await _testStateBills(state, apiKey);
      }

      // Second test: Check for specific examples of bills with history, sponsors, or votes
      await _testSpecificBills(apiKey);
      
      // Third test: Check for active sessions
      await _testActiveSessions(apiKey);

    } catch (e) {
      _appendResult('\nError running tests: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test getting state bills and checking for history, sponsors, votes
  Future<void> _testStateBills(String stateCode, String apiKey) async {
    try {
      // First get the master list of bills for the state
      final masterListUrl = 'https://api.legiscan.com/?key=$apiKey&op=getMasterList&state=$stateCode';
      
      _appendResult('Fetching master list for $stateCode...\n');
      
      // Use a timeout to handle slow responses
      final masterListResponse = await http.get(Uri.parse(masterListUrl))
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('Request timed out after 15 seconds');
      });
      
      if (masterListResponse.statusCode != 200) {
        _appendResult('Failed to get master list: ${masterListResponse.statusCode}\n');
        if (masterListResponse.statusCode == 429) {
          _appendResult('Rate limit exceeded. Please wait and try again later.\n');
        } else if (masterListResponse.statusCode == 401) {
          _appendResult('Authentication error. Please check your API key.\n');
        }
        return;
      }

      final masterListData = json.decode(masterListResponse.body);
      if (masterListData['status'] != 'OK' || !masterListData.containsKey('masterlist')) {
        _appendResult('Invalid master list response\n');
        
        // Check for specific error messages in the API response
        if (masterListData.containsKey('alert')) {
          _appendResult('API Error: ${masterListData['alert']}\n');
        }
        return;
      }

      final masterList = masterListData['masterlist'] as Map<String, dynamic>;
      
      // Remove session info
      masterList.remove('session');
      
      // Count how many bills we found
      _appendResult('Found ${masterList.length} bills in $stateCode\n');
      
      // Only check a sample of bills (first 5) to avoid rate limiting
      int count = 0;
      int withHistory = 0;
      int withSponsors = 0;
      int withVotes = 0;
      
      // Add delay between API calls to avoid rate limiting
      const delay = Duration(milliseconds: 250);
      
      for (final entry in masterList.entries) {
        if (count >= 5) break;
        
        // Apply delay between requests to avoid rate limiting
        if (count > 0) {
          await Future.delayed(delay);
        }
        
        final billId = entry.value['bill_id'];
        _appendResult('Checking bill $billId - ${entry.value['bill_number']}...\n');
        
        // Fetch the bill details
        final billUrl = 'https://api.legiscan.com/?key=$apiKey&op=getBill&id=$billId';
        
        try {
          final billResponse = await http.get(Uri.parse(billUrl))
              .timeout(const Duration(seconds: 20), onTimeout: () {
            throw TimeoutException('Bill request timed out after 20 seconds');
          });
          
          if (billResponse.statusCode != 200) {
            _appendResult('Failed to get bill: ${billResponse.statusCode}\n');
            if (billResponse.statusCode == 429) {
              _appendResult('Rate limit exceeded. Pausing...\n');
              await Future.delayed(const Duration(seconds: 2));
            }
            continue;
          }

          final billData = json.decode(billResponse.body);
          if (billData['status'] != 'OK' || !billData.containsKey('bill')) {
            _appendResult('Invalid bill response\n');
            if (billData.containsKey('alert')) {
              _appendResult('API Error: ${billData['alert']}\n');
            }
            continue;
          }

          final bill = billData['bill'] as Map<String, dynamic>;
          
          // Check for history
          bool hasHistory = false;
          if (bill.containsKey('history') && bill['history'] is List && (bill['history'] as List).isNotEmpty) {
            hasHistory = true;
            _appendResult('  - Has history: ${(bill['history'] as List).length} entries\n');
          } else {
            _appendResult('  - No history\n');
          }
          
          // Check for sponsors
          bool hasSponsors = false;
          if (bill.containsKey('sponsors') && bill['sponsors'] is List && (bill['sponsors'] as List).isNotEmpty) {
            hasSponsors = true;
            _appendResult('  - Has sponsors: ${(bill['sponsors'] as List).length} sponsors\n');
          } else {
            _appendResult('  - No sponsors\n');
          }
          
          // Check for votes
          bool hasVotes = false;
          if (bill.containsKey('votes') && bill['votes'] is List && (bill['votes'] as List).isNotEmpty) {
            hasVotes = true;
            _appendResult('  - Has votes: ${(bill['votes'] as List).length} votes\n');
          } else {
            _appendResult('  - No votes\n');
          }
          
          if (hasHistory) withHistory++;
          if (hasSponsors) withSponsors++;
          if (hasVotes) withVotes++;
          
          count++;
        } catch (billError) {
          _appendResult('Error checking bill $billId: $billError\n');
          // Continue with next bill instead of failing the entire test
          continue;
        }
      }
      
      _appendResult('\nSummary for $stateCode:\n');
      _appendResult('  - Bills with history: $withHistory / $count\n');
      _appendResult('  - Bills with sponsors: $withSponsors / $count\n');
      _appendResult('  - Bills with votes: $withVotes / $count\n');
    } catch (e) {
      _appendResult('Error testing state $stateCode: $e\n');
    }
  }
  
  // Test specific known bill IDs that might have detailed data
  Future<void> _testSpecificBills(String apiKey) async {
    // List of known bill IDs to test - actual LegiScan bill IDs with data
    final billIds = [
      1595820,  // CA SB54 (2023-2024) with history, sponsors, and votes
      1640275,  // NY S8474 (2023-2024) with history and sponsors
      1557952,  // TX HB1 (2023-2024) with history, sponsors, and votes
    ];
    
    _appendResult('\n--- Testing specific bills ---\n');
    
    // Add delay between API calls to avoid rate limiting
    const delay = Duration(milliseconds: 500);
    
    for (int i = 0; i < billIds.length; i++) {
      final billId = billIds[i];
      
      // Apply delay between requests to avoid rate limiting (except for first request)
      if (i > 0) {
        await Future.delayed(delay);
      }
      
      try {
        _appendResult('Checking bill ID $billId...\n');
        
        // Fetch the bill details
        final billUrl = 'https://api.legiscan.com/?key=$apiKey&op=getBill&id=$billId';
        
        final billResponse = await http.get(Uri.parse(billUrl))
            .timeout(const Duration(seconds: 30), onTimeout: () {
          throw TimeoutException('Bill request timed out after 30 seconds');
        });
        
        if (billResponse.statusCode != 200) {
          _appendResult('Failed to get bill: ${billResponse.statusCode}\n');
          if (billResponse.statusCode == 429) {
            _appendResult('Rate limit exceeded. Pausing...\n');
            await Future.delayed(const Duration(seconds: 3));
          } else if (billResponse.statusCode == 401) {
            _appendResult('Authentication error. Please check your API key.\n');
          }
          continue;
        }

        final billData = json.decode(billResponse.body);
        if (billData['status'] != 'OK' || !billData.containsKey('bill')) {
          _appendResult('Invalid bill response or bill not found\n');
          if (billData.containsKey('alert')) {
            _appendResult('API Error: ${billData['alert']}\n');
          }
          continue;
        }

        final bill = billData['bill'] as Map<String, dynamic>;
        
        // Print bill title for reference
        _appendResult('Bill ${bill['bill_number']} - ${bill['title']}\n');
        
        // Check for history
        if (bill.containsKey('history') && bill['history'] is List && (bill['history'] as List).isNotEmpty) {
          final history = bill['history'] as List;
          _appendResult('  - Has history: ${history.length} entries\n');
          if (history.isNotEmpty && history.first is Map) {
            // Safe access to first history item
            final firstItem = history.first as Map;
            _appendResult('  - Sample history: action=${firstItem['action'] ?? 'unknown'}, date=${firstItem['date'] ?? 'unknown'}\n');
          }
        } else {
          _appendResult('  - No history\n');
        }
        
        // Check for sponsors
        if (bill.containsKey('sponsors') && bill['sponsors'] is List && (bill['sponsors'] as List).isNotEmpty) {
          final sponsors = bill['sponsors'] as List;
          _appendResult('  - Has sponsors: ${sponsors.length} sponsors\n');
          if (sponsors.isNotEmpty && sponsors.first is Map) {
            // Safe access to first sponsor
            final firstSponsor = sponsors.first as Map;
            _appendResult('  - Sample sponsor: name=${firstSponsor['name'] ?? 'unknown'}, type=${firstSponsor['type'] ?? 'unknown'}\n');
          }
        } else {
          _appendResult('  - No sponsors\n');
        }
        
        // Check for votes
        if (bill.containsKey('votes') && bill['votes'] is List && (bill['votes'] as List).isNotEmpty) {
          final votes = bill['votes'] as List;
          _appendResult('  - Has votes: ${votes.length} votes\n');
          if (votes.isNotEmpty && votes.first is Map) {
            // Safe access to first vote
            final firstVote = votes.first as Map;
            _appendResult('  - Sample vote: date=${firstVote['date'] ?? 'unknown'}, desc=${firstVote['desc'] ?? 'unknown'}\n');
            
            // Check for roll call data if available
            if (firstVote.containsKey('roll_call_id') && firstVote['roll_call_id'] != null) {
              _appendResult('  - Has roll call ID: ${firstVote['roll_call_id']}\n');
            }
          }
        } else {
          _appendResult('  - No votes\n');
        }
        
        _appendResult('\n'); // Add spacing between bills
        
      } catch (e) {
        _appendResult('Error testing bill $billId: $e\n');
      }
    }
  }

  // Test active sessions to see which states have active legislatures
  Future<void> _testActiveSessions(String apiKey) async {
    try {
      _appendResult('\n--- Testing Active Sessions ---\n');
      
      // Get session list
      final sessionUrl = 'https://api.legiscan.com/?key=$apiKey&op=getSessionList';
      _appendResult('Fetching session list...\n');
      
      final sessionResponse = await http.get(Uri.parse(sessionUrl));
      
      if (sessionResponse.statusCode != 200) {
        _appendResult('Failed to get session list: ${sessionResponse.statusCode}\n');
        return;
      }
      
      final sessionData = json.decode(sessionResponse.body);
      if (sessionData['status'] != 'OK' || !sessionData.containsKey('sessions')) {
        _appendResult('Invalid session list response\n');
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
      _appendResult('Total active sessions: $totalActive\n');
      _appendResult('States with active sessions:\n');
      
      activeSessionsByState.forEach((state, count) {
        _appendResult('  - $state: $count active session(s)\n');
      });
      
      // Test a few active states more deeply
      if (activeSessionsByState.isNotEmpty) {
        final activeStates = activeSessionsByState.keys.take(2).toList();
        
        for (final state in activeStates) {
          _appendResult('\nFetching master list for active state: $state...\n');
          
          // Get master list for the state
          final masterListUrl = 'https://api.legiscan.com/?key=$apiKey&op=getMasterList&state=$state';
          final masterListResponse = await http.get(Uri.parse(masterListUrl));
          
          if (masterListResponse.statusCode != 200) {
            _appendResult('Failed to get master list: ${masterListResponse.statusCode}\n');
            continue;
          }
          
          final masterListData = json.decode(masterListResponse.body);
          if (masterListData['status'] != 'OK' || !masterListData.containsKey('masterlist')) {
            _appendResult('Invalid master list response\n');
            continue;
          }
          
          final masterList = masterListData['masterlist'] as Map<String, dynamic>;
          
          // Remove session info
          masterList.remove('session');
          
          // Count bills
          final int billCount = masterList.length;
          _appendResult('Found $billCount bills in state $state\n');
        }
      }
    } catch (e) {
      _appendResult('Error testing active sessions: $e\n');
    }
  }
  
  void _appendResult(String text) {
    setState(() {
      _results += text;
    });
    
    // Scroll to bottom when results update
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
        title: const Text('Legiscan API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Legiscan API Key',
                hintText: 'Enter your Legiscan API key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _runTests,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Run Tests'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Results:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Text(
                    _results,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}