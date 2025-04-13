import 'package:flutter/material.dart';
import 'package:govvy/widgets/auth/signup_form.dart';
import 'package:provider/provider.dart';
import 'package:govvy/services/auth_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _addressController = TextEditingController();
  bool _showSignUpForm = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _toggleSignUpForm() {
    setState(() {
      _showSignUpForm = !_showSignUpForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Bar
            Container(
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'govvy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'About',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Features',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Contact',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      if (authService.currentUser == null)
                        TextButton(
                          onPressed: _toggleSignUpForm,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Sign Up'),
                        )
                      else
                        TextButton(
                          onPressed: () => authService.signOut(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Sign Out'),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Hero Section
            Container(
              height: screenSize.height * 0.7,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF5E35B1), // Deep Purple 600
                    Color(0xFF7E57C2), // Deep Purple 400
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    right: -100,
                    top: -100,
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(
                        Icons.account_balance,
                        size: 500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Know Your Local Government',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 42,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Track representatives, understand legislation, and engage with your local democracy - all in one place.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: _toggleSignUpForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    child: const Text('Get Started'),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'How it works',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _showSignUpForm
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Create an Account',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5E35B1),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SignUpForm(
                                          onSignUpSuccess: () {
                                            setState(() {
                                              _showSignUpForm = false;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('Already have an account?'),
                                            TextButton(
                                              onPressed: () {
                                                // TODO: Show login form
                                              },
                                              child: const Text('Sign In'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Find Your Representatives',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5E35B1),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        TextField(
                                          controller: _addressController,
                                          decoration: InputDecoration(
                                            hintText: 'Enter your address',
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.location_on,
                                              color: Color(0xFF5E35B1),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (authService.currentUser == null) {
                                                // If not logged in, show sign up form
                                                _toggleSignUpForm();
                                              } else {
                                                // If logged in, perform search
                                                // TODO: Implement representative search
                                              }
                                            },
                                            child: const Text('Search'),
                                          ),
                                        ),
                                        if (authService.currentUser == null) ...[
                                          const SizedBox(height: 16),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Sign up to save your searches and receive updates',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            onPressed: _toggleSignUpForm,
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            child: const Text('Create Account'),
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Features Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
              child: Column(
                children: [
                  Text(
                    'Why Use govvy',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Breaking down the barriers between you and your local government',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      _buildFeatureCard(
                        context,
                        Icons.people_outline,
                        'Identify Your Representatives',
                        'Find all your local representatives by simply entering your address.',
                      ),
                      _buildFeatureCard(
                        context,
                        Icons.how_to_vote_outlined,
                        'Track Voting Records',
                        'See how your representatives vote on issues that matter to you.',
                      ),
                      _buildFeatureCard(
                        context,
                        Icons.monetization_on_outlined,
                        'Follow the Money',
                        'Understand who funds your representatives with transparent donation data.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _buildFeatureCard(
                        context,
                        Icons.account_balance_outlined,
                        'Committee Insights',
                        'Learn which committees your representatives serve on and how they influence policy.',
                      ),
                      _buildFeatureCard(
                        context,
                        Icons.contact_mail_outlined,
                        'Direct Communication',
                        'Easily contact your representatives through provided contact information.',
                      ),
                      _buildFeatureCard(
                        context,
                        Icons.notifications_outlined,
                        'Stay Updated',
                        'Receive notifications about important votes and activities in your area.',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Call to Action
            Container(
              padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
              color: const Color(0xFFEDE7F6), // Deep Purple 50
              child: Column(
                children: [
                  Text(
                    'Democracy Starts Locally',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 600,
                    child: Text(
                      'Understanding your local government is the first step towards active citizenship. Download govvy today and empower yourself with knowledge.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.android),
                        label: const Text('Google Play'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.apple),
                        label: const Text('App Store'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(32),
              color: const Color(0xFF4527A0), // Deep Purple 800
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'govvy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.facebook, color: Colors.white),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.web, color: Colors.white),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.web, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  const Text(
                    '© 2025 govvy. All rights reserved.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, IconData icon, String title, String description) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}