import 'package:flutter/services.dart';

// TextInputFormatter for US phone numbers (###) ###-####
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digit characters
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 10 digits
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    
    // Format the digits
    String formattedValue = '';
    
    if (digits.isEmpty) {
      formattedValue = '';
    } else if (digits.length <= 3) {
      formattedValue = '($digits)';
    } else if (digits.length <= 6) {
      formattedValue = '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else {
      formattedValue = '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    
    // Update the selection to end of input
    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}

// Function to normalize phone number to E.164 format
String normalizePhoneNumber(String phoneNumber) {
  // Strip all non-digit characters
  String digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  
  // For US numbers, ensure it has 10 digits and add +1
  if (digits.length == 10) {
    return '+1$digits';
  }
  
  // If it already has a country code (e.g., 11+ digits), add + prefix
  if (digits.length > 10) {
    return '+$digits';
  }
  
  // Return as is if it doesn't fit expected patterns
  return digits;
}

// Function to validate phone number
bool isValidPhoneNumber(String phoneNumber) {
  // Strip all non-digit characters
  String digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Check if it has at least 10 digits
  return digits.length >= 10;
}