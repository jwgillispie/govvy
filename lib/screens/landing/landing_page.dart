import 'package:flutter/material.dart';
import 'package:govvy/widgets/auth/signup_form.dart';
import 'package:provider/provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _showSignUpForm = false;
  bool _isMenuOpen = false; // For mobile menu

  void _toggleSignUpForm() {
    setState(() {
      _showSignUpForm = !_showSignUpForm;
      // Close menu when toggling sign up
      if (_isMenuOpen) {
        _isMenuOpen = false;
      }
    });
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jordangillispie@outlook.com',
      queryParameters: {
        'subject': 'govvy Feedback',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Future<void> _launchCall() async {
    final Uri callLaunchUri = Uri(
      scheme: 'tel',
      path: '3523271969',
    );

    if (await canLaunchUrl(callLaunchUri)) {
      await launchUrl(callLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Responsive App Bar
            _buildResponsiveAppBar(context, authService, isMobile),

            // Expanded Mobile Menu (when open)
            if (isMobile && _isMenuOpen) _buildMobileMenu(context, authService),

            // Hero Section
            _buildHeroSection(context, screenSize, isMobile, authService),

            // Features Section
            _buildFeaturesSection(context, isMobile),

            // Founder Contact Section
            _buildFounderContactSection(context, isMobile),

            // Call to Action
            _buildCallToAction(context, isMobile),

            // Footer
            _buildFooter(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveAppBar(
      BuildContext context, AuthService authService, bool isMobile) {
    return Container(
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
          if (isMobile)
            // Mobile menu icon
            IconButton(
              icon: Icon(
                _isMenuOpen ? Icons.close : Icons.menu,
                color: Colors.white,
              ),
              onPressed: _toggleMenu,
            )
          else
            // Desktop navigation
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
    );
  }

  Widget _buildMobileMenu(BuildContext context, AuthService authService) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'About',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              _toggleMenu();
              // Navigate to about page
            },
          ),
          ListTile(
            title: const Text(
              'Features',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              _toggleMenu();
              // Navigate to features page
            },
          ),
          ListTile(
            title: const Text(
              'Contact',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              _toggleMenu();
              // Navigate to contact page
            },
          ),
          const Divider(color: Colors.white24),
          if (authService.currentUser == null)
            ListTile(
              title: const Text(
                'Sign Up',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                _toggleMenu();
                _toggleSignUpForm();
              },
            )
          else
            ListTile(
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                _toggleMenu();
                authService.signOut();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Size screenSize, bool isMobile,
      AuthService authService) {
    return Container(
      constraints: BoxConstraints(
        minHeight: isMobile ? screenSize.height * 0.6 : screenSize.height * 0.7,
      ),
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
            padding: const EdgeInsets.all(24.0),
            child: isMobile
                ? _buildMobileHeroContent(context, authService)
                : _buildDesktopHeroContent(context, authService),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeroContent(
      BuildContext context, AuthService authService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get inside the mind of your local government',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Undeniable, unbiased visibility into the actions and responsibilities of your local politicians.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _toggleSignUpForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Join The Movement'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (_showSignUpForm)
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
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
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopHeroContent(
      BuildContext context, AuthService authService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Get inside the mind of your local government',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 42,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 700,
              child: Text(
                'Undeniable, unbiased visibility into the actions and responsibilities of your local representatives.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _toggleSignUpForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Join The Movement'),
            ),
          ],
        ),
        const SizedBox(height: 40),
        if (_showSignUpForm)
          Container(
            width: 450,
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
            child: Column(
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
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Text(
            'How Well Do You Know Your Government?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Questions to consider:',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Who represents you locally? What do they actually do? Have you ever contacted them? How do learn about your government?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Text(
            'Why Use govvy',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'We are breaking down any barriers between you and your local government',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          isMobile
              ? _buildMobileFeatureCards(context)
              : _buildDesktopFeatureCards(context),
        ],
      ),
    );
  }

  Widget _buildMobileFeatureCards(BuildContext context) {
    return Column(
      children: [
        _buildFeatureCardMobile(
          context,
          Icons.people_outline,
          'Identify Your Representatives',
          'Find all your local representatives by simply entering your address.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.how_to_vote_outlined,
          'Track Voting Records',
          'See how your representatives vote on issues that matter to you.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.monetization_on_outlined,
          'Follow the Money',
          'Understand who funds your representatives with transparent donation data.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.account_balance_outlined,
          'Committee Insights',
          'Learn which committees your representatives serve on and how they influence policy.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.contact_mail_outlined,
          'Direct Communication',
          'Easily contact your representatives through provided contact information.',
        ),
        _buildFeatureCardMobile(
          context,
          Icons.notifications_outlined,
          'Stay Updated',
          'Receive notifications about important votes and activities in your area.',
        ),
      ],
    );
  }

  Widget _buildDesktopFeatureCards(BuildContext context) {
    return Column(
      children: [
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
    );
  }

  Widget _buildFeatureCardMobile(
      BuildContext context, IconData icon, String title, String description) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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

  Widget _buildFounderContactSection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: isMobile ? 32 : 40, horizontal: isMobile ? 20 : 32),
      color: const Color(0xFFD1C4E9), // Deep Purple 100
      child: Column(
        children: [
          Text(
            'Hit up the govvy team!! We wanna hear from you ',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: isMobile ? double.infinity : 600,
            child: Text(
              'We asked some questions in that little purple box up there - you can literally email or call us whenever you want to have any of these conversations :)',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          isMobile
              ? Column(
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF5E35B1),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email Us',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: _launchEmail,
                                    child: Text(
                                      'jordangillispie@outlook.com',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: _launchEmail,
                                    child: Text(
                                      'caitlyng129@gmail.com',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              color: Color(0xFF5E35B1),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Call or Text Us',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: _launchCall,
                                    child: Text(
                                      '(352) 327-1969',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: _launchCall,
                                    child: Text(
                                      '(352) 327-1969',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF5E35B1),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email Us',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: _launchEmail,
                                  child: Text(
                                    'jordangillispie@outlook.com',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: _launchEmail,
                                  child: Text(
                                    'caitlyng129@gmail.com',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              color: Color(0xFF5E35B1),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Call Us',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: _launchCall,
                                  child: Text(
                                    '(352) 327-1969',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: _launchCall,
                                  child: Text(
                                    '(443) 223-6741',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildCallToAction(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: isMobile ? 40 : 64, horizontal: isMobile ? 24 : 32),
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
            width: isMobile ? double.infinity : 600,
            child: Text(
              'Understanding your local government is the first step towards active citizenship. Download govvy when we launch and empower yourself with knowledge!',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: EdgeInsets.symmetric(
                vertical: 16, horizontal: isMobile ? 24 : 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.upcoming_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Mobile Apps Coming Soon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF4527A0), // Deep Purple 800
      child: Column(
        children: [
          isMobile
              ? Column(
                  children: [
                    const Text(
                      'govvy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.facebook, color: Colors.white),
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
                )
              : Row(
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
                          icon: const Icon(Icons.facebook, color: Colors.white),
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
    );
  }
}
