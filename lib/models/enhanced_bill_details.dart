// lib/models/enhanced_bill_details.dart
import 'package:flutter/foundation.dart';
import 'package:govvy/models/bill_model.dart';

/// Enhanced bill details model that combines all bill-related data
/// from LegiScan API in a single comprehensive object
class EnhancedBillDetails {
  final BillModel bill;
  final List<RepresentativeSponsor> sponsors;
  final List<BillHistory> history;
  final List<BillDocument> documents;
  final List<String> subjects;
  final List<BillVote>? votes;
  final List<BillAmendment>? amendments;
  final List<BillSupplement>? supplements;
  final Map<String, dynamic> extraData;

  EnhancedBillDetails({
    required this.bill,
    required this.sponsors,
    required this.history,
    required this.documents,
    required this.subjects,
    this.votes,
    this.amendments,
    this.supplements,
    required this.extraData,
  });

  /// Factory constructor to create from API response
  factory EnhancedBillDetails.fromApiResponse(Map<String, dynamic> billData, String stateCode) {
    try {
      if (!billData.containsKey('bill')) {
        throw Exception('Invalid bill data format');
      }

      final billMap = Map<String, dynamic>.from(billData['bill'] as Map);

      // Add state code
      billMap['state'] = stateCode;

      // Add bill type
      billMap['type'] = 'state';

      // Handle fields that might be Lists before creating the model
      if (billMap.containsKey('description') && billMap['description'] is List) {
        billMap['description'] = (billMap['description'] as List).join(' ');
      }

      // Check other potential fields that might be Lists
      final fieldsToCheck = [
        'title',
        'status_desc',
        'status_date',
        'last_action'
      ];
      
      for (final field in fieldsToCheck) {
        if (billMap.containsKey(field) && billMap[field] is List) {
          billMap[field] = (billMap[field] as List).join(' ');
        }
      }

      // Create basic bill model
      final billModel = BillModel.fromMap(billMap);

      // Process sponsors
      List<RepresentativeSponsor> sponsors = [];
      if (billMap.containsKey('sponsors') && billMap['sponsors'] is List) {
        for (final sponsor in billMap['sponsors']) {
          if (sponsor is Map) {
            try {
              final sponsorData = Map<String, dynamic>.from(sponsor);

              // Ensure state is present in sponsor data
              if (!sponsorData.containsKey('state')) {
                sponsorData['state'] = stateCode;
              }

              // Handle List values in sponsor data
              sponsorData.forEach((key, value) {
                if (value is List) {
                  sponsorData[key] = value.join(' ');
                }
              });

              sponsors.add(RepresentativeSponsor.fromMap(sponsorData));
            } catch (e) {
              if (kDebugMode) {
                print('Error processing sponsor: $e');
              }
            }
          }
        }
      }

      // Process history
      List<BillHistory> history = [];
      if (billMap.containsKey('history') && billMap['history'] is List) {
        for (final action in billMap['history']) {
          if (action is Map) {
            try {
              final actionData = Map<String, dynamic>.from(action);

              // Handle List values in action data
              actionData.forEach((key, value) {
                if (value is List) {
                  actionData[key] = value.join(' ');
                }
              });

              // Make sure sequence is an int
              if (actionData.containsKey('sequence') &&
                  actionData['sequence'] is! int) {
                if (actionData['sequence'] is String) {
                  actionData['sequence'] =
                      int.tryParse(actionData['sequence'] as String) ?? 0;
                } else {
                  actionData['sequence'] = 0;
                }
              } else if (!actionData.containsKey('sequence')) {
                actionData['sequence'] = 0;
              }

              history.add(BillHistory.fromMap(actionData));
            } catch (e) {
              if (kDebugMode) {
                print('Error processing history action: $e');
              }
            }
          }
        }
      }

      // Process subjects
      List<String> subjects = [];
      if (billMap.containsKey('subjects') && billMap['subjects'] is List) {
        for (final subject in billMap['subjects']) {
          if (subject is String) {
            subjects.add(subject);
          } else if (subject is Map && subject.containsKey('subject')) {
            var subjectValue = subject['subject'];
            if (subjectValue is String) {
              subjects.add(subjectValue);
            } else if (subjectValue is List) {
              subjects.add(subjectValue.join(' '));
            }
          }
        }
      }

      // Process documents
      List<BillDocument> documents = [];
      if (billMap.containsKey('texts') && billMap['texts'] is List) {
        for (final text in billMap['texts']) {
          if (text is Map) {
            try {
              final textData = Map<String, dynamic>.from(text);
              documents.add(BillDocument.fromMap(textData));
            } catch (e) {
              if (kDebugMode) {
                print('Error processing document: $e');
              }
            }
          }
        }
      }

      // Extract extra data that might be useful
      final extraData = <String, dynamic>{};
      
      // Include progress data if available
      if (billMap.containsKey('progress')) {
        extraData['progress'] = billMap['progress'];
      }
      
      // Include calendar data if available
      if (billMap.containsKey('calendar')) {
        extraData['calendar'] = billMap['calendar'];
      }
      
      // Process votes data if available
      List<BillVote> votes = [];
      if (billMap.containsKey('votes') && billMap['votes'] is List) {
        for (final voteData in billMap['votes']) {
          if (voteData is Map) {
            try {
              final voteMap = Map<String, dynamic>.from(voteData);
              votes.add(BillVote.fromMap(voteMap));
            } catch (e) {
              if (kDebugMode) {
                print('Error processing vote: $e');
              }
            }
          }
        }
      }
      
      // Process amendments if available
      List<BillAmendment> amendments = [];
      if (billMap.containsKey('amendments') && billMap['amendments'] is List) {
        for (final amendmentData in billMap['amendments']) {
          if (amendmentData is Map) {
            try {
              final amendmentMap = Map<String, dynamic>.from(amendmentData);
              amendments.add(BillAmendment.fromMap(amendmentMap));
            } catch (e) {
              if (kDebugMode) {
                print('Error processing amendment: $e');
              }
            }
          }
        }
      }
      
      // Process supplements if available
      List<BillSupplement> supplements = [];
      if (billMap.containsKey('supplements') && billMap['supplements'] is List) {
        for (final supplementData in billMap['supplements']) {
          if (supplementData is Map) {
            try {
              final supplementMap = Map<String, dynamic>.from(supplementData);
              supplements.add(BillSupplement.fromMap(supplementMap));
            } catch (e) {
              if (kDebugMode) {
                print('Error processing supplement: $e');
              }
            }
          }
        }
      }

      // Create enhanced bill details
      return EnhancedBillDetails(
        bill: billModel.copyWith(
          sponsors: sponsors,
          history: history,
          subjects: subjects,
        ),
        sponsors: sponsors,
        history: history,
        documents: documents,
        subjects: subjects,
        votes: votes.isNotEmpty ? votes : null,
        amendments: amendments.isNotEmpty ? amendments : null,
        supplements: supplements.isNotEmpty ? supplements : null,
        extraData: extraData,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating EnhancedBillDetails: $e');
      }
      
      // Return fallback with basic bill
      return EnhancedBillDetails(
        bill: BillModel(
          billId: 0,
          billNumber: 'Error',
          title: 'Error loading bill details',
          status: 'Unknown',
          type: 'state',
          state: stateCode,
          url: '',
        ),
        sponsors: [],
        history: [],
        documents: [],
        subjects: [],
        extraData: {},
      );
    }
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'bill': bill.toMap(),
      'sponsors': sponsors.map((sponsor) => sponsor.toMap()).toList(),
      'history': history.map((item) => item.toMap()).toList(),
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'subjects': subjects,
      'votes': votes?.map((vote) => vote.toMap()).toList(),
      'amendments': amendments?.map((amendment) => amendment.toMap()).toList(),
      'supplements': supplements?.map((supplement) => supplement.toMap()).toList(),
      'extra_data': extraData,
    };
  }

  /// Create from map (for restoring from cache)
  factory EnhancedBillDetails.fromMap(Map<String, dynamic> map) {
    try {
      // Process votes if available
      List<BillVote>? votes;
      if (map.containsKey('votes') && map['votes'] != null) {
        votes = (map['votes'] as List)
            .map((vote) => BillVote.fromMap(vote))
            .toList();
      }
      
      // Process amendments if available
      List<BillAmendment>? amendments;
      if (map.containsKey('amendments') && map['amendments'] != null) {
        amendments = (map['amendments'] as List)
            .map((amendment) => BillAmendment.fromMap(amendment))
            .toList();
      }
      
      // Process supplements if available
      List<BillSupplement>? supplements;
      if (map.containsKey('supplements') && map['supplements'] != null) {
        supplements = (map['supplements'] as List)
            .map((supplement) => BillSupplement.fromMap(supplement))
            .toList();
      }
      
      return EnhancedBillDetails(
        bill: BillModel.fromMap(map['bill']),
        sponsors: (map['sponsors'] as List)
            .map((sponsor) => RepresentativeSponsor.fromMap(sponsor))
            .toList(),
        history: (map['history'] as List)
            .map((item) => BillHistory.fromMap(item))
            .toList(),
        documents: (map['documents'] as List)
            .map((doc) => BillDocument.fromMap(doc))
            .toList(),
        subjects: (map['subjects'] as List).cast<String>(),
        votes: votes,
        amendments: amendments,
        supplements: supplements,
        extraData: map['extra_data'] ?? {},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating EnhancedBillDetails from map: $e');
      }
      
      // Return fallback with basic bill
      return EnhancedBillDetails(
        bill: BillModel(
          billId: 0,
          billNumber: 'Error',
          title: 'Error restoring bill details',
          status: 'Unknown',
          type: 'state',
          state: 'US',
          url: '',
        ),
        sponsors: [],
        history: [],
        documents: [],
        subjects: [],
        votes: null,
        amendments: null,
        supplements: null,
        extraData: {},
      );
    }
  }
}

