// lib/services/csv_bill_service.dart
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/models/local_representative_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
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

  // Cached data for app-wide CSVs
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
      
      // Load app-wide CSV data
      await Future.wait([
        _loadPeopleData(),
        _loadBillsData(),
        _loadSponsorsData(),
        _loadHistoryData(),
      ]);
      
      // Load first state's data as a default example
      if (_availableStates.isNotEmpty) {
        await loadStateData(_availableStates.first);
      }
      
      if (kDebugMode) {
        print('✅ CSV Bill Service initialized successfully');
        print('Found states with CSV data: ${_availableStates.join(', ')}');
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

  // Detect available states with CSV data
  Future<void> _detectAvailableStates() async {
    try {
      // Manually add states we know have CSV files based on directory structure
      // This is more reliable than trying to parse the asset manifest, especially in web mode
      _availableStates = [
        'AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'FL', 'GA', 'HI', 
        'IA', 'IL', 'IN', 'KS', 'KY'
      ];
      
      if (kDebugMode) {
        print('Using ${_availableStates.length} states with CSV data: ${_availableStates.join(', ')}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error detecting available states: $e');
      }
      _availableStates = [];
    }
  }

  // Load state-specific data
  Future<bool> loadStateData(String stateCode) async {
    if (!_availableStates.contains(stateCode)) {
      if (kDebugMode) {
        print('State $stateCode is not available in CSV data');
      }
      return false;
    }
    
    // For Florida and Georgia, always force a reload to ensure fresh data
    if (stateCode == 'FL' || stateCode == 'GA') {
      if (kDebugMode) {
        print('Forced reload requested for special state: $stateCode');
      }
      // Don't check cached data for FL and GA
    } else {
      // Check if already loaded for other states
      if (_statePeopleData.containsKey(stateCode) &&
          _stateBillsData.containsKey(stateCode) &&
          _stateSponsorsData.containsKey(stateCode) &&
          _stateHistoryData.containsKey(stateCode)) {
        return true;
      }
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
        if (kDebugMode) {
          print('Could not find session folder for state $stateCode');
        }
        return false;
      }
      
      // Base path for all CSV files
      final basePath = 'assets/data/csvs/$stateCode/$sessionPath/csv';
      
      if (kDebugMode) {
        print('Loading CSV files from path: $basePath');
      }
      
      // Special handling for FL and GA to ensure proper loading
      if (stateCode == 'FL' || stateCode == 'GA') {
        try {
          if (kDebugMode) {
            print('Using sequential loading for special state: $stateCode');
          }
          
          // Load data sequentially to better debug issues
          await _loadStatePeopleData(stateCode, '$basePath/people.csv');
          if (kDebugMode) {
            print('People data loaded for $stateCode: ${_statePeopleData[stateCode]?.length ?? 0} records');
          }
          
          await _loadStateBillsData(stateCode, '$basePath/bills.csv');
          if (kDebugMode) {
            print('Bills data loaded for $stateCode: ${_stateBillsData[stateCode]?.length ?? 0} records');
          }
          
          await _loadStateSponsorsData(stateCode, '$basePath/sponsors.csv');
          if (kDebugMode) {
            print('Sponsors data loaded for $stateCode: ${_stateSponsorsData[stateCode]?.length ?? 0} records');
          }
          
          await _loadStateHistoryData(stateCode, '$basePath/history.csv');
          if (kDebugMode) {
            print('History data loaded for $stateCode: ${_stateHistoryData[stateCode]?.length ?? 0} records');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error during sequential loading for $stateCode: $e');
            print('Falling back to standard loading method');
          }
          
          // Fallback to standard parallel loading if sequential fails
          await Future.wait([
            _loadStatePeopleData(stateCode, '$basePath/people.csv'),
            _loadStateBillsData(stateCode, '$basePath/bills.csv'),
            _loadStateSponsorsData(stateCode, '$basePath/sponsors.csv'),
            _loadStateHistoryData(stateCode, '$basePath/history.csv'),
          ]);
        }
      } else {
        // Load all data in parallel for other states
        await Future.wait([
          _loadStatePeopleData(stateCode, '$basePath/people.csv'),
          _loadStateBillsData(stateCode, '$basePath/bills.csv'),
          _loadStateSponsorsData(stateCode, '$basePath/sponsors.csv'),
          _loadStateHistoryData(stateCode, '$basePath/history.csv'),
        ]);
      }
      
      if (kDebugMode) {
        print('Loaded state data for $stateCode:');
        print('  People: ${_statePeopleData[stateCode]?.length ?? 0}');
        print('  Bills: ${_stateBillsData[stateCode]?.length ?? 0}');
        print('  Sponsors: ${_stateSponsorsData[stateCode]?.length ?? 0}');
        print('  History: ${_stateHistoryData[stateCode]?.length ?? 0}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading state data for $stateCode: $e');
        print('Exception details: ${e.toString()}');
      }
      return false;
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
        print('App-wide people data loaded: ${_peopleData!.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading app-wide people data: $e');
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
        print('App-wide bills data loaded: ${_billsData!.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading app-wide bills data: $e');
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
        print('App-wide sponsors data loaded: ${_sponsorsData!.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading app-wide sponsors data: $e');
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
        print('App-wide history data loaded: ${_historyData!.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading app-wide history data: $e');
      }
      _historyData = [];
    }
  }

  // Load state-specific people data
  Future<void> _loadStatePeopleData(String stateCode, String assetPath) async {
    try {
      if (kDebugMode) {
        print('Loading people data for $stateCode from path: $assetPath');
      }
      
      final data = await rootBundle.loadString(assetPath);
      
      if (data.isEmpty) {
        if (kDebugMode) {
          print('WARNING: Empty data returned for $stateCode people CSV file');
        }
        _statePeopleData[stateCode] = [];
        return;
      }
      
      // Use a more resilient CSV converter with different delimiters and line endings
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter().convert(data, eol: '\n');
        if (rows.isEmpty) {
          if (kDebugMode) {
            print('Warning: No rows parsed with newline delimiter for $stateCode people, trying \\r\\n');
          }
          rows = const CsvToListConverter().convert(data, eol: '\r\n');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing people CSV data: $e');
          print('Trying fallback CSV parsing approach');
        }
        
        // Manual fallback CSV parsing
        final lines = data.split('\n');
        rows = lines.map((line) => line.split(',')).toList();
      }
      
      if (rows.isEmpty) {
        if (kDebugMode) {
          print('Warning: Failed to parse any rows from people CSV data for $stateCode');
        }
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
      
      if (kDebugMode) {
        print('$stateCode state people data loaded: ${stateData.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading $stateCode state people data: $e');
        print('Exception details: ${e.toString()}');
      }
      _statePeopleData[stateCode] = [];
    }
  }

  // Load state-specific bills data
  Future<void> _loadStateBillsData(String stateCode, String assetPath) async {
    try {
      if (kDebugMode) {
        print('Loading bills data for $stateCode from path: $assetPath');
      }
      
      final data = await rootBundle.loadString(assetPath);
      
      if (data.isEmpty) {
        if (kDebugMode) {
          print('WARNING: Empty data returned for $stateCode bills CSV file');
        }
        _stateBillsData[stateCode] = [];
        return;
      }
      
      if (kDebugMode) {
        print('CSV data loaded successfully for $stateCode (${data.length} bytes)');
        final lineCount = data.split('\n').length;
        print('Lines in CSV: $lineCount');
      }
      
      // Special handling for FL and GA to check if file is being read correctly
      if (stateCode == 'FL' || stateCode == 'GA') {
        if (kDebugMode) {
          print('First 100 characters of $stateCode CSV: ${data.substring(0, data.length > 100 ? 100 : data.length)}...');
        }
      }
      
      // Use a more resilient CSV converter with different delimiters and line endings
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter().convert(data, eol: '\n');
        if (rows.isEmpty) {
          if (kDebugMode) {
            print('Warning: No rows parsed with newline delimiter for $stateCode, trying \\r\\n');
          }
          rows = const CsvToListConverter().convert(data, eol: '\r\n');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing CSV data with standard converter: $e');
          print('Trying fallback CSV parsing approach');
        }
        
        // Manual fallback CSV parsing
        final lines = data.split('\n');
        rows = lines.map((line) => line.split(',')).toList();
      }
      
      if (rows.isEmpty) {
        if (kDebugMode) {
          print('Warning: Failed to parse any rows from CSV data for $stateCode');
        }
        _stateBillsData[stateCode] = [];
        return;
      }
      
      if (kDebugMode) {
        print('Successfully parsed ${rows.length} rows from CSV data for $stateCode');
      }
      
      // Extract headers from first row
      final headers = rows[0].map((e) => e.toString()).toList();
      
      if (kDebugMode) {
        print('CSV headers for $stateCode: ${headers.join(', ')}');
      }
      
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
        } else if (kDebugMode) {
          print('Skipping row $i for $stateCode due to missing bill_number');
        }
      }
      
      _stateBillsData[stateCode] = stateData;
      
      if (kDebugMode) {
        print('$stateCode state bills data loaded: ${stateData.length} records');
        
        // For FL and GA, print first bill as a sample
        if ((stateCode == 'FL' || stateCode == 'GA') && stateData.isNotEmpty) {
          print('Sample bill data for $stateCode:');
          stateData.first.forEach((key, value) {
            print('  $key: $value');
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading $stateCode state bills data: $e');
        print('Exception details: ${e.toString()}');
        print('Stack trace: ${StackTrace.current}');
      }
      _stateBillsData[stateCode] = [];
    }
  }

  // Load state-specific sponsors data
  Future<void> _loadStateSponsorsData(String stateCode, String assetPath) async {
    try {
      if (kDebugMode) {
        print('Loading sponsors data for $stateCode from path: $assetPath');
      }
      
      final data = await rootBundle.loadString(assetPath);
      
      if (data.isEmpty) {
        if (kDebugMode) {
          print('WARNING: Empty data returned for $stateCode sponsors CSV file');
        }
        _stateSponsorsData[stateCode] = [];
        return;
      }
      
      // Use a more resilient CSV converter with different delimiters and line endings
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter().convert(data, eol: '\n');
        if (rows.isEmpty) {
          if (kDebugMode) {
            print('Warning: No rows parsed with newline delimiter for $stateCode sponsors, trying \\r\\n');
          }
          rows = const CsvToListConverter().convert(data, eol: '\r\n');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing sponsors CSV data: $e');
          print('Trying fallback CSV parsing approach');
        }
        
        // Manual fallback CSV parsing
        final lines = data.split('\n');
        rows = lines.map((line) => line.split(',')).toList();
      }
      
      if (rows.isEmpty) {
        if (kDebugMode) {
          print('Warning: Failed to parse any rows from sponsors CSV data for $stateCode');
        }
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
      
      if (kDebugMode) {
        print('$stateCode state sponsors data loaded: ${stateData.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading $stateCode state sponsors data: $e');
        print('Exception details: ${e.toString()}');
      }
      _stateSponsorsData[stateCode] = [];
    }
  }

  // Load state-specific history data
  Future<void> _loadStateHistoryData(String stateCode, String assetPath) async {
    try {
      if (kDebugMode) {
        print('Loading history data for $stateCode from path: $assetPath');
      }
      
      final data = await rootBundle.loadString(assetPath);
      
      if (data.isEmpty) {
        if (kDebugMode) {
          print('WARNING: Empty data returned for $stateCode history CSV file');
        }
        _stateHistoryData[stateCode] = [];
        return;
      }
      
      // Use a more resilient CSV converter with different delimiters and line endings
      List<List<dynamic>> rows;
      try {
        rows = const CsvToListConverter().convert(data, eol: '\n');
        if (rows.isEmpty) {
          if (kDebugMode) {
            print('Warning: No rows parsed with newline delimiter for $stateCode history, trying \\r\\n');
          }
          rows = const CsvToListConverter().convert(data, eol: '\r\n');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing history CSV data: $e');
          print('Trying fallback CSV parsing approach');
        }
        
        // Manual fallback CSV parsing
        final lines = data.split('\n');
        rows = lines.map((line) => line.split(',')).toList();
      }
      
      if (rows.isEmpty) {
        if (kDebugMode) {
          print('Warning: Failed to parse any rows from history CSV data for $stateCode');
        }
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
      
      if (kDebugMode) {
        print('$stateCode state history data loaded: ${stateData.length} records');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading $stateCode state history data: $e');
        print('Exception details: ${e.toString()}');
      }
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
      if (kDebugMode) {
        print('People data not initialized${stateCode != null ? ' for state $stateCode' : ''}');
      }
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
    
    if (kDebugMode) {
      print('getBillsByState called for state: $stateCode');
      print('Checking if state data is available...');
      print('Available states: ${_availableStates.join(', ')}');
      print('Is state in available states: ${_availableStates.contains(stateCode)}');
      print('Already loaded states: ${_stateBillsData.keys.join(', ')}');
    }
    
    // Special handling for Florida and Georgia which were having issues
    if (stateCode == 'FL' || stateCode == 'GA') {
      if (kDebugMode) {
        print('Special handling for $stateCode');
      }
      
      // Remove any existing cached data for this state to ensure a clean reload
      _stateBillsData.remove(stateCode);
      _statePeopleData.remove(stateCode);
      _stateSponsorsData.remove(stateCode);
      _stateHistoryData.remove(stateCode);
      
      if (kDebugMode) {
        print('Cleared existing cache for $stateCode, forcing fresh load');
      }
      
      // Force a fresh load of the state data
      final forcedLoad = await loadStateData(stateCode);
      if (kDebugMode) {
        print('Forced load of $stateCode data: $forcedLoad');
        
        if (_stateBillsData.containsKey(stateCode)) {
          print('$stateCode has ${_stateBillsData[stateCode]!.length} bills after forced load');
          
          // Log a sample of the first few bills to debug
          if (_stateBillsData[stateCode]!.isNotEmpty) {
            print('Sample $stateCode bill data:');
            final sampleBill = _stateBillsData[stateCode]!.first;
            sampleBill.forEach((key, value) {
              print('  $key: $value');
            });
          }
        } else {
          print('$stateCode still has no data after forced load');
        }
      }
    }
    
    // Check if state data is available and load it if needed
    if (!_stateBillsData.containsKey(stateCode)) {
      if (kDebugMode) {
        print('State data not loaded yet for $stateCode, attempting to load...');
      }
      
      final loaded = await loadStateData(stateCode);
      if (!loaded) {
        if (kDebugMode) {
          print('Could not load data for state $stateCode');
        }
        return [];
      }
    }
    
    final billsData = _stateBillsData[stateCode];
    if (billsData == null || billsData.isEmpty) {
      if (kDebugMode) {
        print('No bills data available for state $stateCode');
        
        // Additional diagnostics to help debug the issue
        try {
          // Attempt direct file read to see if the file exists and has content
          final assetPath = 'assets/data/csvs/$stateCode/';
          for (final sessionFolder in [
            '2025-2025_Regular_Session',
            '2025-2026_Regular_Session',
          ]) {
            final fullPath = '$assetPath$sessionFolder/csv/bills.csv';
            print('Attempting direct asset read for diagnostic purposes: $fullPath');
            try {
              final data = await rootBundle.loadString(fullPath);
              final firstLine = data.split('\n').first;
              print('First line of $fullPath: $firstLine');
              print('File exists and has content (${data.length} bytes)');
            } catch (e) {
              print('Failed to read $fullPath: $e');
            }
          }
        } catch (e) {
          print('Diagnostic check failed: $e');
        }
      }
      return [];
    }
    
    if (kDebugMode) {
      print('Found ${billsData.length} bills for state $stateCode');
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
      
      if (kDebugMode) {
        print('Returning ${result.length} bills for state $stateCode');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bills for state $stateCode: $e');
        print('Exception details: ${e.toString()}');
      }
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
      if (kDebugMode) {
        print('Data not initialized${stateCode != null ? ' for state $stateCode' : ''}');
      }
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
        if (kDebugMode) {
          print('No sponsored bills found for people_id: $peopleId${stateCode != null ? ' in state $stateCode' : ''}');
        }
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
    
    // Load state-specific data if needed
    if (_availableStates.contains(rep.state) && !_statePeopleData.containsKey(rep.state)) {
      await loadStateData(rep.state);
    }
    
    // Try to find person ID by name
    final peopleId = findPersonIdByName(rep.name, stateCode: rep.state);
    
    if (peopleId == null) {
      if (kDebugMode) {
        print('Could not find person ID for representative: ${rep.name} in state ${rep.state}');
      }
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
      if (kDebugMode) {
        print('Could not find person ID for local representative: ${rep.name} in state ${rep.state}');
      }
      return [];
    }
    
    return getSponsoredBillsForPerson(peopleId, stateCode: rep.state);
  }
}