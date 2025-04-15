import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:govvy/screens/dashboards/dashboard_screen.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/screens/auth/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Provider.of<AuthService>(context).authStateChanges,
      builder: (context, snapshot) {
        // If we have a user, return the dashboard
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        
        // Otherwise, return a simple login screen
        return const LoginScreen();
      },
    );
  }
}