/// Represents a bill vote (roll call vote)
class BillVote {
  final int rollCallId;
  final String date;
  final String description;
  final String chamber;
  final int yesCount;
  final int noCount;
  final int nVCount;
  final int absentCount;
  final String result;
  final String url;

  BillVote({
    required this.rollCallId,
    required this.date,
    required this.description,
    required this.chamber,
    required this.yesCount,
    required this.noCount,
    required this.nVCount,
    required this.absentCount,
    required this.result,
    required this.url,
  });

  factory BillVote.fromMap(Map<String, dynamic> map) {
    try {
      // Type conversion for integer fields
      int rollCallId = 0;
      if (map['roll_call_id'] is int) {
        rollCallId = map['roll_call_id'] as int;
      } else if (map['roll_call_id'] is String) {
        rollCallId = int.tryParse(map['roll_call_id'] as String) ?? 0;
      }

      // Parse vote counts with type safety
      int yesCount = 0;
      if (map['yes_count'] is int) {
        yesCount = map['yes_count'] as int;
      } else if (map['yes_count'] is String) {
        yesCount = int.tryParse(map['yes_count'] as String) ?? 0;
      }

      int noCount = 0;
      if (map['no_count'] is int) {
        noCount = map['no_count'] as int;
      } else if (map['no_count'] is String) {
        noCount = int.tryParse(map['no_count'] as String) ?? 0;
      }

      int nVCount = 0;
      if (map['nv_count'] is int) {
        nVCount = map['nv_count'] as int;
      } else if (map['nv_count'] is String) {
        nVCount = int.tryParse(map['nv_count'] as String) ?? 0;
      }

      int absCount = 0;
      if (map['absent_count'] is int) {
        absCount = map['absent_count'] as int;
      } else if (map['absent_count'] is String) {
        absCount = int.tryParse(map['absent_count'] as String) ?? 0;
      }

      // Handle URL that might be escaped
      String url = '';
      if (map['url'] is String) {
        url = (map['url'] as String).replaceAll(r'\/', '/');
      }

      return BillVote(
        rollCallId: rollCallId,
        date: map['date'] as String? ?? '',
        description: map['desc'] as String? ?? map['description'] as String? ?? '',
        chamber: map['chamber'] as String? ?? '',
        yesCount: yesCount,
        noCount: noCount,
        nVCount: nVCount,
        absentCount: absCount,
        result: map['passed'] == 1 || map['passed'] == true || map['passed'] == '1' ? 'Passed' : 'Failed',
        url: url,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating BillVote from map: $e');
      }
      
      // Return a placeholder on error
      return BillVote(
        rollCallId: 0,
        date: '',
        description: 'Error parsing vote data',
        chamber: '',
        yesCount: 0,
        noCount: 0,
        nVCount: 0,
        absentCount: 0,
        result: 'Unknown',
        url: '',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'roll_call_id': rollCallId,
      'date': date,
      'desc': description,
      'chamber': chamber,
      'yes_count': yesCount,
      'no_count': noCount,
      'nv_count': nVCount,
      'absent_count': absentCount,
      'result': result,
      'url': url,
    };
  }
}

/// Represents a bill amendment
class BillAmendment {
  final int amendmentId;
  final String amendmentNumber;
  final String description;
  final String? adoptedDate;
  final String chamber;
  final String url;

