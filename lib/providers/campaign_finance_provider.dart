import 'package:flutter/foundation.dart';
import 'package:govvy/services/fec_service.dart';
import 'package:govvy/models/campaign_finance_model.dart';

class CampaignFinanceProvider with ChangeNotifier {
  static final CampaignFinanceProvider _instance = CampaignFinanceProvider._internal();
  factory CampaignFinanceProvider() => _instance;
  CampaignFinanceProvider._internal();

  final FECService _fecService = FECService();

  // Loading states
  bool _isLoadingCandidate = false;
  bool _isLoadingSummary = false;
  bool _isLoadingContributions = false;
  bool _isLoadingExpenditures = false;
  bool _isLoadingCommittees = false;

  // Data storage
  FECCandidate? _currentCandidate;
  CampaignFinanceSummary? _financeSummary;
  List<CampaignContribution> _contributions = [];
  List<CampaignExpenditure> _expenditures = [];
  List<CommitteeInfo> _committees = [];
  List<CampaignContribution> _topContributors = [];
  Map<String, double> _contributionsByState = {};
  Map<String, int> _contributionAmountDistribution = {};
  Map<String, double> _monthlyFundraisingTrends = {};

  // Error handling
  String? _error;

  // Getters
  bool get isLoadingCandidate => _isLoadingCandidate;
  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingContributions => _isLoadingContributions;
  bool get isLoadingExpenditures => _isLoadingExpenditures;
  bool get isLoadingCommittees => _isLoadingCommittees;
  bool get isLoadingAny => _isLoadingCandidate || _isLoadingSummary || 
                          _isLoadingContributions || _isLoadingExpenditures || 
                          _isLoadingCommittees;

  FECCandidate? get currentCandidate => _currentCandidate;
  CampaignFinanceSummary? get financeSummary => _financeSummary;
  List<CampaignContribution> get contributions => _contributions;
  List<CampaignExpenditure> get expenditures => _expenditures;
  List<CommitteeInfo> get committees => _committees;
  List<CampaignContribution> get topContributors => _topContributors;
  Map<String, double> get contributionsByState => _contributionsByState;
  Map<String, int> get contributionAmountDistribution => _contributionAmountDistribution;
  Map<String, double> get monthlyFundraisingTrends => _monthlyFundraisingTrends;
  String? get error => _error;

  bool get hasData => _currentCandidate != null;

  // Clear all data
  void clearData() {
    _currentCandidate = null;
    _financeSummary = null;
    _contributions.clear();
    _expenditures.clear();
    _committees.clear();
    _topContributors.clear();
    _contributionsByState.clear();
    _contributionAmountDistribution.clear();
    _monthlyFundraisingTrends.clear();
    _error = null;
    notifyListeners();
  }

