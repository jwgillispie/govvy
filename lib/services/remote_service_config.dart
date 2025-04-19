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

  // Initialization status
  bool _initialized = false;

  // Initialize remote config
  Future<void> initialize() async {
    if (_initialized) return;

    try {
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

      _initialized = true;

      if (kDebugMode) {
        print('Remote Config initialized successfully');
        print(
            'CONGRESS_API_KEY: ${_remoteConfig.getString(congressApiKey).isEmpty ? "NOT SET" : "SET (hidden)"}');
        print(
            'GOOGLE_MAPS_API_KEY: ${_remoteConfig.getString(googleMapsApiKey).isEmpty ? "NOT SET" : "SET (hidden)"}');
        print(
            'CICERO_API_KEY: ${_remoteConfig.getString(ciceroApiKey).isEmpty ? "NOT SET" : "SET (hidden)"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Remote Config: $e');
      }
      // Fall back to .env file in development
      if (!kIsWeb) {
        await _loadLocalConfig();
      }
    }
  }

  // Fallback to load local .env config in development
  Future<void> _loadLocalConfig() async {
    try {
      await dotenv.load(fileName: "assets/.env");
      if (kDebugMode) {
        print(".env file loaded with ${dotenv.env.length} variables");
      }
    } catch (e) {
      if (kDebugMode) {
        print("WARNING: Error loading .env file: $e");
      }
    }
  }

  // Get API keys
  String? get getCongressApiKey {
    if (_initialized && _remoteConfig.getString(congressApiKey).isNotEmpty) {
      return _remoteConfig.getString(congressApiKey);
    }
    // Fall back to .env in development
    return dotenv.env['CONGRESS_API_KEY'];
  }

  String? get getGoogleMapsApiKey {
    if (_initialized && _remoteConfig.getString(googleMapsApiKey).isNotEmpty) {
      return _remoteConfig.getString(googleMapsApiKey);
    }
    // Fall back to .env in development
    return dotenv.env['GOOGLE_MAPS_API_KEY'];
  }

  String? get getCiceroApiKey {
    if (_initialized && _remoteConfig.getString(ciceroApiKey).isNotEmpty) {
      return _remoteConfig.getString(ciceroApiKey);
    }
    // Fall back to .env in development
    return dotenv.env['CICERO_API_KEY'];
  }
}
