// lib/services/remote_service_config.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RemoteConfigService {
  // Singleton instance
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  // Remote config instance
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Config keys
  static const String congressApiKey = 'CONGRESS_API_KEY';
  static const String googleMapsApiKey = 'GOOGLE_MAPS_API_KEY';
  static const String ciceroApiKey = 'CICERO_API_KEY';
  static const String legiscanApiKey = 'LEGISCAN_API_KEY'; // Added LegiScan API key
  static const String fecApiKey = 'FEC_API_KEY'; // Added FEC API key

  // Initialization status and source tracking
  bool _initialized = false;
  final Map<String, String> _keySource = {};

  // Initialize remote config with improved error handling and logging
  Future<void> initialize() async {
    if (_initialized) return;

    try {

      // Set default values (these will be used until remote values are fetched)
      await _remoteConfig.setDefaults({
        congressApiKey: '',
        googleMapsApiKey: '',
        ciceroApiKey: '',
        legiscanApiKey: '', // Added default for LegiScan API key
        fecApiKey: '', // Added default for FEC API key
      });

      // Set minimum fetch interval
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Fetch and activate values
      await _remoteConfig.fetchAndActivate();

      // Track which values came from Firebase
      if (_remoteConfig.getString(congressApiKey).isNotEmpty) {
        _keySource[congressApiKey] = 'Firebase';
      }
      if (_remoteConfig.getString(googleMapsApiKey).isNotEmpty) {
        _keySource[googleMapsApiKey] = 'Firebase';
      }
      if (_remoteConfig.getString(ciceroApiKey).isNotEmpty) {
        _keySource[ciceroApiKey] = 'Firebase';
      }
      if (_remoteConfig.getString(legiscanApiKey).isNotEmpty) {
        _keySource[legiscanApiKey] = 'Firebase';
      }
      if (_remoteConfig.getString(fecApiKey).isNotEmpty) {
        _keySource[fecApiKey] = 'Firebase';
      }

      _initialized = true;

      // Always try to load local config as well (in development)
      await _loadLocalConfig();

      // Log the available keys
      _logKeyStatus();
    } catch (e) {
      // Fall back to .env file in development
      await _loadLocalConfig();
      _logKeyStatus();
    }
  }

  // Fallback to load local .env config in development
  Future<void> _loadLocalConfig() async {
    try {
      await dotenv.load(fileName: "assets/.env");
      print('DEBUG: Loaded .env from assets/.env');

      // Track which values came from .env
      if (_keySource[congressApiKey] == null && dotenv.env[congressApiKey] != null) {
        _keySource[congressApiKey] = '.env';
      }
      if (_keySource[googleMapsApiKey] == null && dotenv.env[googleMapsApiKey] != null) {
        _keySource[googleMapsApiKey] = '.env';
      }
      if (_keySource[ciceroApiKey] == null && dotenv.env[ciceroApiKey] != null) {
        _keySource[ciceroApiKey] = '.env';
      }
      if (_keySource[legiscanApiKey] == null && dotenv.env[legiscanApiKey] != null) {
        _keySource[legiscanApiKey] = '.env';
      }
      if (_keySource[fecApiKey] == null && dotenv.env[fecApiKey] != null) {
        _keySource[fecApiKey] = '.env';
      }
    } catch (e) {
      // Also try root .env as fallback
      try {
        await dotenv.load(fileName: ".env");
        print('DEBUG: Loaded .env from root .env');
      } catch (e2) {
        print('DEBUG: Failed to load .env from both assets and root: $e2');
      }
    }
  }

  // Empty method stub that previously logged API key status
  void _logKeyStatus() {
    // API key status logging removed
  }

  // Mask API key for safe logging
  String _maskKey(String key) {
    if (key.length <= 8) {
      return '****';
    }
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  // Public method to validate and report on API keys
  Future<Map<String, bool>> validateApiKeys() async {
    if (!_initialized) {
      await initialize();
    }

    return {
      'congress': getCongressApiKey?.isNotEmpty == true,
      'googleMaps': getGoogleMapsApiKey?.isNotEmpty == true,
      'cicero': getCiceroApiKey?.isNotEmpty == true,
      'legiscan': getLegiscanApiKey?.isNotEmpty == true, // Added LegiScan validation
      'fec': getFecApiKey?.isNotEmpty == true, // Added FEC validation
    };
  }

  // Get API keys - with improved null safety
  String? get getCongressApiKey {
    if (!_initialized) {
      // Try to initialize if not done yet
      initialize();
    }

    // First try Remote Config
    final remoteKey = _remoteConfig.getString(congressApiKey);
    if (remoteKey.isNotEmpty) {
      return remoteKey;
    }
    
    // Fall back to .env
    final envKey = dotenv.env[congressApiKey];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    // Debug logging
    print('DEBUG: No Congress API key found in either Remote Config or .env');
    return null;
  }

  String? get getGoogleMapsApiKey {
    if (!_initialized) {
      // Try to initialize if not done yet
      initialize();
    }

    // First try Remote Config
    final remoteKey = _remoteConfig.getString(googleMapsApiKey);
    if (remoteKey.isNotEmpty) {
      return remoteKey;
    }
    
    // Fall back to .env
    return dotenv.env[googleMapsApiKey];
  }

  String? get getCiceroApiKey {
    if (!_initialized) {
      // Try to initialize if not done yet
      initialize();
    }

    // First try Remote Config
    final remoteKey = _remoteConfig.getString(ciceroApiKey);
    if (remoteKey.isNotEmpty) {
      return remoteKey;
    }
    
    // Fall back to .env
    final envKey = dotenv.env[ciceroApiKey];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    // Debug logging
    print('DEBUG: No Cicero API key found in either Remote Config or .env');
    return null;
  }
  
  // Added getter for LegiScan API key
  String? get getLegiscanApiKey {
    if (!_initialized) {
      // Try to initialize if not done yet
      initialize();
    }

    // First try Remote Config
    final remoteKey = _remoteConfig.getString(legiscanApiKey);
    if (remoteKey.isNotEmpty) {
      return remoteKey;
    }
    
    // Fall back to .env
    return dotenv.env[legiscanApiKey];
  }
  
  // Added getter for FEC API key
  String? get getFecApiKey {
    if (!_initialized) {
      // Try to initialize if not done yet
      initialize();
    }

    // First try Remote Config
    final remoteKey = _remoteConfig.getString(fecApiKey);
    if (remoteKey.isNotEmpty) {
      return remoteKey;
    }
    
    // Fall back to .env
    return dotenv.env[fecApiKey];
  }
}