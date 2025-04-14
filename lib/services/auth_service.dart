// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:govvy/models/user_model.dart';
import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'package:universal_html/html.dart' as html;

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Constructor to listen for auth state changes
  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      // Update UI when auth state changes
      notifyListeners();
      if (user != null) {
        // Update last login timestamp for the user
        updateLastLogin(user.uid);
      }
    });
  }

  // Register a new user with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String address,
    String? phone,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save additional user data to Firestore
      if (userCredential.user != null) {
        await _saveUserData(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          address: address,
          phone: phone,
        );
        
        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(name);
      }
      
      notifyListeners();
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        print('Error registering user: $e');
      }
      rethrow;
    }
  }
  
  // Phone number authentication methods
  
  // Step 1: Request verification code via SMS
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      if (kDebugMode) {
        print('Verifying phone number: $phoneNumber');
      }
      
      // For web platform, we need to handle reCAPTCHA differently
      if (kIsWeb) {
        // Create reCAPTCHA verification
        try {
          final recaptchaVerifier = createRecaptchaVerifier();
          
          // Apply reCAPTCHA to the phone authentication process using JavaScript interop
          final authJS = js.context['firebase']['auth']();
          final phoneNumberForAuth = phoneNumber; // Use a different variable name
          
          // Use signInWithPhoneNumber which requires reCAPTCHA on web
          final confirmationResultJS = await authJS.callMethod('signInWithPhoneNumber', 
              [phoneNumberForAuth, recaptchaVerifier]);
          
          // Store the verification ID from confirmationResult
          final verificationId = confirmationResultJS['verificationId'];
          
          // Manual trigger of codeSent callback with the verification ID
          codeSent(verificationId, null);
          
        } catch (e) {
          if (kDebugMode) {
            print('reCAPTCHA error: $e');
          }
          verificationFailed(
            FirebaseAuthException(
              code: 'recaptcha-error',
              message: 'Error with reCAPTCHA verification: $e',
            ),
          );
        }
      } else {
        // For mobile platforms, use the standard verifyPhoneNumber method
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
          timeout: const Duration(seconds: 60),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying phone number: $e');
      }
      rethrow;
    }
  }

  // Create reCAPTCHA verifier for web
  dynamic createRecaptchaVerifier() {
    if (kIsWeb) {
      // Check if Firebase Auth is available
      if (js.context['firebase'] != null && 
          js.context['firebase']['auth'] != null) {
        // Create a RecaptchaVerifier instance
        return js.context['firebase']['auth']().callMethod('RecaptchaVerifier', [
          'recaptcha-container',
          js.JsObject.jsify({
            'size': 'invisible',
            'callback': (js.JsObject token) {
              // reCAPTCHA solved, allow signInWithPhoneNumber
              if (kDebugMode) {
                print('reCAPTCHA verified');
              }
            }
          })
        ]);
      }
    }
    return null;
  }
  
  // Step 2: Sign in with verification code
  Future<UserCredential?> signInWithPhoneCredential(
    PhoneAuthCredential credential, {
    String? name,
    String? address,
  }) async {
    try {
      if (kDebugMode) {
        print('Attempting to sign in with phone credential');
        print('Name: $name, Address: $address');
      }
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (kDebugMode) {
        print('User signed in: ${userCredential.user?.uid}');
        print('Is new user: ${userCredential.additionalUserInfo?.isNewUser}');
      }
      
      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser == true && 
          userCredential.user != null && 
          name != null && 
          address != null) {
        
        if (kDebugMode) {
          print('New user detected, saving user data to Firestore');
        }
        
        // Save additional user data to Firestore
        await _saveUserData(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: name,
          address: address,
          phone: userCredential.user!.phoneNumber,
        );
        
        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(name);
        
        if (kDebugMode) {
          print('Display name updated: $name');
        }
      } else if (userCredential.user != null) {
        if (kDebugMode) {
          print('Existing user, updating last login');
        }
        
        // Update last login for existing users
        await updateLastLogin(userCredential.user!.uid);
      }
      
      notifyListeners();
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in with phone credential: $e');
      }
      rethrow;
    }
  }
  
  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login
      if (userCredential.user != null) {
        await updateLastLogin(userCredential.user!.uid);
      }
      
      notifyListeners();
      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in: $e');
      }
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      rethrow;
    }
  }
  
  // Save user data to Firestore
  Future<void> _saveUserData({
    required String uid,
    required String email,
    required String name,
    required String address,
    String? phone,
  }) async {
    try {
      // Ensure phone number is in the right format if provided
      String? formattedPhone = phone;
      if (phone != null && phone.isNotEmpty && !phone.startsWith('+')) {
        // If no country code is provided, default to US (+1)
        formattedPhone = '+1${phone.replaceAll(RegExp(r'[^0-9]'), '')}';
      }
      
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'address': address,
        'phone': formattedPhone,
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('User data saved to Firestore: $uid');
        print('Phone number saved: $formattedPhone');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user data: $e');
      }
      rethrow;
    }
  }
  
  // Update user's last login timestamp
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'last_login': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('Last login updated for user: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last login: $e');
      }
    }
  }
  
  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(uid, data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user data: $e');
      }
      return null;
    }
  }
  
  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return getUserData(currentUser!.uid);
  }
}