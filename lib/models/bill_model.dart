// lib/models/bill_model.dart
import 'package:flutter/foundation.dart';
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
  factory BillModel.fromRepresentativeBill(
      RepresentativeBill bill, String state) {
    // Extract bill type (federal, state, local) from source
    String billType = 'state';
    if (bill.source == 'Congress') {
      billType = 'federal';
    } else if (bill.source == 'CSV') {
      billType = 'local';
    }

    // Create a unique ID from bill properties for identifying the bill
    final idHash = (bill.congress.hashCode ^
        bill.billType.hashCode ^
        bill.billNumber.hashCode ^
        state.hashCode).abs();
        
    // Special handling for FL and GA with CSV data
    if ((state == 'FL' || state == 'GA') && bill.source == 'CSV') {
      if (kDebugMode) {
        print('Converting bill from CSV for $state with number ${bill.billNumber} and title: ${bill.title}');
      }
    }

    // Make sure the bill number is properly formatted
    String formattedBillNumber = bill.billNumber;
    if (bill.billType.isNotEmpty && !formattedBillNumber.contains(bill.billType)) {
      formattedBillNumber = '${bill.billType} ${bill.billNumber}';
    }
    
    // Extract description from extraData if available, otherwise use title
    String? description = bill.description;
    if (description == null && bill.title.length > 100) {
      description = bill.title.substring(0, 100) + '...';
    }
    
    // Get status from latestAction or statusDescription
    String status = bill.latestAction ?? bill.statusDescription ?? 'Unknown status';
    
    // Get URL from extraData if available
    String url = '';
    if (bill.url != null && bill.url!.isNotEmpty) {
      url = bill.url!;
    } else if (bill.stateLink != null && bill.stateLink!.isNotEmpty) {
      url = bill.stateLink!;
    }
    
    // Create the bill model with enriched data
    return BillModel(
      billId: idHash, // Use hash as ID
      billNumber: formattedBillNumber,
      title: bill.title,
      description: description,
      status: status,
      statusDate: bill.introducedDate,
      introducedDate: bill.introducedDate,
      lastActionDate: bill.introducedDate, // Use introduced date as fallback
      lastAction: bill.latestAction,
      committee: bill.committee,
      type: billType,
      state: state,
      url: url,
      // If we have extra data, add subjects as a list
      subjects: bill.extraData != null && bill.extraData!.containsKey('subjects') ? 
                (bill.extraData!['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() : null,
    );
  }

  // Factory method to create from LegiScan/CSV data

  factory BillModel.fromMap(Map<String, dynamic> map) {
    // Handle LegiScan search results which use different key names
    String title;
    if (map['title'] is String) {
      title = map['title'] as String;
    } else if (map['title'] is List) {
      title = (map['title'] as List).join(' ');
    } else {
      title = 'Untitled';
    }

    // Handle description that could be a List or String
    String description = '';
    if (map['description'] != null) {
      if (map['description'] is String) {
        description = map['description'] as String;
      } else if (map['description'] is List) {
        description = (map['description'] as List).join(' ');
      }
    }

    // Handle either status_desc or last_action for status
    String status;
    if (map['status_desc'] != null) {
      if (map['status_desc'] is String) {
        status = map['status_desc'] as String;
      } else if (map['status_desc'] is List) {
        status = (map['status_desc'] as List).join(' ');
      } else {
        status = 'Unknown status';
      }
    } else if (map['last_action'] != null) {
      if (map['last_action'] is String) {
        status = map['last_action'] as String;
      } else if (map['last_action'] is List) {
        status = (map['last_action'] as List).join(' ');
      } else {
        status = 'Unknown status';
      }
    } else {
      status = 'Unknown status';
    }

    // Handle various date formats and names
    String? statusDate;
    if (map['status_date'] != null) {
      if (map['status_date'] is String) {
        statusDate = map['status_date'] as String;
      } else if (map['status_date'] is List) {
        statusDate = (map['status_date'] as List).join(' ');
      }
    }

    String? lastActionDate;
    if (map['last_action_date'] != null) {
      if (map['last_action_date'] is String) {
        lastActionDate = map['last_action_date'] as String;
      } else if (map['last_action_date'] is List) {
        lastActionDate = (map['last_action_date'] as List).join(' ');
      }
    }

    String? lastAction;
    if (map['last_action'] != null) {
      if (map['last_action'] is String) {
        lastAction = map['last_action'] as String;
      } else if (map['last_action'] is List) {
        lastAction = (map['last_action'] as List).join(' ');
      }
    }

    // Handle Bill ID being different types across APIs
    int billId;
    if (map['bill_id'] is int) {
      billId = map['bill_id'] as int;
    } else if (map['bill_id'] is String) {
      billId = int.tryParse(map['bill_id'] as String) ?? map.hashCode;
    } else {
      // Generate a unique ID based on bill properties
      billId = '${map['state']}-${map['bill_number']}'.hashCode;
    }

    // Handle missing bill_number
    String billNumber;
    if (map['bill_number'] != null) {
      if (map['bill_number'] is String) {
        billNumber = map['bill_number'] as String;
      } else if (map['bill_number'] is List) {
        billNumber = (map['bill_number'] as List).join(' ');
      } else {
        billNumber = 'Unknown';
      }
    } else {
      billNumber = 'Unknown';
    }

    // Handle URL field variations
    String url = '';
    if (map['url'] != null) {
      if (map['url'] is String) {
        url = map['url'] as String;
      } else if (map['url'] is List) {
        url = (map['url'] as List).join(' ');
      }
    } else if (map['text_url'] != null) {
      if (map['text_url'] is String) {
        url = map['text_url'] as String;
      } else if (map['text_url'] is List) {
        url = (map['text_url'] as List).join(' ');
      }
    } else if (map['research_url'] != null) {
      if (map['research_url'] is String) {
        url = map['research_url'] as String;
      } else if (map['research_url'] is List) {
        url = (map['research_url'] as List).join(' ');
      }
    }

    // Clean up escaped forward slashes in URLs
    final cleanedUrl = url.replaceAll(r'\/', '/');

    // Handle committee field
    String? committee;
    if (map['committee'] != null) {
      if (map['committee'] is String) {
        committee = map['committee'] as String;
      } else if (map['committee'] is List) {
        committee = (map['committee'] as List).join(' ');
      }
    }

    // Create model with safely extracted values
    return BillModel(
      billId: billId,
      billNumber: billNumber,
      title: title,
      description: description.isNotEmpty ? description : null,
      status: status,
      statusDate: statusDate,
      introducedDate: map['introduced_date'] as String?,
      lastActionDate: lastActionDate,
      lastAction: lastAction,
      committee: committee,
      type: map['type'] ?? 'state', // Default to state if not specified
      state: map['state'] as String,
      url: cleanedUrl,
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
      position: (map['position'] == 1 || map['position'] == '1')
          ? 'primary'
          : 'cosponsor',
      imageUrl: map['imageUrl'] as String?,
      bioGuideId: map['bioguideId'] as String?,
    );
  }

  // Convert from Representative for bridging between models
  factory RepresentativeSponsor.fromRepresentative(Representative rep,
      {bool isPrimary = true}) {
    return RepresentativeSponsor(
      peopleId: rep.bioGuideId
          .hashCode, // Use hash of bioGuideId since we don't have people_id
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
    } else if (chamberlower.contains('house') ||
        chamberlower == 'national_lower') {
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
    try {
      // Handle null document_id by generating one from other fields
      int docId;
      if (map['document_id'] != null) {
        // Try to get as int first
        if (map['document_id'] is int) {
          docId = map['document_id'] as int;
        } else if (map['document_id'] is String) {
          // Try to parse string to int
          docId = int.tryParse(map['document_id'] as String) ??
              (map['document_type'].toString() + map['url'].toString())
                  .hashCode;
        } else {
          // Generate a unique ID based on other properties
          docId = (map['document_type'].toString() + map['url'].toString())
              .hashCode;
        }
      } else {
        // Generate a unique ID based on other properties
        docId = map.hashCode;
      }

      // Get document type with fallback
      String docType;
      if (map['document_type'] != null) {
        docType = map['document_type'] as String;
      } else if (map['type'] != null) {
        docType = map['type'] as String;
      } else {
        docType = 'Unknown'; // Default
      }

      // Get description or use fallback
      final description =
          map['document_desc'] as String? ?? map['desc'] as String? ?? null;

      // Get URL with fallbacks
      String url;
      if (map['url'] != null) {
        url = map['url'] as String;
      } else if (map['text_url'] != null) {
        url = map['text_url'] as String;
      } else {
        url = ''; // Default to empty string
      }

      // Clean up escaped forward slashes in URL
      url = url.replaceAll(r'\/', '/');

      return BillDocument(
        documentId: docId,
        type: docType,
        description: description,
        url: url,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error processing bill document: $e');
        print('Document data: $map');
      }

      // Return a placeholder document rather than crashing
      return BillDocument(
        documentId: DateTime.now().millisecondsSinceEpoch,
        type: 'Unknown',
        description: 'Error loading document',
        url: '',
      );
    }
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
