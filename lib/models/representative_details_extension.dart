// lib/models/representative_details_extension.dart
import 'package:govvy/models/representative_model.dart';

/// Extension methods for RepresentativeDetails to add additional functionality
extension RepresentativeDetailsExtension on RepresentativeDetails {
  // Add CSV-sourced bills to the sponsored bills list
  void addCSVBills(List<RepresentativeBill> csvBills) {
    if (csvBills.isEmpty) return;
    
    // Mark each bill as coming from CSV
    for (var bill in csvBills) {
      bill.source = 'CSV';
    }
    
    // Add to existing bills
    sponsoredBills.addAll(csvBills);
    
    // Sort bills by introduced date (most recent first)
    sponsoredBills.sort((a, b) {
      if (a.introducedDate == null) return 1;
      if (b.introducedDate == null) return -1;
      return b.introducedDate!.compareTo(a.introducedDate!);
    });
  }
  
  // Check if this representative is a local or state representative (not federal)
  bool isLocalOrStateRepresentative() {
    final chamberUpper = chamber.toUpperCase();
    
    // Check if NOT a federal representative
    return !(
      chamberUpper.contains('NATIONAL') ||
      chamberUpper == 'SENATE' ||
      chamberUpper == 'HOUSE' ||
      chamberUpper == 'CONGRESS' ||
      chamberUpper == 'REPRESENTATIVE' ||
      chamberUpper == 'SENATOR'
    );
  }
  
  // Check if this is a state-level representative
  bool isStateRepresentative() {
    final chamberUpper = chamber.toUpperCase();
    
    return (
      chamberUpper.startsWith('STATE') ||
      chamberUpper == 'STATE_UPPER' ||
      chamberUpper == 'STATE_LOWER' ||
      chamberUpper == 'STATE_EXEC' ||
      chamberUpper == 'STATE SENATE' ||
      chamberUpper == 'STATE HOUSE' ||
      chamberUpper == 'STATE ASSEMBLY'
    );
  }
  
  // Check if this is a local representative (city, county, etc.)
  bool isLocalRepresentative() {
    final chamberUpper = chamber.toUpperCase();
    
    return (
      bioGuideId.startsWith('cicero-') ||
      chamberUpper.contains('LOCAL') ||
      chamberUpper.contains('CITY') ||
      chamberUpper.contains('COUNTY') ||
      chamberUpper.contains('TOWN') ||
      chamberUpper.contains('VILLAGE') ||
      chamberUpper.contains('MAYOR') ||
      chamberUpper.contains('SCHOOL') ||
      chamberUpper.contains('PLACE') ||
      chamberUpper.contains('TOWNSHIP') ||
      chamberUpper.contains('BOROUGH')
    );
  }
}