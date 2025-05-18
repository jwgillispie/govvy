// lib/models/representative_model.dart

import 'package:govvy/models/local_representative_model.dart';
import 'package:govvy/utils/district_type_formatter.dart';

class Representative {
  final String name;
  final String bioGuideId;
  final String party;
  final String chamber;
  final String state;
  final String? district;
  final String? imageUrl;
  final String? office;
  final String? phone;
  final String? email;
  final String? website;
  final List<String>? socialMedia;
  final String? displayTitle;

  Representative({
    required this.name,
    required this.bioGuideId,
    required this.party,
    required this.chamber,
    required this.state,
    this.district,
    this.imageUrl,
    this.office,
    this.phone,
    this.email,
    this.website,
    this.socialMedia,
    this.displayTitle,
  });

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bioGuideId': bioGuideId,
      'party': party,
      'chamber': chamber,
      'state': state,
      'district': district,
      'office': office,
      'phone': phone,
      'email': email,
      'website': website,
      'imageUrl': imageUrl,
      'socialMedia': socialMedia,
      'displayTitle': displayTitle,
    };
  }

  // Create from map (e.g., from cache)
  static Representative fromMap(String id, Map<String, dynamic> map) {
    return Representative(
      name: map['name'] ?? '',
      bioGuideId: map['bioGuideId'] ?? id,
      party: map['party'] ?? '',
      chamber: map['chamber'] ?? '',
      state: map['state'] ?? '',
      district: map['district'],
      office: map['office'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      imageUrl: map['imageUrl'],
      socialMedia: map['socialMedia'] != null
          ? List<String>.from(map['socialMedia'])
          : null,
      displayTitle: map['displayTitle'],
    );
  }

  factory Representative.fromJson(Map<String, dynamic> json) {
    return Representative(
      name: json['name']?.toString() ?? '',
      bioGuideId: json['bioGuideId']?.toString() ?? '',
      party: json['party']?.toString() ?? '',
      chamber: json['chamber']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      office: json['office']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      socialMedia: json['socialMedia'] is List
          ? List<String>.from(json['socialMedia'])
          : null,
      displayTitle: json['displayTitle']?.toString(),
    );
  }

  // Get formatted display title
  String getDisplayTitle() {
    if (displayTitle != null && displayTitle!.isNotEmpty) {
      return displayTitle!;
    }
    return DistrictTypeFormatter.formatRoleWithLocation(
        chamber, office, state, district);
  }
}

class RepresentativeDetails {
  final String bioGuideId;
  final String name;
  final String party;
  final String state;
  final String? district;
  final String chamber;
  final String? dateOfBirth;
  final String? gender;
  final String? office; // Physical office address
  final String? phone;
  final String? email;
  final String? website;
  final String? imageUrl;
  final List<String>? socialMedia;
  // Changed from final to allow adding bills after instantiation
  List<RepresentativeBill> sponsoredBills;
  List<RepresentativeBill> cosponsoredBills;
  final String? displayTitle;
  final String? role; // Actual role/position title
  // New field to track if LegiScan bills were attempted to be loaded
  bool legiscanBillsLoaded = false;

  RepresentativeDetails({
    required this.bioGuideId,
    required this.name,
    required this.party,
    required this.state,
    this.district,
    required this.chamber,
    this.dateOfBirth,
    this.gender,
    this.office,
    this.phone,
    this.email,
    this.website,
    this.imageUrl,
    this.socialMedia,
    required this.sponsoredBills,
    required this.cosponsoredBills,
    this.displayTitle,
    this.role,
    this.legiscanBillsLoaded = false,
  });

