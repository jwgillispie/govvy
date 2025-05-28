import 'package:govvy/services/network_service.dart';

class CongressMember {
  final String name;
  final String party;
  final String state;
  final String chamber; // House or Senate
  final String? district;
  final String? bioguideId;

  CongressMember({
    required this.name,
    required this.party,
    required this.state,
    required this.chamber,
    this.district,
    this.bioguideId,
  });

  factory CongressMember.fromJson(Map<String, dynamic> json) {
    return CongressMember(
      name: json['name']?.toString() ?? '',
      party: json['partyName']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      chamber: json['chamber']?.toString() ?? '',
      district: json['district']?.toString(),
      bioguideId: json['bioguideId']?.toString(),
    );
  }

  String get displayName {
    if (chamber == 'House' && district != null) {
      return '$name ($party-$state-$district)';
    } else {
      return '$name ($party-$state)';
    }
  }

  String get officeTitle {
    if (chamber == 'House') {
      return 'Representative';
    } else {
      return 'Senator';
    }
  }
}

class CongressMembersService {
  static final CongressMembersService _instance = CongressMembersService._internal();
  factory CongressMembersService() => _instance;
  CongressMembersService._internal();

  final NetworkService _networkService = NetworkService();
  
  // Cache for members to avoid repeated API calls
  List<CongressMember>? _cachedMembers;
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(hours: 24);

  Future<List<CongressMember>> getCurrentMembers() async {
    // Return cached data if still valid
    if (_cachedMembers != null && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
      return _cachedMembers!;
    }

    try {
      // Fetch current Congress members (118th Congress)
      final response = await _networkService.getFromCongressApi(
        '/member',
        queryParams: {
          'currentMember': 'true',
          'limit': '600', // Ensure we get all members
        },
      );

      final List<dynamic> membersData = response['members'] ?? [];
      
      final members = membersData.map((memberData) {
        try {
          return CongressMember.fromJson(memberData);
        } catch (e) {
          // Skip malformed entries
          return null;
        }
      }).where((member) => member != null).cast<CongressMember>().toList();

      // Sort by state, then by name
      members.sort((a, b) {
        final stateComparison = a.state.compareTo(b.state);
        if (stateComparison != 0) return stateComparison;
        return a.name.compareTo(b.name);
      });

      // Cache the results
      _cachedMembers = members;
      _lastFetch = DateTime.now();

      return members;
    } catch (e) {
      // If API fails, return empty list or cached data if available
      return _cachedMembers ?? [];
    }
  }

  Future<List<CongressMember>> searchMembers(String query) async {
    final allMembers = await getCurrentMembers();
    
    if (query.isEmpty) return allMembers;

    final lowerQuery = query.toLowerCase();
    return allMembers.where((member) {
      return member.name.toLowerCase().contains(lowerQuery) ||
             member.state.toLowerCase().contains(lowerQuery) ||
             member.party.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<List<CongressMember>> getMembersByState(String state) async {
    final allMembers = await getCurrentMembers();
    print('Congress Service: Filtering ${allMembers.length} members for state: $state');
    
    // Debug: Print unique states in the data
    final uniqueStates = allMembers.map((m) => m.state).toSet().toList()..sort();
    print('Congress Service: Available states in data: $uniqueStates');
    
    final filtered = allMembers.where((member) => 
        member.state.toLowerCase() == state.toLowerCase()).toList();
    print('Congress Service: Found ${filtered.length} members for state: $state');
    
    if (filtered.isEmpty && state != 'All States') {
      print('Congress Service: No members found for $state. Checking if state name format matches...');
      // Try to find similar state names in case of formatting differences
      final similarStates = allMembers.where((member) => 
          member.state.toLowerCase().contains(state.toLowerCase().substring(0, 2))).toList();
      if (similarStates.isNotEmpty) {
        print('Congress Service: Found similar states: ${similarStates.map((m) => m.state).toSet()}');
      }
    }
    
    return filtered;
  }

  Future<List<CongressMember>> getMembersByChamber(String chamber) async {
    final allMembers = await getCurrentMembers();
    return allMembers.where((member) => 
        member.chamber.toLowerCase() == chamber.toLowerCase()).toList();
  }

  Future<List<String>> getAvailableStates() async {
    final allMembers = await getCurrentMembers();
    final states = allMembers.map((m) => m.state).toSet().toList()..sort();
    print('Congress Service: Available states from API: $states');
    return states;
  }
}