// lib/utils/api_debug_util.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:govvy/services/remote_service_config.dart';

/// Utility class for debugging API issues
class ApiDebugUtil {
  // Singleton pattern
  static final ApiDebugUtil _instance = ApiDebugUtil._internal();
  factory ApiDebugUtil() => _instance;
  ApiDebugUtil._internal();
  
  // Constants for API base URLs
  static const String congressApiBaseUrl = 'https://api.congress.gov/v3';
  static const String ciceroApiBaseUrl = 'https://cicero.azavea.com/v3.1';
  static const String googleApiBaseUrl = 'https://maps.googleapis.com/maps/api';

  // Reference to remote config for API keys
  final RemoteConfigService _configService = RemoteConfigService();
  
  // Run basic diagnostics on all APIs
  Future<Map<String, dynamic>> runFullDiagnostics() async {
    // Verify API keys first
    final keyStatus = await _verifyApiKeys();
    
    // Test connectivity to Google (general internet test)
    final internetStatus = await _testInternetConnectivity();
    
    // Test each specific API if its key is available
    Map<String, dynamic> results = {
      'apiKeys': keyStatus,
      'internetConnectivity': internetStatus,
    };
    
    // Test Congress API if key is available
    if (keyStatus['congress'] == true) {
      results['congressApi'] = await _testCongressApi();
    }
    
    // Test Cicero API if key is available
    if (keyStatus['cicero'] == true) {
      results['ciceroApi'] = await _testCiceroApi();
    }
    
    // Test Google Maps API if key is available
    if (keyStatus['googleMaps'] == true) {
      results['googleMapsApi'] = await _testGoogleMapsApi();
    }
    
    return results;
  }
  
  // Check if API keys are available
  Future<Map<String, bool>> _verifyApiKeys() async {
    await _configService.initialize();
    
    final congressKey = _configService.getCongressApiKey;
    final googleKey = _configService.getGoogleMapsApiKey;
    final ciceroKey = _configService.getCiceroApiKey;
    
    return {
      'congress': congressKey != null && congressKey.isNotEmpty,
      'googleMaps': googleKey != null && googleKey.isNotEmpty,
      'cicero': ciceroKey != null && ciceroKey.isNotEmpty,
    };
  }
  
