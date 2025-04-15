// lib/utils/address_validator.dart
import 'package:flutter/foundation.dart';

class AddressValidator {
  // Basic validation to ensure address has minimum required components
  static bool isValidAddress(String address) {
    // Trim the address and check if it's empty
    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) {
      return false;
    }
    
    // Check for minimum address components (street, city, state)
    // This is a basic check - a real validator would be more sophisticated
    final components = trimmedAddress.split(',');
    if (components.length < 2) {
      return false;
    }
    
    // Check if we have text before and after a comma (basic check for "street, city")
    return components[0].trim().isNotEmpty && components[1].trim().isNotEmpty;
  }
  
  // Helper to format address for consistent API calls
  static String formatAddress(String address) {
    // Remove extra spaces and standardize commas
    String formatted = address.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Make sure components are separated by commas with a single space after
    formatted = formatted.replaceAll(RegExp(r',\s*'), ', ');
    
    // Add a basic check for USA at the end if it doesn't have country
    if (!formatted.toLowerCase().contains('usa') && 
        !formatted.toLowerCase().contains('united states')) {
      formatted += ', USA';
    }
    
    return formatted;
  }
  
  // Get helpful error message for invalid address
  static String getErrorMessage(String address) {
    final trimmedAddress = address.trim();
    
    if (trimmedAddress.isEmpty) {
      return 'Please enter an address';
    }
    
    if (!trimmedAddress.contains(',')) {
      return 'Please use format: Street, City, State Zip';
    }
    
    return 'Please enter a complete address';
  }
  
  // Debug function to log address parsing
  static void debugAddress(String address) {
    if (!kDebugMode) return;
    
    print('Address validation:');
    print('Original: "$address"');
    print('Formatted: "${formatAddress(address)}"');
    print('Valid: ${isValidAddress(address)}');
    
    final components = address.split(',');
    print('Components (${components.length}):');
    for (int i = 0; i < components.length; i++) {
      print('  [$i]: "${components[i].trim()}"');
    }
  }
}