// lib/widgets/representatives/name_search_input.dart
import 'package:flutter/material.dart';

class NameSearchInput extends StatefulWidget {
  final Function(String lastName, String? firstName) onNameSubmitted;
  final bool isLoading;

  const NameSearchInput({
    Key? key,
    required this.onNameSubmitted,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<NameSearchInput> createState() => _NameSearchInputState();
}

class _NameSearchInputState extends State<NameSearchInput> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    super.dispose();
  }

  void _submitName() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });

      final lastName = _lastNameController.text.trim();
      final firstName = _firstNameController.text.trim();
      
      // Pass the first name only if it's not empty
      widget.onNameSubmitted(
        lastName, 
        firstName.isNotEmpty ? firstName : null
      );
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
            'Search for representatives by name',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          
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
                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Last Name field (required)
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              hintText: 'e.g. Smith',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
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
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              suffixIcon: _lastNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _lastNameController.clear();
                      },
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a last name';
              }
              if (value.length < 2) {
                return 'Last name is too short';
              }
              return null;
            },
            enabled: !widget.isLoading,
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 12),
          
          // First Name field (optional)
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name (Optional)',
              hintText: 'e.g. John',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
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
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              suffixIcon: _firstNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _firstNameController.clear();
                      },
                    )
                  : null,
            ),
            enabled: !widget.isLoading,
            textCapitalization: TextCapitalization.words,
          ),

          const SizedBox(height: 20),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isLoading ? null : _submitName,
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
                    : 'Find Representatives',
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

          const SizedBox(height: 16),
          
          // Example note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, 
                  color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search for any representative by their last name. Add a first name to narrow results. Example: "Smith" or "John Smith"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}