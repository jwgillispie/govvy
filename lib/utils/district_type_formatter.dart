// lib/utils/district_type_formatter.dart
class DistrictTypeFormatter {
  // Convert API district types to user-friendly terms
  static String formatDistrictType(String? districtType) {
    if (districtType == null || districtType.isEmpty) {
      return 'Unknown';
    }

    switch (districtType.toUpperCase()) {
      case 'NATIONAL_EXEC':
        return 'Federal Executive Branch';
      case 'NATIONAL_UPPER':
        return 'U.S. Senate';
      case 'NATIONAL_LOWER':
        return 'U.S. House of Representatives';
      case 'STATE_EXEC':
        return 'State Executive Branch';
      case 'STATE_UPPER':
        return 'State Senate';
      case 'STATE_LOWER':
        return 'State House';
      case 'LOCAL_EXEC':
        return 'City Mayor';
      case 'LOCAL':
        return 'City Council';
      case 'COUNTY':
        return 'County Commission';
      case 'SCHOOL':
        return 'School Board';
      // Handle special cases for common chamber names
      case 'SENATE':
        return 'U.S. Senate';
      case 'HOUSE':
        return 'U.S. House of Representatives';
      case 'CITY':
        return 'City Council';
      case 'MAYOR':
        return 'City Mayor';
      case 'GOVERNOR':
        return 'Governor';
      default:
        // If it's not a known code, make it sentence case and replace underscores with spaces
        return districtType.split('_')
            .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  // Get the original API district type from a user-friendly term
  static String getApiDistrictType(String? userFriendlyTerm) {
    if (userFriendlyTerm == null || userFriendlyTerm.isEmpty) {
      return '';
    }
    
    switch (userFriendlyTerm.trim()) {
      case 'Federal Executive Branch':
        return 'NATIONAL_EXEC';
      case 'U.S. Senate':
        return 'NATIONAL_UPPER';
      case 'U.S. House of Representatives':
        return 'NATIONAL_LOWER';
      case 'State Executive Branch':
        return 'STATE_EXEC';
      case 'State Senate':
        return 'STATE_UPPER';
      case 'State House':
        return 'STATE_LOWER';
      case 'City Mayor':
        return 'LOCAL_EXEC';
      case 'City Council':
        return 'LOCAL';
      case 'County Commission':
        return 'COUNTY';
      case 'School Board':
        return 'SCHOOL';
      default:
        // If no match found, return the original term
        return userFriendlyTerm;
    }
  }
  
  // Format role with location for user-friendly display
  static String formatRoleWithLocation(String? districtType, String? officeName, String state, String? district) {
    if (districtType == null || districtType.isEmpty) {
      return 'Unknown';
    }

    final String formattedRole = formatDistrictType(districtType);
    String location = '';

    // Determine the appropriate location format based on the role and available information
    if (district != null && district.isNotEmpty) {
      if (districtType.toUpperCase() == 'LOCAL_EXEC' || 
          districtType.toUpperCase() == 'MAYOR' || 
          formattedRole.contains('Mayor')) {
        location = 'of $district';
      } else {
        location = district;
      }
    } else {
      location = state;
    }

    // Format specific roles with office name
    if (officeName != null && officeName.isNotEmpty) {
      return '$officeName, $location';
    }

    // Format based on role type
    switch (districtType.toUpperCase()) {
      case 'NATIONAL_UPPER':
      case 'SENATE':
        return 'U.S. Senator, $state';
      
      case 'NATIONAL_LOWER': 
      case 'HOUSE':
        return district != null 
            ? 'U.S. Representative, $state-$district' 
            : 'U.S. Representative, $state';
      
      case 'STATE_EXEC':
        return 'State Executive, $state';
      
      case 'STATE_UPPER':
        return district != null 
            ? 'State Senator, $state District $district' 
            : 'State Senator, $state';
      
      case 'STATE_LOWER':
        return district != null 
            ? 'State Representative, $state District $district' 
            : 'State Representative, $state';
      
      case 'LOCAL_EXEC':
      case 'MAYOR':
        return 'Mayor of $location';
      
      case 'LOCAL':
      case 'CITY':
        return 'City Council Member, $location';
      
      case 'COUNTY':
        return 'County Commissioner, $location';
      
      case 'SCHOOL':
        return 'School Board Member, $location';
        
      default:
        return '$formattedRole, $location';
    }
  }
}