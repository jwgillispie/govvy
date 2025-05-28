class Election {
  final String id;
  final String name;
  final String description;
  final DateTime electionDate;
  final String state;
  final String city;
  final String county;
  final String electionType;
  final List<Contest> contests;
  final String status;
  final String? registrationDeadline;
  final String? earlyVotingStart;
  final String? earlyVotingEnd;
  final List<PollingLocation> pollingLocations;

  Election({
    required this.id,
    required this.name,
    required this.description,
    required this.electionDate,
    required this.state,
    required this.city,
    required this.county,
    required this.electionType,
    required this.contests,
    required this.status,
    this.registrationDeadline,
    this.earlyVotingStart,
    this.earlyVotingEnd,
    required this.pollingLocations,
  });

  factory Election.fromJson(Map<String, dynamic> json) {
    return Election(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      electionDate: DateTime.tryParse(json['electionDate'] ?? '') ?? DateTime.now(),
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      county: json['county'] ?? '',
      electionType: json['electionType'] ?? '',
      contests: (json['contests'] as List<dynamic>?)
          ?.map((contest) => Contest.fromJson(contest))
          .toList() ?? [],
      status: json['status'] ?? '',
      registrationDeadline: json['registrationDeadline'],
      earlyVotingStart: json['earlyVotingStart'],
      earlyVotingEnd: json['earlyVotingEnd'],
      pollingLocations: (json['pollingLocations'] as List<dynamic>?)
          ?.map((location) => PollingLocation.fromJson(location))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'electionDate': electionDate.toIso8601String(),
      'state': state,
      'city': city,
      'county': county,
      'electionType': electionType,
      'contests': contests.map((contest) => contest.toJson()).toList(),
      'status': status,
      'registrationDeadline': registrationDeadline,
      'earlyVotingStart': earlyVotingStart,
      'earlyVotingEnd': earlyVotingEnd,
      'pollingLocations': pollingLocations.map((location) => location.toJson()).toList(),
    };
  }

  bool get isUpcoming => electionDate.isAfter(DateTime.now());
  bool get isPast => electionDate.isBefore(DateTime.now());
  bool get isToday => 
      electionDate.year == DateTime.now().year &&
      electionDate.month == DateTime.now().month &&
      electionDate.day == DateTime.now().day;

  int get daysUntilElection => 
      isUpcoming ? electionDate.difference(DateTime.now()).inDays : 0;
}

class Contest {
  final String id;
  final String office;
  final String district;
  final String level;
  final List<Candidate> candidates;
  final String contestType;
  final int? numberToElect;

  Contest({
    required this.id,
    required this.office,
    required this.district,
    required this.level,
    required this.candidates,
    required this.contestType,
    this.numberToElect,
  });

  factory Contest.fromJson(Map<String, dynamic> json) {
    return Contest(
      id: json['id'] ?? '',
      office: json['office'] ?? '',
      district: json['district'] ?? '',
      level: json['level'] ?? '',
      candidates: (json['candidates'] as List<dynamic>?)
          ?.map((candidate) => Candidate.fromJson(candidate))
          .toList() ?? [],
      contestType: json['contestType'] ?? '',
      numberToElect: json['numberToElect'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'office': office,
      'district': district,
      'level': level,
      'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
      'contestType': contestType,
      'numberToElect': numberToElect,
    };
  }
}

class Candidate {
  final String id;
  final String name;
  final String party;
  final String? photoUrl;
  final String? candidateUrl;
  final String? email;
  final String? phone;
  final bool isIncumbent;

  Candidate({
    required this.id,
    required this.name,
    required this.party,
    this.photoUrl,
    this.candidateUrl,
    this.email,
    this.phone,
    required this.isIncumbent,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      party: json['party'] ?? '',
      photoUrl: json['photoUrl'],
      candidateUrl: json['candidateUrl'],
      email: json['email'],
      phone: json['phone'],
      isIncumbent: json['isIncumbent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'party': party,
      'photoUrl': photoUrl,
      'candidateUrl': candidateUrl,
      'email': email,
      'phone': phone,
      'isIncumbent': isIncumbent,
    };
  }
}

class PollingLocation {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double? latitude;
  final double? longitude;
  final String? hours;
  final List<String> notes;

  PollingLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.latitude,
    this.longitude,
    this.hours,
    required this.notes,
  });

  factory PollingLocation.fromJson(Map<String, dynamic> json) {
    return PollingLocation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      hours: json['hours'],
      notes: List<String>.from(json['notes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'hours': hours,
      'notes': notes,
    };
  }

  String get fullAddress => '$address, $city, $state $zipCode';
}

class ElectionSearchFilters {
  final String? state;
  final String? city;
  final String? county;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> electionTypes;
  final bool upcomingOnly;

  ElectionSearchFilters({
    this.state,
    this.city,
    this.county,
    this.startDate,
    this.endDate,
    this.electionTypes = const [],
    this.upcomingOnly = true,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (state != null) params['state'] = state;
    if (city != null) params['city'] = city;
    if (county != null) params['county'] = county;
    if (startDate != null) params['startDate'] = startDate!.toIso8601String();
    if (endDate != null) params['endDate'] = endDate!.toIso8601String();
    if (electionTypes.isNotEmpty) params['electionTypes'] = electionTypes.join(',');
    params['upcomingOnly'] = upcomingOnly;
    
    return params;
  }
}