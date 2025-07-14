// lib/debug_launcher.dart
import 'package:flutter/material.dart';
import 'package:govvy/screens/api_debug_screen.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A simple entry point for directly launching the API Debug Screen
/// This can be used to quickly test API connectivity during development
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    // .env file not found - continue with Firebase Remote Config
  }
  
  // Initialize remote config to load API keys
  final remoteConfig = RemoteConfigService();
  await remoteConfig.initialize();
  
  runApp(const DebugLauncher());
}

class DebugLauncher extends StatelessWidget {
  const DebugLauncher({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'API Debug Tools',
      theme: ThemeData(
        primaryColor: const Color(0xFF5E35B1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5E35B1),
          primary: const Color(0xFF5E35B1),
          secondary: const Color(0xFF7E57C2),
          background: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5E35B1),
          foregroundColor: Colors.white,
        ),
      ),
      home: const APIDebugLauncherScreen(),
    );
  }
}

class APIDebugLauncherScreen extends StatefulWidget {
  const APIDebugLauncherScreen({Key? key}) : super(key: key);

  @override
  State<APIDebugLauncherScreen> createState() => _APIDebugLauncherScreenState();
}

class _APIDebugLauncherScreenState extends State<APIDebugLauncherScreen> {
  final RemoteConfigService _configService = RemoteConfigService();
  
  bool _isCheckingKeys = true;
  Map<String, bool> _apiKeyStatus = {};
  
  @override
  void initState() {
    super.initState();
    _checkApiKeys();
  }
  
  Future<void> _checkApiKeys() async {
    setState(() {
      _isCheckingKeys = true;
    });
    
    try {
      // Initialize again to ensure latest values
      await _configService.initialize();
      
      // Get API key status
      final keyStatus = await _configService.validateApiKeys();
      
      setState(() {
        _apiKeyStatus = keyStatus;
        _isCheckingKeys = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingKeys = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug Launcher'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.api,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'API Key Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isCheckingKeys)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _checkApiKeys,
                            tooltip: 'Refresh API key status',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isCheckingKeys
                        ? const Center(
                            child: Text('Checking API keys...'),
                          )
                        : Column(
                            children: [
                              _buildApiKeyStatusRow(
                                'Congress API Key',
                                _apiKeyStatus['congress'] ?? false,
                              ),
                              const Divider(),
                              _buildApiKeyStatusRow(
                                'Google Maps API Key',
                                _apiKeyStatus['googleMaps'] ?? false,
                              ),
                              const Divider(),
                              _buildApiKeyStatusRow(
                                'Cicero API Key',
                                _apiKeyStatus['cicero'] ?? false,
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApiDebugScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Launch API Debug Tools'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            const Text(
              'Debug Instructions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              '1. Ensure your API keys are properly configured in your .env file or Firebase Remote Config.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '2. If any keys are showing as "Missing", check your configuration.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '3. Click "Launch API Debug Tools" to access the full debugging interface.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '4. The debug tools will provide detailed diagnostics and allow you to test API endpoints.',
              style: TextStyle(fontSize: 14),
            ),
            
            const Spacer(),
            
            Center(
              child: Text(
                'govvy Debug Tools',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
}