// lib/screens/representatives/find_representatives_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/representative_provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/widgets/representatives/representative_card.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';

class FindRepresentativesScreen extends StatefulWidget {
  const FindRepresentativesScreen({Key? key}) : super(key: key);

  @override
  State<FindRepresentativesScreen> createState() => _FindRepresentativesScreenState();
}

class _FindRepresentativesScreenState extends State<FindRepresentativesScreen> {
  final _addressController = TextEditingController();
  String? _userAddress;
  bool _usingCurrentAddress = true;
  bool _initialLoadComplete = false;
  
  @override
  void initState() {
    super.initState();
    _fetchAddressFromProfile();
  }
  
  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
  
  // Fetch the user's address from their profile
  Future<void> _fetchAddressFromProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();
      
      if (userData != null && userData.address.isNotEmpty) {
        setState(() {
          _userAddress = userData.address;
          _addressController.text = _userAddress!;
        });
        
        // Auto-fetch representatives using the profile address
        await _fetchRepresentatives();
      }
      
      setState(() {
        _initialLoadComplete = true;
      });
    } catch (e) {
      print('Error fetching user address: $e');
      setState(() {
        _initialLoadComplete = true;
      });
    }
  }
  
  // Fetch representatives based on the current address
  Future<void> _fetchRepresentatives() async {
    final address = _addressController.text.trim();
    
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Clear any previous errors
    final provider = Provider.of<RepresentativeProvider>(context, listen: false);
    provider.clearError();
    
    // Fetch representatives
    await provider.fetchRepresentativesByAddress(address);
    
    if (provider.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter your address to find your representatives',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_userAddress != null) ...[
                        Row(
                          children: [
                            Switch(
                              value: _usingCurrentAddress,
                              onChanged: (value) {
                                setState(() {
                                  _usingCurrentAddress = value;
                                  if (_usingCurrentAddress) {
                                    _addressController.text = _userAddress!;
                                  } else {
                                    _addressController.clear();
                                  }
                                });
                              },
                            ),
                            Text(
                              'Use my profile address',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Enter your address',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _fetchRepresentatives,
                          ),
                          isDense: true,
                        ),
                        onFieldSubmitted: (_) => _fetchRepresentatives(),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _fetchRepresentatives,
                          icon: const Icon(Icons.search),
                          label: const Text('Find Representatives'),
                        ),
                      ),
                    ],
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
                              child: Text(
                                provider.errorMessage != null
                                    ? 'Error: ${provider.errorMessage}'
                                    : 'No representatives found',
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
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