class FECCandidate {
  final String candidateId;
  final String name;
  final String? party;
  final String? office;
  final String? state;
  final String? district;
  final int? electionYear;
  final bool? isIncumbent;
  final String? status;

  FECCandidate({
    required this.candidateId,
    required this.name,
    this.party,
    this.office,
    this.state,
    this.district,
    this.electionYear,
    this.isIncumbent,
    this.status,
  });

  factory FECCandidate.fromJson(Map<String, dynamic> json) {
    return FECCandidate(
      candidateId: json['candidate_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      party: json['party']?.toString(),
      office: json['office']?.toString(),
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      electionYear: json['election_years'] is List && (json['election_years'] as List).isNotEmpty 
          ? _getMostRelevantElectionYear(json['election_years'] as List)
          : json['election_year'],
      isIncumbent: json['incumbent_challenge'] == 'I',
      status: json['candidate_status']?.toString(),
    );
  }

  static int _getMostRelevantElectionYear(List electionYears) {
    final currentYear = DateTime.now().year;
    final years = electionYears.cast<int>();
    
    // Find the most recent election year that's not too far in the future
    // Prefer current or recent years over distant future years
    final sortedYears = years.toList()..sort();
    
    // If current year is an election year, use it
    if (sortedYears.contains(currentYear)) {
      return currentYear;
    }
    
    // Find the most recent past election year
    final pastYears = sortedYears.where((year) => year <= currentYear).toList();
    if (pastYears.isNotEmpty) {
      return pastYears.last;
    }
    
    // If no past years, find the nearest future year that's reasonable (within 6 years)
    final nearFutureYears = sortedYears.where((year) => year > currentYear && year <= currentYear + 6).toList();
    if (nearFutureYears.isNotEmpty) {
      return nearFutureYears.first;
    }
    
    // Fallback to the first year in the list
    return sortedYears.first;
  }
}

class CampaignContribution {
  final String contributorName;
  final String? contributorEmployer;
  final String? contributorOccupation;
  final double amount;
  final DateTime? contributionDate;
  final String? contributorCity;
  final String? contributorState;
  final String? contributorZip;
  final String? imageNumber;
  final String? receiptType;
  final String? committeeName;
  final String? candidateName;
  final String? candidateId;
  final String? committeeId;

  CampaignContribution({
    required this.contributorName,
    this.contributorEmployer,
    this.contributorOccupation,
    required this.amount,
    this.contributionDate,
    this.contributorCity,
    this.contributorState,
    this.contributorZip,
    this.imageNumber,
    this.receiptType,
    this.committeeName,
    this.candidateName,
    this.candidateId,
    this.committeeId,
  });

  factory CampaignContribution.fromJson(Map<String, dynamic> json) {
    // Extract committee information
    final committee = json['committee'] as Map<String, dynamic>?;
    final committeeName = committee?['name']?.toString() ?? json['committee_name']?.toString();
    final committeeId = json['committee_id']?.toString();
    
    // Extract candidate information - prioritize direct candidate data, then committee candidate_ids
    String? candidateName = json['candidate_name']?.toString();
    String? candidateId = json['candidate_id']?.toString();
    
    // If no direct candidate info, try to get from committee
    if ((candidateName == null || candidateName.isEmpty) && committee != null) {
      final candidateIds = committee['candidate_ids'] as List?;
      if (candidateIds != null && candidateIds.isNotEmpty) {
        candidateId = candidateIds.first?.toString();
      }
    }
    
    return CampaignContribution(
      contributorName: json['contributor_name']?.toString() ?? '',
      contributorEmployer: json['contributor_employer']?.toString(),
      contributorOccupation: json['contributor_occupation']?.toString(),
      amount: (json['contribution_receipt_amount'] ?? 0.0).toDouble(),
      contributionDate: json['contribution_receipt_date'] != null
          ? DateTime.tryParse(json['contribution_receipt_date'].toString())
          : null,
      contributorCity: json['contributor_city']?.toString(),
      contributorState: json['contributor_state']?.toString(),
      contributorZip: json['contributor_zip']?.toString(),
      imageNumber: json['image_number']?.toString(),
      receiptType: json['receipt_type']?.toString(),
      committeeName: committeeName,
      candidateName: candidateName,
      candidateId: candidateId,
      committeeId: committeeId,
    );
  }
}

class CampaignExpenditure {
  final String recipientName;
  final double amount;
  final DateTime? expenditureDate;
  final String? purpose;
  final String? category;
  final String? recipientCity;
  final String? recipientState;
  final String? imageNumber;

