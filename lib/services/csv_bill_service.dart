// lib/services/csv_bill_service.dart
// Removed unused import: import 'dart:convert';
// Removed unused import: import 'dart:io' as io;
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/models/local_representative_model.dart';
// Removed unused import: import 'package:path_provider/path_provider.dart';
// Removed unused import: import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

// Helper class for building strings efficiently
class StringBuilder {
  final List<String> _parts = [];
  
  void append(String part) {
    if (part.isNotEmpty) {
      _parts.add(part);
    }
  }
  
  int get length => _parts.length;
  
  @override
  String toString() {
    return _parts.join('');
  }
}

class CSVBillService {
  // Singleton instance
  static final CSVBillService _instance = CSVBillService._internal();
  factory CSVBillService() => _instance;
  CSVBillService._internal();

  // Cached data for app-wide CSVs (needed by methods below)
  List<Map<String, dynamic>>? _peopleData;
  List<Map<String, dynamic>>? _billsData;
  List<Map<String, dynamic>>? _sponsorsData;
  List<Map<String, dynamic>>? _historyData;
  
  // Cached data for state-specific CSVs
  final Map<String, List<Map<String, dynamic>>> _statePeopleData = {};
  final Map<String, List<Map<String, dynamic>>> _stateBillsData = {};
  final Map<String, List<Map<String, dynamic>>> _stateSponsorsData = {};
  final Map<String, List<Map<String, dynamic>>> _stateHistoryData = {};
  
  // Track available states
  List<String> _availableStates = [];
  
  bool _initialized = false;

  // Getter for available states
  List<String> get availableStates => _availableStates;

  // Initialize and load all CSV data
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Find available states with CSV data
      await _detectAvailableStates();
      
      // Load first state's data as a default example
      if (_availableStates.isNotEmpty) {
        await loadStateData(_availableStates.first);
      }
      
