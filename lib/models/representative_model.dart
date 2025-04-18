// lib/models/representative_model.dart - Enhanced Representative model

import 'package:govvy/models/local_representative_model.dart';

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
  final String? email;       // Added email field
  final String? website;
  final List<String>? socialMedia; // Added social media field

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
    this.email,          // Added to constructor
    this.website,
    this.socialMedia,    // Added to constructor
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
      'email': email,             // Added to map
      'website': website,
      'imageUrl': imageUrl,
      'socialMedia': socialMedia, // Added to map
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
      email: map['email'],                     // Extract from map
      website: map['website'],
      imageUrl: map['imageUrl'],
      socialMedia: map['socialMedia'] != null 
          ? List<String>.from(map['socialMedia']) 
          : null,                             // Extract from map
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
      email: json['email']?.toString(),        // Added to fromJson
      website: json['website']?.toString(),
      socialMedia: json['socialMedia'] is List 
          ? List<String>.from(json['socialMedia']) 
          : null,                              // Added to fromJson
    );
  }
}

// Similarly update the RepresentativeDetails class to include email and social media
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
  final String? email;              // Added email field
  final String? website;
  final String? imageUrl;
  final List<String>? socialMedia;  // Added social media field
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
    this.email,               // Added to constructor
    this.website,
    this.imageUrl,
    this.socialMedia,         // Added to constructor
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
    String? email;      // Added email variable
    List<String> socialMediaLinks = [];  // Added for social media
    
    if (details.containsKey('addressInformation') && details['addressInformation'] is Map) {
      final addressInfo = Map<String, dynamic>.from(details['addressInformation'] as Map);
      office = addressInfo['officeAddress']?.toString();
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
    if (email == null && details.containsKey('contactInformation') && details['contactInformation'] is Map) {
      final contactInfo = Map<String, dynamic>.from(details['contactInformation'] as Map);
      if (contactInfo.containsKey('email')) {
        email = contactInfo['email']?.toString();
      }
    }
    
    // Extract social media info if available
    if (details.containsKey('socialMedia') && details['socialMedia'] is List) {
      final socialMediaList = details['socialMedia'] as List;
      for (var media in socialMediaList) {
        if (media is Map) {
          final mediaInfo = Map<String, dynamic>.from(media);
          if (mediaInfo.containsKey('type') && mediaInfo.containsKey('account')) {
            socialMediaLinks.add('${mediaInfo['type']}: ${mediaInfo['account']}');
          }
        }
      }
    }
    
    // Use term data for contact info if not found in address info
    if (office == null && termMap.containsKey('office')) {
      office = termMap['office']?.toString();
    }
    
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
      email: email,                                // Added email field
      website: website,
      imageUrl: imageUrl,
      socialMedia: socialMediaLinks.isEmpty ? null : socialMediaLinks, // Added social media
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

// Make sure LocalRepresentative.toRepresentative() method properly handles the new fields
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
      email: email,  // Pass email to Representative
      website: website,
      imageUrl: imageUrl,
      socialMedia: socialMedia, // Pass social media data
    );
  }
}// Add this class definition to lib/models/representative_model.dart

/// Represents a bill sponsored or co-sponsored by a representative
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
    if (map.containsKey('latestAction') && map['latestAction'] is Map) {
      final actionMap = Map<String, dynamic>.from(map['latestAction'] as Map);
      latestActionText = actionMap['text']?.toString();
    } else if (map.containsKey('latestAction') && map['latestAction'] is String) {
      latestActionText = map['latestAction'] as String;
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

  Map<String, dynamic> toMap() {
    return {
      'congress': congress,
      'billType': billType,
      'billNumber': billNumber,
      'title': title,
      'introducedDate': introducedDate,
      'latestAction': latestAction,
    };
  }
}