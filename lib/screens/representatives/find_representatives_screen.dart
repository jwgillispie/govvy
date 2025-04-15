// lib/screens/representatives/find_representatives_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/representative_provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/widgets/address/structured_address_input.dart';
import 'package:govvy/widgets/representatives/representative_card.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';

class FindRepresentativesScreen extends StatefulWidget {
  const FindRepresentativesScreen({Key? key}) : super(key: key);

  @override
  State<FindRepresentativesScreen> createState() => _FindRepresentativesScreenState();
}

class _FindRepresentativesScreenState extends State<FindRepresentativesScreen> {
  String? _userAddress;
  bool _initialLoadComplete = false;
  String? _validationError;
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _fetchAddressFromProfile();
  }
  
  // Fetch the user's address from their profile
  Future<void> _fetchAddressFromProfile() async {
    try {
      setState(() {
        _initialLoadComplete = false;
      });
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();
      
      if (userData != null && userData.address.isNotEmpty) {
        setState(() {
          _userAddress = userData.address;
          _validationError = null;
        });
        
        // Auto-fetch representatives using the profile address
        await _fetchRepresentatives(_userAddress!);
      }
      
      setState(() {
        _initialLoadComplete = true;
      });
    } catch (e) {
      debugPrint('Error fetching user address: $e');
      setState(() {
        _initialLoadComplete = true;
        _validationError = 'Could not load your profile address. Please enter an address manually.';
      });
    }
  }
  
  // Fetch representatives based on the provided address
  Future<void> _fetchRepresentatives(String address) async {
    if (address.isEmpty) {
      setState(() {
        _validationError = 'Please enter your complete address';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _validationError = null;
    });
    
    try {
      // Clear any previous errors
      final provider = Provider.of<RepresentativeProvider>(context, listen: false);
      provider.clearError();
      
      // Fetch representatives
      await provider.fetchRepresentativesByAddress(address);
      
      if (provider.errorMessage != null && mounted) {
        setState(() {
          _validationError = provider.errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationError = 'Error searching: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RepresentativeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Representatives'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: !_initialLoadComplete
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Address input form
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StructuredAddressInput(
                    initialAddress: _userAddress,
                    isLoading: _isSearching,
                    onAddressSubmitted: (formattedAddress) {
                      _fetchRepresentatives(formattedAddress);
                    },
                  ),
                ),
                
                // Divider
                const Divider(height: 1),
                
                // Loading indicator or representatives list
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.representatives.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sentiment_neutral,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      provider.errorMessage != null
                                          ? 'Error: ${provider.errorMessage}'
                                          : _validationError != null
                                              ? _validationError!
                                              : 'Enter your complete address to find your representatives',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_validationError != null || provider.errorMessage != null) ...[
                                      const SizedBox(height: 24),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _validationError = null;
                                          });
                                          provider.clearError();
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Try Again'),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: provider.representatives.length,
                              itemBuilder: (context, index) {
                                final rep = provider.representatives[index];
                                return RepresentativeCard(
                                  representative: rep,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RepresentativeDetailsScreen(
                                          bioGuideId: rep.bioGuideId,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}