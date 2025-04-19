// lib/screens/dashboards/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:govvy/widgets/debug_access_button.dart';
import 'package:govvy/widgets/share/share_app_widget.dart.dart';
import 'package:govvy/widgets/share/share_reminder_widget.dart';
import 'package:provider/provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/screens/representatives/find_representatives_screen.dart';
import 'package:govvy/services/welcome_service.dart';
import 'package:govvy/widgets/welcome/welcome_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WelcomeService _welcomeService = WelcomeService();
  bool _showShareReminder = false;

  @override
  void initState() {
    super.initState();
    // Check if we should show the welcome dialog
    _checkWelcomeMessage();
    // Check if we should show the share reminder
    _checkShareReminder();
  }

  Future<void> _checkWelcomeMessage() async {
    final shouldShow = await _welcomeService.shouldShowWelcomeMessage();

    if (shouldShow && mounted) {
      // Get personalized data for the welcome message
      final welcomeData = await _welcomeService.getPersonalizedWelcomeData();

      // Show the welcome dialog
      if (mounted) {
        // Use a slight delay to ensure the screen is fully built
        Future.delayed(const Duration(milliseconds: 500), () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => WelcomeDialog(
              name: welcomeData['name'],
              address: welcomeData['address'],
              onDismiss: () {
                Navigator.of(context).pop();
                _welcomeService.markWelcomeMessageAsShown();
              },
            ),
          );
        });
      }
    }
  }

  Future<void> _checkShareReminder() async {
    // Don't show share reminder if welcome message is shown
    final welcomeShouldShow = await _welcomeService.shouldShowWelcomeMessage();
    if (welcomeShouldShow) return;

    // Check if we should show the share reminder
    final shouldShowReminder = await ShareReminderWidget.shouldShowReminder();

    if (shouldShowReminder && mounted) {
      setState(() {
        _showShareReminder = true;
      });
    }
  }

  void _dismissShareReminder() {
    setState(() {
      _showShareReminder = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('govvy'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Add Debug Button here in debug mode
          if (kDebugMode)
            const DebugAccessButton(
              useIconButton: true,
              color: Colors.white,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to govvy',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your local government transparency companion',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),

              // Share reminder (if needed)
              if (_showShareReminder)
                ShareReminderWidget(
                  onDismiss: _dismissShareReminder,
                ),

              const SizedBox(height: 16),

              // Debug button (text variant) for better visibility in development
              if (kDebugMode)
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const DebugAccessButton(
                      useIconButton: false,
                      buttonText: 'Open API Debug Tools',
                    ),
                  ),
                ),

              // Features grid
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    Icons.people_outline,
                    'Representatives',
                    'Find all your elected officials',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindRepresentativesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    Icons.how_to_vote_outlined,
                    'Voting Records',
                    'Track how your representatives vote',
                    () {
                      // Navigate to voting records screen (to be implemented)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    Icons.monetization_on_outlined,
                    'Campaign Finance',
                    'Follow the money in politics',
                    () {
                      // Navigate to campaign finance screen (to be implemented)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                        ),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    Icons.notifications_outlined,
                    'Notifications',
                    'Stay informed about important votes',
                    () {
                      // Navigate to notifications screen (to be implemented)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Share section
              Text(
                'Share govvy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              const ShareAppWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}