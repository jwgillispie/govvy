// lib/screens/representatives/_find_representatives_screen.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/services/representative_service.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/widgets/address/structured_address_input.dart';
import 'package:govvy/widgets/representatives/representative_card.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';
import 'package:govvy/services/auth_service.dart';

class FindRepresentativesScreen extends StatefulWidget {
  const FindRepresentativesScreen({Key? key}) : super(key: key);

  @override
  State<FindRepresentativesScreen> createState() => _FindRepresentativesScreenState();
}

class _FindRepresentativesScreenState extends State<FindRepresentativesScreen> 
    with SingleTickerProviderStateMixin {
  String? _userAddress;
  bool _initialLoadComplete = false;
  String? _validationError;
  bool _isSearching = false;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAddressAndLoadCache();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Fetch address from profile and try to load from cache
  Future<void> _fetchAddressAndLoadCache() async {
    try {
      setState(() {
        _initialLoadComplete = false;
      });
      
      // Try to load from provider's cache first
      final provider = Provider.of<CombinedRepresentativeProvider>(context, listen: false);
      final cacheLoaded = await provider.loadFromCache();
      
      if (cacheLoaded) {
        setState(() {
          _userAddress = provider.lastSearchedAddress;
        });
      } else {
        // If no cache, try to get from user profile
        final authService = Provider.of<AuthService>(context, listen: false);
        final userData = await authService.getCurrentUserData();
        
        if (userData != null && userData.address.isNotEmpty) {
          setState(() {
            _userAddress = userData.address;
          });
        }
      }
      
      setState(() {
        _initialLoadComplete = true;
      });
    } catch (e) {
      debugPrint('Error fetching address: $e');
      setState(() {
        _initialLoadComplete = true;
        _validationError = 'Could not load your saved address. Please enter an address manually.';
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
      final provider = Provider.of<CombinedRepresentativeProvider>(context, listen: false);
      provider.clearErrors();
      
      // Fetch both federal and local representatives
      await provider.fetchAllRepresentativesByAddress(address);
      
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
    final provider = Provider.of<CombinedRepresentativeProvider>(context);
    
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
                
                // Tab bar
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Federal/State'),
                    Tab(text: 'Local'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                ),
                
                // Error message if any
                if (_validationError != null || provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _validationError ?? provider.errorMessage ?? '',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ),
                
                // Loading indicators
                if (provider.isLoading)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (provider.isLoadingFederal)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Text('Loading federal...'),
                          ),
                        if (provider.isLoadingLocal)
                          const Text('Loading local...'),
                        const SizedBox(width: 8),
                        const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // All representatives tab
                      _buildRepresentativesList(
                        provider.allRepresentatives,
                        'Enter your address to find all your representatives'
                      ),
                      
                      // Federal/State representatives tab
                      _buildRepresentativesList(
                        provider.federalRepresentatives,
                        'Enter your address to find your federal and state representatives'
                      ),
                      
                      // Local representatives tab
                      _buildRepresentativesList(
                        provider.localRepresentatives,
                        'Enter your address to find your local county and city representatives'
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildRepresentativesList(List<Representative> representatives, String emptyMessage) {
    if (representatives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: representatives.length,
      itemBuilder: (context, index) {
        final rep = representatives[index];
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
    );
  }
}