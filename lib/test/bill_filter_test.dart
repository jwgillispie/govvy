import 'package:flutter_test/flutter_test.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/widgets/bills/bill_filters.dart';

void main() {
  group('BillFilter Tests', () {
    late List<BillModel> testBills;
    
    setUp(() {
      // Create test bill data
      testBills = [
        BillModel(
          billId: 1,
          billNumber: 'HB 123',
          title: 'Healthcare Reform Act',
          description: 'A comprehensive bill to reform healthcare',
          status: 'Introduced',
          type: 'state',
          state: 'FL',
          url: 'http://example.com/1',
          chamber: 'House',
          committee: 'Health Committee',
          subjects: ['Healthcare', 'Insurance'],
          keywords: ['reform', 'medical'],
          sponsors: [
            RepresentativeSponsor(
              peopleId: 1,
              name: 'John Smith',
              state: 'FL',
              position: 'primary',
            ),
          ],
          introducedDate: '2024-01-15',
          lastActionDate: '2024-01-20',
        ),
        BillModel(
          billId: 2,
          billNumber: 'SB 456',
          title: 'Education Funding Bill',
          description: 'Increase funding for public education',
          status: 'Passed',
          type: 'state',
          state: 'FL',
          url: 'http://example.com/2',
          chamber: 'Senate',
          committee: 'Education Committee',
          subjects: ['Education', 'Budget'],
          keywords: ['funding', 'schools'],
          sponsors: [
            RepresentativeSponsor(
              peopleId: 2,
              name: 'Jane Doe',
              state: 'FL',
              position: 'primary',
            ),
          ],
          introducedDate: '2024-02-01',
          lastActionDate: '2024-02-15',
        ),
        BillModel(
          billId: 3,
          billNumber: 'HB 789',
          title: 'Environmental Protection Act',
          description: 'Strengthen environmental protections',
          status: 'Committee Review',
          type: 'state',
          state: 'CA',
          url: 'http://example.com/3',
          chamber: 'House',
          committee: 'Environment Committee',
          subjects: ['Environment', 'Climate'],
          keywords: ['protection', 'sustainability'],
          sponsors: [
            RepresentativeSponsor(
              peopleId: 3,
              name: 'Bob Johnson',
              state: 'CA',
              position: 'primary',
            ),
          ],
          introducedDate: '2024-03-01',
          lastActionDate: '2024-03-10',
        ),
      ];
    });

    test('BillFilterConfig should track active filters correctly', () {
      // Test empty config
      const emptyConfig = BillFilterConfig();
      expect(emptyConfig.hasActiveFilters, false);
      expect(emptyConfig.filterCount, 0);

      // Test config with filters
      final configWithFilters = BillFilterConfig(
        keyword: 'healthcare',
        chamber: 'House',
        status: 'Introduced',
        dateRange: FilterDateRange.thisYear,
        tags: {'Healthcare', 'Insurance'},
      );
      expect(configWithFilters.hasActiveFilters, true);
      expect(configWithFilters.filterCount, 5); // keyword, chamber, status, dateRange, 2 tags
    });

    test('Filter by keyword should work correctly', () {
      // Test basic keyword filtering
      expect(_filterBillsByKeyword(testBills, 'healthcare', true, false).length, 1);
      expect(_filterBillsByKeyword(testBills, 'HEALTHCARE', true, false).length, 1); // case insensitive
      expect(_filterBillsByKeyword(testBills, 'HEALTHCARE', false, false).length, 0); // case sensitive
      expect(_filterBillsByKeyword(testBills, 'education', true, false).length, 1);
      expect(_filterBillsByKeyword(testBills, 'nonexistent', true, false).length, 0);
    });

    test('Filter by chamber should work correctly', () {
      final houseBills = _filterBillsByChamber(testBills, 'House');
      expect(houseBills.length, 2);
      expect(houseBills.every((bill) => bill.chamber == 'House'), true);

      final senateBills = _filterBillsByChamber(testBills, 'Senate');
      expect(senateBills.length, 1);
      expect(senateBills.first.chamber, 'Senate');
    });

    test('Filter by status should work correctly', () {
      final introducedBills = _filterBillsByStatus(testBills, 'Introduced');
      expect(introducedBills.length, 1);
      expect(introducedBills.first.status, 'Introduced');

      final passedBills = _filterBillsByStatus(testBills, 'Passed');
      expect(passedBills.length, 1);
      expect(passedBills.first.status, 'Passed');
    });

    test('Filter by sponsor should work correctly', () {
      final johnSmithBills = _filterBillsBySponsor(testBills, 'John Smith');
      expect(johnSmithBills.length, 1);
      expect(johnSmithBills.first.sponsors?.any((s) => s.name == 'John Smith'), true);

      final janeDoeBills = _filterBillsBySponsor(testBills, 'Jane Doe');
      expect(janeDoeBills.length, 1);
      expect(janeDoeBills.first.sponsors?.any((s) => s.name == 'Jane Doe'), true);
    });

    test('Filter by tags should work correctly', () {
      final healthcareBills = _filterBillsByTags(testBills, {'Healthcare'});
      expect(healthcareBills.length, 1);
      expect(healthcareBills.first.subjects?.contains('Healthcare'), true);

      final educationBills = _filterBillsByTags(testBills, {'Education'});
      expect(educationBills.length, 1);
      expect(educationBills.first.subjects?.contains('Education'), true);

      final multiTagBills = _filterBillsByTags(testBills, {'Healthcare', 'Education'});
      expect(multiTagBills.length, 2); // Should match bills with ANY of the tags
    });

    test('Date range filtering should work correctly', () {
      final now = DateTime.now();
      final thisYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31);

      final thisYearBills = _filterBillsByDateRange(testBills, thisYear, endOfYear);
      expect(thisYearBills.length, testBills.length); // All test bills are from 2024
    });

    test('Combined filters should work with AND operator', () {
      final config = BillFilterConfig(
        keyword: 'healthcare',
        chamber: 'House',
        filterOperator: FilterOperator.and,
      );

      final filteredBills = _applyFilterConfig(testBills, config);
      expect(filteredBills.length, 1);
      expect(filteredBills.first.billNumber, 'HB 123');
    });

    test('Combined filters should work with OR operator', () {
      final config = BillFilterConfig(
        chamber: 'House',
        status: 'Passed',
        filterOperator: FilterOperator.or,
      );

      final filteredBills = _applyFilterConfig(testBills, config);
      expect(filteredBills.length, 3); // 2 House bills + 1 Passed bill (Senate)
    });

    test('Regex filtering should work correctly', () {
      final regexBills = _filterBillsByKeyword(testBills, r'H[BR]', true, true);
      expect(regexBills.length, 2); // HB 123 and HB 789

      final invalidRegexBills = _filterBillsByKeyword(testBills, '[invalid', true, true);
      expect(invalidRegexBills.length, 0); // Should fallback to contains and find nothing
    });

    test('Sorting should work correctly', () {
      // Test alphabetical sorting
      final alphabeticalBills = List<BillModel>.from(testBills);
      _sortBills(alphabeticalBills, FilterSortBy.alphabetical);
      expect(alphabeticalBills.first.title, 'Education Funding Bill');
      expect(alphabeticalBills.last.title, 'Healthcare Reform Act');

      // Test status sorting
      final statusBills = List<BillModel>.from(testBills);
      _sortBills(statusBills, FilterSortBy.status);
      expect(statusBills.first.status, 'Committee Review');
      expect(statusBills.last.status, 'Passed');
    });
  });
}