  // Load candidate finance data by name
  Future<void> loadCandidateByName(String name, {int? cycle}) async {
    print('Provider: Loading candidate data for: $name');
    
    // Clear any existing data and set loading state
    _currentCandidate = null;
    _financeSummary = null;
    _contributions.clear();
    _expenditures.clear();
    _committees.clear();
    _topContributors.clear();
    _contributionsByState.clear();
    _contributionAmountDistribution.clear();
    _monthlyFundraisingTrends.clear();
    _error = null;
    
    _isLoadingCandidate = true;
    notifyListeners();

    try {
      final candidate = await _fecService.findCandidateByName(name, cycle: cycle);
      
      if (candidate != null) {
        _currentCandidate = candidate;
        print('Provider: Found candidate ${candidate.name} with ID: ${candidate.candidateId}');
        notifyListeners();
        
        // Load additional data for this candidate with timeout protection
        try {
          await _loadAllCandidateData(candidate.candidateId, cycle: cycle ?? 2024)
              .timeout(
            const Duration(minutes: 3),
            onTimeout: () {
              _error = 'Loading campaign finance data is taking longer than expected. Some data may be unavailable.';
              notifyListeners();
            },
          );
        } catch (e) {
          // Log the error but don't override the candidate data
          if (kDebugMode) {
            print('Error loading additional candidate data: $e');
          }
          // Set a warning message but keep the candidate
          _error = 'Some campaign finance data may be unavailable due to API issues.';
        }
      } else {
        _error = 'No campaign finance data found for $name';
      }
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        _error = 'Request timed out - FEC API may be slow. Please try again.';
      } else {
        _error = 'Error loading candidate data: $e';
      }
    } finally {
      _isLoadingCandidate = false;
      notifyListeners();
    }
  }

  // Load all data for a candidate
  Future<void> _loadAllCandidateData(String candidateId, {int? cycle}) async {
    try {
      // Load core data first (most important)
      await Future.wait([
        _loadFinanceSummary(candidateId, cycle: cycle),
        _loadCommittees(candidateId),
      ]);

      // Load secondary data with small delays to reduce server load
      await _loadContributions(candidateId, cycle: cycle);
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _loadExpenditures(candidateId, cycle: cycle);
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _loadTopContributors(candidateId, cycle: cycle);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load analytical data last (least critical) - don't let these block the UI
      try {
        await Future.wait([
          _loadContributionsByState(candidateId, cycle: cycle),
        ]).timeout(const Duration(seconds: 30));
        
        await Future.delayed(const Duration(milliseconds: 500));
        await Future.wait([
          _loadContributionAmountDistribution(candidateId, cycle: cycle),
          _loadMonthlyFundraisingTrends(candidateId, cycle: cycle),
        ]).timeout(const Duration(seconds: 30));
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Some analytical data failed to load: $e');
        }
        // Don't fail the whole process for analytical data
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _loadAllCandidateData: $e');
      }
      rethrow;
    }
  }

  // Load finance summary
  Future<void> _loadFinanceSummary(String candidateId, {int? cycle}) async {
    _isLoadingSummary = true;
    notifyListeners();

    try {
      _financeSummary = await _fecService.getCandidateFinanceSummary(
        candidateId,
        cycle: cycle,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading finance summary: $e');
      }
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  // Load contributions
  Future<void> _loadContributions(String candidateId, {int? cycle}) async {
    _isLoadingContributions = true;
    notifyListeners();

    try {
      _contributions = await _fecService.getCandidateContributions(
        candidateId,
        cycle: cycle,
        perPage: 50,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading contributions: $e');
      }
    } finally {
      _isLoadingContributions = false;
      notifyListeners();
    }
  }

  // Load expenditures
  Future<void> _loadExpenditures(String candidateId, {int? cycle}) async {
    _isLoadingExpenditures = true;
    notifyListeners();

    try {
      _expenditures = await _fecService.getCandidateExpenditures(
        candidateId,
        cycle: cycle,
        perPage: 50,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading expenditures: $e');
      }
    } finally {
      _isLoadingExpenditures = false;
      notifyListeners();
    }
  }

  // Load committees
  Future<void> _loadCommittees(String candidateId) async {
    _isLoadingCommittees = true;
    notifyListeners();

    try {
      _committees = await _fecService.getCandidateCommittees(candidateId);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading committees: $e');
      }
    } finally {
      _isLoadingCommittees = false;
      notifyListeners();
    }
  }

  // Load top contributors
  Future<void> _loadTopContributors(String candidateId, {int? cycle}) async {
    try {
      _topContributors = await _fecService.getTopContributors(
        candidateId,
        cycle: cycle,
        limit: 10,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading top contributors: $e');
      }
    }
  }


  // Load contributions by state
  Future<void> _loadContributionsByState(String candidateId, {int? cycle}) async {
    try {
      _contributionsByState = await _fecService.getContributionsByState(
        candidateId,
        cycle: cycle,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading contributions by state: $e');
      }
    }
  }

  // Load contribution amount distribution
  Future<void> _loadContributionAmountDistribution(String candidateId, {int? cycle}) async {
    try {
      _contributionAmountDistribution = await _fecService.getContributionAmountDistribution(
        candidateId,
        cycle: cycle,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading contribution amount distribution: $e');
      }
    }
  }

  // Load monthly fundraising trends
  Future<void> _loadMonthlyFundraisingTrends(String candidateId, {int? cycle}) async {
    try {
      _monthlyFundraisingTrends = await _fecService.getMonthlyFundraisingTrends(
        candidateId,
        cycle: cycle,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading monthly fundraising trends: $e');
      }
    }
  }

  // Utility methods for UI
  String get formattedTotalRaised {
    if (_financeSummary == null) return 'N/A';
    return _formatCurrency(_financeSummary!.totalRaised);
  }

  String get formattedTotalSpent {
    if (_financeSummary == null) return 'N/A';
    return _formatCurrency(_financeSummary!.totalSpent);
  }

  String get formattedCashOnHand {
    if (_financeSummary == null) return 'N/A';
    return _formatCurrency(_financeSummary!.cashOnHand);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  // Get spending efficiency (amount spent vs raised)
  double? get spendingEfficiency {
    if (_financeSummary == null || _financeSummary!.totalRaised == 0) return null;
    return _financeSummary!.totalSpent / _financeSummary!.totalRaised;
  }

  // Check if candidate has significant campaign activity
  bool get hasSignificantActivity {
    if (_financeSummary == null) return false;
    return _financeSummary!.totalRaised > 1000 || _financeSummary!.totalSpent > 1000;
  }
}