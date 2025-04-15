// lib/widgets/auth/phone_auth_form.dart
import 'package:flutter/material.dart';
import 'package:govvy/widgets/welcome/signup_success_dialog.dart';
import 'package:provider/provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthForm extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  
  const PhoneAuthForm({
    Key? key,
    this.onAuthSuccess,
  }) : super(key: key);

  @override
  State<PhoneAuthForm> createState() => _PhoneAuthFormState();
}

class _PhoneAuthFormState extends State<PhoneAuthForm> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _codeSent = false;
  String _verificationId = '';
  
  // Debug information
  String _debugStatus = 'Not started';
  String _debugVerificationId = '';
  int? _debugResendToken;
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugStatus = 'Sending verification code...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Format the phone number with country code if not included
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+1$phoneNumber'; // Default to US country code
      }
      
      // Show reCAPTCHA information if on web
      if (kIsWeb) {
        setState(() {
          _debugStatus = 'Starting reCAPTCHA verification (required for web)...';
        });
      }
      
      await authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          setState(() {
            _debugStatus = 'Auto-verification completed';
          });
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
            _errorMessage = _handleAuthError(e.message ?? e.code);
            _debugStatus = 'Verification failed: ${e.code}';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
            _debugStatus = 'Code sent';
            _debugVerificationId = verificationId;
            _debugResendToken = resendToken;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _debugStatus = 'Code auto retrieval timeout';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _handleAuthError(e.toString());
        _debugStatus = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationCodeController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the verification code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _debugStatus = 'Verifying code...';
    });

    try {
      // Create a PhoneAuthCredential with the verification ID and code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _verificationCodeController.text.trim(),
      );
      
      await _signInWithCredential(credential);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _handleAuthError(e.toString());
        _debugStatus = 'Verification error: ${e.toString()}';
      });
    }
  }
  
Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    await authService.signInWithPhoneCredential(
      credential,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
    );
    
    setState(() {
      _debugStatus = 'Sign in successful';
    });
    
    // Show success dialog before triggering onAuthSuccess
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SignupSuccessDialog(
          name: _nameController.text.trim().split(' ').first, // Use first name
          onDismiss: () {
            Navigator.of(context).pop();
          },
          onContinue: () {
            Navigator.of(context).pop();
            if (widget.onAuthSuccess != null) {
              widget.onAuthSuccess!();
            }
          },
        ),
      );
    }
    
    // Only call onAuthSuccess if dialog was dismissed with 'Close'
    // If 'Continue' was pressed, the callback is already handled in the dialog
    if (mounted && widget.onAuthSuccess != null) {
      widget.onAuthSuccess!();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    setState(() {
      _errorMessage = _handleAuthError(e.toString());
      _debugStatus = 'Sign in error: ${e.toString()}';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  String _handleAuthError(String errorMessage) {
    if (errorMessage.contains('invalid-phone-number')) {
      return 'The phone number format is incorrect. Please check and try again.';
    } else if (errorMessage.contains('code-expired')) {
      return 'The verification code has expired. Please request a new one.';
    } else if (errorMessage.contains('invalid-verification-code')) {
      return 'Invalid verification code. Please check and try again.';
    } else if (errorMessage.contains('too-many-requests')) {
      return 'Too many requests. Please try again later.';
    } else if (errorMessage.contains('quota-exceeded')) {
      return 'SMS quota exceeded. Please try again tomorrow.';
    } else if (errorMessage.contains('missing-recaptcha-token')) {
      return 'Please complete the reCAPTCHA verification.';
    } else {
      return 'An error occurred. Please try again later. (${errorMessage.split(']').last.trim()})';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDebugMode = true; // Set to false in production

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
          if (isDebugMode)
            Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Status: $_debugStatus'),
                  if (_debugVerificationId.isNotEmpty)
                    Text('Verification ID: ${_debugVerificationId.substring(0, 8)}...'),
                  if (_debugResendToken != null)
                    Text('Resend Token: $_debugResendToken'),
                  if (kIsWeb)
                    Text('Platform: Web (reCAPTCHA required)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
          if (!_codeSent) ...[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                isDense: true,
                hintText: '(123) 456-7890',
                helperText: 'U.S. numbers will have +1 added automatically',
                helperStyle: TextStyle(fontSize: 10),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                // Basic phone validation - can be improved
                String cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
                if (cleaned.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (kIsWeb)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'reCAPTCHA Verification',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Please complete the reCAPTCHA verification when prompted.',
                      style: TextStyle(fontSize: 12),
                    ),
                    // This div will be used for the invisible reCAPTCHA
                    Container(
                      height: 1,
                      width: 1,
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPhoneNumber,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text('Get Verification Code'),
              ),
            ),
          ] else ...[
            // Code verification UI
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                'Verification code sent to ${_phoneController.text}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _verificationCodeController,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: const Icon(Icons.security_outlined, size: 18),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text('Verify Code'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isLoading ? null : _verifyPhoneNumber,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Resend Code'),
            ),
          ],
        ],
      ),
    );
  }
}