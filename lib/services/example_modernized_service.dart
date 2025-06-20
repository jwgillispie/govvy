import 'package:flutter/foundation.dart';
import 'package:govvy/services/base_http_service.dart';
import 'package:govvy/services/api_key_manager.dart';
import 'package:govvy/services/cache_manager.dart';
import 'package:govvy/utils/error_handler.dart';

/// Example service showing how to use the new consolidated base classes
/// This demonstrates the pattern that other services should follow
class ExampleModernizedService extends BaseHttpService {
  static final ExampleModernizedService _instance = ExampleModernizedService._internal();
  factory ExampleModernizedService() => _instance;
  ExampleModernizedService._internal();

  final ApiKeyManager _apiKeyManager = ApiKeyManager();
  final CacheManager _cacheManager = CacheManager();
  
  static const String _baseUrl = 'https://api.example.com/v1';
  static const Duration _cacheTimeout = Duration(hours: 1);

  /// Initialize the service
  Future<void> initialize() async {
    await _apiKeyManager.initialize();
  }

  /// Example of making an API call using the new consolidated patterns
  Future<Map<String, dynamic>?> fetchData(String endpoint, {
    Map<String, dynamic>? queryParams,
    bool useCache = true,
    Duration? timeout,
  }) async {
    try {
      // Check network connectivity using base class method
      if (!await checkNetworkConnectivity()) {
        throw Exception('No internet connection available');
      }

      // Generate cache key
      final cacheKey = 'example_${endpoint}_${queryParams?.toString() ?? ''}';

      // Try cache first if enabled
      if (useCache) {
        final cachedData = await _cacheManager.getValidData<Map<String, dynamic>>(
          cacheKey,
          _cacheTimeout,
          (data) => Map<String, dynamic>.from(data),
        );
        
        if (cachedData != null) {
          if (kDebugMode) {
            debugPrint('Cache hit for $endpoint');
          }
          return cachedData;
        }
      }

      // Build URL using base class method
      final url = buildUrl(_baseUrl, endpoint, queryParameters: queryParams);

      // Get headers using ApiKeyManager
      final headers = _apiKeyManager.getHeaders(
        service: ApiService.congress, // Example - use appropriate service
        additionalHeaders: {'Accept': 'application/json'},
      );

      // Make request using base class method with unified error handling
      final response = await makeJsonRequest(
        url,
        headers: headers,
        timeout: timeout ?? getTimeoutForOperation('query'),
      );

      // Cache the result if caching is enabled
      if (useCache) {
        await _cacheManager.saveDataWithTTL(cacheKey, response, ttl: _cacheTimeout);
      }

      return response;

    } catch (e) {
      // Use unified error handling
      final formattedError = ErrorHandler.formatError(e);
      if (kDebugMode) {
        debugPrint('ExampleModernizedService.fetchData error: $formattedError');
      }
      rethrow;
    }
  }

  /// Example of a POST request with error handling
  Future<Map<String, dynamic>?> postData(
    String endpoint,
    Map<String, dynamic> data, {
    Duration? timeout,
  }) async {
    try {
      if (!await checkNetworkConnectivity()) {
        throw Exception('No internet connection available');
      }

      final url = buildUrl(_baseUrl, endpoint);
      final headers = _apiKeyManager.getHeaders(
        service: ApiService.congress,
        additionalHeaders: {'Content-Type': 'application/json'},
      );

      final response = await makeJsonRequest(
        url,
        headers: headers,
        method: 'POST',
        body: data,
        timeout: timeout ?? getTimeoutForOperation('upload'),
      );

      return response;

    } catch (e) {
      final formattedError = ErrorHandler.formatError(e);
      if (kDebugMode) {
        debugPrint('ExampleModernizedService.postData error: $formattedError');
      }
      rethrow;
    }
  }

  /// Example of search functionality with caching
  Future<List<Map<String, dynamic>>> search(String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final queryParams = {
      'q': query.trim(),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    try {
      final response = await fetchData(
        'search',
        queryParams: queryParams,
        useCache: true,
      );

      if (response?['results'] is List) {
        return List<Map<String, dynamic>>.from(response!['results']);
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Search failed: ${ErrorHandler.formatError(e)}');
      }
      return [];
    }
  }

  /// Clear all cached data for this service
  Future<void> clearCache() async {
    await _cacheManager.clearCacheByType('example');
  }

  /// Get service status and debug information
  Map<String, dynamic> getServiceStatus() {
    return {
      'hasApiKey': _apiKeyManager.hasApiKey(ApiService.congress),
      'serviceName': 'ExampleModernizedService',
      'baseUrl': _baseUrl,
      'cacheTimeout': _cacheTimeout.inMinutes,
      'apiKeyManager': _apiKeyManager.getDebugInfo(),
    };
  }
}

/// This shows how a more complex service might extend the base functionality
class AdvancedExampleService extends ExampleModernizedService {
  static final AdvancedExampleService _instance = AdvancedExampleService._internal();
  factory AdvancedExampleService() => _instance;
  AdvancedExampleService._internal() : super._internal();

  final Map<String, DateTime> _rateLimitTracker = {};
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  /// Example of rate limiting functionality
  Future<bool> _checkRateLimit(String endpoint) async {
    final now = DateTime.now();
    final lastCall = _rateLimitTracker[endpoint];
    
    if (lastCall != null && now.difference(lastCall) < _rateLimitWindow) {
      return false; // Rate limited
    }
    
    _rateLimitTracker[endpoint] = now;
    return true;
  }

  /// Override to add rate limiting
  @override
  Future<Map<String, dynamic>?> fetchData(String endpoint, {
    Map<String, dynamic>? queryParams,
    bool useCache = true,
    Duration? timeout,
  }) async {
    // Check rate limiting first
    if (!await _checkRateLimit(endpoint)) {
      throw Exception('Rate limit exceeded for $endpoint');
    }

    // Call parent implementation
    return super.fetchData(
      endpoint,
      queryParams: queryParams,
      useCache: useCache,
      timeout: timeout,
    );
  }

  /// Example of batch operations
  Future<List<Map<String, dynamic>?>> fetchMultiple(
    List<String> endpoints, {
    int maxConcurrent = 3,
  }) async {
    final results = <Map<String, dynamic>?>[];
    
    // Process in batches to avoid overwhelming the API
    for (int i = 0; i < endpoints.length; i += maxConcurrent) {
      final batch = endpoints.skip(i).take(maxConcurrent);
      
      final batchResults = await Future.wait(
        batch.map((endpoint) => fetchData(endpoint)),
      );
      
      results.addAll(batchResults);
    }
    
    return results;
  }
}