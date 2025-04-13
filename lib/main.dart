import 'package:flutter/material.dart';
import 'package:govvy/screens/landing/landing_page.dart';

void main() {
  runApp(const RepresentativeApp());
}

class RepresentativeApp extends StatelessWidget {
  const RepresentativeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const LandingPage(),
    );
  }
}
