// lib/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:govvy/screens/auth/login_screen.dart';
import 'package:govvy/screens/home/home_screen_wrapper.dart';
import 'package:govvy/screens/landing/landing_page.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/providers/bill_provider.dart';
import 'package:govvy/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Load providers to initialize them
    Provider.of<BillProvider>(context, listen: false);
    Provider.of<CombinedRepresentativeProvider>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // If still loading the auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If authenticated
        if (snapshot.hasData) {
          return const HomeScreenWrapper();
        }
        
        // If not authenticated, check if first time user
        return FutureBuilder<bool>(
          future: authService.isFirstTimeUser(),
          builder: (context, firstTimeSnapshot) {
            if (firstTimeSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // Show landing page for first-time users
            if (firstTimeSnapshot.data == true) {
              return const LandingPage();
            }
            
            // Otherwise show login screen
            return const LoginScreen();
          },
        );
      },
    );
  }
}