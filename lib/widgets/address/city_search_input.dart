// lib/widgets/address/city_search_input.dart
import 'package:flutter/material.dart';

class CitySearchInput extends StatefulWidget {
  final Function(String cityName) onCitySubmitted;
  final String? initialCity;
  final bool isLoading;

  const CitySearchInput({
    Key? key,
    required this.onCitySubmitted,
    this.initialCity,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<CitySearchInput> createState() => _CitySearchInputState();
}

class _CitySearchInputState extends State<CitySearchInput> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  String? _errorMessage;

  // Enhanced common US cities with state information for disambiguation
  final List<Map<String, String>> _citiesWithStates = [
    {"city": "New York", "state": "NY", "display": "New York, NY"},
    {"city": "Los Angeles", "state": "CA", "display": "Los Angeles, CA"},
    {"city": "Chicago", "state": "IL", "display": "Chicago, IL"},
    {"city": "Houston", "state": "TX", "display": "Houston, TX"},
    {"city": "Phoenix", "state": "AZ", "display": "Phoenix, AZ"},
    {"city": "Philadelphia", "state": "PA", "display": "Philadelphia, PA"},
    {"city": "San Antonio", "state": "TX", "display": "San Antonio, TX"},
    {"city": "San Diego", "state": "CA", "display": "San Diego, CA"},
    {"city": "Dallas", "state": "TX", "display": "Dallas, TX"},
    {"city": "San Jose", "state": "CA", "display": "San Jose, CA"},
    {"city": "Austin", "state": "TX", "display": "Austin, TX"},
    {"city": "Jacksonville", "state": "FL", "display": "Jacksonville, FL"},
    {"city": "Fort Worth", "state": "TX", "display": "Fort Worth, TX"},
    {"city": "Columbus", "state": "OH", "display": "Columbus, OH"},
    {"city": "Charlotte", "state": "NC", "display": "Charlotte, NC"},
    {"city": "Indianapolis", "state": "IN", "display": "Indianapolis, IN"},
    {"city": "San Francisco", "state": "CA", "display": "San Francisco, CA"},
    {"city": "Seattle", "state": "WA", "display": "Seattle, WA"},
    {"city": "Denver", "state": "CO", "display": "Denver, CO"},
    {"city": "Boston", "state": "MA", "display": "Boston, MA"},
    {"city": "Portland", "state": "OR", "display": "Portland, OR"},
    {"city": "Portland", "state": "ME", "display": "Portland, ME"}, // Duplicate city name example
    {"city": "Las Vegas", "state": "NV", "display": "Las Vegas, NV"},
    {"city": "Miami", "state": "FL", "display": "Miami, FL"},
    {"city": "Atlanta", "state": "GA", "display": "Atlanta, GA"},
    {"city": "Minneapolis", "state": "MN", "display": "Minneapolis, MN"},
    {"city": "Tampa", "state": "FL", "display": "Tampa, FL"},
    {"city": "Orlando", "state": "FL", "display": "Orlando, FL"},
    {"city": "Cleveland", "state": "OH", "display": "Cleveland, OH"},
    {"city": "New Orleans", "state": "LA", "display": "New Orleans, LA"},
    {"city": "Kansas City", "state": "MO", "display": "Kansas City, MO"},
    {"city": "Kansas City", "state": "KS", "display": "Kansas City, KS"}, // Duplicate city name example
    {"city": "St. Louis", "state": "MO", "display": "St. Louis, MO"},
    {"city": "Cincinnati", "state": "OH", "display": "Cincinnati, OH"},
    {"city": "Nashville", "state": "TN", "display": "Nashville, TN"},
    {"city": "Washington", "state": "DC", "display": "Washington, DC"},
    {"city": "Gainesville", "state": "FL", "display": "Gainesville, FL"},
    {"city": "Gainesville", "state": "GA", "display": "Gainesville, GA"}, // Duplicate city name example
    {"city": "Gainesville", "state": "TX", "display": "Gainesville, TX"}, // Duplicate city name example
    {"city": "Charlottesville", "state": "VA", "display": "Charlottesville, VA"},
    {"city": "Charleston", "state": "SC", "display": "Charleston, SC"},
    {"city": "Charleston", "state": "WV", "display": "Charleston, WV"}, // Duplicate city name example
    {"city": "Springfield", "state": "IL", "display": "Springfield, IL"},
    {"city": "Springfield", "state": "MO", "display": "Springfield, MO"}, // Duplicate city name example
    {"city": "Springfield", "state": "MA", "display": "Springfield, MA"}, // Duplicate city name example
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _cityController.text = widget.initialCity!;
    }
  }

