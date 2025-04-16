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

  // List of common US cities for autocomplete
  final List<String> _commonCities = [
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston',
    'Phoenix',
    'Philadelphia',
    'San Antonio',
    'San Diego',
    'Dallas',
    'San Jose',
    'Austin',
    'Jacksonville',
    'Fort Worth',
    'Columbus',
    'Charlotte',
    'Indianapolis',
    'San Francisco',
    'Seattle',
    'Denver',
    'Washington DC',
    'Boston',
    'El Paso',
    'Nashville',
    'Detroit',
    'Oklahoma City',
    'Portland',
    'Las Vegas',
    'Memphis',
    'Louisville',
    'Baltimore',
    'Milwaukee',
    'Albuquerque',
    'Tucson',
    'Fresno',
    'Sacramento',
    'Kansas City',
    'Long Beach',
    'Mesa',
    'Atlanta',
    'Colorado Springs',
    'Raleigh',
    'Omaha',
    'Miami',
    'Oakland',
    'Minneapolis'
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

  void _submitCity() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });

      final cityName = _cityController.text.trim();
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
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Local Government Search',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a city name to find your local representatives, including city council members, mayors, county commissioners, and more.',
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

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

              return _commonCities.where((city) => city
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selection) {
              _cityController.text = selection;
              // Auto-submit when a city is selected from the dropdown
              Future.delayed(const Duration(milliseconds: 100), () {
                _submitCity();
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
                  labelText: 'City Name',
                  hintText: 'e.g. Chicago, Atlanta, Houston',
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
                  _submitCity();
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
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          leading: const Icon(Icons.location_city_outlined),
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

          const SizedBox(height: 16),

          // Popular cities chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text(
                'Popular: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ..._buildPopularCityChips(),
            ],
          ),

          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isLoading ? null : _submitCity,
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
        ],
      ),
    );
  }

  // Helper to build popular city chips
  List<Widget> _buildPopularCityChips() {
    final List<String> popularCities = [
      'New York',
      'Chicago',
      'Los Angeles',
      'Seattle',
      'Atlanta'
    ];

    return popularCities
        .map((city) => ActionChip(
              label: Text(city),
              onPressed: widget.isLoading
                  ? null
                  : () {
                      setState(() {
                        _cityController.text = city;
                      });
                      // Ensure we call submitCity with a slight delay to allow state to update
                      Future.microtask(() => _submitCity());
                    },
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ))
        .toList();
  }
}
