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
  // Enhanced fields for more comprehensive bill data
  final String? chamber; // House, Senate, etc.
  final int? sessionId; // Legislative session ID
  final String? currentCommittee; // Current committee handling the bill
  final String? priorityStatus; // Emergency, routine, etc.
  final double? completionPercentage; // How far through legislative process
  final int? totalVotes; // Total number of votes on this bill
  final String? fiscalNote; // Financial impact summary
  final bool hasAmendments; // Whether bill has amendments
  final bool hasSupplements; // Whether bill has fiscal notes/analyses
  final List<String>? keywords; // Searchable keywords
  final String? summary; // AI-generated or official summary

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
    // Enhanced fields
    this.chamber,
    this.sessionId,
    this.currentCommittee,
    this.priorityStatus,
    this.completionPercentage,
    this.totalVotes,
    this.fiscalNote,
    this.hasAmendments = false,
    this.hasSupplements = false,
    this.keywords,
    this.summary,
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
      // No special handling needed here anymore
    }

    // Make sure the bill number is properly formatted
    String formattedBillNumber = bill.billNumber;
    if (bill.billType.isNotEmpty && !formattedBillNumber.contains(bill.billType)) {
      formattedBillNumber = '${bill.billType} ${bill.billNumber}';
    }
    
    // Extract description from extraData if available, otherwise use title
    String? description = bill.description;
    if (description == null && bill.title.length > 100) {
      description = '${bill.title.substring(0, 100)}...';
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

    // Handle missing bill_number with improved field detection
    String billNumber = 'Unknown';
    
    // Try multiple possible field names for bill number
    final possibleBillNumberFields = [
      'bill_number', 'number', 'bill_num', 'bill_no', 
      'bill', 'doc_id', 'measure_number'
    ];
    
    for (final fieldName in possibleBillNumberFields) {
      if (map.containsKey(fieldName) && map[fieldName] != null) {
        if (map[fieldName] is String && (map[fieldName] as String).isNotEmpty) {
          billNumber = map[fieldName] as String;
          break;
        } else if (map[fieldName] is List && (map[fieldName] as List).isNotEmpty) {
          billNumber = (map[fieldName] as List).join(' ');
          break;
        }
      }
    }
    
    // If still no bill number found, try to extract from title
    if (billNumber == 'Unknown' && title != 'Untitled') {
      // Try to extract bill number from title (e.g., "HB 123 - Some Title")
      final billNumberMatch = RegExp(r'^([A-Z]{1,3}[\s]*\d+)').firstMatch(title);
      if (billNumberMatch != null) {
        billNumber = billNumberMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' ');
      }
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

    // Extract enhanced fields
    String? chamber;
    if (map['chamber'] != null) {
      if (map['chamber'] is String) {
        chamber = map['chamber'] as String;
      } else if (map['chamber'] is List) {
        chamber = (map['chamber'] as List).join(' ');
      }
    }
    
    int? sessionId;
    if (map['session_id'] != null) {
      if (map['session_id'] is int) {
        sessionId = map['session_id'] as int;
      } else if (map['session_id'] is String) {
        sessionId = int.tryParse(map['session_id'] as String);
      }
    }
    
    // Extract completion percentage from progress data
    double? completionPercentage;
    if (map['progress'] != null && map['progress'] is List) {
      final progress = map['progress'] as List;
      if (progress.isNotEmpty) {
        // Calculate completion based on number of completed steps
        final completedSteps = progress.where((step) => step['passed'] == 1).length;
        completionPercentage = (completedSteps / progress.length) * 100;
      }
    }
    
    // Extract vote count
    int? totalVotes;
    if (map['votes'] != null && map['votes'] is List) {
      totalVotes = (map['votes'] as List).length;
    }
    
    // Check for amendments and supplements
    bool hasAmendments = false;
    if (map['amendments'] != null && map['amendments'] is List) {
      hasAmendments = (map['amendments'] as List).isNotEmpty;
    }
    
    bool hasSupplements = false;
    if (map['supplements'] != null && map['supplements'] is List) {
      hasSupplements = (map['supplements'] as List).isNotEmpty;
    }
    
    // Extract fiscal note summary
    String? fiscalNote;
    if (map['fiscal_note'] != null) {
      if (map['fiscal_note'] is String) {
        fiscalNote = map['fiscal_note'] as String;
      } else if (map['fiscal_note'] is List) {
        fiscalNote = (map['fiscal_note'] as List).join(' ');
      }
    }
    
    // Extract keywords
    List<String>? keywords;
    if (map['keywords'] != null && map['keywords'] is List) {
      keywords = (map['keywords'] as List).cast<String>();
    }
    
    // Use description as summary if available, otherwise use a truncated title
    String? summary = description.isNotEmpty ? description : null;
    if (summary == null && title.length > 100) {
      summary = '${title.substring(0, 97)}...';
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
      // Enhanced fields
      chamber: chamber,
      sessionId: sessionId,
      currentCommittee: committee, // Use committee as current committee
      priorityStatus: map['priority'] as String?,
      completionPercentage: completionPercentage,
      totalVotes: totalVotes,
      fiscalNote: fiscalNote,
      hasAmendments: hasAmendments,
      hasSupplements: hasSupplements,
      keywords: keywords,
      summary: summary,
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
      // Enhanced fields
      'chamber': chamber,
      'session_id': sessionId,
      'current_committee': currentCommittee,
      'priority_status': priorityStatus,
      'completion_percentage': completionPercentage,
      'total_votes': totalVotes,
      'fiscal_note': fiscalNote,
      'has_amendments': hasAmendments,
      'has_supplements': hasSupplements,
      'keywords': keywords,
      'summary': summary,
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
    // Enhanced fields
    String? chamber,
    int? sessionId,
    String? currentCommittee,
    String? priorityStatus,
    double? completionPercentage,
    int? totalVotes,
    String? fiscalNote,
    bool? hasAmendments,
    bool? hasSupplements,
    List<String>? keywords,
    String? summary,
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
      // Enhanced fields
      chamber: chamber ?? this.chamber,
      sessionId: sessionId ?? this.sessionId,
      currentCommittee: currentCommittee ?? this.currentCommittee,
      priorityStatus: priorityStatus ?? this.priorityStatus,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      totalVotes: totalVotes ?? this.totalVotes,
      fiscalNote: fiscalNote ?? this.fiscalNote,
      hasAmendments: hasAmendments ?? this.hasAmendments,
      hasSupplements: hasSupplements ?? this.hasSupplements,
      keywords: keywords ?? this.keywords,
      summary: summary ?? this.summary,
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
          map['document_desc'] as String? ?? map['desc'] as String?;

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
      // Error handling for document processing

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
