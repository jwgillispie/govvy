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
                    final user = authService.currentUser;
                    
                    // Format account creation date if available
                    String accountCreatedDate = 'Unknown';
                    if (userData?.createdAt != null) {
                      accountCreatedDate = '${userData!.createdAt!.month}/${userData.createdAt!.day}/${userData.createdAt!.year}';
                    } else if (user?.metadata.creationTime != null) {
                      accountCreatedDate = '${user!.metadata.creationTime!.month}/${user.metadata.creationTime!.day}/${user.metadata.creationTime!.year}';
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData?.name ?? user?.displayName ?? 'User',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userData?.email ?? user?.email ?? 'No email',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Account type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Active Account',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.orange.shade800,
                                size: 20,
                              ),
                            ),
                            title: const Text('Your Address'),
                            subtitle: Text(userData.address),
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                        // User's phone
                        if (userData?.phone != null && userData!.phone!.isNotEmpty)
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone,
                                color: Colors.blue.shade800,
                                size: 20,
                              ),
                            ),
                            title: const Text('Phone Number'),
                            subtitle: Text(userData.phone!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        
                        // Account created date
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.green.shade800,
                              size: 20,
                            ),
                          ),
                          title: const Text('Account Created'),
                          subtitle: Text(accountCreatedDate),
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        // Last sign in date
                        if (user?.metadata.lastSignInTime != null)
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.access_time,
                                color: Colors.purple.shade800,
                                size: 20,
                              ),
                            ),
                            title: const Text('Last Sign In'),
                            subtitle: Text('${user!.metadata.lastSignInTime!.month}/${user.metadata.lastSignInTime!.day}/${user.metadata.lastSignInTime!.year}'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                        const SizedBox(height: 16),
                        
                        // Edit Profile Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                            onPressed: () {
                              // Show a coming soon message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edit profile feature coming soon')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Sign out button
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.logout,
                          color: Theme.of(context).colorScheme.error,
                          size: 24,
                        ),
                      ),
                      title: const Text('Sign Out'),
                      subtitle: const Text('Log out of your account'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      onTap: () {
                        _showSignOutConfirmation(context, authService);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Full-width sign out button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        onPressed: () {
                          _showSignOutConfirmation(context, authService);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
  
  // Helper to show sign out confirmation dialog
  void _showSignOutConfirmation(
    BuildContext context,
    AuthService authService,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out?'),
          content: const Text(
            'Are you sure you want to sign out? You will need to sign in again to access your account.'
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Sign Out'),
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signing out...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Perform sign out
                await authService.signOut();
                
                if (context.mounted) {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
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