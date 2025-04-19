// lib/screens/debug/api_debug_screen.dart
import 'package:flutter/material.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/utils/api_debug_utils.dart';

class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({Key? key}) : super(key: key);

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiDebugUtil _apiDebugUtil = ApiDebugUtil();
  final RemoteConfigService _configService = RemoteConfigService();
  final NetworkService _networkService = NetworkService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _diagnosticResults;
  String _statusMessage = '';
  
  // Controllers for custom endpoint test
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _paramsController = TextEditingController();
  Map<String, dynamic>? _customEndpointResult;
  bool _customEndpointLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _baseUrlController.text = 'https://api.congress.gov/v3';
    _endpointController.text = '/congress';
    _paramsController.text = 'format=json';
    _runDiagnostics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _baseUrlController.dispose();
    _endpointController.dispose();
    _paramsController.dispose();
    super.dispose();
  }
  
  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running API diagnostics...';
    });
    
    try {
      // Initialize remote config first
      await _configService.initialize();
      
      // Check internet connectivity
      final hasConnectivity = await _networkService.checkConnectivity();
      
      if (!hasConnectivity) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No internet connection. Please check your network and try again.';
        });
        return;
      }
      
      // Run diagnostics
      final results = await _apiDebugUtil.runFullDiagnostics();
      
      setState(() {
        _isLoading = false;
        _diagnosticResults = results;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error running diagnostics: $e';
      });
    }
  }
  
  Future<void> _testCustomEndpoint() async {
    setState(() {
      _customEndpointLoading = true;
      _customEndpointResult = null;
    });
    
    try {
      final baseUrl = _baseUrlController.text.trim();
      final endpoint = _endpointController.text.trim();
      
      // Parse query parameters
      final paramsText = _paramsController.text.trim();
      final Map<String, String> queryParams = {};
      
      if (paramsText.isNotEmpty) {
        final paramPairs = paramsText.split('&');
        for (final pair in paramPairs) {
          final parts = pair.split('=');
          if (parts.length == 2) {
            queryParams[parts[0].trim()] = parts[1].trim();
          }
        }
      }
      
      // Try to add API key if needed
      if (baseUrl.contains('congress.gov') && !queryParams.containsKey('api_key')) {
        final apiKey = _configService.getCongressApiKey;
        if (apiKey != null && apiKey.isNotEmpty) {
          queryParams['api_key'] = apiKey;
        }
      } else if (baseUrl.contains('cicero') && !queryParams.containsKey('key')) {
        final apiKey = _configService.getCiceroApiKey;
        if (apiKey != null && apiKey.isNotEmpty) {
          queryParams['key'] = apiKey;
        }
      } else if (baseUrl.contains('google') && !queryParams.containsKey('key')) {
        final apiKey = _configService.getGoogleMapsApiKey;
        if (apiKey != null && apiKey.isNotEmpty) {
          queryParams['key'] = apiKey;
        }
      }
      
      final result = await _apiDebugUtil.testApiEndpoint(baseUrl, endpoint, queryParams);
      
      setState(() {
        _customEndpointLoading = false;
        _customEndpointResult = result;
      });
    } catch (e) {
      setState(() {
        _customEndpointLoading = false;
        _customEndpointResult = {
          'status': 'error',
          'message': e.toString(),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Diagnostics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'API Tests'),
            Tab(text: 'Custom Endpoint')
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runDiagnostics,
            tooltip: 'Run diagnostics again',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildApiTestsTab(),
          _buildCustomEndpointTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running diagnostics...'),
          ],
        ),
      );
    }
    
    if (_statusMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_statusMessage),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _runDiagnostics,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    if (_diagnosticResults == null) {
      return const Center(
        child: Text('No diagnostic results available.'),
      );
    }
    
    // Check API keys
    final apiKeys = _diagnosticResults!['apiKeys'] as Map<String, bool>;
    final hasAllKeys = apiKeys['congress']! && apiKeys['googleMaps']! && apiKeys['cicero']!;
    
    // Check internet
    final hasInternet = _diagnosticResults!['internetConnectivity'] as bool;
    
    // Check APIs
    bool allApisWorking = hasInternet;
    
    if (hasInternet) {
      if (apiKeys['congress']! && _diagnosticResults!.containsKey('congressApi')) {
        allApisWorking = allApisWorking && 
            (_diagnosticResults!['congressApi'] as Map<String, dynamic>)['status'] == 'success';
      }
      
      if (apiKeys['cicero']! && _diagnosticResults!.containsKey('ciceroApi')) {
        allApisWorking = allApisWorking && 
            (_diagnosticResults!['ciceroApi'] as Map<String, dynamic>)['status'] == 'success';
      }
      
      if (apiKeys['googleMaps']! && _diagnosticResults!.containsKey('googleMapsApi')) {
        allApisWorking = allApisWorking && 
            (_diagnosticResults!['googleMapsApi'] as Map<String, dynamic>)['status'] == 'success';
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: allApisWorking 
                ? Colors.green.shade50
                : hasInternet ? Colors.orange.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    allApisWorking 
                        ? Icons.check_circle
                        : hasInternet ? Icons.warning : Icons.error,
                    size: 48,
                    color: allApisWorking 
                        ? Colors.green
                        : hasInternet ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    allApisWorking
                        ? 'All API systems operational'
                        : hasInternet 
                            ? 'Some API services have issues'
                            : 'Network connectivity issue',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    allApisWorking
                        ? 'Your app should be able to access all API services.'
                        : hasInternet 
                            ? 'Some API services may not be working correctly. See details below.'
                            : 'No internet connection detected. Please check your network settings.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text('API Keys Status', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatusListTile(
                'Congress API Key',
                apiKeys['congress']!,
                apiKeys['congress']! ? 'Available' : 'Missing',
              ),
              _buildStatusListTile(
                'Google Maps API Key',
                apiKeys['googleMaps']!,
                apiKeys['googleMaps']! ? 'Available' : 'Missing',
              ),
              _buildStatusListTile(
                'Cicero API Key',
                apiKeys['cicero']!,
                apiKeys['cicero']! ? 'Available' : 'Missing',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          const Text('Network Status', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          _buildStatusListTile(
            'Internet Connectivity',
            hasInternet,
            hasInternet ? 'Connected' : 'No Connection',
          ),
          
          if (hasInternet) ...[
            const SizedBox(height: 24),
            
            const Text('API Service Status', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            if (apiKeys['congress']! && _diagnosticResults!.containsKey('congressApi'))
              _buildStatusListTile(
                'Congress API Service',
                (_diagnosticResults!['congressApi'] as Map<String, dynamic>)['status'] == 'success',
                (_diagnosticResults!['congressApi'] as Map<String, dynamic>)['status'] == 'success'
                    ? 'Working'
                    : 'Not responding correctly',
              ),
              
            if (apiKeys['cicero']! && _diagnosticResults!.containsKey('ciceroApi'))
              _buildStatusListTile(
                'Cicero API Service',
                (_diagnosticResults!['ciceroApi'] as Map<String, dynamic>)['status'] == 'success',
                (_diagnosticResults!['ciceroApi'] as Map<String, dynamic>)['status'] == 'success'
                    ? 'Working'
                    : 'Not responding correctly',
              ),
              
            if (apiKeys['googleMaps']! && _diagnosticResults!.containsKey('googleMapsApi'))
              _buildStatusListTile(
                'Google Maps API Service',
                (_diagnosticResults!['googleMapsApi'] as Map<String, dynamic>)['status'] == 'success',
                (_diagnosticResults!['googleMapsApi'] as Map<String, dynamic>)['status'] == 'success'
                    ? 'Working'
                    : 'Not responding correctly',
              ),
          ],
          
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _runDiagnostics,
              icon: const Icon(Icons.refresh),
              label: const Text('Run Diagnostics Again'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildApiTestsTab() {
    if (_diagnosticResults == null) {
      return const Center(
        child: Text('No diagnostic results available. Please run diagnostics first.'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_diagnosticResults!.containsKey('congressApi')) ...[
            const Text('Congress API Test', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildApiResultCard('congressApi'),
            const SizedBox(height: 24),
          ],
          
          if (_diagnosticResults!.containsKey('ciceroApi')) ...[
            const Text('Cicero API Test', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildApiResultCard('ciceroApi'),
            const SizedBox(height: 24),
          ],
          
          if (_diagnosticResults!.containsKey('googleMapsApi')) ...[
            const Text('Google Maps API Test', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildApiResultCard('googleMapsApi'),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCustomEndpointTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Test Custom API Endpoint', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'Use this tool to test any API endpoint. The appropriate API key will be added automatically if needed.',
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'e.g. https://api.congress.gov/v3',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _endpointController,
            decoration: const InputDecoration(
              labelText: 'Endpoint',
              hintText: 'e.g. /congress',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _paramsController,
            decoration: const InputDecoration(
              labelText: 'Query Parameters',
              hintText: 'e.g. format=json&limit=10',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _customEndpointLoading ? null : _testCustomEndpoint,
              icon: _customEndpointLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(_customEndpointLoading ? 'Testing...' : 'Test Endpoint'),
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_customEndpointResult != null) ...[
            const Divider(),
            const SizedBox(height: 16),
            
            Text(
              'Test Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Card(
              color: _customEndpointResult!['status'] == 'success'
                  ? Colors.green.shade50
                  : _customEndpointResult!['status'] == 'failed'
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _customEndpointResult!['status'] == 'success'
                              ? Icons.check_circle
                              : _customEndpointResult!['status'] == 'failed'
                                  ? Icons.warning
                                  : Icons.error,
                          color: _customEndpointResult!['status'] == 'success'
                              ? Colors.green
                              : _customEndpointResult!['status'] == 'failed'
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _customEndpointResult!['status'] == 'success'
                              ? 'Success'
                              : _customEndpointResult!['status'] == 'failed'
                                  ? 'Failed'
                                  : 'Error',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_customEndpointResult!.containsKey('statusCode'))
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusCodeColor(
                                  _customEndpointResult!['statusCode'] as int),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Status ${_customEndpointResult!['statusCode']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    if (_customEndpointResult!.containsKey('message'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Error Message:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_customEndpointResult!['message'] as String),
                          const SizedBox(height: 16),
                        ],
                      ),
                      
                    if (_customEndpointResult!.containsKey('dataSize'))
                      Row(
                        children: [
                          const Text(
                            'Response Size:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatDataSize(_customEndpointResult!['dataSize'] as int)}',
                          ),
                        ],
                      ),
                      
                    const SizedBox(height: 8),
                    
                    if (_customEndpointResult!.containsKey('data'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Response Data:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                _customEndpointResult!['data'] as String,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildApiResultCard(String apiKey) {
    final apiResult = _diagnosticResults![apiKey] as Map<String, dynamic>;
    final bool isSuccess = apiResult['status'] == 'success';
    
    return Card(
      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isSuccess ? 'Success' : 'Failed',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (apiResult.containsKey('statusCode'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusCodeColor(apiResult['statusCode'] as int),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Status ${apiResult['statusCode']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            if (apiResult.containsKey('dataSize'))
              Row(
                children: [
                  const Text(
                    'Response Size:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDataSize(apiResult['dataSize'] as int)}',
                  ),
                ],
              ),
              
            const SizedBox(height: 8),
            
            if (isSuccess && apiKey == 'congressApi' && apiResult.containsKey('hasData'))
              Row(
                children: [
                  const Text(
                    'Congresses Data:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    apiResult['hasData'] == true ? 'Available' : 'Not found',
                  ),
                ],
              ),
              
            if (isSuccess && apiKey == 'ciceroApi' && apiResult.containsKey('hasData'))
              Row(
                children: [
                  const Text(
                    'Officials Data:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    apiResult['hasData'] == true ? 'Available' : 'Not found',
                  ),
                ],
              ),
              
            if (isSuccess && apiKey == 'googleMapsApi' && apiResult.containsKey('hasResults'))
              Row(
                children: [
                  const Text(
                    'Geocode Results:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    apiResult['hasResults'] == true ? 'Available' : 'Not found',
                  ),
                ],
              ),
              
            if (isSuccess && apiKey == 'googleMapsApi' && apiResult.containsKey('geocodeStatus'))
              Row(
                children: [
                  const Text(
                    'Geocode Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    apiResult['geocodeStatus'] as String,
                  ),
                ],
              ),
              
            if (!isSuccess && apiResult.containsKey('error'))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    apiResult['error'].toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusListTile(String title, bool isOk, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isOk ? Colors.green.shade100 : Colors.red.shade100,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            isOk ? Icons.check : Icons.close,
            color: isOk ? Colors.green : Colors.red,
          ),
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
  
  Color _getStatusCodeColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return Colors.green;
    } else if (statusCode >= 300 && statusCode < 400) {
      return Colors.blue;
    } else if (statusCode >= 400 && statusCode < 500) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  String _formatDataSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes bytes';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}