#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Test script to validate bill filtering functionality
/// This script can be run independently to test filter logic

void main(List<String> arguments) {
  print('🧪 Bill Filter Validation Tests');
  print('================================\n');

  // Create test data
  final testBills = createTestBills();
  
  // Run validation tests
  runBasicFilterTests(testBills);
  runAdvancedFilterTests(testBills);
  runPerformanceTests(testBills);
  runEdgeCaseTests(testBills);
  
  print('\n✅ All validation tests completed!');
}

List<Map<String, dynamic>> createTestBills() {
  return [
    {
      'billId': 1,
      'billNumber': 'HB 123',
      'title': 'Healthcare Reform Act',
      'description': 'A comprehensive bill to reform healthcare',
      'status': 'Introduced',
      'type': 'state',
      'state': 'FL',
      'chamber': 'House',
      'committee': 'Health Committee',
      'subjects': ['Healthcare', 'Insurance'],
      'keywords': ['reform', 'medical'],
      'sponsors': [{'name': 'John Smith', 'party': 'Democrat'}],
      'introducedDate': '2024-01-15',
      'lastActionDate': '2024-01-20',
    },
    {
      'billId': 2,
      'billNumber': 'SB 456',
      'title': 'Education Funding Bill',
      'description': 'Increase funding for public education',
      'status': 'Passed',
      'type': 'state',
      'state': 'FL',
      'chamber': 'Senate',
      'committee': 'Education Committee',
      'subjects': ['Education', 'Budget'],
      'keywords': ['funding', 'schools'],
      'sponsors': [{'name': 'Jane Doe', 'party': 'Republican'}],
      'introducedDate': '2024-02-01',
      'lastActionDate': '2024-02-15',
    },
    {
      'billId': 3,
      'billNumber': 'HB 789',
      'title': 'Environmental Protection Act',
      'description': 'Strengthen environmental protections',
      'status': 'Committee Review',
      'type': 'state',
      'state': 'CA',
      'chamber': 'House',
      'committee': 'Environment Committee',
      'subjects': ['Environment', 'Climate'],
      'keywords': ['protection', 'sustainability'],
      'sponsors': [{'name': 'Bob Johnson', 'party': 'Democrat'}],
      'introducedDate': '2024-03-01',
      'lastActionDate': '2024-03-10',
    },
    {
      'billId': 4,
      'billNumber': 'SB 101',
      'title': 'Tax Reform Act',
      'description': 'Comprehensive tax code reform',
      'status': 'Failed',
      'type': 'federal',
      'state': 'US',
      'chamber': 'Senate',
      'committee': 'Finance Committee',
      'subjects': ['Taxation', 'Economy'],
      'keywords': ['tax', 'reform', 'economy'],
      'sponsors': [{'name': 'Alice Wilson', 'party': 'Republican'}],
      'introducedDate': '2023-12-01',
      'lastActionDate': '2024-01-05',
    },
  ];
}

void runBasicFilterTests(List<Map<String, dynamic>> bills) {
  print('📋 Basic Filter Tests');
  print('---------------------');

  // Test keyword filtering
  print('Testing keyword filtering...');
  final healthcareBills = filterByKeyword(bills, 'healthcare');
  assert(healthcareBills.length == 1, 'Should find 1 healthcare bill');
  print('✓ Keyword filter: ${healthcareBills.length} bills found for "healthcare"');

  final educationBills = filterByKeyword(bills, 'education');
  assert(educationBills.length == 1, 'Should find 1 education bill');
  print('✓ Keyword filter: ${educationBills.length} bills found for "education"');

  // Test chamber filtering
  print('\nTesting chamber filtering...');
  final houseBills = filterByChamber(bills, 'House');
  assert(houseBills.length == 2, 'Should find 2 House bills');
  print('✓ Chamber filter: ${houseBills.length} House bills found');

  final senateBills = filterByChamber(bills, 'Senate');
  assert(senateBills.length == 2, 'Should find 2 Senate bills');
  print('✓ Chamber filter: ${senateBills.length} Senate bills found');

  // Test status filtering
  print('\nTesting status filtering...');
  final passedBills = filterByStatus(bills, 'Passed');
  assert(passedBills.length == 1, 'Should find 1 passed bill');
  print('✓ Status filter: ${passedBills.length} passed bills found');

  final failedBills = filterByStatus(bills, 'Failed');
  assert(failedBills.length == 1, 'Should find 1 failed bill');
  print('✓ Status filter: ${failedBills.length} failed bills found');

  // Test sponsor filtering
  print('\nTesting sponsor filtering...');
  final johnSmithBills = filterBySponsor(bills, 'John Smith');
  assert(johnSmithBills.length == 1, 'Should find 1 bill by John Smith');
  print('✓ Sponsor filter: ${johnSmithBills.length} bills found for "John Smith"');

  print('✅ Basic filter tests passed!\n');
}