  CampaignExpenditure({
    required this.recipientName,
    required this.amount,
    this.expenditureDate,
    this.purpose,
    this.category,
    this.recipientCity,
    this.recipientState,
    this.imageNumber,
  });

  factory CampaignExpenditure.fromJson(Map<String, dynamic> json) {
    return CampaignExpenditure(
      recipientName: json['recipient_name']?.toString() ?? '',
      amount: (json['disbursement_amount'] ?? 0.0).toDouble(),
      expenditureDate: json['disbursement_date'] != null
          ? DateTime.tryParse(json['disbursement_date'].toString())
          : null,
      purpose: json['disbursement_description']?.toString(),
      category: json['category_code']?.toString(),
      recipientCity: json['recipient_city']?.toString(),
      recipientState: json['recipient_state']?.toString(),
      imageNumber: json['image_number']?.toString(),
    );
  }
}

class CampaignFinanceSummary {
  final String candidateId;
  final String candidateName;
  final int cycle;
  final double totalRaised;
  final double totalSpent;
  final double cashOnHand;
  final double totalDebt;
  final DateTime? coverageEndDate;
  final int individualContributionsCount;
  final double individualContributionsTotal;

  CampaignFinanceSummary({
    required this.candidateId,
    required this.candidateName,
    required this.cycle,
    required this.totalRaised,
    required this.totalSpent,
    required this.cashOnHand,
    required this.totalDebt,
    this.coverageEndDate,
    required this.individualContributionsCount,
    required this.individualContributionsTotal,
  });

  factory CampaignFinanceSummary.fromJson(Map<String, dynamic> json) {
    return CampaignFinanceSummary(
      candidateId: json['candidate_id']?.toString() ?? '',
      candidateName: json['candidate_name']?.toString() ?? '',
      cycle: (json['cycle'] is int) 
          ? json['cycle'] 
          : (json['cycle'] ?? 0.0).toDouble().toInt(),
      totalRaised: (json['receipts'] ?? 0.0).toDouble(),
      totalSpent: (json['disbursements'] ?? 0.0).toDouble(),
      cashOnHand: (json['last_cash_on_hand_end_period'] ?? 0.0).toDouble(),
      totalDebt: (json['last_debts_owed_by_committee'] ?? 0.0).toDouble(),
      coverageEndDate: json['coverage_end_date'] != null
          ? DateTime.tryParse(json['coverage_end_date'].toString())
          : null,
      individualContributionsCount: (json['individual_itemized_contributions'] is int) 
          ? json['individual_itemized_contributions'] 
          : (json['individual_itemized_contributions'] ?? 0.0).toDouble().toInt(),
      individualContributionsTotal: (json['individual_contributions'] ?? 0.0).toDouble(),
    );
  }
}

class CommitteeInfo {
  final String committeeId;
  final String name;
  final String? treasurerName;
  final String? designation;
  final String? committeeType;
  final String? state;
  final String? party;
  final DateTime? firstFileDate;
  final DateTime? lastFileDate;

  CommitteeInfo({
    required this.committeeId,
    required this.name,
    this.treasurerName,
    this.designation,
    this.committeeType,
    this.state,
    this.party,
    this.firstFileDate,
    this.lastFileDate,
  });

  factory CommitteeInfo.fromJson(Map<String, dynamic> json) {
    return CommitteeInfo(
      committeeId: json['committee_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      treasurerName: json['treasurer_name']?.toString(),
      designation: json['designation']?.toString(),
      committeeType: json['committee_type']?.toString(),
      state: json['state']?.toString(),
      party: json['party']?.toString(),
      firstFileDate: json['first_file_date'] != null
          ? DateTime.tryParse(json['first_file_date'].toString())
          : null,
      lastFileDate: json['last_file_date'] != null
          ? DateTime.tryParse(json['last_file_date'].toString())
          : null,
    );
  }
}

class FECSearchResponse<T> {
  final List<T> results;
  final int totalCount;
  final int page;
  final int perPage;

