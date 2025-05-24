// test_api_calls/test_legiscan_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to make API calls to LegiScan and check for history, sponsors, and votes data
void main() async {
  // Replace these with your actual values
  final String apiKey = 'YOUR_API_KEY_HERE'; // Replace with your actual API key
  final String baseUrl = 'https://api.legiscan.com/';
  
  // Test different API endpoints
  await testGetBill(baseUrl, apiKey);
  await testGetBillWithRollCalls(baseUrl, apiKey);
  await testSessionList(baseUrl, apiKey);
  await testSearch(baseUrl, apiKey);
}

/// Test the getBill endpoint to check for history, sponsors, and votes
Future<void> testGetBill(String baseUrl, String apiKey) async {
  print('\n====== Testing getBill endpoint ======\n');
  
  // Sample bill ID - you'll need to replace this with a valid ID
  final int billId = 1234567; // Sample bill ID
  
  // Build URL parameters
  final Map<String, String> queryParams = {
    'key': apiKey,
    'op': 'getBill',
    'id': billId.toString(),
  };
  
  // Make the request
  try {
    final url = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    print('Making request to: ${url.toString().replaceAll(apiKey, '[REDACTED]')}');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // First check overall response status
      if (data['status'] == 'OK') {
        print('API Response Status: OK');
        
        // Check if bill data is present
        if (data.containsKey('bill')) {
          print('Bill data found in response');
          final bill = data['bill'];
          
          // Print basic bill information
          print('\nBasic bill info:');
          print('Bill ID: ${bill['bill_id']}');
          print('Bill Number: ${bill['bill_number']}');
          print('Title: ${bill['title']}');
          print('State: ${bill['state']}');
          
          // Check for history data
          if (bill.containsKey('history') && bill['history'] is List) {
            final history = bill['history'] as List;
            print('\nHistory data found: ${history.length} entries');
            
            if (history.isNotEmpty) {
              print('\nSample history entry:');
              final historyEntry = history[0];
              print(json.encode(historyEntry));
            } else {
              print('History list is empty');
            }
          } else {
            print('\nNo history data found in the bill response');
          }
          
          // Check for sponsors data
          if (bill.containsKey('sponsors') && bill['sponsors'] is List) {
            final sponsors = bill['sponsors'] as List;
            print('\nSponsors data found: ${sponsors.length} entries');
            
            if (sponsors.isNotEmpty) {
              print('\nSample sponsor entry:');
              final sponsorEntry = sponsors[0];
              print(json.encode(sponsorEntry));
            } else {
              print('Sponsors list is empty');
            }
          } else {
            print('\nNo sponsors data found in the bill response');
          }
          
          // Check for texts (documents) data
          if (bill.containsKey('texts') && bill['texts'] is List) {
            final texts = bill['texts'] as List;
            print('\nTexts/Documents data found: ${texts.length} entries');
            
            if (texts.isNotEmpty) {
              print('\nSample text/document entry:');
              final textEntry = texts[0];
              print(json.encode(textEntry));
            } else {
              print('Texts/Documents list is empty');
            }
          } else {
            print('\nNo texts/documents data found in the bill response');
          }
          
          // Check for votes data
          if (bill.containsKey('votes') && bill['votes'] is List) {
            final votes = bill['votes'] as List;
            print('\nVotes data found: ${votes.length} entries');
            
            if (votes.isNotEmpty) {
              print('\nSample vote entry:');
              final voteEntry = votes[0];
              print(json.encode(voteEntry));
              
              // Check if this vote has a roll call reference
              if (voteEntry.containsKey('roll_call_id')) {
                print('\nThis vote has a roll call ID: ${voteEntry['roll_call_id']}');
                print('You can fetch vote details using the getRollCall endpoint');
              }
            } else {
              print('Votes list is empty');
            }
          } else {
            print('\nNo votes data found in the bill response');
          }
          
          // Print all available top-level keys in the bill object for reference
          print('\nAll available bill data fields:');
          bill.keys.forEach((key) {
            print('- $key (${bill[key].runtimeType})');
          });
        } else {
          print('No bill data found in the response');
        }
      } else {
        print('API returned error: ${data['status']}');
        if (data.containsKey('alert')) {
          print('Alert message: ${data['alert']}');
        }
      }
    } else {
      print('HTTP error: ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Error making request: $e');
  }
}