  factory RepresentativeDetails.fromMap({
    required Map<String, dynamic> details,
    required List<dynamic> sponsoredBills,
    required List<dynamic> cosponsoredBills,
  }) {
    // Extract current term information from terms list or map
    Map<String, dynamic> termMap = {};

    if (details.containsKey('terms')) {
      final terms = details['terms'];

      if (terms is List && terms.isNotEmpty) {
        // Get the most recent term (usually first in the list)
        termMap = Map<String, dynamic>.from(terms[0] as Map);
      } else if (terms is Map && terms.containsKey('item')) {
        final items = terms['item'];
        if (items is List && items.isNotEmpty) {
          termMap = Map<String, dynamic>.from(items[0] as Map);
        } else if (items is Map) {
          termMap = Map<String, dynamic>.from(items as Map);
        }
      }
    }

    // Extract address information if available
    String? officeAddress;
    String? phone;
    String? email;
    String? role; // Added separate field for actual role/position
    List<String> socialMediaLinks = [];

    if (details.containsKey('addressInformation') &&
        details['addressInformation'] is Map) {
      final addressInfo =
          Map<String, dynamic>.from(details['addressInformation'] as Map);
      officeAddress = addressInfo['officeAddress']?.toString();
      phone = addressInfo['phoneNumber']?.toString();

      // Extract email if available
      if (addressInfo.containsKey('email')) {
        email = addressInfo['email']?.toString();
      }
    }

    // Try to extract email from other sources
    if (email == null && details.containsKey('email')) {
      email = details['email']?.toString();
    }

    if (email == null && details.containsKey('contactForm')) {
      email = details['contactForm']?.toString();
    }

    // Look for emails in "contactInformation" if available
    if (email == null &&
        details.containsKey('contactInformation') &&
        details['contactInformation'] is Map) {
      final contactInfo =
          Map<String, dynamic>.from(details['contactInformation'] as Map);
      if (contactInfo.containsKey('email')) {
        email = contactInfo['email']?.toString();
      }
    }

    // Extract role information if available
    if (termMap.containsKey('memberType')) {
      role = termMap['memberType']?.toString();
    } else if (details.containsKey('memberType')) {
      role = details['memberType']?.toString();
    }

    // Extract social media info if available
    if (details.containsKey('socialMedia') && details['socialMedia'] is List) {
      final socialMediaList = details['socialMedia'] as List;
      for (var media in socialMediaList) {
        if (media is Map) {
          final mediaInfo = Map<String, dynamic>.from(media);
          if (mediaInfo.containsKey('type') &&
              mediaInfo.containsKey('account')) {
            socialMediaLinks
                .add('${mediaInfo['type']}: ${mediaInfo['account']}');
          }
        }
      }
    }

    // Phone and email (not address)
    if (phone == null && termMap.containsKey('phone')) {
      phone = termMap['phone']?.toString();
    }

    if (email == null && termMap.containsKey('email')) {
      email = termMap['email']?.toString();
    }

    if (email == null && termMap.containsKey('contact_form')) {
      email = termMap['contact_form']?.toString();
    }

    // Get website either from term or from official website URL
    String? website = termMap['website']?.toString();
    if (website == null && details.containsKey('officialWebsiteUrl')) {
      website = details['officialWebsiteUrl']?.toString();
    }

    // Handle image URL
    String? imageUrl;
    if (details.containsKey('depiction') && details['depiction'] is Map) {
      final depiction = Map<String, dynamic>.from(details['depiction'] as Map);
      imageUrl = depiction['imageUrl']?.toString();
    }

    // If no image URL but we have bioGuideId, construct a standard one
    if (imageUrl == null && details.containsKey('bioGuideId')) {
      final bioId = details['bioGuideId']?.toString();
      if (bioId != null && bioId.isNotEmpty) {
        imageUrl =
            'https://bioguide.congress.gov/bioguide/photo/${bioId[0]}/$bioId.jpg';
      }
    }

    // Get chamber info
    String chamber = termMap['chamber']?.toString() ?? '';

    // Get state and district info
    String state = termMap['state']?.toString() ??
        termMap['stateCode']?.toString() ??
        details['state']?.toString() ??
        '';
    String? district = termMap['district']?.toString();
    if (district == null && details.containsKey('district')) {
      district = details['district']?.toString();
    }

    // Extract party information
    String party = '';
    
    // First check partyHistory if available (most reliable source from Congress.gov API)
    if (details.containsKey('partyHistory') && details['partyHistory'] is List && (details['partyHistory'] as List).isNotEmpty) {
      final partyHistoryList = details['partyHistory'] as List;
      // Use the most recent party affiliation
      if (partyHistoryList.isNotEmpty) {
        final mostRecentParty = partyHistoryList[0];
        if (mostRecentParty is Map) {
          final partyMap = Map<String, dynamic>.from(mostRecentParty);
          if (partyMap.containsKey('partyName')) {
            party = partyMap['partyName']?.toString() ?? '';
          } else if (partyMap.containsKey('partyAbbreviation')) {
            // Convert abbreviation to full name
            final abbr = partyMap['partyAbbreviation']?.toString() ?? '';
            switch (abbr) {
              case 'R':
                party = 'Republican';
                break;
              case 'D':
                party = 'Democratic';
                break;
              case 'I':
                party = 'Independent';
                break;
              default:
                party = abbr;
            }
          }
        }
      }
    }
    
    // If still empty, try other potential sources
    if (party.isEmpty) {
      // Check term data
      if (termMap.containsKey('party')) {
        party = termMap['party']?.toString() ?? '';
      }
      
      // Check direct fields
      if (party.isEmpty && details.containsKey('party')) {
        party = details['party']?.toString() ?? '';
      }
      
      if (party.isEmpty && details.containsKey('partyName')) {
        party = details['partyName']?.toString() ?? '';
      }
    }

    // Convert 'R' or 'D' abbreviations to full names if needed
    if (party == 'R') {
      party = 'Republican';
    } else if (party == 'D') {
      party = 'Democratic';
    }

    // Don't use office in display title since it contains address
    String? displayTitle;
    if (role != null && role.isNotEmpty) {
      displayTitle = '$role, $state${district != null ? ' District $district' : ''}';
    } else {
      displayTitle = DistrictTypeFormatter.formatRoleWithLocation(
          chamber, null, state, district);
    }

    // Process sponsored and cosponsored bills
    List<RepresentativeBill> processedSponsoredBills = sponsoredBills
        .map((bill) => RepresentativeBill.fromMap(
            bill is Map ? Map<String, dynamic>.from(bill) : {}))
        .toList();
    
    List<RepresentativeBill> processedCosponsoredBills = cosponsoredBills
        .map((bill) => RepresentativeBill.fromMap(
            bill is Map ? Map<String, dynamic>.from(bill) : {}))
        .toList();

    // Convert all values to strings to handle both int and string types from API
    return RepresentativeDetails(
      bioGuideId: details['bioGuideId']?.toString() ?? '',
      name: details['name']?.toString() ??
          details['directOrderName']?.toString() ??
          details['invertedOrderName']?.toString() ??
          '',
      party: party,
      state: state,
      district: district,
      chamber: chamber,
      dateOfBirth:
          details['birthYear']?.toString() ?? details['birthDate']?.toString(),
      gender: details['gender']?.toString(),
      office: officeAddress, // Use office only for the physical address now
      phone: phone,
      email: email,
      website: website,
      imageUrl: imageUrl,
      socialMedia: socialMediaLinks.isEmpty ? null : socialMediaLinks,
      displayTitle: displayTitle,
      role: role, // Add separate role field
      sponsoredBills: processedSponsoredBills,
      cosponsoredBills: processedCosponsoredBills,
      legiscanBillsLoaded: false, // Initialize as not loaded
    );
  }

