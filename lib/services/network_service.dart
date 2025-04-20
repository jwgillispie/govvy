// lib/services/network_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:govvy/services/remote_service_config.dart';

class NetworkService {
  // Singleton pattern
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  // Reference to remote config for API keys
  final RemoteConfigService _configService = RemoteConfigService();

  // Timeout durations
  final Duration _connectTimeout = const Duration(seconds: 10);
  final Duration _receiveTimeout = const Duration(seconds: 30);

  // Request tracking (for debugging)
  int _requestCounter = 0;
  bool _loggingEnabled = kDebugMode;

  // Enable more detailed logging in development
  void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }

// In your NetworkService class
  Future<bool> checkConnectivity() async {
    try {
      if (kIsWeb) {
        // For web platforms, use your own app domain to avoid CORS issues
        try {
          final response = await http
              .get(Uri.parse('https://govvy--dev.web.app/favicon.ico'))
              .timeout(const Duration(seconds: 5));
          return response.statusCode == 200;
        } catch (e) {
          if (kDebugMode) {
            print('Network connectivity check failed: $e');
          }
          return false;
        }
      } else {
        // For mobile platforms
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(const Duration(seconds: 5));
        return response.statusCode == 200;
      }
    } catch (e) {
      return false;
    }
  }

  // Generic GET request with tracing
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    String? apiKeyParam,
    String? apiKey,
  }) async {
    // Add request tracking ID
    final int requestId = ++_requestCounter;

    // Create headers if not provided
    headers ??= {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    // Add API key to URL if specified and available
    if (apiKeyParam != null && apiKey != null) {
      final queryParams = Map<String, String>.from(url.queryParameters);
      queryParams[apiKeyParam] = apiKey;
      url = url.replace(queryParameters: queryParams);
    }

    // Log request for debugging
    if (_loggingEnabled) {
      String redactedUrl = url.toString();
      if (apiKey != null) {
        redactedUrl = redactedUrl.replaceAll(apiKey, '[REDACTED]');
      }
      print('🌐 [$requestId] HTTP GET Request: $redactedUrl');
      print('🌐 [$requestId] Headers: $headers');
    }

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(_receiveTimeout);

      stopwatch.stop();

      if (_loggingEnabled) {
        final duration = stopwatch.elapsedMilliseconds;
        print(
            '🌐 [$requestId] Response: ${response.statusCode} (${duration}ms)');
        print(
            '🌐 [$requestId] Response Size: ${response.contentLength ?? response.body.length} bytes');

        if (response.statusCode != 200) {
          print(
              '🌐 [$requestId] Error Response: ${response.body.substring(0, min(500, response.body.length))}');
        } else {
          // Print a snippet of successful response for debugging
          print(
              '🌐 [$requestId] Response Preview: ${response.body.substring(0, min(100, response.body.length))}...');
        }
      }

      return response;
    } on SocketException catch (e) {
      if (_loggingEnabled) {
        print('🌐 [$requestId] Socket Exception: $e');
      }
      throw Exception('Network error - please check your internet connection.');
    } on http.ClientException catch (e) {
      if (_loggingEnabled) {
        print('🌐 [$requestId] HTTP Client Exception: $e');
      }
      throw Exception('HTTP client error: ${e.message}');
    } on TimeoutException catch (e) {
      if (_loggingEnabled) {
        print('🌐 [$requestId] Timeout Exception: $e');
      }
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      stopwatch.stop();
      if (_loggingEnabled) {
        print(
            '🌐 [$requestId] Exception after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      rethrow;
    }
  }

  // Specialized GET for Congress API
  Future<Map<String, dynamic>> getFromCongressApi(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final apiKey = _configService.getCongressApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Congress API key not configured');
    }

    // Build query parameters including API key
    final params = queryParams ?? {};
    params['api_key'] = apiKey;
    params['format'] = 'json';

    final url = Uri.parse('https://api.congress.gov/v3$endpoint')
        .replace(queryParameters: params);

    final response = await get(url, apiKey: apiKey);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Congress API error: ${response.statusCode}');
    }
  }

  // Specialized GET for Cicero API
  Future<Map<String, dynamic>> getFromCiceroApi(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final apiKey = _configService.getCiceroApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Cicero API key not configured');
    }

    // Build query parameters including API key
    final params = queryParams ?? {};
    params['key'] = apiKey;
    params['format'] = 'json';

    final url = Uri.parse('https://cicero.azavea.com/v3.1$endpoint')
        .replace(queryParameters: params);

    final response = await get(url, apiKey: apiKey);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Cicero API error: ${response.statusCode}');
    }
  }

  // Specialized GET for Google Geocoding API
  Future<Map<String, dynamic>> getFromGoogleMapsApi(
    String endpoint, {
    Map<String, String>? queryParams,
    bool isGeocode = true,
  }) async {
    final apiKey = _configService.getGoogleMapsApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Maps API key not configured');
    }

    // Build query parameters including API key
    final params = queryParams ?? {};
    params['key'] = apiKey;

    final baseUrl = isGeocode
        ? 'https://maps.googleapis.com/maps/api/geocode'
        : 'https://maps.googleapis.com/maps/api';

    final url = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);

    final response = await get(url, apiKey: apiKey);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Google Maps API error: ${response.statusCode}');
    }
  }

  // Geocode an address to coordinates
  Future<Map<String, double>?> geocodeAddress(String address) async {
    try {
      final data = await getFromGoogleMapsApi('/json', queryParams: {
        'address': address,
      });

      if (data['status'] != 'OK' || data['results'].isEmpty) {
        return null;
      }

      final location = data['results'][0]['geometry']['location'];
      return {
        'lat': location['lat'],
        'lng': location['lng'],
      };
    } catch (e) {
      if (_loggingEnabled) {
        print('Geocoding error: $e');
      }
      return null;
    }
  }
  // lib/services/network_service.dart

// Add this method to your NetworkService class
  Future<String> getProxiedImageUrl(String originalUrl) async {
    if (!kIsWeb) {
      // For mobile, just return the original URL
      return originalUrl;
    }

    // For web, check if the URL needs proxying
    if (originalUrl.contains('congress.gov') ||
        originalUrl.contains('cicero.azavea.com')) {
      // Use a CORS proxy for image URLs
      return 'https://corsproxy.io/?${Uri.encodeComponent(originalUrl)}';
    }

    // If it's not a problematic URL, return as is
    return originalUrl;
  }

  // Helper function to safely take a substring
  int min(int a, int b) => a < b ? a : b;
}