  BillAmendment({
    required this.amendmentId,
    required this.amendmentNumber,
    required this.description,
    this.adoptedDate,
    required this.chamber,
    required this.url,
  });

  factory BillAmendment.fromMap(Map<String, dynamic> map) {
    try {
      // Type conversion for integer fields
      int amendmentId = 0;
      if (map['amendment_id'] is int) {
        amendmentId = map['amendment_id'] as int;
      } else if (map['amendment_id'] is String) {
        amendmentId = int.tryParse(map['amendment_id'] as String) ?? 0;
      }

      // Handle URL that might be escaped
      String url = '';
      if (map['url'] is String) {
        url = (map['url'] as String).replaceAll(r'\/', '/');
      }

      return BillAmendment(
        amendmentId: amendmentId,
        amendmentNumber: map['amendment_number'] as String? ?? map['number'] as String? ?? '',
        description: map['description'] as String? ?? map['desc'] as String? ?? '',
        adoptedDate: map['adopted_date'] as String?,
        chamber: map['chamber'] as String? ?? '',
        url: url,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating BillAmendment from map: $e');
      }
      
      // Return a placeholder on error
      return BillAmendment(
        amendmentId: 0,
        amendmentNumber: '',
        description: 'Error parsing amendment data',
        adoptedDate: null,
        chamber: '',
        url: '',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'amendment_id': amendmentId,
      'amendment_number': amendmentNumber,
      'description': description,
      'adopted_date': adoptedDate,
      'chamber': chamber,
      'url': url,
    };
  }
}

/// Represents a bill supplement (fiscal notes, analyses, etc.)
class BillSupplement {
  final int supplementId;
  final String supplementType;
  final String description;
  final String date;
  final String url;

  BillSupplement({
    required this.supplementId,
    required this.supplementType,
    required this.description,
    required this.date,
    required this.url,
  });

  factory BillSupplement.fromMap(Map<String, dynamic> map) {
    try {
      // Type conversion for integer fields
      int supplementId = 0;
      if (map['supplement_id'] is int) {
        supplementId = map['supplement_id'] as int;
      } else if (map['supplement_id'] is String) {
        supplementId = int.tryParse(map['supplement_id'] as String) ?? 0;
      }

      // Handle URL that might be escaped
      String url = '';
      if (map['url'] is String) {
        url = (map['url'] as String).replaceAll(r'\/', '/');
      }

      return BillSupplement(
        supplementId: supplementId,
        supplementType: map['type'] as String? ?? '',
        description: map['description'] as String? ?? map['desc'] as String? ?? '',
        date: map['date'] as String? ?? '',
        url: url,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating BillSupplement from map: $e');
      }
      
      // Return a placeholder on error
      return BillSupplement(
        supplementId: 0,
        supplementType: '',
        description: 'Error parsing supplement data',
        date: '',
        url: '',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'supplement_id': supplementId,
      'type': supplementType,
      'description': description,
      'date': date,
      'url': url,
    };
  }
}