  // Get formatted display title
  String getDisplayTitle() {
    if (displayTitle != null && displayTitle!.isNotEmpty) {
      return displayTitle!;
    }
    return DistrictTypeFormatter.formatRoleWithLocation(
        chamber, null, state, district);
  }
  
  // Add LegiScan bills to sponsored bills list
  void addLegiscanBills(List<RepresentativeBill> legiscanBills) {
    if (legiscanBills.isNotEmpty) {
      // Mark each bill as coming from LegiScan
      for (var bill in legiscanBills) {
        bill.source = 'LegiScan';
      }
      sponsoredBills.addAll(legiscanBills);
      // Sort bills by introduced date (most recent first)
      sponsoredBills.sort((a, b) {
        if (a.introducedDate == null) return 1;
        if (b.introducedDate == null) return -1;
        return b.introducedDate!.compareTo(a.introducedDate!);
      });
    }
    legiscanBillsLoaded = true;
  }
}

// Extension for LocalRepresentative to convert to Representative
extension LocalRepToRepresentative on LocalRepresentative {
  Representative toRepresentative() {
    return Representative(
      name: name,
      bioGuideId: bioGuideId,
      party: party,
      chamber: level, // Use level as chamber for display
      state: state,
      district: district,
      office: office,
      phone: phone,
      email: email,
      website: website,
      imageUrl: imageUrl,
      socialMedia: socialMedia,
      displayTitle: DistrictTypeFormatter.formatRoleWithLocation(
          level, office, state, district),
    );
  }
}