      _initialized = true;
    } catch (e) {
      rethrow;
    }
  }

  // Detect available states with CSV data
  Future<void> _detectAvailableStates() async {
    try {
      // Manually add states we know have CSV files based on directory structure
      // This is more reliable than trying to parse the asset manifest, especially in web mode
      _availableStates = [
        'AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'FL', 'GA', 'HI', 
        'IA', 'IL', 'IN', 'KS', 'KY'
      ];
    } catch (e) {
      _availableStates = [];
    }
  }

  // Load state-specific data
  Future<bool> loadStateData(String stateCode) async {
    if (!_availableStates.contains(stateCode)) {
      return false;
    }
    
      // Check if already loaded
    if (_statePeopleData.containsKey(stateCode) &&
        _stateBillsData.containsKey(stateCode) &&
        _stateSponsorsData.containsKey(stateCode) &&
        _stateHistoryData.containsKey(stateCode)) {
      return true;
    }
    
    try {
      // Web browsers have issues with dynamically determining paths
      // Let's use a map of known session folders for each state
      final Map<String, String> sessionFolders = {
        'AK': '2025-2026_34th_Legislature',
        'AL': '2025-2025_Regular_Session',
        'AR': '2025-2025_95th_General_Assembly',
        'AZ': '2025-2025_Fifty-seventh_Legislature_1st_Regular',
        'CA': '2025-2026_Regular_Session',
        'CO': '2025-2025_Regular_Session',
        'CT': '2025-2025_General_Assembly',
        'FL': '2025-2025_Regular_Session',
        'GA': '2025-2026_Regular_Session',
        'HI': '2025-2025_Regular_Session',
        'IA': '2025-2026_91st_General_Assembly',
        'IL': '2025-2026_104th_General_Assembly',
        'IN': '2025-2025_Regular_Session',
        'KS': '2025-2026_Regular_Session',
        'KY': '2025-2025_Regular_Session',
      };
      
      String? sessionPath = sessionFolders[stateCode];
      
      if (sessionPath == null) {
        return false;
      }
      
      // Base path for all CSV files
      final basePath = 'assets/data/csvs/$stateCode/$sessionPath/csv';
      
      // Load all data in parallel
      await Future.wait([
        _loadStatePeopleData(stateCode, '$basePath/people.csv'),
        _loadStateBillsData(stateCode, '$basePath/bills.csv'),
        _loadStateSponsorsData(stateCode, '$basePath/sponsors.csv'),
        _loadStateHistoryData(stateCode, '$basePath/history.csv'),
      ]);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Removed loading from root people.csv - using state-specific files only

  // Removed loading from root bills.csv - using state-specific files only

  // Removed loading from root sponsors.csv - using state-specific files only

  // Removed loading from root history.csv - using state-specific files only

  // Load state-specific people data
  Future<void> _loadStatePeopleData(String stateCode, String assetPath) async {
    try {
      final data = await rootBundle.loadString(assetPath);
      
      if (data.isEmpty) {
        _statePeopleData[stateCode] = [];
        return;
      }
      
      // Use a more resilient CSV converter with different delimiters and line endings
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter().convert(data, eol: '\n');
        if (rows.isEmpty) {
          rows = const CsvToListConverter().convert(data, eol: '\r\n');
        }
      } catch (e) {
        // Manual fallback CSV parsing
        final lines = data.split('\n');
        rows = lines.map((line) => line.split(',')).toList();
      }
      
      if (rows.isEmpty) {
        _statePeopleData[stateCode] = [];
        return;
      }
      
      // Extract headers from first row
      final headers = rows[0].map((e) => e.toString()).toList();
      
      // Convert rows to maps
      final stateData = <Map<String, dynamic>>[];
      for (int i = 1; i < rows.length; i++) {
        // Skip empty rows
        if (rows[i].isEmpty || (rows[i].length == 1 && rows[i][0].toString().trim().isEmpty)) {
          continue;
        }
        
        final rowData = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          rowData[headers[j]] = rows[i][j];
        }
        stateData.add(rowData);
      }
      
      _statePeopleData[stateCode] = stateData;
    } catch (e) {
      _statePeopleData[stateCode] = [];
    }
  }

  // Load state-specific bills data
  Future<void> _loadStateBillsData(String stateCode, String assetPath) async {
    try {
      final data = await rootBundle.loadString(assetPath);
      
      if (data.isEmpty) {
        _stateBillsData[stateCode] = [];
        return;
      }
      
      // Use a more resilient CSV converter with different delimiters and line endings
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter().convert(data, eol: '\n');
        if (rows.isEmpty) {
          rows = const CsvToListConverter().convert(data, eol: '\r\n');
        }
      } catch (e) {
        // Manual fallback CSV parsing
        final lines = data.split('\n');
        rows = lines.map((line) => line.split(',')).toList();
      }
      
      if (rows.isEmpty) {
        _stateBillsData[stateCode] = [];
        return;
      }
      
      // Extract headers from first row
      final headers = rows[0].map((e) => e.toString()).toList();
      
      // Convert rows to maps
      final stateData = <Map<String, dynamic>>[];
      
      for (int i = 1; i < rows.length; i++) {
        // Skip empty rows
        if (rows[i].isEmpty || (rows[i].length == 1 && rows[i][0].toString().trim().isEmpty)) {
          continue;
        }
        
        final rowData = <String, dynamic>{};
        
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          rowData[headers[j]] = rows[i][j];
        }
        
        // Add state code to the data
        rowData['state'] = stateCode;
        
        // Verify the row has minimum required data
        if (rowData.containsKey('bill_number') && rowData['bill_number'] != null) {
          stateData.add(rowData);
        }
      }
      
      _stateBillsData[stateCode] = stateData;
    } catch (e) {
      _stateBillsData[stateCode] = [];
    }
  }

  // Load state-specific sponsors data
  Future<void> _loadStateSponsorsData(String stateCode, String assetPath) async {
    try {
      final data = await rootBundle.loadString(assetPath);
      
      if (data.isEmpty) {
        _stateSponsorsData[stateCode] = [];
        return;
      }
      
      // Use a more resilient CSV converter with different delimiters and line endings
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter().convert(data, eol: '\n');
        if (rows.isEmpty) {
          rows = const CsvToListConverter().convert(data, eol: '\r\n');
        }
      } catch (e) {
        // Manual fallback CSV parsing
        final lines = data.split('\n');
        rows = lines.map((line) => line.split(',')).toList();
      }
      
      if (rows.isEmpty) {
        _stateSponsorsData[stateCode] = [];
        return;
      }
      
      // Extract headers from first row
      final headers = rows[0].map((e) => e.toString()).toList();
      
      // Convert rows to maps
      final stateData = <Map<String, dynamic>>[];
      for (int i = 1; i < rows.length; i++) {
        // Skip empty rows
        if (rows[i].isEmpty || (rows[i].length == 1 && rows[i][0].toString().trim().isEmpty)) {
          continue;
        }
        
        final rowData = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          rowData[headers[j]] = rows[i][j];
        }
        stateData.add(rowData);
      }
      
      _stateSponsorsData[stateCode] = stateData;
    } catch (e) {
      _stateSponsorsData[stateCode] = [];
    }
  }

  // Load state-specific history data
  Future<void> _loadStateHistoryData(String stateCode, String assetPath) async {
    try {
      final data = await rootBundle.loadString(assetPath);
      
      if (data.isEmpty) {
        _stateHistoryData[stateCode] = [];
        return;
      }
      
      // Use a more resilient CSV converter with different delimiters and line endings
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter().convert(data, eol: '\n');
        if (rows.isEmpty) {
          rows = const CsvToListConverter().convert(data, eol: '\r\n');
        }
      } catch (e) {
        // Manual fallback CSV parsing
        final lines = data.split('\n');
        rows = lines.map((line) => line.split(',')).toList();
      }
      
      if (rows.isEmpty) {
        _stateHistoryData[stateCode] = [];
        return;
      }
      
      // Extract headers from first row
      final headers = rows[0].map((e) => e.toString()).toList();
      
      // Convert rows to maps
      final stateData = <Map<String, dynamic>>[];
      for (int i = 1; i < rows.length; i++) {
        // Skip empty rows
        if (rows[i].isEmpty || (rows[i].length == 1 && rows[i][0].toString().trim().isEmpty)) {
          continue;
        }
        
        final rowData = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < rows[i].length; j++) {
          rowData[headers[j]] = rows[i][j];
        }
        stateData.add(rowData);
      }
      
      _stateHistoryData[stateCode] = stateData;
    } catch (e) {
      _stateHistoryData[stateCode] = [];
    }
  }

  // Find person by name and return their people_id
  int? findPersonIdByName(String name, {String? stateCode}) {
    // Check if we need to load state-specific data
    final peopleData = stateCode != null && _statePeopleData.containsKey(stateCode)
        ? _statePeopleData[stateCode]!
        : _peopleData;
    
    if (!_initialized || peopleData == null || peopleData.isEmpty) {
      return null;
    }

    // Normalize name for comparison
    final normalizedName = name.toLowerCase().trim();
    final nameParts = normalizedName.split(' ');
    
    // Try exact match first
    for (final person in peopleData) {
      final personName = '${person['first_name']} ${person['last_name']}'.toLowerCase();
      if (personName == normalizedName) {
        return person['people_id'] as int?;
      }
    }
    
    // Try partial matches
    for (final person in peopleData) {
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

  // Get all bills for a state
  Future<List<RepresentativeBill>> getBillsByState(String stateCode) async {
    if (!_initialized) {
      await initialize();
    }
    
    // Special handling for Florida and Georgia which were having issues
    if (stateCode == 'FL' || stateCode == 'GA') {
      // Remove any existing cached data for this state to ensure a clean reload
      _stateBillsData.remove(stateCode);
      _statePeopleData.remove(stateCode);
      _stateSponsorsData.remove(stateCode);
      _stateHistoryData.remove(stateCode);
      
      // Force a fresh load of the state data
      await loadStateData(stateCode);
    }
    
    // Check if state data is available and load it if needed
    if (!_stateBillsData.containsKey(stateCode)) {
      final loaded = await loadStateData(stateCode);
      if (!loaded) {
        return [];
      }
    }
    
    final billsData = _stateBillsData[stateCode];
    if (billsData == null || billsData.isEmpty) {
      return [];
    }
    
    final List<RepresentativeBill> result = [];
    
    try {
      // Convert each bill to RepresentativeBill format
      for (final billData in billsData) {
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
        
        // Get latest action
        String? latestAction = billData['last_action'] as String?;
        String? statusDesc = billData['status_desc'] as String?;
        String? statusDate = billData['status_date'] as String?;
        String? description = billData['description'] as String?;
        
        // For FL and GA, enhance the bill info with additional data
        if (stateCode == 'FL' || stateCode == 'GA') {
          // Use status_desc if last_action is empty
          if (latestAction == null || latestAction.isEmpty) {
            latestAction = statusDesc;
          }
          
          // Create a detailed description from various fields
          final StringBuilder detailedDescription = StringBuilder();
          
          if (description != null && description.isNotEmpty) {
            detailedDescription.append(description);
          } else if (billData['title'] != null && (billData['title'] as String).length > 50) {
            detailedDescription.append(billData['title'] as String);
          }
          
          // Add committee if available
          if (billData['committee'] != null && (billData['committee'] as String).isNotEmpty) {
            if (detailedDescription.length > 0) {
              detailedDescription.append('\n\n');
            }
            detailedDescription.append('Committee: ${billData['committee']}');
          }
          
          // Add state link if available
          if (billData['state_link'] != null && (billData['state_link'] as String).isNotEmpty) {
            if (detailedDescription.length > 0) {
              detailedDescription.append('\n\n');
            }
            detailedDescription.append('State Link: ${billData['state_link']}');
          }
          
          // Add URL if available
          if (billData['url'] != null && (billData['url'] as String).isNotEmpty) {
            if (detailedDescription.length > 0) {
              detailedDescription.append('\n\n');
            }
            detailedDescription.append('URL: ${billData['url']}');
          }
          
          // Create enriched bill with extra data
          final enrichedBill = RepresentativeBill(
            congress: 'State Session',
            billType: billType,
            billNumber: number,
            title: billData['title'] as String? ?? 'Untitled Bill',
            introducedDate: statusDate,
            latestAction: latestAction,
            source: 'CSV',
            // Add additional data in extraData field
            extraData: {
              'status_desc': statusDesc,
              'description': detailedDescription.toString(),
              'state_link': billData['state_link'] as String?,
              'url': billData['url'] as String?,
              'committee': billData['committee'] as String?,
              'bill_id': billData['bill_id']?.toString(),
              'session_id': billData['session_id']?.toString(),
              'status': billData['status']?.toString(),
            },
          );
          
          result.add(enrichedBill);
        } else {
          // Standard bill for other states
          result.add(RepresentativeBill(
            congress: 'State Session',
            billType: billType,
            billNumber: number,
            title: billData['title'] as String? ?? 'Untitled Bill',
            introducedDate: statusDate,
            latestAction: latestAction,
            source: 'CSV',
          ));
        }
      }
      
      // Sort bills by introduced date (newest first)
      result.sort((a, b) {
        if (a.introducedDate == null) return 1;
        if (b.introducedDate == null) return -1;
        return b.introducedDate!.compareTo(a.introducedDate!);
      });
      
      return result;
    } catch (e) {
      return [];
    }
  }

  // Get sponsored bills for a person by their people_id
  List<RepresentativeBill> getSponsoredBillsForPerson(int peopleId, {String? stateCode}) {
    final sponsorsData = stateCode != null && _stateSponsorsData.containsKey(stateCode)
        ? _stateSponsorsData[stateCode]!
        : _sponsorsData;
        
    final billsData = stateCode != null && _stateBillsData.containsKey(stateCode)
        ? _stateBillsData[stateCode]!
        : _billsData;
        
    final historyData = stateCode != null && _stateHistoryData.containsKey(stateCode)
        ? _stateHistoryData[stateCode]!
        : _historyData;
    
    if (!_initialized || 
        sponsorsData == null || 
        sponsorsData.isEmpty ||
        billsData == null ||
        billsData.isEmpty ||
        historyData == null) {
      return [];
    }
    
    final List<RepresentativeBill> result = [];
    
    try {
      // Find all bill_ids where this person is a sponsor
      final sponsoredBillIds = sponsorsData
          .where((sponsor) => sponsor['people_id'] == peopleId)
          .map((sponsor) => sponsor['bill_id'])
          .toList();
      
      if (sponsoredBillIds.isEmpty) {
        return [];
      }
      
      // Get bill details for each sponsored bill
      for (final billId in sponsoredBillIds) {
        final billData = billsData.firstWhere(
          (bill) => bill['bill_id'] == billId,
          orElse: () => <String, dynamic>{},
        );
        
        if (billData.isEmpty) continue;
        
        // Get the latest action from history data
        final actions = historyData
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
      return [];
    }
  }
  
  // Get sponsored bills for a representative
  Future<List<RepresentativeBill>> getSponsoredBills(Representative rep) async {
    if (!_initialized) {
      await initialize();
    }
    
    // Load state-specific data if needed
    if (_availableStates.contains(rep.state) && !_statePeopleData.containsKey(rep.state)) {
      await loadStateData(rep.state);
    }
    
    // Try to find person ID by name
    final peopleId = findPersonIdByName(rep.name, stateCode: rep.state);
    
    if (peopleId == null) {
      return [];
    }
    
    return getSponsoredBillsForPerson(peopleId, stateCode: rep.state);
  }

  // Get sponsored bills for a local representative
  Future<List<RepresentativeBill>> getSponsoredBillsForLocalRep(LocalRepresentative rep) async {
    if (!_initialized) {
      await initialize();
    }
    
    // Load state-specific data if needed
    if (_availableStates.contains(rep.state) && !_statePeopleData.containsKey(rep.state)) {
      await loadStateData(rep.state);
    }
    
    // Try to find person ID by name
    final peopleId = findPersonIdByName(rep.name, stateCode: rep.state);
    
    if (peopleId == null) {
      return [];
    }
    
    return getSponsoredBillsForPerson(peopleId, stateCode: rep.state);
  }
}