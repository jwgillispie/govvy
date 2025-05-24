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
      };

      if (cycle != null) {
        queryParams['cycle'] = cycle.toString();
      }

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
      };

      if (cycle != null) {
        queryParams['two_year_transaction_period'] = cycle.toString();
      }
      if (minAmount != null) {
        queryParams['min_amount'] = minAmount.toString();
      }
      if (maxAmount != null) {
        queryParams['max_amount'] = maxAmount.toString();
      }

      final url = Uri.parse('$_baseUrl/schedules/schedule_a/')
          .replace(queryParameters: queryParams..addAll({
            'candidate_id': candidateId,
          }));

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => CampaignContribution.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting candidate contributions: $e');
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
      };

      if (cycle != null) {
        queryParams['two_year_transaction_period'] = cycle.toString();
      }
      if (minAmount != null) {
        queryParams['min_amount'] = minAmount.toString();
      }
      if (maxAmount != null) {
        queryParams['max_amount'] = maxAmount.toString();
      }

      final url = Uri.parse('$_baseUrl/schedules/schedule_b/')
          .replace(queryParameters: queryParams..addAll({
            'candidate_id': candidateId,
          }));

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
    final contributions = await getCandidateContributions(
      candidateId,
      cycle: cycle,
      perPage: 1000, // Get more to find top contributors
    );

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
  }

  Future<Map<String, double>> getExpenditureCategorySummary(
    String candidateId, {
    int? cycle,
  }) async {
    final expenditures = await getCandidateExpenditures(
      candidateId,
      cycle: cycle,
      perPage: 1000, // Get more transactions for better summary
    );

    final Map<String, double> categorySums = {};

    for (final expenditure in expenditures) {
      final rawCategory = expenditure.category ?? 'other';
      final friendlyCategory = _getFriendlyCategoryName(rawCategory);
      categorySums[friendlyCategory] = (categorySums[friendlyCategory] ?? 0) + expenditure.amount;
    }

    return categorySums;
  }

  // Map FEC category codes to human-readable names
  String _getFriendlyCategoryName(String categoryCode) {
    final Map<String, String> categoryMapping = {
      '001': 'Administrative/Salary/Benefits',
      '002': 'Travel/Lodging/Meals', 
      '003': 'Equipment/Office/Technology',
      '004': 'Communications/Media',
      '005': 'Fundraising Events',
      '006': 'Voter Outreach/Mobilization',
      '007': 'Polling/Research',
      '008': 'Legal/Accounting/Compliance',
      '009': 'Rent/Utilities/Office Space',
      '010': 'Advertising (General)',
      '011': 'Advertising (Media Buy)',
      '012': 'Campaign Materials/Literature',
      '013': 'Postage/Shipping',
      '014': 'Event Production/Staging',
      '015': 'Consulting/Strategy',
      '016': 'Data/Analytics/Technology',
      '017': 'Security Services',
      '018': 'Transportation/Vehicle',
      '019': 'Volunteer Coordination',
      '020': 'Campaign Merchandise',
      'other': 'Other Campaign Expenses',
      'oth': 'Other Campaign Expenses',
    };

    return categoryMapping[categoryCode.toLowerCase()] ?? 
           '${categoryCode.toUpperCase()} - Unknown Category';
  }
}