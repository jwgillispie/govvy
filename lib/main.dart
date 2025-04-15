import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:govvy/firebase_options.dart';
import 'package:govvy/screens/auth/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/services/representative_service.dart';
import 'package:govvy/providers/representative_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try loading .env, but continue if it fails
  try {
    await dotenv.load(fileName: "assets/.env");
    debugPrint(".env file loaded successfully");
  } catch (e) {
    debugPrint("Warning: .env file not found or could not be loaded: $e");
    debugPrint("Continuing without environment variables. API features may be limited.");
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const RepresentativeApp());
}

class RepresentativeApp extends StatelessWidget {
  const RepresentativeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => RepresentativeService()),
        ChangeNotifierProxyProvider<RepresentativeService, RepresentativeProvider>(
          create: (context) => RepresentativeProvider(context.read<RepresentativeService>()),
          update: (context, service, previous) => previous ?? RepresentativeProvider(service),
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
        home: const AuthWrapper(),
      ),
    );
  }
}