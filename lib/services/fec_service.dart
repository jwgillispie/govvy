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
    }
    return key;
  }

  Future<FECCandidate?> findCandidateByName(String name, {int? cycle}) async {
    final apiKey = await _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('FEC API key not configured');
    }


    try {
      // Strategy 1: Direct name search
      var candidate = await _searchCandidateDirectly(name, cycle, apiKey);
      if (candidate != null) {
        return candidate;
      }

      // Strategy 2: Try variations of the name
      final nameVariations = _generateNameVariations(name);
      for (final variation in nameVariations) {
        candidate = await _searchCandidateDirectly(variation, cycle, apiKey);
        if (candidate != null) {
          return candidate;
        }
      }

      // Strategy 3: Search through committees and extract candidate info
      candidate = await _searchCandidateThroughCommittees(name, cycle, apiKey);
      if (candidate != null) {
        return candidate;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<FECCandidate?> _searchCandidateDirectly(String name, int? cycle, String apiKey) async {
    try {
      final queryParams = <String, String>{
        'name': name,
        'api_key': apiKey,
        'sort': '-load_date',
        'per_page': '5',
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
      return null;
    }
  }

  List<String> _generateNameVariations(String name) {
    final variations = <String>[];
    final nameParts = name.trim().split(RegExp(r'\s+'));
    
    if (nameParts.length >= 2) {
      // Try last name only
      variations.add(nameParts.last);
      
      // Try first name + last name
      variations.add('${nameParts.first} ${nameParts.last}');
      
      // Try with common title variations
      variations.add('${nameParts.first} ${nameParts.last}');
      
      // Try different orderings
      if (nameParts.length == 2) {
        variations.add('${nameParts.last}, ${nameParts.first}');
      }
    }
    
    return variations.where((v) => v != name).toList();
  }

  Future<FECCandidate?> _searchCandidateThroughCommittees(String name, int? cycle, String apiKey) async {
    try {
      // Search for committees that might contain the candidate's name
      final queryParams = <String, String>{
        'name': name,
        'api_key': apiKey,
        'per_page': '20',
      };

      if (cycle != null) {
        queryParams['cycle'] = cycle.toString();
      }

      final url = Uri.parse('$_baseUrl/committees/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        
        // Look for committees that match candidate patterns
        for (final committee in results) {
          final committeeName = committee['name']?.toString() ?? '';
          final candidateIds = committee['candidate_ids'] as List? ?? [];
          
          
          // If this committee has candidate IDs, try to get the candidate info
          for (final candidateId in candidateIds) {
            if (candidateId != null) {
              final candidate = await _getCandidateById(candidateId.toString(), apiKey);
              if (candidate != null && _nameMatches(candidate.name, name)) {
                return candidate;
              }
            }
          }
          
          // If no candidate IDs, create a pseudo-candidate from committee info
          if (_committeeNameMatches(committeeName, name)) {
            return FECCandidate(
              candidateId: committee['committee_id']?.toString() ?? '',
              name: _extractCandidateNameFromCommittee(committeeName, name),
              party: committee['party']?.toString(),
              office: 'Unknown',
              state: committee['state']?.toString(),
              electionYear: cycle ?? 2024,
            );
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<FECCandidate?> _getCandidateById(String candidateId, String? apiKey) async {
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }
    
    try {
      final url = Uri.parse('$_baseUrl/candidate/$candidateId/')
          .replace(queryParameters: {'api_key': apiKey});

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
      return null;
    }
  }

  bool _nameMatches(String candidateName, String searchName) {
    final candidate = candidateName.toLowerCase();
    final search = searchName.toLowerCase();
    
    // Exact match
    if (candidate == search) return true;
    
    // Contains all words from search
    final searchWords = search.split(' ');
    return searchWords.every((word) => candidate.contains(word));
  }

  bool _committeeNameMatches(String committeeName, String searchName) {
    final committee = committeeName.toLowerCase();
    final search = searchName.toLowerCase();
    
    final searchWords = search.split(' ');
    // Committee name should contain most of the search words
    final matchingWords = searchWords.where((word) => committee.contains(word)).length;
    return matchingWords >= (searchWords.length * 0.7); // At least 70% of words match
  }

  String _extractCandidateNameFromCommittee(String committeeName, String searchName) {
    // Use the search name as the candidate name since it's what the user searched for
    return searchName;
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

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => CampaignExpenditure.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
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
      return {};
    }
  }

  // Search contributions by contributor name across all committees
  Future<List<CampaignContribution>> searchContributionsByContributor(
    String contributorName, {
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
        'contributor_name': contributorName,
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
        
        final contributions = results.map((json) => CampaignContribution.fromJson(json)).toList();
        
        // Enhance contributions by resolving candidate names for those with IDs but no names
        return await _enhanceContributionsWithCandidateNames(contributions);
      } else {
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  // Enhance contributions by looking up candidate names for those with IDs but no names
  Future<List<CampaignContribution>> _enhanceContributionsWithCandidateNames(
    List<CampaignContribution> contributions
  ) async {
    final enhancedContributions = <CampaignContribution>[];
    final candidateCache = <String, String>{}; // candidateId -> candidateName
    
    for (final contribution in contributions) {
      // If we have a candidate ID but no candidate name, look it up
      if (contribution.candidateId != null && 
          contribution.candidateId!.isNotEmpty &&
          (contribution.candidateName == null || contribution.candidateName!.isEmpty)) {
        
        String? candidateName = candidateCache[contribution.candidateId!];
        
        if (candidateName == null) {
          try {
            final candidate = await _getCandidateById(contribution.candidateId!, await _apiKey);
            candidateName = candidate?.name;
            if (candidateName != null) {
              candidateCache[contribution.candidateId!] = candidateName;
            }
          } catch (e) {
          }
        }
        
        if (candidateName != null) {
          // Create enhanced contribution with resolved candidate name
          enhancedContributions.add(CampaignContribution(
            contributorName: contribution.contributorName,
            contributorEmployer: contribution.contributorEmployer,
            contributorOccupation: contribution.contributorOccupation,
            amount: contribution.amount,
            contributionDate: contribution.contributionDate,
            contributorCity: contribution.contributorCity,
            contributorState: contribution.contributorState,
            contributorZip: contribution.contributorZip,
            imageNumber: contribution.imageNumber,
            receiptType: contribution.receiptType,
            committeeName: contribution.committeeName,
            candidateName: candidateName,
            candidateId: contribution.candidateId,
            committeeId: contribution.committeeId,
          ));
        } else {
          enhancedContributions.add(contribution);
        }
      } else {
        enhancedContributions.add(contribution);
      }
    }
    
    return enhancedContributions;
  }

  // Search for general contributions with flexible filters
  Future<List<CampaignContribution>> searchContributions({
    String? contributorName,
    String? committeeId,
    String? candidateName,
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
        'two_year_transaction_period': (cycle ?? 2024).toString(),
      };

      if (contributorName != null && contributorName.isNotEmpty) {
        queryParams['contributor_name'] = contributorName;
      }
      if (committeeId != null && committeeId.isNotEmpty) {
        queryParams['committee_id'] = committeeId;
      }
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
        
        final contributions = results.map((json) => CampaignContribution.fromJson(json)).toList();
        
        // Enhance contributions by resolving candidate names for those with IDs but no names
        return await _enhanceContributionsWithCandidateNames(contributions);
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  // Election Calendar Methods
  Future<List<FECCalendarEvent>> getElectionCalendar({
    String? state,
    int? year,
    List<int>? categoryIds,
    int page = 1,
    int perPage = 100,
  }) async {
    final apiKey = await _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      // Use DEMO_KEY as fallback for election calendar
      return await _getElectionCalendarWithDemoKey(
        state: state, 
        year: year, 
        categoryIds: categoryIds, 
        page: page, 
        perPage: perPage
      );
    }

    try {
      // If multiple category IDs, make separate calls and combine results
      if (categoryIds != null && categoryIds.length > 1) {
        final allEvents = <FECCalendarEvent>[];
        for (final categoryId in categoryIds) {
          final events = await getElectionCalendar(
            state: state,
            year: year,
            categoryIds: [categoryId],
            page: page,
            perPage: perPage,
          );
          allEvents.addAll(events);
        }
        
        // Sort by start date and return
        allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
        return allEvents;
      }
      
      final queryParams = <String, String>{
        'api_key': apiKey,
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort': 'start_date',
      };

      if (state != null && state.isNotEmpty && state != 'US') {
        queryParams['state'] = state;
      }
      if (year != null) {
        queryParams['min_start_date'] = '$year-01-01';
        queryParams['max_start_date'] = '$year-12-31';
      }
      if (categoryIds != null && categoryIds.isNotEmpty) {
        // FEC API doesn't support multiple category IDs in one call
        // We'll need to call for each category separately and combine results
        if (categoryIds.length == 1) {
          queryParams['calendar_category_id'] = categoryIds.first.toString();
        }
      }

      final url = Uri.parse('$_baseUrl/calendar-dates/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => FECCalendarEvent.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<FECCalendarEvent>> _getElectionCalendarWithDemoKey({
    String? state,
    int? year,
    List<int>? categoryIds,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      // If multiple category IDs, make separate calls and combine results
      if (categoryIds != null && categoryIds.length > 1) {
        final allEvents = <FECCalendarEvent>[];
        for (final categoryId in categoryIds) {
          final events = await _getElectionCalendarWithDemoKey(
            state: state,
            year: year,
            categoryIds: [categoryId],
            page: page,
            perPage: perPage,
          );
          allEvents.addAll(events);
        }
        
        // Sort by start date and return
        allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
        return allEvents;
      }
      
      final queryParams = <String, String>{
        'api_key': 'DEMO_KEY',
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort': 'start_date',
      };

      if (state != null && state.isNotEmpty && state != 'US') {
        queryParams['state'] = state;
      }
      if (year != null) {
        queryParams['min_start_date'] = '$year-01-01';
        queryParams['max_start_date'] = '$year-12-31';
      }
      if (categoryIds != null && categoryIds.isNotEmpty) {
        // FEC API doesn't support multiple category IDs in one call
        // We'll need to call for each category separately and combine results
        if (categoryIds.length == 1) {
          queryParams['calendar_category_id'] = categoryIds.first.toString();
        }
      }

      final url = Uri.parse('$_baseUrl/calendar-dates/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => FECCalendarEvent.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<FECCalendarEvent>> getElectionDates({String? state, int? year}) async {
    // Category ID 36 = Election Dates
    return await getElectionCalendar(
      state: state,
      year: year,
      categoryIds: [36],
    );
  }

  Future<List<FECCalendarEvent>> getReportingDeadlines({String? state, int? year}) async {
    // Category ID 21 = Reporting Deadlines  
    return await getElectionCalendar(
      state: state,
      year: year,
      categoryIds: [21],
    );
  }

  // Elections API endpoints
  Future<List<FECElection>> searchElections({
    String? state,
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
        'sort': '-election_date',
      };

      if (state != null && state.isNotEmpty) {
        queryParams['state'] = state;
      }
      if (office != null && office.isNotEmpty) {
        queryParams['office'] = office;
      }
      if (cycle != null) {
        queryParams['cycle'] = cycle.toString();
      }

      final url = Uri.parse('$_baseUrl/elections/search/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => FECElection.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<FECElection>> getElections({
    String? state,
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
        'sort': '-election_date',
      };

      if (state != null && state.isNotEmpty) {
        queryParams['state'] = state;
      }
      if (cycle != null) {
        queryParams['cycle'] = cycle.toString();
      }

      final url = Uri.parse('$_baseUrl/elections/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        
        return results.map((json) => FECElection.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getElectionSummary({
    String? state,
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

      if (state != null && state.isNotEmpty) {
        queryParams['state'] = state;
      }
      if (cycle != null) {
        queryParams['cycle'] = cycle.toString();
      }

      final url = Uri.parse('$_baseUrl/elections/summary/')
          .replace(queryParameters: queryParams);

      final response = await _networkService.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }

  // Map FEC category codes to human-readable names
}