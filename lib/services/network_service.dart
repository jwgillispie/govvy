// lib/services/network_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
  final Duration _connectTimeout = const Duration(seconds: 15);
  final Duration _receiveTimeout = const Duration(seconds: 60);

  // Request tracking (for debugging)
  int _requestCounter = 0;
  bool _loggingEnabled = kDebugMode;

  // Enable more detailed logging in development
  void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }

  Future<bool> checkConnectivity() async {
    try {
      if (kIsWeb) {
        // Check if we're in local development
        final currentUrl = Uri.base.toString();
        final isLocalDevelopment = currentUrl.contains('localhost') ||
            currentUrl.contains('127.0.0.1');

        if (isLocalDevelopment) {
          // For local development, just assume we're connected
          // or use a public domain that doesn't have CORS restrictions
          final response = await http
              .get(Uri.parse('https://www.google.com/favicon.ico'))
              .timeout(const Duration(seconds: 5));
          return response.statusCode == 200;
        } else {
          // For production, use your app domain
          final response = await http
              .get(Uri.parse('https://govvy--dev.web.app/favicon.ico'))
              .timeout(const Duration(seconds: 5));
          return response.statusCode == 200;
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

  Future<String> getProxiedImageUrl(String originalUrl) async {
    if (originalUrl.isEmpty) {
      return ''; // Return empty string for empty URLs
    }

    // For mobile platforms, just return the original URL
    if (!kIsWeb) {
      return originalUrl;
    }

    // For web platform, apply proxying to problematic domains
    try {
      // Always use a proxy for these domains which commonly have CORS issues
      final List<String> corsRestrictedDomains = [
        'congress.gov',
        'cicero.azavea.com',
        'bioguide.congress.gov',
        'www.govtrack.us',
        'www.senate.gov',
        'www.house.gov',
        'azavea.com',
        's3.amazonaws.com/cicero-media-files',
        'cicero-media-files.s3.amazonaws.com'
      ];

      // Check if URL contains any of the restricted domains
      bool needsProxy = corsRestrictedDomains.any(
          (domain) => originalUrl.toLowerCase().contains(domain.toLowerCase()));

      if (needsProxy) {
        if (_loggingEnabled) {
          print('Proxying image URL: $originalUrl');
        }

        // Try multiple proxy services in case one doesn't work
        // Option 1: corsproxy.io (main)
        String proxiedUrl =
            'https://corsproxy.io/?${Uri.encodeComponent(originalUrl)}';

        // Option 2: If you need alternative proxies, uncomment these
        // String proxiedUrl = 'https://cors-anywhere.herokuapp.com/$originalUrl';
        // String proxiedUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';

        return proxiedUrl;
      }

      // For non-restricted domains, return original URL
      return originalUrl;
    } catch (e) {
      if (_loggingEnabled) {
        print('Error proxying URL: $e, returning original URL');
      }
      return originalUrl;
    }
  }
}
