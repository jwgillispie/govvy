// lib/utils/government_level_helper.dart

import 'package:flutter/material.dart';

enum GovernmentLevel {
  federal,
  state,
  local,
}

class GovernmentLevelHelper {
  // Visual language system colors
  static const Color federalColor = Color(0xFF1E3A8A); // Blue
  static const Color stateColor = Color(0xFF16A085); // Green
  static const Color localColor = Color(0xFFFF8C00); // Orange

  // Icon mappings
  static const IconData federalIcon = Icons.account_balance;
  static const IconData stateIcon = Icons.flag;
  static const IconData localIcon = Icons.location_city;

  /// Determines government level from chamber/type string and optional context
  static GovernmentLevel getGovernmentLevel(String? chamber, {String? bioGuideId, String? source}) {
    // IMPORTANT: Anyone from Congress.gov should be Federal
    if (bioGuideId != null && 
        bioGuideId.isNotEmpty && 
        !bioGuideId.startsWith('cicero-') && 
        bioGuideId.length > 3) {
      // Congress.gov bioGuideIds are typically short alphanumeric codes (e.g., "B001230")
      // Cicero local IDs start with "cicero-"
      return GovernmentLevel.federal;
    }
    
    // Check source explicitly
    if (source == 'Congress' || source == 'congress.gov') {
      return GovernmentLevel.federal;
    }

    if (chamber == null || chamber.isEmpty) {
      return GovernmentLevel.local; // Default to local for unknown
    }

    final chamberLower = chamber.toLowerCase();

    // Federal level patterns
    if (chamberLower == 'senate' ||
        chamberLower == 'house' ||
        chamberLower == 'national_upper' ||
        chamberLower == 'national_lower' ||
        chamberLower.contains('congress') ||
        chamberLower.contains('federal') ||
        chamberLower == 'representative' ||
        chamberLower == 'senator') {
      return GovernmentLevel.federal;
    }

    // State level patterns
    if (chamberLower.startsWith('state_') ||
        chamberLower.contains('state senate') ||
        chamberLower.contains('state house') ||
        chamberLower.contains('assembly') ||
        chamberLower.contains('legislature')) {
      return GovernmentLevel.state;
    }

    // Local level patterns
    if (chamberLower == 'county' ||
        chamberLower == 'city' ||
        chamberLower == 'place' ||
        chamberLower == 'township' ||
        chamberLower == 'borough' ||
        chamberLower == 'town' ||
        chamberLower == 'village' ||
        chamberLower == 'local' ||
        chamberLower == 'local_exec' ||
        chamberLower.contains('council') ||
        chamberLower.contains('mayor') ||
        chamberLower.contains('commissioner') ||
        chamberLower.contains('school board')) {
      return GovernmentLevel.local;
    }

    // Default to local for unrecognized patterns
    return GovernmentLevel.local;
  }

  /// Gets the color for a government level
  static Color getLevelColor(GovernmentLevel level) {
    switch (level) {
      case GovernmentLevel.federal:
        return federalColor;
      case GovernmentLevel.state:
        return stateColor;
      case GovernmentLevel.local:
        return localColor;
    }
  }

  /// Gets the icon for a government level
  static IconData getLevelIcon(GovernmentLevel level) {
    switch (level) {
      case GovernmentLevel.federal:
        return federalIcon;
      case GovernmentLevel.state:
        return stateIcon;
      case GovernmentLevel.local:
        return localIcon;
    }
  }

  /// Gets the display name for a government level
  static String getLevelDisplayName(GovernmentLevel level) {
    switch (level) {
      case GovernmentLevel.federal:
        return 'Federal';
      case GovernmentLevel.state:
        return 'State';
      case GovernmentLevel.local:
        return 'Local';
    }
  }

  /// Gets the display name with short format
  static String getLevelShortName(GovernmentLevel level) {
    switch (level) {
      case GovernmentLevel.federal:
        return 'Fed';
      case GovernmentLevel.state:
        return 'State';
      case GovernmentLevel.local:
        return 'Local';
    }
  }

  /// Convenience method to get level from chamber string
  static GovernmentLevel getLevelFromChamber(String? chamber, {String? bioGuideId, String? source}) {
    return getGovernmentLevel(chamber, bioGuideId: bioGuideId, source: source);
  }
  
  /// Get level from Representative object (recommended method)
  static GovernmentLevel getLevelFromRepresentative(dynamic representative) {
    // Handle both Representative and RepresentativeDetails objects
    String? chamber;
    String? bioGuideId;
    
    if (representative != null) {
      // Try to access chamber property
      try {
        chamber = representative.chamber as String?;
      } catch (e) {
        chamber = null;
      }
      
      // Try to access bioGuideId property
      try {
        bioGuideId = representative.bioGuideId as String?;
      } catch (e) {
        bioGuideId = null;
      }
    }
    
    return getGovernmentLevel(chamber, bioGuideId: bioGuideId);
  }

  /// Convenience method to get level from bill type
  static GovernmentLevel getLevelFromBillType(String? billType) {
    if (billType == null || billType.isEmpty) {
      return GovernmentLevel.state; // Default for bills
    }

    final typeLower = billType.toLowerCase();
    
    if (typeLower == 'federal') {
      return GovernmentLevel.federal;
    } else if (typeLower == 'local') {
      return GovernmentLevel.local;
    } else {
      return GovernmentLevel.state; // Default for bills
    }
  }

  /// Gets a light version of the level color for backgrounds
  static Color getLevelLightColor(GovernmentLevel level) {
    switch (level) {
      case GovernmentLevel.federal:
        return federalColor.withOpacity(0.1);
      case GovernmentLevel.state:
        return stateColor.withOpacity(0.1);
      case GovernmentLevel.local:
        return localColor.withOpacity(0.1);
    }
  }

  /// Gets hierarchy order (for sorting)
  static int getLevelOrder(GovernmentLevel level) {
    switch (level) {
      case GovernmentLevel.federal:
        return 1;
      case GovernmentLevel.state:
        return 2;
      case GovernmentLevel.local:
        return 3;
    }
  }

  /// Sorts a list by government level hierarchy
  static List<T> sortByLevel<T>(List<T> items, GovernmentLevel Function(T) getLevelFunction) {
    return items..sort((a, b) {
      final levelA = getLevelFunction(a);
      final levelB = getLevelFunction(b);
      return getLevelOrder(levelA).compareTo(getLevelOrder(levelB));
    });
  }

  /// Groups items by government level
  static Map<GovernmentLevel, List<T>> groupByLevel<T>(
    List<T> items, 
    GovernmentLevel Function(T) getLevelFunction
  ) {
    final groups = <GovernmentLevel, List<T>>{
      GovernmentLevel.federal: [],
      GovernmentLevel.state: [],
      GovernmentLevel.local: [],
    };

    for (final item in items) {
      final level = getLevelFunction(item);
      groups[level]!.add(item);
    }

    return groups;
  }
}