  FECSearchResponse({
    required this.results,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory FECSearchResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final resultsJson = json['results'] as List? ?? [];
    return FECSearchResponse(
      results: resultsJson.map((item) => fromJsonT(item)).toList(),
      totalCount: json['pagination']?['count'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      perPage: json['pagination']?['per_page'] ?? 20,
    );
  }
}

class FECCalendarEvent {
  final int eventId;
  final String summary;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool allDay;
  final int? categoryId;
  final String? category;
  final String? location;
  final List<String>? states;
  final String? url;

  FECCalendarEvent({
    required this.eventId,
    required this.summary,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.allDay,
    this.categoryId,
    this.category,
    this.location,
    this.states,
    this.url,
  });

  factory FECCalendarEvent.fromJson(Map<String, dynamic> json) {
    return FECCalendarEvent(
      eventId: json['event_id'] ?? 0,
      summary: json['summary']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      allDay: json['all_day'] ?? false,
      categoryId: json['calendar_category_id'],
      category: json['category']?.toString(),
      location: json['location']?.toString(),
      states: json['state'] != null ? List<String>.from(json['state']) : null,
      url: json['url']?.toString(),
    );
  }

  String get categoryDisplayName {
    switch (categoryId) {
      case 36:
        return 'Election Date';
      case 21:
        return 'Reporting Deadline';
      case 20:
        return 'Commission Meeting';
      case 32:
        return 'Open Meeting';
      case 39:
        return 'Executive Session';
      case 40:
        return 'Public Hearing';
      case 37:
        return 'Federal Holiday';
      case 38:
        return 'FEA Period';
      case 27:
        return 'Pre/Post-Election';
      case 28:
        return 'EC Period';
      case 29:
        return 'IE Period';
      default:
        return category ?? 'Event';
    }
  }

  bool get isElectionDate => categoryId == 36;
  bool get isReportingDeadline => categoryId == 21;
  bool get isCommissionMeeting => categoryId == 20;
}

class FECElection {
  final String electionId;
  final String state;
  final String? district;
  final String? office;
  final String? electionType;
  final DateTime? electionDate;
  final int? cycle;
  final bool? primaryGeneral;
  final String? updateDate;

  FECElection({
    required this.electionId,
    required this.state,
    this.district,
    this.office,
    this.electionType,
    this.electionDate,
    this.cycle,
    this.primaryGeneral,
    this.updateDate,
  });

  factory FECElection.fromJson(Map<String, dynamic> json) {
    return FECElection(
      electionId: json['election_id']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString(),
      office: json['office']?.toString(),
      electionType: json['election_type']?.toString(),
      electionDate: json['election_date'] != null 
          ? DateTime.tryParse(json['election_date'].toString())
          : null,
      cycle: json['cycle'],
      primaryGeneral: json['primary_general'],
      updateDate: json['update_date']?.toString(),
    );
  }

  String get officeName {
    switch (office) {
      case 'P':
        return 'President';
      case 'S':
        return 'Senate';
      case 'H':
        return 'House';
      default:
        return office ?? 'Unknown Office';
    }
  }

  String get electionTypeName {
    switch (electionType) {
      case 'G':
        return 'General';
      case 'P':
        return 'Primary';
      case 'R':
        return 'Runoff';
      case 'S':
        return 'Special';
      default:
        return electionType ?? 'Unknown';
    }
  }

  bool get isUpcoming => electionDate?.isAfter(DateTime.now()) ?? false;
  bool get isPast => electionDate?.isBefore(DateTime.now()) ?? false;
  bool get isToday => electionDate != null && 
      electionDate!.year == DateTime.now().year &&
      electionDate!.month == DateTime.now().month &&
      electionDate!.day == DateTime.now().day;
}