// lib/services/csv_bill_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/models/local_representative_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class CSVBillService {
  // Singleton instance
  static final CSVBillService _instance = CSVBillService._internal();
  factory CSVBillService() => _instance;
  CSVBillService._internal();

  // Cached data
  List<Map<String, dynamic>>? _peopleData;
  List<Map<String, dynamic>>? _billsData;
  List<Map<String, dynamic>>? _sponsorsData;
  List<Map<String, dynamic>>? _historyData;
  bool _initialized = false;

  // Initialize and load all CSV data
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Future.wait([
        _loadPeopleData(),
        _loadBillsData(),
        _loadSponsorsData(),
        _loadHistoryData(),
      ]);
      
      if (kDebugMode) {
        print('✅ CSV Bill Service initialized successfully');
        print('People count: ${_peopleData?.length ?? 0}');
        print('Bills count: ${_billsData?.length ?? 0}');
        print('Sponsors count: ${_sponsorsData?.length ?? 0}');
        print('History count: ${_historyData?.length ?? 0}');
      }
      
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing CSV Bill Service: $e');
      }
      rethrow;
    }
  }

  // Load people data from CSV
  Future<void> _loadPeopleData() async {
    try {
      final data = await rootBundle.loadString('assets/data/people.csv');
      
      final rows = const CsvToListConverter().convert(data, eol: '\n');
      
      // Extract headers from first row
      final headers = rows[0].map((e) => e.toString()).toList();
      
      // Convert rows to maps
      _peopleData = [];
      for (int i = 1; i < rows.length; i++) {
        final rowData = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          rowData[headers[j]] = rows[i][j];
        }
        _peopleData!.add(rowData);
      }
      
      if (kDebugMode) {
        print('People data loaded: ${_peopleData!.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading people data: $e');
      }
      _peopleData = [];
    }
  }

  // Load bills data from CSV
  Future<void> _loadBillsData() async {
    try {
      final data = await rootBundle.loadString('assets/data/bills.csv');
      
      final rows = const CsvToListConverter().convert(data, eol: '\n');
      
      // Extract headers from first row
      final headers = rows[0].map((e) => e.toString()).toList();
      
      // Convert rows to maps
      _billsData = [];
      for (int i = 1; i < rows.length; i++) {
        final rowData = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          rowData[headers[j]] = rows[i][j];
        }
        _billsData!.add(rowData);
      }
      
      if (kDebugMode) {
        print('Bills data loaded: ${_billsData!.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading bills data: $e');
      }
      _billsData = [];
    }
  }

  // Load sponsors data from CSV
  Future<void> _loadSponsorsData() async {
    try {
      final data = await rootBundle.loadString('assets/data/sponsors.csv');
      
      final rows = const CsvToListConverter().convert(data, eol: '\n');
      
      // Extract headers from first row
      final headers = rows[0].map((e) => e.toString()).toList();
      
      // Convert rows to maps
      _sponsorsData = [];
      for (int i = 1; i < rows.length; i++) {
        final rowData = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          rowData[headers[j]] = rows[i][j];
        }
        _sponsorsData!.add(rowData);
      }
      
      if (kDebugMode) {
        print('Sponsors data loaded: ${_sponsorsData!.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sponsors data: $e');
      }
      _sponsorsData = [];
    }
  }

  // Load history data from CSV
  Future<void> _loadHistoryData() async {
    try {
      final data = await rootBundle.loadString('assets/data/history.csv');
      
      final rows = const CsvToListConverter().convert(data, eol: '\n');
      
      // Extract headers from first row
      final headers = rows[0].map((e) => e.toString()).toList();
      
      // Convert rows to maps
      _historyData = [];
      for (int i = 1; i < rows.length; i++) {
        final rowData = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          rowData[headers[j]] = rows[i][j];
        }
        _historyData!.add(rowData);
      }
      
      if (kDebugMode) {
        print('History data loaded: ${_historyData!.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading history data: $e');
      }
      _historyData = [];
    }
  }

  // Find person by name and return their people_id
  int? findPersonIdByName(String name) {
    if (!_initialized || _peopleData == null || _peopleData!.isEmpty) {
      if (kDebugMode) {
        print('People data not initialized');
      }
      return null;
    }

    // Normalize name for comparison
    final normalizedName = name.toLowerCase().trim();
    final nameParts = normalizedName.split(' ');
    
    // Try exact match first
    for (final person in _peopleData!) {
      final personName = '${person['first_name']} ${person['last_name']}'.toLowerCase();
      if (personName == normalizedName) {
        return person['people_id'] as int?;
      }
    }
    
    // Try partial matches
    for (final person in _peopleData!) {
      final firstName = (person['first_name'] as String?)?.toLowerCase() ?? '';
      final lastName = (person['last_name'] as String?)?.toLowerCase() ?? '';
      
      // Match if last name and first initial match
      if (nameParts.length > 1) {
        final firstInitial = nameParts[0].substring(0, 1);
        if (lastName == nameParts.last && firstName.startsWith(firstInitial)) {
          return person['people_id'] as int?;
        }
      }
      
      // Match if just last name matches (less accurate)
      if (lastName == nameParts.last) {
        return person['people_id'] as int?;
      }
    }
    
    return null;
  }

  // Get sponsored bills for a person by their people_id
  List<RepresentativeBill> getSponsoredBillsForPerson(int peopleId) {
    if (!_initialized || 
        _sponsorsData == null || 
        _sponsorsData!.isEmpty ||
        _billsData == null ||
        _billsData!.isEmpty ||
        _historyData == null) {
      if (kDebugMode) {
        print('Data not initialized');
      }
      return [];
    }
    
    final List<RepresentativeBill> result = [];
    
    try {
      // Find all bill_ids where this person is a sponsor
      final sponsoredBillIds = _sponsorsData!
          .where((sponsor) => sponsor['people_id'] == peopleId)
          .map((sponsor) => sponsor['bill_id'])
          .toList();
      
      if (sponsoredBillIds.isEmpty) {
        if (kDebugMode) {
          print('No sponsored bills found for people_id: $peopleId');
        }
        return [];
      }
      
      // Get bill details for each sponsored bill
      for (final billId in sponsoredBillIds) {
        final billData = _billsData!.firstWhere(
          (bill) => bill['bill_id'] == billId,
          orElse: () => <String, dynamic>{},
        );
        
        if (billData.isEmpty) continue;
        
        // Get the latest action from history data
        final actions = _historyData!
            .where((action) => action['bill_id'] == billId)
            .toList();
            
        actions.sort((a, b) {
          final aDate = a['date'] as String? ?? '';
          final bDate = b['date'] as String? ?? '';
          return bDate.compareTo(aDate); // Sort newest first
        });
        
        final latestAction = actions.isNotEmpty ? actions.first['action'] : null;
        
        // Extract bill number and type
        final billNumber = billData['bill_number'] as String? ?? '';
        String billType = '';
        String number = '';
        
        final RegExp regex = RegExp(r'([A-Za-z]+)(\s*)(\d+)');
        final match = regex.firstMatch(billNumber);
        if (match != null) {
          billType = match.group(1) ?? '';
          number = match.group(3) ?? billNumber;
        } else {
          billType = 'Bill';
          number = billNumber;
        }
        
        // Create the bill object
        result.add(RepresentativeBill(
          congress: 'State Session',
          billType: billType,
          billNumber: number,
          title: billData['title'] as String? ?? 'Untitled Bill',
          introducedDate: billData['status_date'] as String?,
          latestAction: latestAction as String?,
          source: 'CSV',
        ));
      }
      
      // Sort bills by introduced date (newest first)
      result.sort((a, b) {
        if (a.introducedDate == null) return 1;
        if (b.introducedDate == null) return -1;
        return b.introducedDate!.compareTo(a.introducedDate!);
      });
      
      // Limit to 10 most recent bills
      if (result.length > 10) {
        return result.sublist(0, 10);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sponsored bills: $e');
      }
      return [];
    }
  }
  
  // Get sponsored bills for a representative
  Future<List<RepresentativeBill>> getSponsoredBills(Representative rep) async {
    if (!_initialized) {
      await initialize();
    }
    
    // Try to find person ID by name
    final peopleId = findPersonIdByName(rep.name);
    
    if (peopleId == null) {
      if (kDebugMode) {
        print('Could not find person ID for representative: ${rep.name}');
      }
      return [];
    }
    
    return getSponsoredBillsForPerson(peopleId);
  }

  // Get sponsored bills for a local representative
  Future<List<RepresentativeBill>> getSponsoredBillsForLocalRep(LocalRepresentative rep) async {
    if (!_initialized) {
      await initialize();
    }
    
    // Try to find person ID by name
    final peopleId = findPersonIdByName(rep.name);
    
    if (peopleId == null) {
      if (kDebugMode) {
        print('Could not find person ID for local representative: ${rep.name}');
      }
      return [];
    }
    
    return getSponsoredBillsForPerson(peopleId);
  }
}