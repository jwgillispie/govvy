// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:govvy/firebase_options.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/screens/auth/auth_wrapper.dart';
import 'package:govvy/screens/landing/landing_page.dart';
import 'package:provider/provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/services/representative_service.dart';
import 'package:govvy/providers/representative_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file with improved error handling and verification
  await _loadEnvironmentVariables();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RepresentativeApp());
}

Future<void> _loadEnvironmentVariables() async {
  try {
    // Try to load .env file
    await dotenv.load(fileName: "assets/.env");

    // Verify required API keys
    final congressApiKey = dotenv.env['CONGRESS_API_KEY'];
    final googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

    // Log status of each key (securely)
    if (congressApiKey == null) {
      debugPrint("WARNING: CONGRESS_API_KEY not found in .env file");
    } else if (congressApiKey.isEmpty) {
      debugPrint("WARNING: CONGRESS_API_KEY is empty in .env file");
    } else {
      debugPrint(
          "CONGRESS_API_KEY loaded successfully (${congressApiKey.substring(0, min(3, congressApiKey.length))}...)");
    }

    if (googleMapsApiKey == null) {
      debugPrint("WARNING: GOOGLE_MAPS_API_KEY not found in .env file");
    } else if (googleMapsApiKey.isEmpty) {
      debugPrint("WARNING: GOOGLE_MAPS_API_KEY is empty in .env file");
    } else {
      debugPrint(
          "GOOGLE_MAPS_API_KEY loaded successfully (${googleMapsApiKey.substring(0, min(3, googleMapsApiKey.length))}...)");
    }

    debugPrint(".env file loaded with ${dotenv.env.length} variables");
  } catch (e) {
    debugPrint("WARNING: Error loading .env file: $e");
    debugPrint(
        "WARNING: API features may not work correctly without environment variables.");
  }
}

// Helper function to safely take a substring
int min(int a, int b) => a < b ? a : b;

class RepresentativeApp extends StatelessWidget {
  const RepresentativeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => RepresentativeService()),
        ChangeNotifierProxyProvider<RepresentativeService,
            RepresentativeProvider>(
          create: (context) =>
              RepresentativeProvider(context.read<RepresentativeService>()),
          update: (context, service, previous) =>
              previous ?? RepresentativeProvider(service),
        ),
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
        debugShowCheckedModeBanner: false,
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
        // For web, show only the landing page
        // For mobile, show the full app with auth wrapper
        home: kIsWeb ? const LandingPage() : const AuthWrapper(),
      ),
    );
  }
}
