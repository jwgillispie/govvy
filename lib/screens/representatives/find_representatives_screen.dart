// lib/screens/representatives/find_representatives_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/representative_provider.dart';
import 'package:govvy/services/auth_service.dart';
import 'package:govvy/utils/address_validator.dart';
import 'package:govvy/widgets/representatives/representative_card.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';

class FindRepresentativesScreen extends StatefulWidget {
  const FindRepresentativesScreen({Key? key}) : super(key: key);

  @override
  State<FindRepresentativesScreen> createState() => _FindRepresentativesScreenState();
}

class _FindRepresentativesScreenState extends State<FindRepresentativesScreen> {
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _userAddress;
  bool _usingCurrentAddress = true;
  bool _initialLoadComplete = false;
  String? _validationError;
  bool _isSearching = false;
  
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
      setState(() {
        _initialLoadComplete = false;
      });
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();
      
      if (userData != null && userData.address.isNotEmpty) {
        setState(() {
          _userAddress = userData.address;
          _addressController.text = _userAddress!;
          _validationError = null;
        });
        
        // Auto-fetch representatives using the profile address
        await _fetchRepresentatives();
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
  
  // Fetch representatives based on the current address
  Future<void> _fetchRepresentatives() async {
    // Get and validate the address
    final address = _addressController.text.trim();
    
    if (address.isEmpty) {
      setState(() {
        _validationError = 'Please enter an address';
      });
      return;
    }
    
    // Basic address validation
    if (!AddressValidator.isValidAddress(address)) {
      setState(() {
        _validationError = AddressValidator.getErrorMessage(address);
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _validationError = null;
    });
    
    // Format the address for consistent API calls
    final formattedAddress = AddressValidator.formatAddress(address);
    AddressValidator.debugAddress(address);
    
    try {
      // Clear any previous errors
      final provider = Provider.of<RepresentativeProvider>(context, listen: false);
      provider.clearError();
      
      // Fetch representatives
      await provider.fetchRepresentativesByAddress(formattedAddress);
      
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
                  child: Form(
                    key: _formKey,
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
                                      _validationError = null;
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
                            helperText: 'Example: 123 Main St, Anytown, FL 32000',
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
                              onPressed: _isSearching ? null : _fetchRepresentatives,
                            ),
                            isDense: true,
                            errorText: _validationError,
                          ),
                          onFieldSubmitted: (_) => _fetchRepresentatives(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your address';
                            }
                            if (!AddressValidator.isValidAddress(value)) {
                              return AddressValidator.getErrorMessage(value);
                            }
                            return null;
                          },
                          enabled: !_isSearching,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSearching ? null : _fetchRepresentatives,
                            icon: _isSearching 
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    padding: const EdgeInsets.all(2.0),
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(_isSearching ? 'Searching...' : 'Find Representatives'),
                          ),
                        ),
                      ],
                    ),
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
                                              : 'Enter an address to find your representatives',
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