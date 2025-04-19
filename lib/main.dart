// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:govvy/firebase_options.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/screens/auth/auth_wrapper.dart';
import 'package:govvy/screens/landing/landing_page.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/remote_service_config.dart';
import 'package:provider/provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/services/representative_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services with proper error handling
  await _initializeServices();

  runApp(const RepresentativeApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kDebugMode) {
      print('✅ Firebase initialized successfully');
    }

    // Always attempt to load .env file for development (do this early)
    if (kDebugMode) {
      try {
        await dotenv.load(fileName: "assets/.env");
        print("✅ Loaded .env file with ${dotenv.env.length} variables");

        // Log the API keys we found (masked for security)
        if (dotenv.env.containsKey('CONGRESS_API_KEY')) {
          final key = dotenv.env['CONGRESS_API_KEY']!;
          print("📋 CONGRESS_API_KEY: ${_maskApiKey(key)}");
        }

        if (dotenv.env.containsKey('GOOGLE_MAPS_API_KEY')) {
          final key = dotenv.env['GOOGLE_MAPS_API_KEY']!;
          print("📋 GOOGLE_MAPS_API_KEY: ${_maskApiKey(key)}");
        }

        if (dotenv.env.containsKey('CICERO_API_KEY')) {
          final key = dotenv.env['CICERO_API_KEY']!;
          print("📋 CICERO_API_KEY: ${_maskApiKey(key)}");
        }
      } catch (e) {
        print("⚠️ Failed to load .env file: $e");
      }
    }

    // Initialize Remote Config
    final remoteConfig = RemoteConfigService();
    await remoteConfig.initialize();

    // Initialize NetworkService
    final networkService = NetworkService();

    // Validate API keys and check connectivity in parallel
    await Future.wait([
      remoteConfig.validateApiKeys().then((keyStatus) {
        if (kDebugMode) {
          print('🔑 API Keys: $keyStatus');
        }
      }),
      networkService.checkConnectivity().then((hasConnectivity) {
        if (kDebugMode) {
          print(hasConnectivity
              ? '🌐 Network connectivity: Connected'
              : '🌐 Network connectivity: Not connected');
        }
      }),
    ]);
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error initializing services: $e');
    }
  }
}

// Helper to mask API key for logging
String _maskApiKey(String key) {
  if (key.length <= 8) {
    return '****';
  }
  return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
}

// Helper function to safely take a substring
int min(int a, int b) => a < b ? a : b;

class RepresentativeApp extends StatelessWidget {
  const RepresentativeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Network Service (add this)
        Provider(create: (_) => NetworkService()),

        // Remote Config Service (add this)
        Provider(create: (_) => RemoteConfigService()),

        // Auth Service
        ChangeNotifierProvider(create: (_) => AuthService()),

        // Representative Services
        Provider(create: (_) => RepresentativeService()),

        // Combined Representative Provider
        ChangeNotifierProxyProvider<RepresentativeService,
            CombinedRepresentativeProvider>(
          create: (context) => CombinedRepresentativeProvider(
              context.read<RepresentativeService>()),
          update: (context, service, previous) =>
              previous ?? CombinedRepresentativeProvider(service),
        ),
      ],
      child: MaterialApp(
        title: 'govvy',
        debugShowCheckedModeBanner:
            kDebugMode, // Only show debug banner in debug mode
        theme: ThemeData(
          primaryColor: const Color(0xFF5E35B1), // Deep Purple 600
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5E35B1),
            primary: const Color(0xFF5E35B1),
            secondary: const Color(0xFF7E57C2), // Deep Purple 400
            background: Colors.white,
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4527A0), // Deep Purple 800
            ),
            headlineMedium: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5E35B1), // Deep Purple 600
            ),
            bodyLarge: TextStyle(
              fontSize: 16.0,
              color: Color(0xFF424242), // Grey 800
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E35B1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: kIsWeb ? const LandingPage() : const AuthWrapper(),
        routes: {
          '/': (context) => kIsWeb ? const LandingPage() : const AuthWrapper(),
        },
      ),
    );
  }
}
