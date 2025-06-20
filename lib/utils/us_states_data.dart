class USStatesData {
  static const List<Map<String, String>> states = [
    {"name": "Alabama", "code": "AL"},
    {"name": "Alaska", "code": "AK"},
    {"name": "Arizona", "code": "AZ"},
    {"name": "Arkansas", "code": "AR"},
    {"name": "California", "code": "CA"},
    {"name": "Colorado", "code": "CO"},
    {"name": "Connecticut", "code": "CT"},
    {"name": "Delaware", "code": "DE"},
    {"name": "Florida", "code": "FL"},
    {"name": "Georgia", "code": "GA"},
    {"name": "Hawaii", "code": "HI"},
    {"name": "Idaho", "code": "ID"},
    {"name": "Illinois", "code": "IL"},
    {"name": "Indiana", "code": "IN"},
    {"name": "Iowa", "code": "IA"},
    {"name": "Kansas", "code": "KS"},
    {"name": "Kentucky", "code": "KY"},
    {"name": "Louisiana", "code": "LA"},
    {"name": "Maine", "code": "ME"},
    {"name": "Maryland", "code": "MD"},
    {"name": "Massachusetts", "code": "MA"},
    {"name": "Michigan", "code": "MI"},
    {"name": "Minnesota", "code": "MN"},
    {"name": "Mississippi", "code": "MS"},
    {"name": "Missouri", "code": "MO"},
    {"name": "Montana", "code": "MT"},
    {"name": "Nebraska", "code": "NE"},
    {"name": "Nevada", "code": "NV"},
    {"name": "New Hampshire", "code": "NH"},
    {"name": "New Jersey", "code": "NJ"},
    {"name": "New Mexico", "code": "NM"},
    {"name": "New York", "code": "NY"},
    {"name": "North Carolina", "code": "NC"},
    {"name": "North Dakota", "code": "ND"},
    {"name": "Ohio", "code": "OH"},
    {"name": "Oklahoma", "code": "OK"},
    {"name": "Oregon", "code": "OR"},
    {"name": "Pennsylvania", "code": "PA"},
    {"name": "Rhode Island", "code": "RI"},
    {"name": "South Carolina", "code": "SC"},
    {"name": "South Dakota", "code": "SD"},
    {"name": "Tennessee", "code": "TN"},
    {"name": "Texas", "code": "TX"},
    {"name": "Utah", "code": "UT"},
    {"name": "Vermont", "code": "VT"},
    {"name": "Virginia", "code": "VA"},
    {"name": "Washington", "code": "WA"},
    {"name": "West Virginia", "code": "WV"},
    {"name": "Wisconsin", "code": "WI"},
    {"name": "Wyoming", "code": "WY"},
    {"name": "District of Columbia", "code": "DC"},
  ];

  static const List<Map<String, String>> territories = [
    {"name": "American Samoa", "code": "AS"},
    {"name": "Guam", "code": "GU"},
    {"name": "Northern Mariana Islands", "code": "MP"},
    {"name": "Puerto Rico", "code": "PR"},
    {"name": "U.S. Virgin Islands", "code": "VI"},
  ];

  /// Get all states and territories combined
  static List<Map<String, String>> get all => [...states, ...territories];

  /// Get only US states (excludes DC and territories)
  static List<Map<String, String>> get statesOnly => 
      states.where((state) => state["code"] != "DC").toList();

  /// Get state name by code
  static String? getStateName(String code) {
    final state = all.firstWhere(
      (state) => state["code"] == code.toUpperCase(),
      orElse: () => {},
    );
    return state.isNotEmpty ? state["name"] : null;
  }

  /// Get state code by name
  static String? getStateCode(String name) {
    final state = all.firstWhere(
      (state) => state["name"]?.toLowerCase() == name.toLowerCase(),
      orElse: () => {},
    );
    return state.isNotEmpty ? state["code"] : null;
  }

  /// Check if code is valid
  static bool isValidCode(String code) {
    return all.any((state) => state["code"] == code.toUpperCase());
  }

  /// Check if name is valid
  static bool isValidName(String name) {
    return all.any((state) => state["name"]?.toLowerCase() == name.toLowerCase());
  }

  /// Get states sorted by name
  static List<Map<String, String>> get sortedByName {
    final sortedStates = List<Map<String, String>>.from(all);
    sortedStates.sort((a, b) => a["name"]!.compareTo(b["name"]!));
    return sortedStates;
  }

  /// Get states sorted by code
  static List<Map<String, String>> get sortedByCode {
    final sortedStates = List<Map<String, String>>.from(all);
    sortedStates.sort((a, b) => a["code"]!.compareTo(b["code"]!));
    return sortedStates;
  }

  /// Get list of state codes only
  static List<String> get codes => all.map((state) => state["code"]!).toList();

  /// Get list of state names only
  static List<String> get names => all.map((state) => state["name"]!).toList();

  /// Search states by partial name match
  static List<Map<String, String>> searchByName(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return all.where((state) => 
      state["name"]!.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Search states by partial code match
  static List<Map<String, String>> searchByCode(String query) {
    if (query.isEmpty) return [];
    
    final upperQuery = query.toUpperCase();
    return all.where((state) => 
      state["code"]!.startsWith(upperQuery)
    ).toList();
  }

  /// Get neighboring states (this is a simplified version - could be expanded)
  static List<String> getNeighboringStates(String stateCode) {
    const Map<String, List<String>> neighbors = {
      'AL': ['FL', 'GA', 'MS', 'TN'],
      'AK': [], // No land borders
      'AZ': ['CA', 'CO', 'NM', 'NV', 'UT'],
      'AR': ['LA', 'MO', 'MS', 'OK', 'TN', 'TX'],
      'CA': ['AZ', 'NV', 'OR'],
      'CO': ['AZ', 'KS', 'NE', 'NM', 'OK', 'UT', 'WY'],
      'CT': ['MA', 'NY', 'RI'],
      'DE': ['MD', 'NJ', 'PA'],
      'FL': ['AL', 'GA'],
      'GA': ['AL', 'FL', 'NC', 'SC', 'TN'],
      // Add more as needed...
    };
    
    return neighbors[stateCode.toUpperCase()] ?? [];
  }

  /// Get states by region
  static List<Map<String, String>> getStatesByRegion(USRegion region) {
    const Map<USRegion, List<String>> regionStates = {
      USRegion.northeast: ['CT', 'ME', 'MA', 'NH', 'NJ', 'NY', 'PA', 'RI', 'VT'],
      USRegion.midwest: ['IL', 'IN', 'IA', 'KS', 'MI', 'MN', 'MO', 'NE', 'ND', 'OH', 'SD', 'WI'],
      USRegion.south: ['AL', 'AR', 'DE', 'FL', 'GA', 'KY', 'LA', 'MD', 'MS', 'NC', 'OK', 'SC', 'TN', 'TX', 'VA', 'WV'],
      USRegion.west: ['AK', 'AZ', 'CA', 'CO', 'HI', 'ID', 'MT', 'NV', 'NM', 'OR', 'UT', 'WA', 'WY'],
    };
    
    final codes = regionStates[region] ?? [];
    return all.where((state) => codes.contains(state["code"])).toList();
  }

  /// Format state display text (e.g., "California (CA)")
  static String formatDisplayText(String stateCode) {
    final name = getStateName(stateCode);
    return name != null ? '$name ($stateCode)' : stateCode;
  }

  /// Format state display text from name
  static String formatDisplayTextFromName(String stateName) {
    final code = getStateCode(stateName);
    return code != null ? '$stateName ($code)' : stateName;
  }
}

enum USRegion {
  northeast,
  midwest,
  south,
  west,
}

extension USRegionExtension on USRegion {
  String get displayName {
    switch (this) {
      case USRegion.northeast:
        return 'Northeast';
      case USRegion.midwest:
        return 'Midwest';
      case USRegion.south:
        return 'South';
      case USRegion.west:
        return 'West';
    }
  }
}