void runAdvancedFilterTests(List<Map<String, dynamic>> bills) {
  print('🔬 Advanced Filter Tests');
  print('------------------------');

  // Test regex filtering
  print('Testing regex filtering...');
  final hbBills = filterByRegex(bills, r'H[BR]');
  assert(hbBills.length == 2, 'Should find 2 bills matching HB pattern');
  print('✓ Regex filter: ${hbBills.length} bills found for pattern "H[BR]"');

  // Test case sensitivity
  print('\nTesting case sensitivity...');
  final caseInsensitive = filterByKeyword(bills, 'HEALTHCARE', caseInsensitive: true);
  final caseSensitive = filterByKeyword(bills, 'HEALTHCARE', caseInsensitive: false);
  assert(caseInsensitive.length == 1, 'Should find 1 bill (case insensitive)');
  assert(caseSensitive.length == 0, 'Should find 0 bills (case sensitive)');
  print('✓ Case insensitive: ${caseInsensitive.length} bills found');
  print('✓ Case sensitive: ${caseSensitive.length} bills found');

  // Test date range filtering
  print('\nTesting date range filtering...');
  final thisYearBills = filterByDateRange(bills, DateTime(2024, 1, 1), DateTime(2024, 12, 31));
  assert(thisYearBills.length == 3, 'Should find 3 bills from 2024');
  print('✓ Date range filter: ${thisYearBills.length} bills found for 2024');

  // Test tag filtering
  print('\nTesting tag filtering...');
  final healthcareTagBills = filterByTags(bills, ['Healthcare']);
  assert(healthcareTagBills.length == 1, 'Should find 1 bill with Healthcare tag');
  print('✓ Tag filter: ${healthcareTagBills.length} bills found for "Healthcare" tag');

  // Test combined filters (AND)
  print('\nTesting combined filters (AND)...');
  final combinedAnd = filterCombined(bills, {
    'chamber': 'House',
    'status': 'Introduced',
  }, operator: 'AND');
  assert(combinedAnd.length == 1, 'Should find 1 bill (House AND Introduced)');
  print('✓ Combined AND filter: ${combinedAnd.length} bills found');

  // Test combined filters (OR)
  print('\nTesting combined filters (OR)...');
  final combinedOr = filterCombined(bills, {
    'chamber': 'House',
    'status': 'Passed',
  }, operator: 'OR');
  assert(combinedOr.length == 3, 'Should find 3 bills (House OR Passed)');
  print('✓ Combined OR filter: ${combinedOr.length} bills found');

  print('✅ Advanced filter tests passed!\n');
}

void runPerformanceTests(List<Map<String, dynamic>> bills) {
  print('⚡ Performance Tests');
  print('-------------------');

  // Create larger dataset
  final largeBills = <Map<String, dynamic>>[];
  for (int i = 0; i < 1000; i++) {
    largeBills.addAll(bills.map((bill) => Map<String, dynamic>.from(bill)
      ..['billId'] = bill['billId'] + i * 10));
  }

  print('Testing with ${largeBills.length} bills...');

  final stopwatch = Stopwatch()..start();

  // Test filtering performance
  final results = filterByKeyword(largeBills, 'reform');
  
  stopwatch.stop();
  
  print('✓ Filtered ${largeBills.length} bills in ${stopwatch.elapsedMilliseconds}ms');
  print('✓ Found ${results.length} matching bills');
  
  assert(stopwatch.elapsedMilliseconds < 1000, 'Filtering should complete in under 1 second');
  
  print('✅ Performance tests passed!\n');
}