/// Test the getRollCall endpoint to check for vote details
Future<void> testGetBillWithRollCalls(String baseUrl, String apiKey) async {
  print('\n====== Testing getBill and getRollCall endpoints ======\n');
  
  // Sample bill ID that should have votes - you'll need to replace this
  final int billId = 1234568; // Different sample bill ID
  
  // Build URL parameters for getBill
  final Map<String, String> queryParams = {
    'key': apiKey,
    'op': 'getBill',
    'id': billId.toString(),
  };
  
  // Make the request
  try {
    final url = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    print('Making request to: ${url.toString().replaceAll(apiKey, '[REDACTED]')}');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data.containsKey('bill')) {
        final bill = data['bill'];
        
        print('Bill ID: ${bill['bill_id']}');
        print('Bill Number: ${bill['bill_number']}');
        
        // Check for votes data
        if (bill.containsKey('votes') && bill['votes'] is List && bill['votes'].isNotEmpty) {
          final votes = bill['votes'] as List;
          print('\nFound ${votes.length} votes for this bill');
          
          // Get the first vote with a roll call ID
          int? rollCallId;
          for (final vote in votes) {
            if (vote.containsKey('roll_call_id')) {
              rollCallId = vote['roll_call_id'];
              print('\nFound roll call ID: $rollCallId');
              break;
            }
          }
          
          if (rollCallId != null) {
            // Now fetch the roll call data
            final rollCallParams = {
              'key': apiKey,
              'op': 'getRollCall',
              'id': rollCallId.toString(),
            };
            
            final rollCallUrl = Uri.parse(baseUrl).replace(queryParameters: rollCallParams);
            print('\nFetching roll call details: ${rollCallUrl.toString().replaceAll(apiKey, '[REDACTED]')}');
            
            final rollCallResponse = await http.get(rollCallUrl);
            
            if (rollCallResponse.statusCode == 200) {
              final rollCallData = json.decode(rollCallResponse.body);
              
              if (rollCallData['status'] == 'OK' && rollCallData.containsKey('roll_call')) {
                final rollCall = rollCallData['roll_call'];
                
                print('\nRoll Call data:');
                print('Roll Call ID: ${rollCall['roll_call_id']}');
                print('Date: ${rollCall['date']}');
                print('Description: ${rollCall['desc']}');
                
                // Check for individual votes
                if (rollCall.containsKey('votes') && rollCall['votes'] is Map) {
                  final Map<String, dynamic> votes = rollCall['votes'];
                  print('\nIndividual votes found: ${votes.length} entries');
                  
                  if (votes.isNotEmpty) {
                    print('\nSample vote entries:');
                    int count = 0;
                    votes.forEach((key, value) {
                      if (count < 3) { // Show just a few examples
                        print('Person ID: $key, Vote: $value');
                        count++;
                      }
                    });
                    
                    print('\nVote summary:');
                    if (rollCall.containsKey('yea')) print('Yea: ${rollCall['yea']}');
                    if (rollCall.containsKey('nay')) print('Nay: ${rollCall['nay']}');
                    if (rollCall.containsKey('nv')) print('Not Voting: ${rollCall['nv']}');
                    if (rollCall.containsKey('absent')) print('Absent: ${rollCall['absent']}');
                  } else {
                    print('Votes map is empty');
                  }
                } else {
                  print('\nNo individual votes found in roll call data');
                }
              } else {
                print('Roll Call API returned error: ${rollCallData['status']}');
              }
            } else {
              print('HTTP error on roll call request: ${rollCallResponse.statusCode}');
            }
          } else {
            print('\nNo roll call IDs found for this bill');
          }
        } else {
          print('\nNo votes data found for this bill');
        }
      } else {
        print('API returned error or no bill data found');
      }
    } else {
      print('HTTP error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error making request: $e');
  }
}

/// Test the getSessionList endpoint to find active sessions
Future<void> testSessionList(String baseUrl, String apiKey) async {
  print('\n====== Testing getSessionList endpoint ======\n');
  
  // Sample state - you can change this
  final String state = 'GA'; // Georgia
  
  // Build URL parameters
  final Map<String, String> queryParams = {
    'key': apiKey,
    'op': 'getSessionList',
    'state': state,
  };
  
  // Make the request
  try {
    final url = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    print('Making request to: ${url.toString().replaceAll(apiKey, '[REDACTED]')}');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data.containsKey('sessions')) {
        final sessions = data['sessions'] as List;
        
        print('\nFound ${sessions.length} sessions for $state:');
        
        // Find the most recent active session
        for (var session in sessions) {
          print('Session ID: ${session['session_id']}, '
              'Name: ${session['name']}, '
              'Year Start: ${session['year_start']}, '
              'Year End: ${session['year_end']}, '
              'Special: ${session['special']}, '
              'Session Hash: ${session['session_hash']}');
        }
      } else {
        print('API returned error or no sessions found');
      }
    } else {
      print('HTTP error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error making request: $e');
  }
}

/// Test the getSearch endpoint to find recent bills
Future<void> testSearch(String baseUrl, String apiKey) async {
  print('\n====== Testing getSearch endpoint ======\n');
  
  // Sample state - you can change this
  final String state = 'GA'; // Georgia
  
  // Build URL parameters
  final Map<String, String> queryParams = {
    'key': apiKey,
    'op': 'getSearch',
    'state': state,
    'query': '*', // Wildcard search for recent bills
    'year': '2025', // Current session
  };
  
  // Make the request
  try {
    final url = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    print('Making request to: ${url.toString().replaceAll(apiKey, '[REDACTED]')}');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Check for searchresult format
      if (data.containsKey('searchresult')) {
        final searchResult = data['searchresult'];
        
        // Remove summary to focus on bill data
        searchResult.remove('summary');
        
        final int billCount = searchResult.length;
        print('\nFound $billCount bills in search results');
        
        if (billCount > 0) {
          // Get the first few bill IDs to suggest for detailed testing
          print('\nSample bill IDs you can use for detailed testing:');
          int count = 0;
          
          searchResult.forEach((key, value) {
            if (count < 5) {
              print('Bill ID: ${value['bill_id']}, Number: ${value['bill_number']}, Title: ${value['title']}');
              count++;
            }
          });
        } else {
          print('No bills found in search results');
        }
      } else if (data.containsKey('results') && 
                data['results'].containsKey('bills')) {
        final bills = data['results']['bills'] as List;
        
        print('\nFound ${bills.length} bills in search results');
        
        if (bills.isNotEmpty) {
          // Get the first few bill IDs to suggest for detailed testing
          print('\nSample bill IDs you can use for detailed testing:');
          
          for (int i = 0; i < 5 && i < bills.length; i++) {
            final bill = bills[i];
            print('Bill ID: ${bill['bill_id']}, Number: ${bill['bill_number']}, Title: ${bill['title']}');
          }
        } else {
          print('No bills found in search results');
        }
      } else {
        print('Unexpected API response format');
        print('Response keys: ${data.keys.join(', ')}');
      }
    } else {
      print('HTTP error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error making request: $e');
  }
}