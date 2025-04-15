// lib/models/local_representative_model.dart
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/representative_service.dart';

class LocalRepresentative {
 final String name;
 final String bioGuideId;
 final String party;
 final String level; // COUNTY, CITY, etc.
 final String state;
 final String district;
 final String office;
 final String? phone;
 final String? email;
 final String? website;
 final String? imageUrl;
 final List<String>? socialMedia;

 LocalRepresentative({
   required this.name,
   required this.bioGuideId,
   required this.party,
   required this.level,
   required this.state,
   required this.district,
   required this.office,
   this.phone,
   this.email,
   this.website,
   this.imageUrl,
   this.socialMedia,
 });

 // Convert to map for storage
 Map<String, dynamic> toMap() {
   return {
     'name': name,
     'bioGuideId': bioGuideId,
     'party': party,
     'level': level,
     'state': state,
     'district': district,
     'office': office,
     'phone': phone,
     'email': email,
     'website': website,
     'imageUrl': imageUrl,
     'socialMedia': socialMedia,
   };
 }

 // Create from map (e.g., from cache)
 factory LocalRepresentative.fromMap(Map<String, dynamic> map) {
   return LocalRepresentative(
     name: map['name'] ?? '',
     bioGuideId: map['bioGuideId'] ?? '',
     party: map['party'] ?? '',
     level: map['level'] ?? '',
     state: map['state'] ?? '',
     district: map['district'] ?? '',
     office: map['office'] ?? '',
     phone: map['phone'],
     email: map['email'],
     website: map['website'],
     imageUrl: map['imageUrl'],
     socialMedia: map['socialMedia'] != null 
         ? List<String>.from(map['socialMedia']) 
         : null,
   );
 }

 // Convert to Representative model for compatibility with existing UI
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
     website: website,
     imageUrl: imageUrl,
   );
 }
}