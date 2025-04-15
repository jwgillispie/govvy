// lib/widgets/address/structured_address_input.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StructuredAddressInput extends StatefulWidget {
  final Function(String formattedAddress) onAddressSubmitted;
  final String? initialAddress;
  final bool isLoading;
  
  const StructuredAddressInput({
    Key? key,
    required this.onAddressSubmitted,
    this.initialAddress,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<StructuredAddressInput> createState() => _StructuredAddressInputState();
}

class _StructuredAddressInputState extends State<StructuredAddressInput> {
  final _formKey = GlobalKey<FormState>();
  
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  
  String? _errorMessage;
  
  // List of US state abbreviations
  final List<String> _stateAbbreviations = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY', 'DC'
  ];
  
  @override
  void initState() {
    super.initState();
    _parseInitialAddress();
  }
  
  @override
  void didUpdateWidget(StructuredAddressInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAddress != oldWidget.initialAddress) {
      _parseInitialAddress();
    }
  }
  
  void _parseInitialAddress() {
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      try {
        // Very basic parsing - assume comma-separated parts
        final parts = widget.initialAddress!.split(',');
        
        if (parts.length >= 3) {
          _streetController.text = parts[0].trim();
          _cityController.text = parts[1].trim();
          
          // For the last part, try to extract state and zip
          final stateZipPart = parts[2].trim();
          final stateZipRegex = RegExp(r'([A-Za-z]{2})\s+(\d{5})');
          final match = stateZipRegex.firstMatch(stateZipPart);
          
          if (match != null) {
            _stateController.text = match.group(1)!.toUpperCase();
            _zipController.text = match.group(2)!;
          } else {
            // Fallback to simpler parsing
            final stateZipParts = stateZipPart.split(' ');
            if (stateZipParts.isNotEmpty) {
              _stateController.text = stateZipParts[0].toUpperCase();
              if (stateZipParts.length > 1) {
                _zipController.text = stateZipParts[1];
              }
            }
          }
        }
      } catch (e) {
        // If parsing fails, keep fields empty
        debugPrint('Error parsing address: $e');
      }
    }
  }
  
  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }
  
  void _submitAddress() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });
      
      // Format the address in a standard way
      final formattedAddress = 
          '${_streetController.text}, ${_cityController.text}, ${_stateController.text} ${_zipController.text}';
      
      widget.onAddressSubmitted(formattedAddress);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your address to find your representatives',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          
          // Street address field
          TextFormField(
            controller: _streetController,
            decoration: InputDecoration(
              labelText: 'Street Address',
              hintText: '123 Main St',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: const Icon(Icons.home_outlined, size: 18),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your street address';
              }
              return null;
            },
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 12),
          
          // City field
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'City',
              hintText: 'Anytown',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your city';
              }
              return null;
            },
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 12),
          
          // State and ZIP code on the same row
          Row(
            children: [
              // State dropdown
              Expanded(
                flex: 2,
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _stateAbbreviations.where((state) {
                      return state.contains(textEditingValue.text.toUpperCase());
                    });
                  },
                  onSelected: (String selection) {
                    _stateController.text = selection;
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController controller,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Initialize with existing value
                    if (controller.text.isEmpty && _stateController.text.isNotEmpty) {
                      controller.text = _stateController.text;
                    }
                    
                    // Sync controllers
                    controller.addListener(() {
                      _stateController.text = controller.text.toUpperCase();
                    });
                    
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'State',
                        hintText: 'FL',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (!_stateAbbreviations.contains(value.toUpperCase())) {
                          return 'Invalid state';
                        }
                        return null;
                      },
                      enabled: !widget.isLoading,
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // ZIP code field
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _zipController,
                  decoration: InputDecoration(
                    labelText: 'ZIP Code',
                    hintText: '12345',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length < 5) {
                      return 'Enter 5 digits';
                    }
                    return null;
                  },
                  enabled: !widget.isLoading,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isLoading ? null : _submitAddress,
              icon: widget.isLoading 
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
              label: Text(widget.isLoading ? 'Searching...' : 'Find Representatives'),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to format text as uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}