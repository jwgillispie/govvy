import 'package:govvy/services/network_service.dart';
import 'package:govvy/models/campaign_finance_model.dart';

class FollowTheMoneyCandidate {
  final String candidateId;
  final String name;
  final String office;
  final String state;
  final String party;
  final int cycle;
  final String level; // 'federal', 'state', 'local'
  final String? district;
  final String? county;
  final bool isIncumbent;

  FollowTheMoneyCandidate({
    required this.candidateId,
    required this.name,
    required this.office,
    required this.state,
    required this.party,
    required this.cycle,
    required this.level,
    this.district,
    this.county,
    this.isIncumbent = false,
  });

  factory FollowTheMoneyCandidate.fromJson(Map<String, dynamic> json) {
    return FollowTheMoneyCandidate(
      candidateId: json['candidate_id']?.toString() ?? '',
      name: json['candidate_name']?.toString() ?? '',
      office: json['office']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      party: json['party']?.toString() ?? '',
      cycle: int.tryParse(json['cycle']?.toString() ?? '0') ?? 0,
      level: _determineLevel(json['office']?.toString() ?? ''),
      district: json['district']?.toString(),
      county: json['county']?.toString(),
      isIncumbent: json['incumbent']?.toString().toLowerCase() == 'true',
    );
  }

  static String _determineLevel(String office) {
    final officeLower = office.toLowerCase();
    if (officeLower.contains('president') || 
        officeLower.contains('senate') || 
        officeLower.contains('house') ||
        officeLower.contains('congress')) {
      return 'federal';
    } else if (officeLower.contains('governor') || 
               officeLower.contains('state') ||
               officeLower.contains('attorney general') ||
               officeLower.contains('secretary of state')) {
      return 'state';
    } else {
      return 'local';
    }
  }

  String get displayOffice {
    if (district != null) {
      return '$office - District $district';
    }
    return office;
  }

  String get officeLevel {
    switch (level) {
      case 'federal':
        return 'Federal';
      case 'state':
        return 'State';
      case 'local':
        return 'Local';
      default:
        return 'Unknown';
    }
  }
}

class FollowTheMoneyFinance {
  final String candidateId;
  final double totalRaised;
  final double totalSpent;
  final double cashOnHand;
  final int contributionCount;
  final int cycle;
  final Map<String, double> topContributorTypes;
  final Map<String, double> expenditureCategories;

  FollowTheMoneyFinance({
    required this.candidateId,
    required this.totalRaised,
    required this.totalSpent,
    required this.cashOnHand,
    required this.contributionCount,
    required this.cycle,
    required this.topContributorTypes,
    required this.expenditureCategories,
  });

  factory FollowTheMoneyFinance.fromJson(Map<String, dynamic> json) {
    return FollowTheMoneyFinance(
      candidateId: json['candidate_id']?.toString() ?? '',
      totalRaised: double.tryParse(json['total_raised']?.toString() ?? '0') ?? 0.0,
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0.0,
      cashOnHand: double.tryParse(json['cash_on_hand']?.toString() ?? '0') ?? 0.0,
      contributionCount: int.tryParse(json['contribution_count']?.toString() ?? '0') ?? 0,
      cycle: int.tryParse(json['cycle']?.toString() ?? '0') ?? 0,
      topContributorTypes: _parseContributorTypes(json['contributor_types'] ?? {}),
      expenditureCategories: _parseExpenditureCategories(json['expenditure_categories'] ?? {}),
    );
  }

  static Map<String, double> _parseContributorTypes(dynamic data) {
    final result = <String, double>{};
    if (data is Map) {
      data.forEach((key, value) {
        result[key.toString()] = double.tryParse(value.toString()) ?? 0.0;
      });
    }
    return result;
  }

  static Map<String, double> _parseExpenditureCategories(dynamic data) {
    final result = <String, double>{};
    if (data is Map) {
      data.forEach((key, value) {
        result[key.toString()] = double.tryParse(value.toString()) ?? 0.0;
      });
    }
    return result;
  }
}

