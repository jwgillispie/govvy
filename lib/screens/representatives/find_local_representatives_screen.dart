// lib/screens/representatives/find_local_representatives_screen.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/providers/representative_provider.dart';
import 'package:provider/provider.dart';
import 'package:govvy/widgets/address/city_search_input.dart';
import 'package:govvy/widgets/representatives/representative_card.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';
import 'package:govvy/services/auth_service.dart';

class FindLocalRepresentativesScreen extends StatefulWidget {
  const FindLocalRepresentativesScreen({Key? key}) : super(key: key);

  @override
  State<FindLocalRepresentativesScreen> createState() => _FindLocalRepresentativesScreenState();
}

class _FindLocalRepresentativesScreenState extends State<FindLocalRepresentativesScreen> {
  String? _userCity;
  bool _initialLoadComplete = false;
  String? _validationError;
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  // Initialize the screen
  Future<void> _initialize() async {
    setState(() {
      _initialLoadComplete = false;
    });
    
    try {
      // Try to get a city from user profile if available
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();
      
      if (userData != null && userData.address.isNotEmpty) {
        // Extract city from address if available
        final address = userData.address;
        final addressParts = address.split(',');
        
        if (addressParts.length > 1) {
          // Assume the second part is the city
          setState(() {
            _userCity = addressParts[1].trim();
          });
        }
      }
      
      setState(() {
        _initialLoadComplete = true;
      });
    } catch (e) {
      debugPrint('Error initializing: $e');
      setState(() {
        _initialLoadComplete = true;
      });
    }
  }
  
  // Fetch representatives based on the provided city name
  Future<void> _fetchLocalRepresentatives(String city) async {
    if (city.isEmpty) {
      setState(() {
        _validationError = 'Please enter a city name';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _validationError = null;
      _userCity = city; // Store the searched city
    });
    
    try {
      // Get the provider and fetch local reps by city
      final provider = Provider.of<RepresentativeProvider>(context, listen: false);
      provider.clearError(); // Clear any previous errors
      
      // Use the new method to fetch representatives by city
      await provider.fetchLocalRepresentativesByCity(city);
      
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
        title: const Text('Find Local Representatives'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: !_initialLoadComplete
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // City input form
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CitySearchInput(
                    initialCity: _userCity,
                    isLoading: _isSearching,
                    onCitySubmitted: (cityName) {
                      _fetchLocalRepresentatives(cityName);
                    },
                  ),
                ),
                
                // Error message if any
                if (_validationError != null || provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                
                // Loading indicator
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                
                // Results section
                Expanded(
                  child: _buildRepresentativesList(
                    provider.representatives,
                    'Enter a city name to find your local representatives'
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
                Icons.location_city,
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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