import 'package:flutter/foundation.dart';
import 'package:govvy/services/fec_service.dart';
import 'package:govvy/services/follow_the_money_service.dart';
import 'package:govvy/models/unified_candidate_model.dart';

class UnifiedFinanceProvider with ChangeNotifier {
  static final UnifiedFinanceProvider _instance = UnifiedFinanceProvider._internal();
  factory UnifiedFinanceProvider() => _instance;
  UnifiedFinanceProvider._internal();

  final FECService _fecService = FECService();
  final FollowTheMoneyService _ftmService = FollowTheMoneyService();

  // Loading states
  bool _isSearching = false;
  bool _isLoadingFinance = false;

  // Search results and current candidate
  List<CandidateSearchResult> _searchResults = [];
  UnifiedCandidate? _currentCandidate;
  UnifiedFinanceData? _currentFinanceData;

  // Error handling
  String? _error;

  // Getters
  bool get isSearching => _isSearching;
  bool get isLoadingFinance => _isLoadingFinance;
  bool get isLoadingAny => _isSearching || _isLoadingFinance;
  
  List<CandidateSearchResult> get searchResults => _searchResults;
  UnifiedCandidate? get currentCandidate => _currentCandidate;
  UnifiedFinanceData? get currentFinanceData => _currentFinanceData;
  String? get error => _error;

  bool get hasResults => _searchResults.isNotEmpty;
  bool get hasCurrentCandidate => _currentCandidate != null;
  bool get hasFinanceData => _currentFinanceData != null;

  // Clear all data
  void clearData() {
    _searchResults.clear();
    _currentCandidate = null;
    _currentFinanceData = null;
    _error = null;
    notifyListeners();
  }

