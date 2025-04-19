// lib/screens/debug/debug_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:govvy/screens/api_debug_screen.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:govvy/utils/api_debug_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A navigation screen to access different debugging tools
class DebugNavigationScreen extends StatefulWidget {
  const DebugNavigationScreen({Key? key}) : super(key: key);

  @override
  State<DebugNavigationScreen> createState() => _DebugNavigationScreenState();
}

class _DebugNavigationScreenState extends State<DebugNavigationScreen> {
  final RemoteConfigService _configService = RemoteConfigService();
  bool _isLoading = true;
  Map<String, bool>? _apiKeyStatus;
  String _appVersion = '';
  String _buildNumber = '';
  
  @override
  void initState() {
    super.initState();
    _loadInfo();
  }
  
  Future<void> _loadInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Initialize remote config
      await _configService.initialize();
      
      // Get API key status
      final keyStatus = await _configService.validateApiKeys();
      
      // Get package info
      final packageInfo = await PackageInfo.fromPlatform();
      
      setState(() {
        _apiKeyStatus = keyStatus;
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debugging Tools'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.purple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.purple.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'App Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Version', _appVersion),
                          _buildInfoRow('Build Number', _buildNumber),
                          _buildInfoRow('Environment', 'Development'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Debug Tools',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDebugTile(
                    'API Diagnostics',
                    'Test API connectivity and endpoints',
                    Icons.api,
                    Colors.blue,
                    _hasAnyApiKey(),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ApiDebugScreen(),
                      ),
                    ),
                  ),
                  
                  _buildDebugTile(
                    'Network Monitor',
                    'Monitor network requests and responses',
                    Icons.network_check,
                    Colors.green,
                    true,
                    () {
                      // TODO: Implement network monitor screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Network monitor coming soon!'),
                        ),
                      );
                    },
                  ),
                  
                  _buildDebugTile(
                    'Local Storage Inspector',
                    'View and edit local storage data',
                    Icons.storage,
                    Colors.orange,
                    true,
                    () {
                      // TODO: Implement storage inspector screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Storage inspector coming soon!'),
                        ),
                      );
                    },
                  ),
                  
                  _buildDebugTile(
                    'Log Viewer',
                    'View application logs',
                    Icons.list_alt,
                    Colors.red,
                    true,
                    () {
                      // TODO: Implement log viewer screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Log viewer coming soon!'),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'API Keys Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildApiKeyCard(),
                  
                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _runQuickDiagnostics,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDebugTile(
    String title, 
    String subtitle, 
    IconData icon, 
    Color color,
    bool isEnabled,
    VoidCallback onTap,
  ) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: isEnabled ? onTap : null,
        ),
      ),
    );
  }
  
  Widget _buildApiKeyCard() {
    if (_apiKeyStatus == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No API key information available'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildApiKeyStatusRow(
              'Congress API Key',
              _apiKeyStatus!['congress'] ?? false,
            ),
            const Divider(),
            _buildApiKeyStatusRow(
              'Google Maps API Key',
              _apiKeyStatus!['googleMaps'] ?? false,
            ),
            const Divider(),
            _buildApiKeyStatusRow(
              'Cicero API Key',
              _apiKeyStatus!['cicero'] ?? false,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildApiKeyStatusRow(String keyName, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.error,
            color: isAvailable ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              keyName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            isAvailable ? 'Available' : 'Missing',
            style: TextStyle(
              color: isAvailable ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  bool _hasAnyApiKey() {
    if (_apiKeyStatus == null) {
      return false;
    }
    
    return _apiKeyStatus!['congress'] == true ||
           _apiKeyStatus!['googleMaps'] == true ||
           _apiKeyStatus!['cicero'] == true;
  }
  
  Future<void> _runQuickDiagnostics() async {
    // Run API key validation again
    await _loadInfo();
    
    // Show results as a snackbar
    if (mounted) {
      final bool allKeysAvailable = _apiKeyStatus!['congress'] == true &&
                                   _apiKeyStatus!['googleMaps'] == true &&
                                   _apiKeyStatus!['cicero'] == true;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allKeysAvailable
                ? 'All API keys are available'
                : 'Some API keys are missing. See status for details.',
          ),
          backgroundColor: allKeysAvailable ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}