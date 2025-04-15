// lib/models/representative_model.dart
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
    return RepresentativeBill(
      congress: map['congress'] ?? '',
      billType: map['billType'] ?? '',
      billNumber: map['billNumber'] ?? '',
      title: map['title'] ?? '',
      introducedDate: map['introducedDate'],
      latestAction: map['latestAction']?['text'],
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
    final currentTerm = details['terms'] != null && details['terms'].isNotEmpty 
        ? details['terms'][0] : {};
        
    return RepresentativeDetails(
      bioGuideId: details['bioGuideId'] ?? '',
      name: details['name'] ?? '',
      party: currentTerm['party'] ?? '',
      state: currentTerm['state'] ?? '',
      district: currentTerm['district'],
      chamber: currentTerm['chamber'] ?? '',
      dateOfBirth: details['birthDate'],
      gender: details['gender'],
      office: currentTerm['office'],
      phone: currentTerm['phone'],
      website: currentTerm['website'],
      imageUrl: details['bioGuideId'] != null 
          ? 'https://bioguide.congress.gov/bioguide/photo/${details['bioGuideId'][0]}/${details['bioGuideId']}.jpg'
          : null,
      sponsoredBills: sponsoredBills
          .map((bill) => RepresentativeBill.fromMap(bill))
          .toList(),
      cosponsoredBills: cosponsoredBills
          .map((bill) => RepresentativeBill.fromMap(bill))
          .toList(),
    );
  }
}