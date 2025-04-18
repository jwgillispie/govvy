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
}