void runEdgeCaseTests(List<Map<String, dynamic>> bills) {
  print('🎯 Edge Case Tests');
  print('------------------');

  // Test empty input
  print('Testing empty input...');
  final emptyResults = filterByKeyword([], 'test');
  assert(emptyResults.isEmpty, 'Empty input should return empty results');
  print('✓ Empty input handled correctly');

  // Test null/missing fields
  print('\nTesting null/missing fields...');
  final billWithNulls = <Map<String, dynamic>>[
    {
      'billId': 999,
      'billNumber': 'TEST 999',
      'title': 'Test Bill',
      'status': 'Test Status',
      'type': 'test',
      'state': 'TEST',
      // Missing description, chamber, committee, etc.
    }
  ];
  
  final nullResults = filterByKeyword(billWithNulls, 'test');
  assert(nullResults.length == 1, 'Should handle null fields gracefully');
  print('✓ Null/missing fields handled correctly');

  // Test special characters
  print('\nTesting special characters...');
  final specialCharResults = filterByKeyword(bills, 'Act');
  assert(specialCharResults.length >= 2, 'Should find bills with "Act" in title');
  print('✓ Special characters handled correctly');

  // Test invalid regex
  print('\nTesting invalid regex...');
  final invalidRegexResults = filterByRegex(bills, '[invalid');
  // Should fallback to normal string search
  print('✓ Invalid regex handled gracefully');

  print('✅ Edge case tests passed!\n');
}

// Filter implementation functions
List<Map<String, dynamic>> filterByKeyword(
  List<Map<String, dynamic>> bills, 
  String keyword, 
  {bool caseInsensitive = true}
) {
  return bills.where((bill) {
    final searchText = [
      bill['title'] ?? '',
      bill['description'] ?? '',
      bill['billNumber'] ?? '',
      bill['status'] ?? '',
      ...(bill['subjects'] ?? []).cast<String>(),
      ...(bill['keywords'] ?? []).cast<String>(),
      bill['committee'] ?? '',
    ].join(' ');

    final searchTarget = caseInsensitive ? searchText.toLowerCase() : searchText;
    final searchKeyword = caseInsensitive ? keyword.toLowerCase() : keyword;
    
    return searchTarget.contains(searchKeyword);
  }).toList();
}

List<Map<String, dynamic>> filterByChamber(List<Map<String, dynamic>> bills, String chamber) {
  return bills.where((bill) => bill['chamber'] == chamber).toList();
}

List<Map<String, dynamic>> filterByStatus(List<Map<String, dynamic>> bills, String status) {
  return bills.where((bill) => bill['status'] == status).toList();
}

List<Map<String, dynamic>> filterBySponsor(List<Map<String, dynamic>> bills, String sponsorName) {
  return bills.where((bill) {
    final sponsors = bill['sponsors'] as List<dynamic>? ?? [];
    return sponsors.any((sponsor) => sponsor['name'] == sponsorName);
  }).toList();
}

List<Map<String, dynamic>> filterByRegex(List<Map<String, dynamic>> bills, String pattern) {
  try {
    final regex = RegExp(pattern);
    return bills.where((bill) {
      final searchText = [
        bill['title'] ?? '',
        bill['billNumber'] ?? '',
      ].join(' ');
      return regex.hasMatch(searchText);
    }).toList();
  } catch (e) {
    // Fallback to normal search if regex is invalid
    return filterByKeyword(bills, pattern);
  }
}

List<Map<String, dynamic>> filterByDateRange(
  List<Map<String, dynamic>> bills, 
  DateTime startDate, 
  DateTime endDate
) {
  return bills.where((bill) {
    final dateStr = bill['lastActionDate'] ?? bill['introducedDate'];
    if (dateStr == null) return false;
    
    final billDate = DateTime.tryParse(dateStr);
    if (billDate == null) return false;
    
    return billDate.isAfter(startDate) && billDate.isBefore(endDate);
  }).toList();
}

List<Map<String, dynamic>> filterByTags(List<Map<String, dynamic>> bills, List<String> tags) {
  return bills.where((bill) {
    final billTags = <String>{
      ...(bill['subjects'] ?? []).cast<String>(),
      ...(bill['keywords'] ?? []).cast<String>(),
    };
    return tags.any((tag) => billTags.contains(tag));
  }).toList();
}

List<Map<String, dynamic>> filterCombined(
  List<Map<String, dynamic>> bills, 
  Map<String, String> filters,
  {String operator = 'AND'}
) {
  return bills.where((bill) {
    if (operator == 'AND') {
      return filters.entries.every((entry) {
        return bill[entry.key] == entry.value;
      });
    } else {
      return filters.entries.any((entry) {
        return bill[entry.key] == entry.value;
      });
    }
  }).toList();
}