class FollowTheMoneyService {
  static final FollowTheMoneyService _instance = FollowTheMoneyService._internal();
  factory FollowTheMoneyService() => _instance;
  FollowTheMoneyService._internal();

  final NetworkService _networkService = NetworkService();
  
  // Follow the Money API base URL (Note: This is a placeholder - you'll need to get actual API access)
  static const String _baseUrl = 'https://api.followthemoney.org/v1';
  
  // Cache for performance
  final Map<String, List<FollowTheMoneyCandidate>> _candidateCache = {};
  final Map<String, FollowTheMoneyFinance> _financeCache = {};
  static const Duration _cacheTimeout = Duration(hours: 1);
  DateTime? _lastCacheUpdate;

  Future<List<FollowTheMoneyCandidate>> searchCandidates({
    required String name,
    String? state,
    String? office,
    int? cycle,
    int limit = 20,
  }) async {
    final cacheKey = '${name}_${state ?? 'all'}_${office ?? 'all'}_${cycle ?? 'current'}';
    
    // Check cache first
    if (_candidateCache.containsKey(cacheKey) && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout) {
      return _candidateCache[cacheKey]!;
    }

    try {
      print('FollowTheMoney: Searching for candidates: $name');
      
      // Build query parameters
      final queryParams = <String, String>{
        'candidate_name': name,
        'limit': limit.toString(),
      };
      
      if (state != null && state != 'All States') {
        queryParams['state'] = state;
      }
      
      if (office != null && office != 'All Offices') {
        queryParams['office'] = office;
      }
      
      if (cycle != null) {
        queryParams['cycle'] = cycle.toString();
      } else {
        // Default to recent cycles
        queryParams['cycle'] = '2022,2024';
      }

      // For now, return mock data since we need actual API access
      // TODO: Replace with real API call once we have access
      final mockResults = _generateMockCandidates(name, state, office, cycle);
      
      // Cache the results
      _candidateCache[cacheKey] = mockResults;
      _lastCacheUpdate = DateTime.now();
      
      print('FollowTheMoney: Found ${mockResults.length} candidates');
      return mockResults;
      
      /*
      // Real API implementation would look like this:
      final response = await _networkService.getFromExternalApi(
        '$_baseUrl/candidates',
        queryParams: queryParams,
      );
      
      final List<dynamic> candidatesData = response['results'] ?? [];
      final candidates = candidatesData
          .map((data) => FollowTheMoneyCandidate.fromJson(data))
          .toList();
      
      _candidateCache[cacheKey] = candidates;
      _lastCacheUpdate = DateTime.now();
      
      return candidates;
      */
    } catch (e) {
      print('Error searching Follow the Money candidates: $e');
      return [];
    }
  }

  Future<FollowTheMoneyFinance?> getCandidateFinance(
    String candidateId, {
    int? cycle,
  }) async {
    final cacheKey = '${candidateId}_${cycle ?? 'current'}';
    
    // Check cache first
    if (_financeCache.containsKey(cacheKey) && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout) {
      return _financeCache[cacheKey]!;
    }

    try {
      print('FollowTheMoney: Getting finance data for candidate: $candidateId');
      
      // For now, return mock data
      // TODO: Replace with real API call
      final mockFinance = _generateMockFinance(candidateId, cycle);
      
      _financeCache[cacheKey] = mockFinance;
      return mockFinance;
      
      /*
      // Real API implementation:
      final queryParams = <String, String>{};
      if (cycle != null) {
        queryParams['cycle'] = cycle.toString();
      }
      
      final response = await _networkService.getFromExternalApi(
        '$_baseUrl/candidates/$candidateId/finance',
        queryParams: queryParams,
      );
      
      final finance = FollowTheMoneyFinance.fromJson(response);
      _financeCache[cacheKey] = finance;
      
      return finance;
      */
    } catch (e) {
      print('Error getting Follow the Money finance data: $e');
      return null;
    }
  }

