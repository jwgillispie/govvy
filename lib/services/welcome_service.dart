import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Key to track if welcome message has been shown
  static const String _welcomeShownKey = 'welcome_message_shown';
  
  // Check if the welcome message has been shown to the user
  Future<bool> shouldShowWelcomeMessage() async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Check local storage if we've already shown the welcome message
      final prefs = await SharedPreferences.getInstance();
      final String key = '${_welcomeShownKey}_${user.uid}';
      final bool welcomeShown = prefs.getBool(key) ?? false;
      
      if (welcomeShown) return false;
      
      // Get user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) return false;
      
      // Check if user is a new signup (created within the last day)
      final createdAt = userDoc.data()?['created_at'] as Timestamp?;
      if (createdAt == null) return false;
      
      final now = DateTime.now();
      final signupDate = createdAt.toDate();
      final difference = now.difference(signupDate);
      
      // Show welcome message if user signed up less than 1 day ago
      return difference.inDays < 1;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking welcome message status: $e');
      }
      return false;
    }
  }
  
  // Mark that the welcome message has been shown to the user
  Future<void> markWelcomeMessageAsShown() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final String key = '${_welcomeShownKey}_${user.uid}';
      await prefs.setBool(key, true);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking welcome message as shown: $e');
      }
    }
  }
  
  // Get personalized welcome data
  Future<Map<String, dynamic>> getPersonalizedWelcomeData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'name': 'there',
          'isNewUser': true,
        };
      }
      
      // Get user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        return {
          'name': user.displayName ?? 'there',
          'isNewUser': true,
        };
      }
      
      final userData = userDoc.data()!;
      
      return {
        'name': userData['name'] ?? user.displayName ?? 'there',
        'address': userData['address'],
        'isNewUser': true,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting personalized welcome data: $e');
      }
      return {
        'name': 'there',
        'isNewUser': true,
      };
    }
  }
}