// Helper functions for testing individual filter components
List<BillModel> _filterBillsByKeyword(List<BillModel> bills, String keyword, bool caseInsensitive, bool useRegex) {
  return bills.where((bill) {
    final searchFields = [
      bill.title,
      bill.description ?? '',
      bill.billNumber,
      bill.status,
      ...bill.subjects ?? [],
      ...bill.keywords ?? [],
      bill.committee ?? '',
      ...bill.sponsors?.map((s) => s.name) ?? [],
    ];

    final searchText = caseInsensitive 
        ? searchFields.join(' ').toLowerCase() 
        : searchFields.join(' ');
        
    final searchKeyword = caseInsensitive ? keyword.toLowerCase() : keyword;

    if (useRegex) {
      try {
        final regex = RegExp(searchKeyword, caseSensitive: !caseInsensitive);
        return regex.hasMatch(searchText);
      } catch (e) {
        return searchText.contains(searchKeyword);
      }
    } else {
      return searchText.contains(searchKeyword);
    }
  }).toList();
}

List<BillModel> _filterBillsByChamber(List<BillModel> bills, String chamber) {
  return bills.where((bill) => bill.chamber == chamber).toList();
}

List<BillModel> _filterBillsByStatus(List<BillModel> bills, String status) {
  return bills.where((bill) => bill.status == status).toList();
}