/// Represents a bill sponsored or co-sponsored by a representative
class RepresentativeBill {
  final String congress;
  final String billType;
  final String billNumber;
  final String title;
  final String? introducedDate;
  final String? latestAction;
  // Added source to track where the bill came from
  String source = 'Congress';
  // Extra data map for additional bill information (especially for FL and GA)
  final Map<String, dynamic>? extraData;

  RepresentativeBill({
    required this.congress,
    required this.billType,
    required this.billNumber,
    required this.title,
    this.introducedDate,
    this.latestAction,
    this.source = 'Congress',
    this.extraData,
  });

  factory RepresentativeBill.fromMap(Map<String, dynamic> map) {
    // Extract latestAction text if it exists and handle properly
    String? latestActionText;
    if (map.containsKey('latestAction') && map['latestAction'] is Map) {
      final actionMap = Map<String, dynamic>.from(map['latestAction'] as Map);
      latestActionText = actionMap['text']?.toString();
    } else if (map.containsKey('latestAction') &&
        map['latestAction'] is String) {
      latestActionText = map['latestAction'] as String;
    }

    // Extract extra data if available
    Map<String, dynamic>? extraData;
    if (map.containsKey('extraData') && map['extraData'] is Map) {
      extraData = Map<String, dynamic>.from(map['extraData'] as Map);
    }

    // Convert all values to strings to prevent type errors
    return RepresentativeBill(
      congress: map['congress']?.toString() ?? '',
      billType: map['billType']?.toString() ?? '',
      billNumber: map['billNumber']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      introducedDate: map['introducedDate']?.toString(),
      latestAction: latestActionText,
      source: map['source']?.toString() ?? 'Congress',
      extraData: extraData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'congress': congress,
      'billType': billType,
      'billNumber': billNumber,
      'title': title,
      'introducedDate': introducedDate,
      'latestAction': latestAction,
      'source': source,
      'extraData': extraData,
    };
  }
  
  // Helper method to get a description
  String? get description {
    if (extraData != null && extraData!.containsKey('description')) {
      return extraData!['description'] as String?;
    }
    return null;
  }
  
  // Helper method to get state link
  String? get stateLink {
    if (extraData != null && extraData!.containsKey('state_link')) {
      return extraData!['state_link'] as String?;
    }
    return null;
  }
  
  // Helper method to get URL
  String? get url {
    if (extraData != null && extraData!.containsKey('url')) {
      return extraData!['url'] as String?;
    }
    return null;
  }
  
  // Helper method to get committee
  String? get committee {
    if (extraData != null && extraData!.containsKey('committee')) {
      return extraData!['committee'] as String?;
    }
    return null;
  }
  
  // Helper method to get status description
  String? get statusDescription {
    if (extraData != null && extraData!.containsKey('status_desc')) {
      return extraData!['status_desc'] as String?;
    }
    return null;
  }
}