  // Test basic internet connectivity
  Future<bool> _testInternetConnectivity() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Internet connectivity test failed: $e');
      }
      return false;
    }
  }
  
  // Test Congress API connectivity
  Future<Map<String, dynamic>> _testCongressApi() async {
    final apiKey = _configService.getCongressApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return {'status': 'failed', 'error': 'API key not available'};
    }
    
    try {
      // Try to get a simple list of congresses (should be fast and stable)
      final url = Uri.parse('$congressApiBaseUrl/congress')
          .replace(queryParameters: {
            'format': 'json',
            'api_key': apiKey,
          });
          
      if (kDebugMode) {
        print('Testing Congress API: ${url.toString().replaceAll(apiKey, '[REDACTED]')}');
      }
      
      final response = await http.get(url)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': 'success',
          'statusCode': response.statusCode,
          'dataSize': response.body.length,
          'hasData': data.containsKey('congresses') && data['congresses'] != null,
        };
      } else {
        return {
          'status': 'failed',
          'statusCode': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  // Test Cicero API connectivity
  Future<Map<String, dynamic>> _testCiceroApi() async {
    final apiKey = _configService.getCiceroApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return {'status': 'failed', 'error': 'API key not available'};
    }
    
    try {
      // Use a well-known location like the White House
      final url = Uri.parse('$ciceroApiBaseUrl/official')
          .replace(queryParameters: {
            'format': 'json',
            'key': apiKey,
            'lat': '38.8977',
            'lon': '-77.0365',
          });
      
      if (kDebugMode) {
        print('Testing Cicero API: ${url.toString().replaceAll(apiKey, '[REDACTED]')}');
      }
      
      final response = await http.get(url)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': 'success',
          'statusCode': response.statusCode,
          'dataSize': response.body.length,
          'hasData': data.containsKey('response') && data['response'] != null,
        };
      } else {
        return {
          'status': 'failed',
          'statusCode': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  // Test Google Maps API connectivity
  Future<Map<String, dynamic>> _testGoogleMapsApi() async {
    final apiKey = _configService.getGoogleMapsApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return {'status': 'failed', 'error': 'API key not available'};
    }
    
    try {
      // Use a well-known address for geocoding
      final url = Uri.parse('$googleApiBaseUrl/geocode/json')
          .replace(queryParameters: {
            'address': 'White House, Washington DC',
            'key': apiKey,
          });
      
      if (kDebugMode) {
        print('Testing Google Maps API: ${url.toString().replaceAll(apiKey, '[REDACTED]')}');
      }
      
      final response = await http.get(url)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': 'success',
          'statusCode': response.statusCode,
          'dataSize': response.body.length,
          'hasResults': data.containsKey('results') && data['results'] is List && (data['results'] as List).isNotEmpty,
          'geocodeStatus': data['status'],
        };
      } else {
        return {
          'status': 'failed',
          'statusCode': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  // Run a manual test for any API
  Future<Map<String, dynamic>> testApiEndpoint(String baseUrl, String endpoint, Map<String, String> queryParams) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParams);
      
      if (kDebugMode) {
        // Redact any possible API keys
        String redactedUrl = url.toString();
        if (queryParams.containsKey('api_key')) {
          redactedUrl = redactedUrl.replaceAll(queryParams['api_key']!, '[REDACTED]');
        }
        if (queryParams.containsKey('key')) {
          redactedUrl = redactedUrl.replaceAll(queryParams['key']!, '[REDACTED]');
        }
        print('Testing custom endpoint: $redactedUrl');
      }
      
      final response = await http.get(url)
          .timeout(const Duration(seconds: 15));
      
      return {
        'status': response.statusCode == 200 ? 'success' : 'failed',
        'statusCode': response.statusCode,
        'dataSize': response.body.length,
        'data': response.body.length > 1000 
            ? '${response.body.substring(0, 1000)}...(truncated)'
            : response.body,
      };
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  // Add a debug page widget that can be added to the app for testing
  Widget buildDebugPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Diagnostics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: runFullDiagnostics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Running API diagnostics...'),
                ],
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          final results = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDiagnosticSection('API Keys', results['apiKeys']),
                _buildDiagnosticSection('Internet Connectivity', 
                  {'status': results['internetConnectivity'] ? 'success' : 'failed'}),
                if (results.containsKey('congressApi'))
                  _buildDiagnosticSection('Congress API', results['congressApi']),
                if (results.containsKey('ciceroApi'))
                  _buildDiagnosticSection('Cicero API', results['ciceroApi']),
                if (results.containsKey('googleMapsApi'))
                  _buildDiagnosticSection('Google Maps API', results['googleMapsApi']),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDiagnosticSection(String title, dynamic data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            )),
            const Divider(),
            if (data is Map<String, dynamic>)
              ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text('${entry.key}:', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: _formatValue(entry.value),
                    ),
                  ],
                ),
              )),
            if (data is Map<String, bool>)
              ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text('${entry.key}:', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Icon(
                      entry.value ? Icons.check_circle : Icons.error,
                      color: entry.value ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value ? 'Available' : 'Missing'),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
  
  Widget _formatValue(dynamic value) {
    if (value is String && value.startsWith('{') && value.endsWith('}')) {
      try {
        // Try to pretty-print JSON
        final jsonObj = json.decode(value);
        return Text(const JsonEncoder.withIndent('  ').convert(jsonObj));
      } catch (_) {
        return Text(value.toString());
      }
    }
    
    if (value == 'success') {
      return Row(
        children: const [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Success'),
        ],
      );
    }
    
    if (value == 'failed' || value == 'error') {
      return Row(
        children: const [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text('Failed'),
        ],
      );
    }
    
    return Text(value.toString());
  }
}