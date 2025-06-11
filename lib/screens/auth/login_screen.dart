import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/widgets/auth/signup_form.dart';
import 'package:govvy/screens/home/home_screen_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSignUpForm = false;
  bool _isResetPasswordLoading = false;
  String? _resetPasswordMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final userCredential = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // If user is now logged in, navigate to HomeScreenWrapper
      if (userCredential != null && context.mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (context) => const HomeScreenWrapper(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = _handleAuthError(e.toString());
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
    if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'Wrong password provided.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Invalid email format.';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }

  void _toggleSignUpForm() {
    setState(() {
      _showSignUpForm = !_showSignUpForm;
      _errorMessage = null;
      _resetPasswordMessage = null;
    });
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address to reset password.';
      });
      return;
    }

    setState(() {
      _isResetPasswordLoading = true;
      _errorMessage = null;
      _resetPasswordMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendPasswordResetEmail(email: _emailController.text.trim());
      
      setState(() {
        _resetPasswordMessage = 'Password reset email sent! Check your inbox.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = _handleResetPasswordError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResetPasswordLoading = false;
        });
      }
    }
  }

  String _handleResetPasswordError(String errorMessage) {
    if (errorMessage.contains('user-not-found')) {
      return 'No account found with this email address.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else {
      return 'Failed to send reset email. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'govvy',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Connect with your representatives',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 48),
                
                if (!_showSignUpForm) ...[
                  // Login Form
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
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
                  
                  if (_resetPasswordMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        _resetPasswordMessage!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _isResetPasswordLoading ? null : _resetPassword,
                      child: _isResetPasswordLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            )
                          : const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _toggleSignUpForm,
                      child: const Text('Don\'t have an account? Sign Up'),
                    ),
                  ),
                ] else ...[
                  // Sign Up Form
                  Center(
                    child: Text(
                      'Create an Account',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SignUpForm(
                    onSignUpSuccess: () {
                      // We don't need to navigate because the AuthWrapper will do it
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _toggleSignUpForm,
                      child: const Text('Already have an account? Sign In'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}