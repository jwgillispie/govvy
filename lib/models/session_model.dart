// lib/models/session_model.dart
import 'package:flutter/foundation.dart';

/// Model representing a legislative session from LegiScan API
class SessionData {
  final int sessionId;
  final String stateCode;
  final String name;
  final String title;
  final DateTime sessionStartDate;
  final DateTime sessionEndDate;
  final bool isActive;

  SessionData({
    required this.sessionId,
    required this.stateCode,
    required this.name,
    required this.title,
    required this.sessionStartDate,
    required this.sessionEndDate,
    required this.isActive,
  });

  /// Create a SessionData instance from JSON map
  factory SessionData.fromJson(Map<String, dynamic> json) {
    try {
      // Handle sessionId that could be int or string
      int sessionId;
      if (json.containsKey('session_id')) {
        if (json['session_id'] is int) {
          sessionId = json['session_id'];
        } else if (json['session_id'] is String) {
          sessionId = int.parse(json['session_id']);
        } else {
          sessionId = 0;
        }
      } else if (json.containsKey('id')) {
        // Handle alternative field name
        if (json['id'] is int) {
          sessionId = json['id'];
        } else if (json['id'] is String) {
          sessionId = int.parse(json['id']);
        } else {
          sessionId = 0;
        }
      } else {
        sessionId = 0;
      }
      
      // Parse dates - handle different format possibilities
      DateTime? startDate;
      DateTime? endDate;
      
      try {
        // Try different possible field names for start date
        final startDateField = json.containsKey('session_start') 
            ? 'session_start'
            : (json.containsKey('start_date') ? 'start_date' : null);
            
        if (startDateField != null && json[startDateField] is String) {
          startDate = DateTime.parse(json[startDateField]);
        } else {
          startDate = DateTime(2000);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing session start date: ${json['session_start'] ?? json['start_date']}');
        }
        startDate = DateTime(2000);
      }
      
      try {
        // Try different possible field names for end date
        final endDateField = json.containsKey('session_end') 
            ? 'session_end'
            : (json.containsKey('end_date') ? 'end_date' : null);
            
        if (endDateField != null && json[endDateField] is String) {
          endDate = DateTime.parse(json[endDateField]);
        } else {
          endDate = DateTime(2100);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing session end date: ${json['session_end'] ?? json['end_date']}');
        }
        endDate = DateTime(2100);
      }

      // Parse state code - handle different field names
      String stateCode = '';
      if (json.containsKey('state_code')) {
        stateCode = json['state_code'] as String;
      } else if (json.containsKey('state')) {
        stateCode = json['state'] as String;
      } else if (json.containsKey('state_abbr')) {
        stateCode = json['state_abbr'] as String;
      }

      // Parse name and title - handle different field names
      String name = '';
      if (json.containsKey('name')) {
        name = json['name'] as String? ?? '';
      } else if (json.containsKey('session_name')) {
        name = json['session_name'] as String? ?? '';
      }
      
      String title = '';
      if (json.containsKey('title')) {
        title = json['title'] as String? ?? '';
      } else if (json.containsKey('session_title')) {
        title = json['session_title'] as String? ?? '';
      } else if (json.containsKey('description')) {
        title = json['description'] as String? ?? '';
      }

      // Parse active status - handle different field names
      bool isActive = false;
      if (json.containsKey('is_active')) {
        isActive = json['is_active'] == 1 || json['is_active'] == true;
      } else if (json.containsKey('active')) {
        isActive = json['active'] == 1 || json['active'] == true;
      } else if (json.containsKey('status')) {
        isActive = json['status'] == 'active' || json['status'] == 1 || json['status'] == true;
      }

      return SessionData(
        sessionId: sessionId,
        stateCode: stateCode,
        name: name,
        title: title,
        sessionStartDate: startDate,
        sessionEndDate: endDate,
        isActive: isActive,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating SessionData from JSON: $e');
        print('JSON data: $json');
      }
      
      // Return a fallback object
      return SessionData(
        sessionId: 0,
        stateCode: '',
        name: 'Error',
        title: 'Error loading session',
        sessionStartDate: DateTime(2000),
        sessionEndDate: DateTime(2100),
        isActive: false,
      );
    }
  }

  /// Convert to JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'state_code': stateCode,
      'name': name,
      'title': title,
      'session_start': sessionStartDate.toIso8601String(),
      'session_end': sessionEndDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }
}