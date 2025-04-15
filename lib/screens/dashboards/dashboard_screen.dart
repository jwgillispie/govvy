// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:govvy/widgets/share/share_app_widget.dart.dart';
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
  
  @override
  void initState() {
    super.initState();
    // Check if we should show the welcome dialog
    _checkWelcomeMessage();
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('govvy'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
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
              const SizedBox(height: 24),
              
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
                    'Find and learn about your elected officials',
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
                    Icons.account_balance_outlined,
                    'Committees',
                    'Explore legislative committees',
                    () {
                      // Navigate to committees screen (to be implemented)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Share section
              Text(
                'Share govvy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              const ShareAppWidget(),
              
              const SizedBox(height: 32),
              
              // Recent activity section
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Placeholder for recent activity
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start exploring to see updates here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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