  @override
  void didUpdateWidget(CitySearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCity != oldWidget.initialCity &&
        widget.initialCity != null &&
        widget.initialCity!.isNotEmpty) {
      _cityController.text = widget.initialCity!;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _submitCity(String cityValue) {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });

      // Extract city name from the selection (remove state if present)
      String cityName = cityValue;
      if (cityValue.contains(",")) {
        cityName = cityValue.split(",")[0].trim();
      }

      widget.onCitySubmitted(cityName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // City field with autocomplete
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }

              // Filter cities based on input text
              final List<String> filteredOptions = _citiesWithStates
                  .where((city) {
                    // Match by city name or city+state (case-insensitive)
                    final input = textEditingValue.text.toLowerCase();
                    return city["display"]!.toLowerCase().contains(input) ||
                        city["city"]!.toLowerCase().contains(input);
                  })
                  .map((city) => city["display"]!)
                  .toList();

              // Limit to 10 suggestions max
              return filteredOptions.length > 10
                  ? filteredOptions.sublist(0, 10)
                  : filteredOptions;
            },
            onSelected: (String selection) {
              _cityController.text = selection;
              // Auto-submit when a city is selected from the dropdown
              Future.delayed(const Duration(milliseconds: 100), () {
                _submitCity(selection);
              });
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController controller,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              // Initialize with existing value
              if (controller.text.isEmpty && _cityController.text.isNotEmpty) {
                controller.text = _cityController.text;
              }

              // Sync controllers
              controller.addListener(() {
                _cityController.text = controller.text;
              });

              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g. Chicago, Miami, Portland',
                  helperText: 'Enter city name',
                  helperStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon:
                      const Icon(Icons.location_city_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: controller.text.isEmpty
                        ? null
                        : () {
                            controller.clear();
                            _cityController.clear();
                          },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a city name';
                  }
                  if (value.length < 2) {
                    return 'City name is too short';
                  }
                  return null;
                },
                enabled: !widget.isLoading,
                onFieldSubmitted: (_) {
                  onFieldSubmitted();
                  _submitCity(controller.text);
                },
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.search,
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 250,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        // Check if it's a city-state pair
                        bool hasDuplicate = _hasDuplicateCityName(option.split(',')[0].trim());
                        
                        return ListTile(
                          title: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: option.split(',')[0].trim(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: option.contains(',') ? ', ${option.split(',')[1].trim()}' : '',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Show warning icon for duplicate city names
                          leading: Icon(
                            hasDuplicate
                                ? Icons.info_outline
                                : Icons.location_city_outlined,
                            color: hasDuplicate
                                ? Colors.orange
                                : Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          dense: true,
                          onTap: () {
                            onSelected(option);
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isLoading ? null : () => _submitCity(_cityController.text),
              icon: widget.isLoading
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                widget.isLoading
                    ? 'Searching...'
                    : 'Find Local Representatives',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // No popular cities section as requested
        ],
      ),
    );
  }

  // Helper method to check if a city name appears in multiple states
  bool _hasDuplicateCityName(String cityName) {
    int count = 0;
    for (var city in _citiesWithStates) {
      if (city["city"]!.trim().toLowerCase() == cityName.toLowerCase()) {
        count++;
        if (count > 1) return true;
      }
    }
    return false;
  }

  // Popular city chips method removed
}