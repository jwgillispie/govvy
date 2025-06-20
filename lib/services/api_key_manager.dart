import 'package:flutter/foundation.dart';
import 'package:govvy/services/remote_service_config.dart';

enum ApiService {
  congress,
  googleMaps,
  cicero,
  legiscan,
  fec,
}

class ApiKeyManager {
  static final ApiKeyManager _instance = ApiKeyManager._internal();
  factory ApiKeyManager() => _instance;
  ApiKeyManager._internal();

  final RemoteConfigService _remoteConfig = RemoteConfigService();

  // Cache for API keys to avoid repeated config calls
  final Map<ApiService, String?> _keyCache = {};
  bool _cacheInitialized = false;

  Future<void> initialize() async {
    if (_cacheInitialized) return;
    
    await _remoteConfig.initialize();
    _refreshCache();
    _cacheInitialized = true;
  }

  void _refreshCache() {
    _keyCache[ApiService.congress] = _remoteConfig.getCongressApiKey;
    _keyCache[ApiService.googleMaps] = _remoteConfig.getGoogleMapsApiKey;
    _keyCache[ApiService.cicero] = _remoteConfig.getCiceroApiKey;
    _keyCache[ApiService.legiscan] = _remoteConfig.getLegiscanApiKey;
    _keyCache[ApiService.fec] = _remoteConfig.getFecApiKey;
  }

  String? getApiKey(ApiService service) {
    if (!_cacheInitialized) {
      if (kDebugMode) {
        print('ApiKeyManager: Not initialized, using direct config access for ${service.name}');
      }
      return _getKeyDirectly(service);
    }
    
    return _keyCache[service];
  }

  String? _getKeyDirectly(ApiService service) {
    switch (service) {
      case ApiService.congress:
        return _remoteConfig.getCongressApiKey;
      case ApiService.googleMaps:
        return _remoteConfig.getGoogleMapsApiKey;
      case ApiService.cicero:
        return _remoteConfig.getCiceroApiKey;
      case ApiService.legiscan:
        return _remoteConfig.getLegiscanApiKey;
      case ApiService.fec:
        return _remoteConfig.getFecApiKey;
    }
  }

  bool hasApiKey(ApiService service) {
    final key = getApiKey(service);
    return key != null && key.isNotEmpty;
  }

  List<ApiService> getAvailableServices() {
    return ApiService.values.where((service) => hasApiKey(service)).toList();
  }

  List<ApiService> getMissingServices() {
    return ApiService.values.where((service) => !hasApiKey(service)).toList();
  }

  Map<ApiService, bool> getServiceStatus() {
    return Map.fromEntries(
      ApiService.values.map((service) => MapEntry(service, hasApiKey(service)))
    );
  }

  String getServiceDisplayName(ApiService service) {
    switch (service) {
      case ApiService.congress:
        return 'Congress.gov API';
      case ApiService.googleMaps:
        return 'Google Maps API';
      case ApiService.cicero:
        return 'Cicero API';
      case ApiService.legiscan:
        return 'LegiScan API';
      case ApiService.fec:
        return 'FEC API';
    }
  }

  String getServiceDescription(ApiService service) {
    switch (service) {
      case ApiService.congress:
        return 'Access to federal legislative data and member information';
      case ApiService.googleMaps:
        return 'Geocoding and location services';
      case ApiService.cicero:
        return 'Local representative information and district mapping';
      case ApiService.legiscan:
        return 'State-level legislative data and bill tracking';
      case ApiService.fec:
        return 'Federal campaign finance data';
    }
  }

  Map<String, String> getHeaders({
    required ApiService service,
    Map<String, String>? additionalHeaders,
  }) {
    final apiKey = getApiKey(service);
    final headers = <String, String>{
      'User-Agent': 'Govvy/1.0.0',
      'Accept': 'application/json',
    };

    if (apiKey != null && apiKey.isNotEmpty) {
      switch (service) {
        case ApiService.congress:
          headers['X-API-Key'] = apiKey;
          break;
        case ApiService.legiscan:
          headers['Authorization'] = 'Bearer $apiKey';
          break;
        case ApiService.fec:
          headers['X-API-Key'] = apiKey;
          break;
        case ApiService.cicero:
          headers['X-API-Key'] = apiKey;
          break;
        case ApiService.googleMaps:
          // Google Maps API key is typically passed as query parameter
          break;
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  Uri buildUrlWithApiKey({
    required String baseUrl,
    required String path,
    required ApiService service,
    Map<String, dynamic>? queryParameters,
  }) {
    final apiKey = getApiKey(service);
    final effectiveQueryParams = Map<String, dynamic>.from(queryParameters ?? {});

    // Add API key as query parameter for services that require it
    if (apiKey != null && apiKey.isNotEmpty) {
      switch (service) {
        case ApiService.googleMaps:
          effectiveQueryParams['key'] = apiKey;
          break;
        case ApiService.legiscan:
          effectiveQueryParams['key'] = apiKey;
          break;
        case ApiService.fec:
          effectiveQueryParams['api_key'] = apiKey;
          break;
        default:
          // For other services, API key goes in headers
          break;
      }
    }

    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = baseUrl.endsWith('/') 
        ? '${baseUrl.substring(0, baseUrl.length - 1)}$cleanPath'
        : '$baseUrl$cleanPath';
    
    return Uri.parse(fullUrl).replace(queryParameters: effectiveQueryParams);
  }

  void clearCache() {
    _keyCache.clear();
    _cacheInitialized = false;
  }

  void refreshKeys() {
    if (_cacheInitialized) {
      _refreshCache();
    }
  }

  String getDebugInfo() {
    if (!kDebugMode) return 'Debug info only available in debug mode';
    
    final buffer = StringBuffer();
    buffer.writeln('ApiKeyManager Debug Info:');
    buffer.writeln('Cache initialized: $_cacheInitialized');
    buffer.writeln('Available services:');
    
    for (final service in ApiService.values) {
      final hasKey = hasApiKey(service);
      final key = getApiKey(service);
      final keyPreview = hasKey && key != null && key.length > 8 
          ? '${key.substring(0, 4)}...${key.substring(key.length - 4)}'
          : 'None';
      buffer.writeln('  ${getServiceDisplayName(service)}: $hasKey ($keyPreview)');
    }
    
    return buffer.toString();
  }
}