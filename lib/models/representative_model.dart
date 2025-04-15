// lib/models/representative_model.dart


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
  final String? website;

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
    this.website,
  });

  // lib/models/representative_model.dart - Add these methods to your existing Representative class

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
    'website': website,
    'imageUrl': imageUrl,
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
    website: map['website'],
    imageUrl: map['imageUrl'],
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
      website: json['website']?.toString(),
    );
  }
}

class RepresentativeBill {
  final String congress;
  final String billType;
  final String billNumber;
  final String title;
  final String? introducedDate;
  final String? latestAction;

  RepresentativeBill({
    required this.congress,
    required this.billType,
    required this.billNumber,
    required this.title,
    this.introducedDate,
    this.latestAction,
  });

  factory RepresentativeBill.fromMap(Map<String, dynamic> map) {
    // Extract latestAction text if it exists and handle properly
    String? latestActionText;
    if (map['latestAction'] is Map) {
      final actionMap = Map<String, dynamic>.from(map['latestAction'] as Map);
      latestActionText = actionMap['text']?.toString();
    }

    // Convert all values to strings to prevent type errors
    return RepresentativeBill(
      congress: map['congress']?.toString() ?? '',
      billType: map['billType']?.toString() ?? '',
      billNumber: map['billNumber']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      introducedDate: map['introducedDate']?.toString(),
      latestAction: latestActionText,
    );
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
  final String? office;
  final String? phone;
  final String? website;
  final String? imageUrl;
  final List<RepresentativeBill> sponsoredBills;
  final List<RepresentativeBill> cosponsoredBills;

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
    this.website,
    this.imageUrl,
    required this.sponsoredBills,
    required this.cosponsoredBills,
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
    String? office;
    String? phone;
    
    if (details.containsKey('addressInformation') && details['addressInformation'] is Map) {
      final addressInfo = Map<String, dynamic>.from(details['addressInformation'] as Map);
      office = addressInfo['officeAddress']?.toString();
      phone = addressInfo['phoneNumber']?.toString();
    }
    
    // Use term data for contact info if not found in address info
    if (office == null && termMap.containsKey('office')) {
      office = termMap['office']?.toString();
    }
    
    if (phone == null && termMap.containsKey('phone')) {
      phone = termMap['phone']?.toString();
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
        imageUrl = 'https://bioguide.congress.gov/bioguide/photo/${bioId[0]}/$bioId.jpg';
      }
    }

    // Convert all values to strings to handle both int and string types from API
    return RepresentativeDetails(
      bioGuideId: details['bioGuideId']?.toString() ?? '',
      name: details['name']?.toString() ?? 
            details['invertedOrderName']?.toString() ?? 
            details['directOrderName']?.toString() ?? '',
      party: termMap['party']?.toString() ?? 
             termMap['partyName']?.toString() ?? 
             details['partyName']?.toString() ?? '',
      state: termMap['state']?.toString() ?? 
             termMap['stateCode']?.toString() ?? 
             details['state']?.toString() ?? '',
      district: termMap['district']?.toString(), // Convert int to string
      chamber: termMap['chamber']?.toString() ?? '',
      dateOfBirth: details['birthYear']?.toString() ?? details['birthDate']?.toString(),
      gender: details['gender']?.toString(),
      office: office,
      phone: phone,
      website: website,
      imageUrl: imageUrl,
      sponsoredBills: sponsoredBills
          .map((bill) => RepresentativeBill.fromMap(
              bill is Map ? Map<String, dynamic>.from(bill) : {}))
          .toList(),
      cosponsoredBills: cosponsoredBills
          .map((bill) => RepresentativeBill.fromMap(
              bill is Map ? Map<String, dynamic>.from(bill) : {}))
          .toList(),
    );
  }

  
}