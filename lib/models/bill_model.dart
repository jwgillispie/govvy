// lib/models/bill_model.dart
import 'package:govvy/models/representative_model.dart';

class BillModel {
  final int billId;
  final String billNumber;
  final String title;
  final String? description;
  final String status;
  final String? statusDate;
  final String? introducedDate;
  final String? lastActionDate;
  final String? lastAction;
  final String? committee;
  final String type; // 'federal', 'state', 'local'
  final String state;
  final String url;
  final List<RepresentativeSponsor>? sponsors;
  final List<BillHistory>? history;
  final List<String>? subjects;

  BillModel({
    required this.billId,
    required this.billNumber,
    required this.title,
    this.description,
    required this.status,
    this.statusDate,
    this.introducedDate,
    this.lastActionDate,
    this.lastAction,
    this.committee,
    required this.type,
    required this.state,
    required this.url,
    this.sponsors,
    this.history,
    this.subjects,
  });

  // Convert from RepresentativeBill format (for bridging between models)
  factory BillModel.fromRepresentativeBill(RepresentativeBill bill, String state) {
    // Extract bill type (federal, state, local) from source
    String billType = 'state';
    if (bill.source == 'Congress') {
      billType = 'federal';
    } else if (bill.source == 'CSV') {
      billType = 'local';
    }

    // Create a unique ID from bill properties for identifying the bill
    final idHash = bill.congress.hashCode ^ 
                  bill.billType.hashCode ^ 
                  bill.billNumber.hashCode;

    return BillModel(
      billId: idHash.abs(), // Use hash as ID
      billNumber: '${bill.billType} ${bill.billNumber}',
      title: bill.title,
      status: bill.latestAction ?? 'Unknown status',
      statusDate: bill.introducedDate,
      type: billType,
      state: state,
      url: '', // We don't have the URL in this conversion
    );
  }

  // Factory method to create from LegiScan/CSV data
  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      billId: map['bill_id'] as int,
      billNumber: map['bill_number'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status_desc'] as String,
      statusDate: map['status_date'] as String?,
      lastActionDate: map['last_action_date'] as String?,
      lastAction: map['last_action'] as String?,
      committee: map['committee'] as String?,
      type: map['type'] ?? 'state', // Default to state if not specified
      state: map['state'] as String,
      url: map['url'] as String,
      introducedDate: null, // To be populated from history
      sponsors: null, // To be populated separately
      history: null, // To be populated separately
      subjects: null, // To be populated separately
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'bill_id': billId,
      'bill_number': billNumber,
      'title': title,
      'description': description,
      'status': status,
      'status_date': statusDate,
      'last_action_date': lastActionDate,
      'last_action': lastAction,
      'committee': committee,
      'type': type,
      'state': state,
      'url': url,
      'introduced_date': introducedDate,
    };
  }

  // Copy with method for updating bill data
  BillModel copyWith({
    int? billId,
    String? billNumber,
    String? title,
    String? description,
    String? status,
    String? statusDate,
    String? introducedDate,
    String? lastActionDate,
    String? lastAction,
    String? committee,
    String? type,
    String? state,
    String? url,
    List<RepresentativeSponsor>? sponsors,
    List<BillHistory>? history,
    List<String>? subjects,
  }) {
    return BillModel(
      billId: billId ?? this.billId,
      billNumber: billNumber ?? this.billNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      statusDate: statusDate ?? this.statusDate,
      introducedDate: introducedDate ?? this.introducedDate,
      lastActionDate: lastActionDate ?? this.lastActionDate,
      lastAction: lastAction ?? this.lastAction,
      committee: committee ?? this.committee,
      type: type ?? this.type,
      state: state ?? this.state,
      url: url ?? this.url,
      sponsors: sponsors ?? this.sponsors,
      history: history ?? this.history,
      subjects: subjects ?? this.subjects,
    );
  }

  // Formatting helpers
  String get formattedBillNumber => billNumber;
  
  String get formattedIntroducedDate {
    if (introducedDate == null) return 'Unknown';
    // TODO: Format date
    return introducedDate!;
  }
  
  String get formattedStatusDate {
    if (statusDate == null) return 'Unknown';
    // TODO: Format date
    return statusDate!;
  }
  
  String get statusColor {
    // Return appropriate color based on status
    if (status.toLowerCase().contains('introduced')) return 'blue';
    if (status.toLowerCase().contains('passed')) return 'green';
    if (status.toLowerCase().contains('failed')) return 'red';
    if (status.toLowerCase().contains('vetoed')) return 'orange';
    return 'gray';
  }
}

