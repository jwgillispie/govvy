// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/providers/bill_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final repProvider = Provider.of<CombinedRepresentativeProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder(
                  future: authService.getCurrentUserData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final userData = snapshot.data;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData?.name ?? 'User',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData?.email ?? 'No email',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        
                        // User's address
                        if (userData?.address != null && userData!.address.isNotEmpty)
                          ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Your Address'),
                            subtitle: Text(userData.address),
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                        // User's phone
                        if (userData?.phone != null && userData!.phone!.isNotEmpty)
                          ListTile(
                            leading: Icon(
                              Icons.phone,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Phone Number'),
                            subtitle: Text(userData.phone!),
                            contentPadding: EdgeInsets.zero,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Settings section
            Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Clear data cache
                  ListTile(
                    leading: Icon(
                      Icons.cleaning_services,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Clear Cached Data'),
                    subtitle: const Text('Clear locally stored representatives and bills data'),
                    onTap: () {
                      _showClearCacheConfirmation(context, repProvider, billProvider);
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  // Theme settings (placeholder)
                  ListTile(
                    leading: Icon(
                      Icons.dark_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Display Theme'),
                    subtitle: const Text('Light mode'),
                    // Placeholder - would connect to a theme provider
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Theme settings coming soon')),
                      );
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  // Notification settings (placeholder)
                  ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Notifications'),
                    subtitle: const Text('Manage legislative alerts'),
                    // Placeholder - would connect to notifications settings
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Account section
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Sign out button
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: const Text('Sign Out'),
                    onTap: () async {
                      await authService.signOut();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App information
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // App version info
                  ListTile(
                    leading: Icon(
                      Icons.info,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'), // Would normally get from package_info
                  ),
                  
                  const Divider(height: 1),
                  
                  // Privacy policy
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      // Would navigate to privacy policy page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy policy coming soon')),
                      );
                    },
                  ),
                  
                  const Divider(height: 1),
                  
                  // Terms of service
                  ListTile(
                    leading: Icon(
                      Icons.description,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Terms of Service'),
                    onTap: () {
                      // Would navigate to terms of service page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of service coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper to show clear cache confirmation dialog
  void _showClearCacheConfirmation(
    BuildContext context, 
    CombinedRepresentativeProvider repProvider,
    BillProvider billProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cache?'),
          content: const Text(
            'This will clear all locally stored data for representatives and bills. '
            'You will need to search again to reload the data.'
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () async {
                // Clear both caches
                repProvider.clearAll();
                billProvider.clearAll();
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared successfully')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}