  // Mock data generators for development (remove when real API is available)
  List<FollowTheMoneyCandidate> _generateMockCandidates(String name, String? state, String? office, int? cycle) {
    final nameLower = name.toLowerCase();
    final mockCandidates = <FollowTheMoneyCandidate>[];
    
    // Generate mock state-level candidates based on search
    if (nameLower.contains('smith')) {
      mockCandidates.addAll([
        FollowTheMoneyCandidate(
          candidateId: 'ftm_smith_gov_001',
          name: 'John Smith',
          office: 'Governor',
          state: state ?? 'California',
          party: 'Democratic',
          cycle: cycle ?? 2024,
          level: 'state',
          isIncumbent: false,
        ),
        FollowTheMoneyCandidate(
          candidateId: 'ftm_smith_sen_001',
          name: 'Sarah Smith',
          office: 'State Senate',
          state: state ?? 'Texas',
          party: 'Republican',
          cycle: cycle ?? 2024,
          level: 'state',
          district: '15',
          isIncumbent: true,
        ),
      ]);
    }
    
    if (nameLower.contains('johnson')) {
      mockCandidates.addAll([
        FollowTheMoneyCandidate(
          candidateId: 'ftm_johnson_may_001',
          name: 'Mike Johnson',
          office: 'Mayor',
          state: state ?? 'Florida',
          party: 'Independent',
          cycle: cycle ?? 2024,
          level: 'local',
          county: 'Miami-Dade',
          isIncumbent: false,
        ),
      ]);
    }
    
    // Add some generic candidates if no specific matches
    if (mockCandidates.isEmpty) {
      mockCandidates.addAll([
        FollowTheMoneyCandidate(
          candidateId: 'ftm_generic_001',
          name: '$name (State)',
          office: 'State Representative',
          state: state ?? 'New York',
          party: 'Democratic',
          cycle: cycle ?? 2024,
          level: 'state',
          district: '42',
          isIncumbent: false,
        ),
        FollowTheMoneyCandidate(
          candidateId: 'ftm_generic_002',
          name: '$name (Local)',
          office: 'City Council',
          state: state ?? 'California',
          party: 'Republican',
          cycle: cycle ?? 2024,
          level: 'local',
          isIncumbent: true,
        ),
      ]);
    }
    
    return mockCandidates;
  }

  FollowTheMoneyFinance _generateMockFinance(String candidateId, int? cycle) {
    // Generate different mock data based on candidate ID for testing
    final isStateLevel = candidateId.contains('gov') || candidateId.contains('sen');
    final isLocalLevel = candidateId.contains('may') || candidateId.contains('city');
    
    double baseAmount = 50000; // Default for state/local
    if (isStateLevel) baseAmount = 500000;
    if (isLocalLevel) baseAmount = 25000;
    
    return FollowTheMoneyFinance(
      candidateId: candidateId,
      totalRaised: baseAmount * (0.8 + (candidateId.hashCode % 100) / 100),
      totalSpent: baseAmount * (0.6 + (candidateId.hashCode % 50) / 100),
      cashOnHand: baseAmount * (0.2 + (candidateId.hashCode % 30) / 100),
      contributionCount: 150 + (candidateId.hashCode % 300),
      cycle: cycle ?? 2024,
      topContributorTypes: {
        'Individual': baseAmount * 0.6,
        'Business': baseAmount * 0.25,
        'Labor': baseAmount * 0.1,
        'Other': baseAmount * 0.05,
      },
      expenditureCategories: {
        'Advertising': baseAmount * 0.4,
        'Staff': baseAmount * 0.25,
        'Events': baseAmount * 0.15,
        'Travel': baseAmount * 0.1,
        'Other': baseAmount * 0.1,
      },
    );
  }

  void clearCache() {
    _candidateCache.clear();
    _financeCache.clear();
    _lastCacheUpdate = null;
  }
}