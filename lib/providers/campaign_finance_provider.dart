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
  Map<String, double> _expenditureCategorySummary = {};

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
  Map<String, double> get expenditureCategorySummary => _expenditureCategorySummary;
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
    _expenditureCategorySummary.clear();
    _error = null;
    notifyListeners();
  }

  // Load candidate finance data by name
  Future<void> loadCandidateByName(String name, {int? cycle}) async {
    _isLoadingCandidate = true;
    _error = null;
    notifyListeners();

    try {
      final candidate = await _fecService.findCandidateByName(name, cycle: cycle);
      
      if (candidate != null) {
        _currentCandidate = candidate;
        notifyListeners();
        
        // Load additional data for this candidate
        await _loadAllCandidateData(candidate.candidateId, cycle: cycle);
      } else {
        _error = 'No campaign finance data found for $name';
      }
    } catch (e) {
      _error = 'Error loading candidate data: $e';
    } finally {
      _isLoadingCandidate = false;
      notifyListeners();
    }
  }

  // Load all data for a candidate
  Future<void> _loadAllCandidateData(String candidateId, {int? cycle}) async {
    // Load all data concurrently
    await Future.wait([
      _loadFinanceSummary(candidateId, cycle: cycle),
      _loadContributions(candidateId, cycle: cycle),
      _loadExpenditures(candidateId, cycle: cycle),
      _loadCommittees(candidateId),
      _loadTopContributors(candidateId, cycle: cycle),
      _loadExpenditureCategorySummary(candidateId, cycle: cycle),
    ]);
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

  // Load expenditure category summary
  Future<void> _loadExpenditureCategorySummary(String candidateId, {int? cycle}) async {
    try {
      _expenditureCategorySummary = await _fecService.getExpenditureCategorySummary(
        candidateId,
        cycle: cycle,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading expenditure categories: $e');
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