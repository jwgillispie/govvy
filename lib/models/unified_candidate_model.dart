import 'package:govvy/models/campaign_finance_model.dart';
import 'package:govvy/services/follow_the_money_service.dart';

enum DataSource {
  fec('FEC', 'Federal Election Commission'),
  followTheMoney('FTM', 'Follow the Money'),
  stateSpecific('State', 'State Election Commission'),
  ballotpedia('BP', 'Ballotpedia');

  const DataSource(this.code, this.fullName);
  final String code;
  final String fullName;
}

enum OfficeLevel {
  federal('Federal'),
  state('State'),
  local('Local');

  const OfficeLevel(this.displayName);
  final String displayName;
}

class UnifiedCandidate {
  final String id;
  final String name;
  final String office;
  final String state;
  final String party;
  final int cycle;
  final OfficeLevel level;
  final DataSource primarySource;
  final List<DataSource> availableSources;
  final String? district;
  final String? county;
  final bool isIncumbent;
  final DateTime lastUpdated;

  // Original source data for fallback
  final FECCandidate? fecData;
  final FollowTheMoneyCandidate? ftmData;

  UnifiedCandidate({
    required this.id,
    required this.name,
    required this.office,
    required this.state,
    required this.party,
    required this.cycle,
    required this.level,
    required this.primarySource,
    required this.availableSources,
    this.district,
    this.county,
    this.isIncumbent = false,
    DateTime? lastUpdated,
    this.fecData,
    this.ftmData,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Factory constructor for FEC candidates
  factory UnifiedCandidate.fromFEC(FECCandidate fecCandidate) {
    return UnifiedCandidate(
      id: 'fec_${fecCandidate.candidateId}',
      name: fecCandidate.name,
      office: fecCandidate.office ?? 'Federal Office',
      state: fecCandidate.state ?? 'Unknown',
      party: fecCandidate.party ?? 'Unknown',
      cycle: fecCandidate.electionYear ?? 2024,
      level: OfficeLevel.federal,
      primarySource: DataSource.fec,
      availableSources: [DataSource.fec],
      district: fecCandidate.district,
      isIncumbent: fecCandidate.isIncumbent ?? false,
      fecData: fecCandidate,
    );
  }

  // Factory constructor for Follow the Money candidates
  factory UnifiedCandidate.fromFollowTheMoney(FollowTheMoneyCandidate ftmCandidate) {
    OfficeLevel level;
    switch (ftmCandidate.level) {
      case 'federal':
        level = OfficeLevel.federal;
        break;
      case 'state':
        level = OfficeLevel.state;
        break;
      case 'local':
        level = OfficeLevel.local;
        break;
      default:
        level = OfficeLevel.state;
    }

    return UnifiedCandidate(
      id: 'ftm_${ftmCandidate.candidateId}',
      name: ftmCandidate.name,
      office: ftmCandidate.displayOffice,
      state: ftmCandidate.state,
      party: ftmCandidate.party,
      cycle: ftmCandidate.cycle,
      level: level,
      primarySource: DataSource.followTheMoney,
      availableSources: [DataSource.followTheMoney],
      district: ftmCandidate.district,
      county: ftmCandidate.county,
      isIncumbent: ftmCandidate.isIncumbent,
      ftmData: ftmCandidate,
    );
  }

  String get displayName {
    final parts = <String>[name];
    
    if (district != null) {
      parts.add('District $district');
    }
    
    parts.add('($party)');
    
    return parts.join(' ');
  }

  String get officeWithLevel {
    return '${level.displayName} - $office';
  }

  String get dataSourceLabel {
    if (availableSources.length > 1) {
      return '${primarySource.code} +${availableSources.length - 1}';
    }
    return primarySource.code;
  }

  String get sourceTooltip {
    if (availableSources.length == 1) {
      return primarySource.fullName;
    }
    
    final sources = availableSources.map((s) => s.fullName).join(', ');
    return 'Primary: ${primarySource.fullName}\nAlso available: $sources';
  }

  bool get hasMultipleSources => availableSources.length > 1;

  // Helper to get the appropriate candidate ID for different services
  String getCandidateIdForSource(DataSource source) {
    switch (source) {
      case DataSource.fec:
        return fecData?.candidateId ?? id.replaceFirst('fec_', '');
      case DataSource.followTheMoney:
        return ftmData?.candidateId ?? id.replaceFirst('ftm_', '');
      default:
        return id;
    }
  }
}

class UnifiedFinanceData {
  final String candidateId;
  final DataSource source;
  final double totalRaised;
  final double totalSpent;
  final double cashOnHand;
  final int contributionCount;
  final int cycle;
  final Map<String, double> topContributorTypes;
  final DateTime lastUpdated;
  final String? dataQualityNote;

  // Original source data for reference
  final CampaignFinanceSummary? fecSummary;
  final FollowTheMoneyFinance? ftmFinance;
  final List<CampaignContribution>? fecContributions;
  final List<CampaignExpenditure>? fecExpenditures;

  UnifiedFinanceData({
    required this.candidateId,
    required this.source,
    required this.totalRaised,
    required this.totalSpent,
    required this.cashOnHand,
    required this.contributionCount,
    required this.cycle,
    required this.topContributorTypes,
    DateTime? lastUpdated,
    this.dataQualityNote,
    this.fecSummary,
    this.ftmFinance,
    this.fecContributions,
    this.fecExpenditures,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Factory constructor for FEC data
  factory UnifiedFinanceData.fromFEC({
    required String candidateId,
    required CampaignFinanceSummary summary,
    required List<CampaignContribution> contributions,
    required List<CampaignExpenditure> expenditures,
    required int cycle,
  }) {
    // Calculate contributor types from contributions
    final contributorTypes = <String, double>{};
    for (final contribution in contributions) {
      final type = contribution.contributorEmployer?.isNotEmpty == true 
          ? 'Business' 
          : 'Individual';
      contributorTypes[type] = (contributorTypes[type] ?? 0) + contribution.amount;
    }

    return UnifiedFinanceData(
      candidateId: candidateId,
      source: DataSource.fec,
      totalRaised: summary.totalRaised,
      totalSpent: summary.totalSpent,
      cashOnHand: summary.cashOnHand,
      contributionCount: contributions.length,
      cycle: cycle,
      topContributorTypes: contributorTypes,
      dataQualityNote: 'Complete federal campaign finance data',
      fecSummary: summary,
      fecContributions: contributions,
      fecExpenditures: expenditures,
    );
  }

  // Factory constructor for Follow the Money data
  factory UnifiedFinanceData.fromFollowTheMoney(FollowTheMoneyFinance ftmFinance) {
    return UnifiedFinanceData(
      candidateId: ftmFinance.candidateId,
      source: DataSource.followTheMoney,
      totalRaised: ftmFinance.totalRaised,
      totalSpent: ftmFinance.totalSpent,
      cashOnHand: ftmFinance.cashOnHand,
      contributionCount: ftmFinance.contributionCount,
      cycle: ftmFinance.cycle,
      topContributorTypes: ftmFinance.topContributorTypes,
      dataQualityNote: 'State/local campaign finance data',
      ftmFinance: ftmFinance,
    );
  }

  String get formattedTotalRaised => _formatCurrency(totalRaised);
  String get formattedTotalSpent => _formatCurrency(totalSpent);
  String get formattedCashOnHand => _formatCurrency(cashOnHand);

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  double? get spendingEfficiency {
    if (totalRaised == 0) return null;
    return totalSpent / totalRaised;
  }

  bool get hasSignificantActivity {
    return totalRaised > 1000 || totalSpent > 1000;
  }

  String get dataSourceLabel => source.code;
  String get dataSourceFullName => source.fullName;
}

class CandidateSearchResult {
  final UnifiedCandidate candidate;
  final double relevanceScore;
  final String matchType; // 'exact', 'partial', 'fuzzy'
  final List<String> matchedFields; // ['name', 'office', 'state']

  CandidateSearchResult({
    required this.candidate,
    required this.relevanceScore,
    required this.matchType,
    required this.matchedFields,
  });
}