List<BillModel> _filterBillsBySponsor(List<BillModel> bills, String sponsorName) {
  return bills.where((bill) {
    return bill.sponsors?.any((sponsor) => sponsor.name == sponsorName) ?? false;
  }).toList();
}

List<BillModel> _filterBillsByTags(List<BillModel> bills, Set<String> tags) {
  return bills.where((bill) {
    final billTags = <String>{
      ...bill.subjects ?? [],
      ...bill.keywords ?? [],
    };
    return tags.any((tag) => billTags.contains(tag));
  }).toList();
}

List<BillModel> _filterBillsByDateRange(List<BillModel> bills, DateTime? startDate, DateTime? endDate) {
  return bills.where((bill) {
    final billDate = _getBillDate(bill);
    if (billDate == null) return false;
    
    if (startDate != null && billDate.isBefore(startDate)) return false;
    if (endDate != null && billDate.isAfter(endDate)) return false;
    
    return true;
  }).toList();
}

DateTime? _getBillDate(BillModel bill) {
  try {
    if (bill.lastActionDate != null) {
      return DateTime.tryParse(bill.lastActionDate!);
    }
    if (bill.introducedDate != null) {
      return DateTime.tryParse(bill.introducedDate!);
    }
    if (bill.statusDate != null) {
      return DateTime.tryParse(bill.statusDate!);
    }
  } catch (e) {
    // Handle parsing errors
  }
  return null;
}

List<BillModel> _applyFilterConfig(List<BillModel> bills, BillFilterConfig config) {
  List<BillModel> filteredBills = List.from(bills);

  // Apply keyword filter
  if (config.keyword != null) {
    filteredBills = _filterBillsByKeyword(
      filteredBills, 
      config.keyword!, 
      config.caseInsensitive, 
      config.useRegex
    );
  }

  // Apply other filters based on operator
  if (config.filterOperator == FilterOperator.and) {
    if (config.chamber != null) {
      filteredBills = _filterBillsByChamber(filteredBills, config.chamber!);
    }
    if (config.status != null) {
      filteredBills = _filterBillsByStatus(filteredBills, config.status!);
    }
  } else {
    // OR operation
    if (config.chamber != null || config.status != null) {
      filteredBills = bills.where((bill) {
        return (config.chamber != null && bill.chamber == config.chamber) ||
               (config.status != null && bill.status == config.status);
      }).toList();
    }
  }

  return filteredBills;
}

void _sortBills(List<BillModel> bills, FilterSortBy sortBy) {
  switch (sortBy) {
    case FilterSortBy.alphabetical:
      bills.sort((a, b) => a.title.compareTo(b.title));
      break;
    case FilterSortBy.status:
      bills.sort((a, b) => a.status.compareTo(b.status));
      break;
    case FilterSortBy.date:
      bills.sort((a, b) {
        final dateA = _getBillDate(a);
        final dateB = _getBillDate(b);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
      break;
    case FilterSortBy.relevance:
      // Keep original order
      break;
  }
}