import 'dart:convert';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:govvy/models/campaign_finance_model.dart';

class FECService {
  static final FECService _instance = FECService._internal();
  factory FECService() => _instance;
  FECService._internal();

  final NetworkService _networkService = NetworkService();
  final RemoteConfigService _configService = RemoteConfigService();

  static const String _baseUrl = 'https://api.open.fec.gov/v1';

  Future<String?> get _apiKey async {
    // Ensure remote config is initialized
    await _configService.initialize();
    
    final key = _configService.getFecApiKey;
    if (key == null || key.isEmpty) {
      print('DEBUG: FEC API key is null or empty');
      print('DEBUG: Remote config initialized: $_configService');
    }
    return key;
  }

  Future<FECCandidate?> findCandidateByName(String name, {int? cycle}) async {
    final apiKey = await _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('FEC API key not configured');
    }

    try {
      final queryParams = <String, String>{
        'name': name,
        'api_key': apiKey,
        'sort': '-load_date',
        'per_page': '1',
      };

      if (cycle != null) {
        queryParams['cycle'] = cycle.toString();
      }

      final url = Uri.parse('$_baseUrl/candidates/search/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        
        if (results != null && results.isNotEmpty) {
          return FECCandidate.fromJson(results.first);
        }
      }
      return null;
    } catch (e) {
      print('Error finding candidate by name: $e');
      return null;
    }
  }

  Future<List<FECCandidate>> searchCandidates({
    String? name,
    String? state,
    String? party,
    String? office,
    int? cycle,
    int page = 1,
    int perPage = 20,
  }) async {
    final apiKey = await _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('FEC API key not configured');
    }

    try {
      final queryParams = <String, String>{
        'api_key': apiKey,
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort': '-load_date',
      };

      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }
      if (state != null && state.isNotEmpty) {
        queryParams['state'] = state;
      }
      if (party != null && party.isNotEmpty) {
        queryParams['party'] = party;
      }
      if (office != null && office.isNotEmpty) {
        queryParams['office'] = office;
      }
      if (cycle != null) {
        queryParams['cycle'] = cycle.toString();
      }

      final url = Uri.parse('$_baseUrl/candidates/search/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => FECCandidate.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error searching candidates: $e');
      return [];
    }
  }

  Future<CampaignFinanceSummary?> getCandidateFinanceSummary(
    String candidateId, {
    int? cycle,
  }) async {
    final apiKey = await _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('FEC API key not configured');
    }

    try {
      final queryParams = <String, String>{
        'api_key': apiKey,
        'cycle': (cycle ?? 2024).toString(), // Always include cycle - default to 2024
      };

      final url = Uri.parse('$_baseUrl/candidate/$candidateId/totals/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        
        if (results != null && results.isNotEmpty) {
          return CampaignFinanceSummary.fromJson(results.first);
        }
      }
      return null;
    } catch (e) {
      print('Error getting candidate finance summary: $e');
      return null;
    }
  }

  Future<List<CampaignContribution>> getCandidateContributions(
    String candidateId, {
    int? cycle,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int perPage = 20,
  }) async {
    // Get contributions through the candidate's committees
    try {
      final committees = await getCandidateCommittees(candidateId);
      if (committees.isEmpty) {
        return [];
      }

      // Get the most relevant committee (prefer principal campaign committees)
      CommitteeInfo? primaryCommittee;
      
      // First try to find a principal campaign committee
      for (final committee in committees) {
        if (committee.designation == 'P') {
          primaryCommittee = committee;
          break;
        }
      }
      
      // If no principal committee found, use the first committee
      primaryCommittee ??= committees.first;
      return await getCommitteeContributions(
        primaryCommittee.committeeId,
        cycle: cycle,
        minAmount: minAmount,
        maxAmount: maxAmount,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      print('Error getting candidate contributions: $e');
      return [];
    }
  }

  Future<List<CampaignContribution>> getCommitteeContributions(
    String committeeId, {
    int? cycle,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int perPage = 20,
  }) async {
    final apiKey = await _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('FEC API key not configured');
    }

    try {
      final queryParams = <String, String>{
        'api_key': apiKey,
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort': '-contribution_receipt_date',
        'committee_id': committeeId,
        'two_year_transaction_period': (cycle ?? 2024).toString(),
      };

      if (minAmount != null) {
        queryParams['min_amount'] = minAmount.toString();
      }
      if (maxAmount != null) {
        queryParams['max_amount'] = maxAmount.toString();
      }

      final url = Uri.parse('$_baseUrl/schedules/schedule_a/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => CampaignContribution.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting committee contributions: $e');
      return [];
    }
  }

  Future<List<CampaignExpenditure>> getCandidateExpenditures(
    String candidateId, {
    int? cycle,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int perPage = 20,
  }) async {
    final apiKey = await _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('FEC API key not configured');
    }

    try {
      final queryParams = <String, String>{
        'api_key': apiKey,
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort': '-disbursement_date',
        'candidate_id': candidateId,
        'two_year_transaction_period': (cycle ?? 2024).toString(), // Always include cycle
      };

      if (minAmount != null) {
        queryParams['min_amount'] = minAmount.toString();
      }
      if (maxAmount != null) {
        queryParams['max_amount'] = maxAmount.toString();
      }

      final url = Uri.parse('$_baseUrl/schedules/schedule_b/')
          .replace(queryParameters: queryParams);

      print('FECService: Expenditures API call for $candidateId: $url');
      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => CampaignExpenditure.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting candidate expenditures: $e');
      return [];
    }
  }

  Future<List<CommitteeInfo>> getCandidateCommittees(String candidateId) async {
    final apiKey = await _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('FEC API key not configured');
    }

    try {
      final queryParams = <String, String>{
        'api_key': apiKey,
        'candidate_id': candidateId,
      };

      final url = Uri.parse('$_baseUrl/candidate/$candidateId/committees/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => CommitteeInfo.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting candidate committees: $e');
      return [];
    }
  }

  Future<List<CampaignContribution>> getTopContributors(
    String candidateId, {
    int? cycle,
    int limit = 10,
  }) async {
    try {
      // First get the candidate's committees
      final committees = await getCandidateCommittees(candidateId);
      if (committees.isEmpty) {
        return [];
      }

      // Get the most relevant committee (prefer principal campaign committees)
      CommitteeInfo? primaryCommittee;
      
      // First try to find a principal campaign committee
      for (final committee in committees) {
        if (committee.designation == 'P') {
          primaryCommittee = committee;
          break;
        }
      }
      
      // If no principal committee found, use the first committee
      primaryCommittee ??= committees.first;
      final contributions = await getCommitteeContributions(
        primaryCommittee.committeeId,
        cycle: cycle ?? 2024,
        perPage: 50,
      );

      if (contributions.isEmpty) {
        return [];
      }

      // Group by contributor name and sum amounts
      final Map<String, double> contributorTotals = {};
      final Map<String, CampaignContribution> contributorInfo = {};

      for (final contribution in contributions) {
        final name = contribution.contributorName;
        contributorTotals[name] = (contributorTotals[name] ?? 0) + contribution.amount;
        contributorInfo[name] = contribution;
      }

      // Sort by total amount and return top contributors
      final sortedContributors = contributorTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedContributors
          .take(limit)
          .map((entry) => contributorInfo[entry.key]!)
          .toList();
    } catch (e) {
      print('Error getting top contributors: $e');
      return [];
    }
  }


  // New method to get geographic contribution distribution
  Future<Map<String, double>> getContributionsByState(
    String candidateId, {
    int? cycle,
  }) async {
    try {
      final committees = await getCandidateCommittees(candidateId);
      if (committees.isEmpty) {
        return {};
      }

      // Get the most relevant committee (prefer principal campaign committees)
      CommitteeInfo? primaryCommittee;
      
      // First try to find a principal campaign committee
      for (final committee in committees) {
        if (committee.designation == 'P') {
          primaryCommittee = committee;
          break;
        }
      }
      
      // If no principal committee found, use the first committee
      primaryCommittee ??= committees.first;
      final contributions = await getCommitteeContributions(
        primaryCommittee.committeeId,
        cycle: cycle ?? 2024,
        perPage: 50,
      );

      final Map<String, double> stateContributions = {};
      for (final contribution in contributions) {
        final state = contribution.contributorState ?? 'Unknown';
        stateContributions[state] = (stateContributions[state] ?? 0) + contribution.amount;
      }

      return stateContributions;
    } catch (e) {
      print('Error getting contributions by state: $e');
      return {};
    }
  }

  // New method to get contribution patterns by amount ranges
  Future<Map<String, int>> getContributionAmountDistribution(
    String candidateId, {
    int? cycle,
  }) async {
    try {
      final committees = await getCandidateCommittees(candidateId);
      if (committees.isEmpty) {
        return {};
      }

      // Get the most relevant committee (prefer principal campaign committees)
      CommitteeInfo? primaryCommittee;
      
      // First try to find a principal campaign committee
      for (final committee in committees) {
        if (committee.designation == 'P') {
          primaryCommittee = committee;
          break;
        }
      }
      
      // If no principal committee found, use the first committee
      primaryCommittee ??= committees.first;
      final contributions = await getCommitteeContributions(
        primaryCommittee.committeeId,
        cycle: cycle ?? 2024,
        perPage: 50,
      );

      final Map<String, int> distribution = {
        'Small (\$1-\$200)': 0,
        'Medium (\$201-\$1000)': 0,
        'Large (\$1001-\$2900)': 0,
        'Max (\$2900+)': 0,
      };

      for (final contribution in contributions) {
        if (contribution.amount <= 200) {
          distribution['Small (\$1-\$200)'] = distribution['Small (\$1-\$200)']! + 1;
        } else if (contribution.amount <= 1000) {
          distribution['Medium (\$201-\$1000)'] = distribution['Medium (\$201-\$1000)']! + 1;
        } else if (contribution.amount <= 2900) {
          distribution['Large (\$1001-\$2900)'] = distribution['Large (\$1001-\$2900)']! + 1;
        } else {
          distribution['Max (\$2900+)'] = distribution['Max (\$2900+)']! + 1;
        }
      }

      return distribution;
    } catch (e) {
      print('Error getting contribution distribution: $e');
      return {};
    }
  }

  // New method to get monthly fundraising trends
  Future<Map<String, double>> getMonthlyFundraisingTrends(
    String candidateId, {
    int? cycle,
  }) async {
    try {
      final committees = await getCandidateCommittees(candidateId);
      if (committees.isEmpty) {
        return {};
      }

      // Get the most relevant committee (prefer principal campaign committees)
      CommitteeInfo? primaryCommittee;
      
      // First try to find a principal campaign committee
      for (final committee in committees) {
        if (committee.designation == 'P') {
          primaryCommittee = committee;
          break;
        }
      }
      
      // If no principal committee found, use the first committee
      primaryCommittee ??= committees.first;
      final contributions = await getCommitteeContributions(
        primaryCommittee.committeeId,
        cycle: cycle ?? 2024,
        perPage: 50, // Max allowed per page
      );

      final Map<String, double> monthlyTotals = {};
      for (final contribution in contributions) {
        if (contribution.contributionDate != null) {
          final monthKey = '${contribution.contributionDate!.year}-${contribution.contributionDate!.month.toString().padLeft(2, '0')}';
          monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + contribution.amount;
        }
      }

      return monthlyTotals;
    } catch (e) {
      print('Error getting monthly trends: $e');
      return {};
    }
  }

  // Map FEC category codes to human-readable names
}