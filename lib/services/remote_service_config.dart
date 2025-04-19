// lib/services/remote_config_service.dart
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

  // Initialization status and source tracking
  bool _initialized = false;
  Map<String, String> _keySource = {};

  // Initialize remote config with improved error handling and logging
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kDebugMode) {
        print('🔑 Initializing RemoteConfigService...');
      }

      // Set default values (these will be used until remote values are fetched)
      await _remoteConfig.setDefaults({
        congressApiKey: '',
        googleMapsApiKey: '',
        ciceroApiKey: '',
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

      _initialized = true;

      // Always try to load local config as well (in development)
      if (!kIsWeb) {
        await _loadLocalConfig();
      }

      // Log the available keys
      _logKeyStatus();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Remote Config: $e');
      }
      // Fall back to .env file in development
      if (!kIsWeb) {
        await _loadLocalConfig();
        _logKeyStatus();
      }
    }
  }

  // Fallback to load local .env config in development
  Future<void> _loadLocalConfig() async {
    try {
      await dotenv.load(fileName: "assets/.env");
      if (kDebugMode) {
        print("🔑 Loading .env file with ${dotenv.env.length} variables");
      }

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
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error loading .env file: $e");
      }
    }
  }

  // Log the status of all API keys
  void _logKeyStatus() {
    if (!kDebugMode) return;

    print('🔑 API Key Status:');
    
    // Congress API Key
    final congressKey = getCongressApiKey;
    if (congressKey != null && congressKey.isNotEmpty) {
      print('✅ CONGRESS_API_KEY: Valid (from ${_keySource[congressApiKey] ?? "unknown"}, ${_maskKey(congressKey)})');
    } else {
      print('❌ CONGRESS_API_KEY: Missing or empty');
    }
    
    // Google Maps API Key
    final googleKey = getGoogleMapsApiKey;
    if (googleKey != null && googleKey.isNotEmpty) {
      print('✅ GOOGLE_MAPS_API_KEY: Valid (from ${_keySource[googleMapsApiKey] ?? "unknown"}, ${_maskKey(googleKey)})');
    } else {
      print('❌ GOOGLE_MAPS_API_KEY: Missing or empty');
    }
    
    // Cicero API Key
    final ciceroKey = getCiceroApiKey;
    if (ciceroKey != null && ciceroKey.isNotEmpty) {
      print('✅ CICERO_API_KEY: Valid (from ${_keySource[ciceroApiKey] ?? "unknown"}, ${_maskKey(ciceroKey)})');
    } else {
      print('❌ CICERO_API_KEY: Missing or empty');
    }
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
    return dotenv.env[congressApiKey];
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
    return dotenv.env[ciceroApiKey];
  }
}