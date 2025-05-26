// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:govvy/firebase_options.dart';
import 'package:govvy/providers/bill_provider.dart';
import 'package:govvy/providers/enhanced_bill_provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/providers/campaign_finance_provider.dart';
// Removed: import 'package:govvy/providers/csv_representative_provider.dart';
import 'package:govvy/screens/auth/auth_wrapper.dart';
import 'package:govvy/screens/bills/bill_details_screen.dart';
import 'package:govvy/screens/bills/enhanced_bill_screen.dart';
import 'package:govvy/screens/campaign_finance/modular_campaign_finance_screen.dart';
import 'package:govvy/services/bill_service.dart';
import 'package:govvy/services/enhanced_legiscan_service.dart';
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

  // Initialize enhanced bill services 
  await _initializeEnhancedServices();

  runApp(const RepresentativeApp());
}

// In main.dart
Future<void> _initializeServices() async {
  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Load .env file before RemoteConfig
    try {
      await dotenv.load(fileName: "assets/.env");
    } catch (e) {
      // Silently handle .env loading errors
    }

    // Initialize Remote Config
    final remoteConfig = RemoteConfigService();
    await remoteConfig.initialize();

    // Validate API keys
    final keyStatus = await remoteConfig.validateApiKeys();

    // Debug all API keys
    final congressKey = remoteConfig.getCongressApiKey;
    final googleMapsKey = remoteConfig.getGoogleMapsApiKey;
    final ciceroKey = remoteConfig.getCiceroApiKey;
    final fecKey = remoteConfig.getFecApiKey;


  } catch (e) {
    // Silently handle initialization errors
  }
}

// Initialize enhanced services
Future<void> _initializeEnhancedServices() async {
  try {
    // Initialize the enhanced LegiScan service
    final enhancedLegiscanService = EnhancedLegiscanService();
    await enhancedLegiscanService.initialize();
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing enhanced services: $e');
    }
    // Silently handle initialization errors in production
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
        // Network Service
        Provider(create: (_) => NetworkService()),

        // Remote Config Service
        Provider(create: (_) => RemoteConfigService()),
        
        // Bill Service
        Provider(create: (_) => BillService()),
        
        // Removed: CSV Representative Provider
        // ChangeNotifierProvider(
        //   create: (_) => CSVRepresentativeProvider(),
        //   lazy: false,
        // ),

        // Bill Provider
        ChangeNotifierProvider(
          create: (_) => BillProvider(),
          lazy: false,
        ),
        
        // Enhanced Bill Provider
        ChangeNotifierProvider(
          create: (_) => EnhancedBillProvider(),
          lazy: false,
        ),

        // Campaign Finance Provider
        ChangeNotifierProvider(
          create: (_) => CampaignFinanceProvider(),
          lazy: false,
        ),

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
        home: const AuthWrapper(),
        routes: {
          '/bills': (context) => const EnhancedBillScreen(),
          '/campaign_finance': (context) => const ModularCampaignFinanceScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/bill_details') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => BillDetailsScreen(
                billId: args['billId'],
                stateCode: args['stateCode'],
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
