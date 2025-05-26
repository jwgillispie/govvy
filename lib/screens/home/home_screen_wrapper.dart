// lib/screens/home/home_screen_wrapper.dart
import 'package:flutter/material.dart';
import 'package:govvy/screens/bills/enhanced_bill_screen.dart';
import 'package:govvy/screens/representatives/find_representatives_screen.dart';
import 'package:govvy/screens/campaign_finance/modular_campaign_finance_screen.dart';
import 'package:govvy/screens/profile/profile_screen.dart';

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({Key? key}) : super(key: key);

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  int _currentIndex = 0;

  // List of screens for the bottom navigation
  final List<Widget> _screens = [
    const FindRepresentativesScreen(),
    const EnhancedBillScreen(),
    const ModularCampaignFinanceScreen(),
    const ProfileScreen(), // Assuming you have a ProfileScreen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Needed for 4+ items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Representatives',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Bills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}