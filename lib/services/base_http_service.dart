import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/api_exceptions.dart';

abstract class BaseHttpService {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _defaultMaxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  Future<http.Response> makeRequest(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
    String? method = 'GET',
    Object? body,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final effectiveMaxRetries = maxRetries ?? _defaultMaxRetries;
    
    int attempt = 0;
    while (attempt < effectiveMaxRetries) {
      final stopwatch = Stopwatch()..start();
      
      try {
        if (kDebugMode) {
          print('HTTP Request attempt ${attempt + 1}/$effectiveMaxRetries: ${method?.toUpperCase()} $url');
        }

        http.Response response;
        
        switch (method?.toUpperCase()) {
          case 'POST':
            response = await http.post(
              url,
              headers: headers,
              body: body,
            ).timeout(effectiveTimeout);
            break;
          case 'PUT':
            response = await http.put(
              url,
              headers: headers,
              body: body,
            ).timeout(effectiveTimeout);
            break;
          case 'DELETE':
            response = await http.delete(
              url,
              headers: headers,
            ).timeout(effectiveTimeout);
            break;
          default:
            response = await http.get(
              url,
              headers: headers,
            ).timeout(effectiveTimeout);
        }

        stopwatch.stop();
        
        if (kDebugMode) {
          print('HTTP Response: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        } else if (shouldRetry(response.statusCode) && attempt < effectiveMaxRetries - 1) {
          attempt++;
          await Future.delayed(_retryDelay * attempt);
          continue;
        } else {
          throw ApiException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        stopwatch.stop();
        
        if (kDebugMode) {
          print('HTTP Request failed (${stopwatch.elapsedMilliseconds}ms): $e');
        }

        if (attempt < effectiveMaxRetries - 1 && shouldRetryOnException(e)) {
          attempt++;
          await Future.delayed(_retryDelay * attempt);
          continue;
        } else {
          rethrow;
        }
      }
    }
    
    throw ApiException('Max retries exceeded');
  }

  Future<Map<String, dynamic>> makeJsonRequest(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
    String? method = 'GET',
    Object? body,
  }) async {
    final effectiveHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    final response = await makeRequest(
      url,
      headers: effectiveHeaders,
      timeout: timeout,
      maxRetries: maxRetries,
      method: method,
      body: body,
    );

    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Invalid JSON response: $e');
    }
  }

  Future<List<dynamic>> makeJsonListRequest(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
    String? method = 'GET',
    Object? body,
  }) async {
    final effectiveHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    final response = await makeRequest(
      url,
      headers: effectiveHeaders,
      timeout: timeout,
      maxRetries: maxRetries,
      method: method,
      body: body,
    );

    try {
      return json.decode(response.body) as List<dynamic>;
    } catch (e) {
      throw ApiException('Invalid JSON array response: $e');
    }
  }

  Future<bool> checkNetworkConnectivity() async {
    final networkService = NetworkService();
    return await networkService.checkConnectivity();
  }

  bool shouldRetry(int statusCode) {
    return statusCode == 429 || // Too Many Requests
           statusCode == 502 || // Bad Gateway
           statusCode == 503 || // Service Unavailable
           statusCode == 504;   // Gateway Timeout
  }

  bool shouldRetryOnException(dynamic exception) {
    if (exception is http.ClientException) {
      return true;
    }
    if (exception.toString().contains('timeout')) {
      return true;
    }
    if (exception.toString().contains('connection')) {
      return true;
    }
    return false;
  }

  Duration getTimeoutForOperation(String operation) {
    switch (operation.toLowerCase()) {
      case 'search':
      case 'query':
        return const Duration(seconds: 45);
      case 'upload':
      case 'download':
        return const Duration(minutes: 2);
      case 'auth':
      case 'login':
        return const Duration(seconds: 20);
      default:
        return _defaultTimeout;
    }
  }

  Uri buildUrl(
    String baseUrl,
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = baseUrl.endsWith('/') 
        ? '${baseUrl.substring(0, baseUrl.length - 1)}$cleanPath'
        : '$baseUrl$cleanPath';
    
    return Uri.parse(fullUrl).replace(queryParameters: queryParameters);
  }

  Map<String, String> buildHeaders({
    String? apiKey,
    String? authToken,
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      'User-Agent': 'Govvy/1.0.0',
      'Accept': 'application/json',
    };

    if (apiKey != null) {
      headers['X-API-Key'] = apiKey;
    }

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }
}