class RepresentativeSponsor {
  final int peopleId;
  final String name;
  final String? role;
  final String? party;
  final String? district;
  final String state;
  final String position; // 'primary' or 'cosponsor'
  final String? imageUrl;
  final String? bioGuideId; // To link back to representative data

  RepresentativeSponsor({
    required this.peopleId,
    required this.name,
    this.role,
    this.party,
    this.district,
    required this.state,
    required this.position,
    this.imageUrl,
    this.bioGuideId,
  });

  factory RepresentativeSponsor.fromMap(Map<String, dynamic> map) {
    return RepresentativeSponsor(
      peopleId: map['people_id'] as int,
      name: map['name'] as String,
      role: map['role'] as String?,
      party: map['party'] as String?,
      district: map['district'] as String?,
      state: map['state'] as String,
      position: (map['position'] == 1 || map['position'] == '1') ? 'primary' : 'cosponsor',
      imageUrl: map['imageUrl'] as String?,
      bioGuideId: map['bioguideId'] as String?,
    );
  }

  // Convert from Representative for bridging between models
  factory RepresentativeSponsor.fromRepresentative(Representative rep, {bool isPrimary = true}) {
    return RepresentativeSponsor(
      peopleId: rep.bioGuideId.hashCode, // Use hash of bioGuideId since we don't have people_id
      name: rep.name,
      role: _getRoleFromChamber(rep.chamber),
      party: rep.party,
      district: rep.district,
      state: rep.state,
      position: isPrimary ? 'primary' : 'cosponsor',
      imageUrl: rep.imageUrl,
      bioGuideId: rep.bioGuideId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'people_id': peopleId,
      'name': name,
      'role': role,
      'party': party,
      'district': district,
      'state': state,
      'position': position,
      'imageUrl': imageUrl,
      'bioGuideId': bioGuideId,
    };
  }

  // Helper to derive role from chamber
  static String? _getRoleFromChamber(String chamber) {
    final chamberlower = chamber.toLowerCase();
    if (chamberlower.contains('senate') || chamberlower == 'national_upper') {
      return 'Senator';
    } else if (chamberlower.contains('house') || chamberlower == 'national_lower') {
      return 'Representative';
    } else if (chamberlower.contains('mayor') || chamberlower == 'local_exec') {
      return 'Mayor';
    } else if (chamberlower.contains('council') || chamberlower == 'local') {
      return 'Council Member';
    } else if (chamberlower.contains('county')) {
      return 'County Commissioner';
    } else if (chamberlower.contains('state_upper')) {
      return 'State Senator';
    } else if (chamberlower.contains('state_lower')) {
      return 'State Representative';
    }
    return null;
  }
}

class BillHistory {
  final String date;
  final String action;
  final String? chamber;
  final int sequence;

  BillHistory({
    required this.date,
    required this.action,
    this.chamber,
    required this.sequence,
  });

  factory BillHistory.fromMap(Map<String, dynamic> map) {
    return BillHistory(
      date: map['date'] as String,
      action: map['action'] as String,
      chamber: map['chamber'] as String?,
      sequence: map['sequence'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'action': action,
      'chamber': chamber,
      'sequence': sequence,
    };
  }
}

class BillDocument {
  final int documentId;
  final String type;
  final String? description;
  final String url;

  BillDocument({
    required this.documentId,
    required this.type,
    this.description,
    required this.url,
  });

  factory BillDocument.fromMap(Map<String, dynamic> map) {
    return BillDocument(
      documentId: map['document_id'] as int,
      type: map['document_type'] as String,
      description: map['document_desc'] as String?,
      url: map['url'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'document_id': documentId,
      'document_type': type,
      'document_desc': description,
      'url': url,
    };
  }
}