  // Search candidates across all sources
  Future<void> searchCandidates({
    required String name,
    String? state,
    String? office,
    List<OfficeLevel> levels = const [OfficeLevel.federal, OfficeLevel.state, OfficeLevel.local],
    int? cycle,
  }) async {
    
    _isSearching = true;
    _searchResults.clear();
    _error = null;
    notifyListeners();

    try {
      final results = <CandidateSearchResult>[];

      // Search federal candidates via FEC if federal level is requested
      if (levels.contains(OfficeLevel.federal)) {
        try {
          final fecCandidates = await _fecService.searchCandidates(
            name: name,
            state: state,
            office: office,
            cycle: cycle,
          );
          for (final fecCandidate in fecCandidates) {
            final unifiedCandidate = UnifiedCandidate.fromFEC(fecCandidate);
            final relevanceScore = _calculateRelevanceScore(
              unifiedCandidate, 
              name, 
              state, 
              office,
            );
            
            results.add(CandidateSearchResult(
              candidate: unifiedCandidate,
              relevanceScore: relevanceScore,
              matchType: _getMatchType(unifiedCandidate.name, name),
              matchedFields: _getMatchedFields(unifiedCandidate, name, state, office),
            ));
          }
        } catch (e) {
          // Error searching FEC candidates - continuing with other sources
        }
      }

      // Search state/local candidates via Follow the Money
      if (levels.contains(OfficeLevel.state) || levels.contains(OfficeLevel.local)) {
        try {
          final ftmCandidates = await _ftmService.searchCandidates(
            name: name,
            state: state,
            office: office,
            cycle: cycle,
          );
          
          for (final ftmCandidate in ftmCandidates) {
            // Filter by requested levels
            final candidateLevel = OfficeLevel.values.firstWhere(
              (level) => level.name == ftmCandidate.level,
              orElse: () => OfficeLevel.state,
            );
            
            if (!levels.contains(candidateLevel)) continue;

            final unifiedCandidate = UnifiedCandidate.fromFollowTheMoney(ftmCandidate);
            final relevanceScore = _calculateRelevanceScore(
              unifiedCandidate, 
              name, 
              state, 
              office,
            );
            
            results.add(CandidateSearchResult(
              candidate: unifiedCandidate,
              relevanceScore: relevanceScore,
              matchType: _getMatchType(unifiedCandidate.name, name),
              matchedFields: _getMatchedFields(unifiedCandidate, name, state, office),
            ));
          }
        } catch (e) {
          // Error searching Follow the Money candidates - continuing
        }
      }

      // Sort by relevance and remove duplicates
      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      _searchResults = _removeDuplicates(results);
      
      
    } catch (e) {
      _error = 'Error searching candidates: $e';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Load finance data for a specific candidate
  Future<void> loadFinanceData(UnifiedCandidate candidate, {int? cycle}) async {
    
    _isLoadingFinance = true;
    _currentCandidate = candidate;
    _currentFinanceData = null;
    _error = null;
    notifyListeners();

    try {
      UnifiedFinanceData? financeData;

      switch (candidate.primarySource) {
        case DataSource.fec:
          financeData = await _loadFECFinanceData(candidate, cycle: cycle);
          break;
        case DataSource.followTheMoney:
          financeData = await _loadFTMFinanceData(candidate, cycle: cycle);
          break;
        case DataSource.stateSpecific:
        case DataSource.ballotpedia:
          // TODO: Implement when we add these sources
          _error = 'Finance data not yet available for ${candidate.primarySource.fullName}';
          break;
      }

      if (financeData != null) {
        _currentFinanceData = financeData;
      } else {
        _error = 'No finance data available for ${candidate.name}';
      }

    } catch (e) {
      _error = 'Error loading finance data: $e';
    } finally {
      _isLoadingFinance = false;
      notifyListeners();
    }
  }

  // Load FEC finance data (reuse existing infrastructure)
  Future<UnifiedFinanceData?> _loadFECFinanceData(UnifiedCandidate candidate, {int? cycle}) async {
    if (candidate.fecData == null) return null;

    try {
      final candidateId = candidate.getCandidateIdForSource(DataSource.fec);
      
      // Reuse existing FEC service methods
      final summary = await _fecService.getCandidateFinanceSummary(candidateId, cycle: cycle);
      final contributions = await _fecService.getCandidateContributions(candidateId, cycle: cycle, perPage: 50);
      final expenditures = await _fecService.getCandidateExpenditures(candidateId, cycle: cycle, perPage: 50);

      if (summary != null) {
        return UnifiedFinanceData.fromFEC(
          candidateId: candidateId,
          summary: summary,
          contributions: contributions,
          expenditures: expenditures,
          cycle: cycle ?? 2024,
        );
      }
    } catch (e) {
      // Error loading FEC finance data
    }
    
    return null;
  }

  // Load Follow the Money finance data
  Future<UnifiedFinanceData?> _loadFTMFinanceData(UnifiedCandidate candidate, {int? cycle}) async {
    if (candidate.ftmData == null) return null;

    try {
      final candidateId = candidate.getCandidateIdForSource(DataSource.followTheMoney);
      final ftmFinance = await _ftmService.getCandidateFinance(candidateId, cycle: cycle);

      if (ftmFinance != null) {
        return UnifiedFinanceData.fromFollowTheMoney(ftmFinance);
      }
    } catch (e) {
      // Error loading Follow the Money finance data
    }
    
    return null;
  }

  // Helper methods
  double _calculateRelevanceScore(UnifiedCandidate candidate, String query, String? state, String? office) {
    double score = 0.0;
    final queryLower = query.toLowerCase();
    final nameLower = candidate.name.toLowerCase();

    // Exact name match gets highest score
    if (nameLower == queryLower) {
      score += 100.0;
    } else if (nameLower.contains(queryLower)) {
      score += 80.0;
    } else if (_isPartialMatch(nameLower, queryLower)) {
      score += 60.0;
    }

    // State match bonus
    if (state != null && state != 'All States' && candidate.state.toLowerCase() == state.toLowerCase()) {
      score += 20.0;
    }

    // Office match bonus
    if (office != null && candidate.office.toLowerCase().contains(office.toLowerCase())) {
      score += 15.0;
    }

    // Recent cycle bonus
    final currentYear = DateTime.now().year;
    if (candidate.cycle >= currentYear - 2) {
      score += 10.0;
    }

    // Data source reliability bonus
    switch (candidate.primarySource) {
      case DataSource.fec:
        score += 5.0; // FEC is most reliable for federal
        break;
      case DataSource.followTheMoney:
        score += 3.0; // Good for state/local
        break;
      default:
        break;
    }

    return score;
  }

  bool _isPartialMatch(String name, String query) {
    final nameWords = name.split(' ');
    final queryWords = query.split(' ');
    
    for (final queryWord in queryWords) {
      if (queryWord.length >= 3) {
        for (final nameWord in nameWords) {
          if (nameWord.startsWith(queryWord)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  String _getMatchType(String candidateName, String query) {
    final nameLower = candidateName.toLowerCase();
    final queryLower = query.toLowerCase();

    if (nameLower == queryLower) return 'exact';
    if (nameLower.contains(queryLower)) return 'partial';
    return 'fuzzy';
  }

  List<String> _getMatchedFields(UnifiedCandidate candidate, String name, String? state, String? office) {
    final matched = <String>[];
    
    if (candidate.name.toLowerCase().contains(name.toLowerCase())) {
      matched.add('name');
    }
    
    if (state != null && candidate.state.toLowerCase() == state.toLowerCase()) {
      matched.add('state');
    }
    
    if (office != null && candidate.office.toLowerCase().contains(office.toLowerCase())) {
      matched.add('office');
    }
    
    return matched;
  }

  List<CandidateSearchResult> _removeDuplicates(List<CandidateSearchResult> results) {
    final seen = <String>{};
    final unique = <CandidateSearchResult>[];
    
    for (final result in results) {
      // Create a key based on name and office to identify duplicates
      final key = '${result.candidate.name.toLowerCase()}_${result.candidate.office.toLowerCase()}_${result.candidate.state.toLowerCase()}';
      
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(result);
      }
    }
    
    return unique;
  }

  // Utility methods for UI
  List<CandidateSearchResult> getResultsByLevel(OfficeLevel level) {
    return _searchResults.where((result) => result.candidate.level == level).toList();
  }

  Map<OfficeLevel, List<CandidateSearchResult>> getResultsGroupedByLevel() {
    final grouped = <OfficeLevel, List<CandidateSearchResult>>{};
    
    for (final level in OfficeLevel.values) {
      grouped[level] = getResultsByLevel(level);
    }
    
    return grouped;
  }

  bool hasResultsForLevel(OfficeLevel level) {
    return getResultsByLevel(level).isNotEmpty;
  }
}