// test_api_calls/test_legiscan_api_minimal.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Minimal test script to check if LegiScan API bills have history, sponsors, and votes data
void main() async {
  // Replace with your actual API key
  final String apiKey = 'YOUR_API_KEY_HERE';
  final String baseUrl = 'https://api.legiscan.com/';
  final String state = 'GA'; // Georgia
  
  // Step 1: Find recent bills using getSearch
  print('Looking for recent Georgia bills...');
  final billIds = await findRecentBills(baseUrl, apiKey, state);
  
  if (billIds.isEmpty) {
    print('No bills found for testing. Please check your API key or try another state.');
    return;
  }
  
  print('\nFound ${billIds.length} bills to test.');
  
  // Step 2: Check each bill for history, sponsors, and votes data
  final results = <Map<String, dynamic>>[];
  
  print('\nChecking each bill for history, sponsors, and votes data...');
  for (final billInfo in billIds) {
    final billId = billInfo['id'];
    final billNumber = billInfo['number'];
    
    final data = await checkBillData(baseUrl, apiKey, billId);
    
    results.add({
      'bill_id': billId,
      'bill_number': billNumber,
      'has_history': data['has_history'],
      'history_count': data['history_count'],
      'has_sponsors': data['has_sponsors'],
      'sponsors_count': data['sponsors_count'],
      'has_votes': data['has_votes'],
      'votes_count': data['votes_count'],
    });
    
    print('Checked bill $billNumber (ID: $billId)');
  }
  
  // Step 3: Summarize results
  print('\n=== RESULTS SUMMARY ===\n');
  
  // Table header
  print('Bill ID\tBill Number\tHistory\tSponsors\tVotes');
  print('-------\t-----------\t-------\t--------\t-----');
  
  // Table rows
  for (final result in results) {
    print('${result['bill_id']}\t${result['bill_number']}\t'
          '${result['history_count'] ?? 0}\t'
          '${result['sponsors_count'] ?? 0}\t'
          '${result['votes_count'] ?? 0}');
  }
  
  // Count how many bills have each type of data
  final billsWithHistory = results.where((r) => r['has_history'] == true).length;
  final billsWithSponsors = results.where((r) => r['has_sponsors'] == true).length;
  final billsWithVotes = results.where((r) => r['has_votes'] == true).length;
  
  print('\nSummary:');
  print('- ${results.length} bills checked');
  print('- $billsWithHistory bills have history data (${(billsWithHistory/results.length*100).toStringAsFixed(1)}%)');
  print('- $billsWithSponsors bills have sponsors data (${(billsWithSponsors/results.length*100).toStringAsFixed(1)}%)');
  print('- $billsWithVotes bills have votes data (${(billsWithVotes/results.length*100).toStringAsFixed(1)}%)');
  
  if (billsWithHistory == 0 || billsWithSponsors == 0 || billsWithVotes == 0) {
    print('\nDIAGNOSIS: Some data types are completely missing. This suggests the data may not be available in the API responses.');
  } else {
    print('\nDIAGNOSIS: Data is available for at least some bills. The app may have integration issues displaying this data.');
  }
}

/// Find recent bills for a state using getSearch
Future<List<Map<String, dynamic>>> findRecentBills(String baseUrl, String apiKey, String state) async {
  try {
    // Build URL parameters for getSearch
    final Map<String, String> queryParams = {
      'key': apiKey,
      'op': 'getSearch',
      'state': state,
      'query': '*', // Wildcard search for recent bills
      'year': '2025', // Current session
    };
    
    // Make the request
    final url = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    print('Making search request to: ${url.toString().replaceAll(apiKey, '[REDACTED]')}');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<Map<String, dynamic>> billIds = [];
      
      // Handle different response formats
      if (data.containsKey('searchresult')) {
        final searchResult = data['searchresult'] as Map<String, dynamic>;
        
        // Remove the summary key
        searchResult.remove('summary');
        
        // Process the remaining bill entries
        searchResult.forEach((key, value) {
          if (value is Map && value.containsKey('bill_id') && value.containsKey('bill_number')) {
            billIds.add({
              'id': value['bill_id'],
              'number': value['bill_number'],
            });
          }
        });
      } else if (data.containsKey('results') && 
                data['results'].containsKey('bills')) {
        final bills = data['results']['bills'] as List;
        
        for (final bill in bills) {
          if (bill is Map && bill.containsKey('bill_id') && bill.containsKey('bill_number')) {
            billIds.add({
              'id': bill['bill_id'],
              'number': bill['bill_number'],
            });
          }
        }
      }
      
      // Limit to 10 bills
      return billIds.take(10).toList();
    } else {
      print('HTTP error: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error finding recent bills: $e');
    return [];
  }
}

/// Check if a bill has history, sponsors, and votes data
Future<Map<String, dynamic>> checkBillData(String baseUrl, String apiKey, dynamic billId) async {
  try {
    // Build URL parameters for getBill
    final Map<String, String> queryParams = {
      'key': apiKey,
      'op': 'getBill',
      'id': billId.toString(),
    };
    
    // Make the request
    final url = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Default results
      final results = {
        'has_history': false,
        'history_count': 0,
        'has_sponsors': false,
        'sponsors_count': 0,
        'has_votes': false,
        'votes_count': 0,
      };
      
      // Check for bill data
      if (data['status'] == 'OK' && data.containsKey('bill')) {
        final bill = data['bill'];
        
        // Check for history data
        if (bill.containsKey('history') && bill['history'] is List) {
          final historyList = bill['history'] as List;
          results['has_history'] = true;
          results['history_count'] = historyList.length;
        }
        
        // Check for sponsors data
        if (bill.containsKey('sponsors') && bill['sponsors'] is List) {
          final sponsorsList = bill['sponsors'] as List;
          results['has_sponsors'] = true;
          results['sponsors_count'] = sponsorsList.length;
        }
        
        // Check for votes data
        if (bill.containsKey('votes') && bill['votes'] is List) {
          final votesList = bill['votes'] as List;
          results['has_votes'] = true;
          results['votes_count'] = votesList.length;
        }
      }
      
      return results;
    } else {
      print('HTTP error checking bill $billId: ${response.statusCode}');
      return {
        'has_history': false,
        'history_count': 0,
        'has_sponsors': false,
        'sponsors_count': 0,
        'has_votes': false,
        'votes_count': 0,
      };
    }
  } catch (e) {
    print('Error checking bill $billId: $e');
    return {
      'has_history': false,
      'history_count': 0,
      'has_sponsors': false,
      'sponsors_count': 0,
      'has_votes': false,
      'votes_count': 0,
    };
  }
}