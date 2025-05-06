// lib/widgets/bills/bill_search_input.dart
import 'package:flutter/material.dart';

class BillSearchInput extends StatefulWidget {
  final Function(String query, String? stateCode) onSearch;
  final bool isLoading;
  final String? initialQuery;
  final String? initialState;

  const BillSearchInput({
    Key? key,
    required this.onSearch,
    this.isLoading = false,
    this.initialQuery,
    this.initialState,
  }) : super(key: key);

  @override
  State<BillSearchInput> createState() => _BillSearchInputState();
}

class _BillSearchInputState extends State<BillSearchInput> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String? _selectedState;
  bool _filterByState = false;

  // US States mapping for dropdown
  final List<Map<String, String>> _usStates = [
    {"name": "Alabama", "code": "AL"},
    {"name": "Alaska", "code": "AK"},
    {"name": "Arizona", "code": "AZ"},
    {"name": "Arkansas", "code": "AR"},
    {"name": "California", "code": "CA"},
    {"name": "Colorado", "code": "CO"},
    {"name": "Connecticut", "code": "CT"},
    {"name": "Delaware", "code": "DE"},
    {"name": "Florida", "code": "FL"},
    {"name": "Georgia", "code": "GA"},
    {"name": "Hawaii", "code": "HI"},
    {"name": "Idaho", "code": "ID"},
    {"name": "Illinois", "code": "IL"},
    {"name": "Indiana", "code": "IN"},
    {"name": "Iowa", "code": "IA"},
    {"name": "Kansas", "code": "KS"},
    {"name": "Kentucky", "code": "KY"},
    {"name": "Louisiana", "code": "LA"},
    {"name": "Maine", "code": "ME"},
    {"name": "Maryland", "code": "MD"},
    {"name": "Massachusetts", "code": "MA"},
    {"name": "Michigan", "code": "MI"},
    {"name": "Minnesota", "code": "MN"},
    {"name": "Mississippi", "code": "MS"},
    {"name": "Missouri", "code": "MO"},
    {"name": "Montana", "code": "MT"},
    {"name": "Nebraska", "code": "NE"},
    {"name": "Nevada", "code": "NV"},
    {"name": "New Hampshire", "code": "NH"},
    {"name": "New Jersey", "code": "NJ"},
    {"name": "New Mexico", "code": "NM"},
    {"name": "New York", "code": "NY"},
    {"name": "North Carolina", "code": "NC"},
    {"name": "North Dakota", "code": "ND"},
    {"name": "Ohio", "code": "OH"},
    {"name": "Oklahoma", "code": "OK"},
    {"name": "Oregon", "code": "OR"},
    {"name": "Pennsylvania", "code": "PA"},
    {"name": "Rhode Island", "code": "RI"},
    {"name": "South Carolina", "code": "SC"},
    {"name": "South Dakota", "code": "SD"},
    {"name": "Tennessee", "code": "TN"},
    {"name": "Texas", "code": "TX"},
    {"name": "Utah", "code": "UT"},
    {"name": "Vermont", "code": "VT"},
    {"name": "Virginia", "code": "VA"},
    {"name": "Washington", "code": "WA"},
    {"name": "West Virginia", "code": "WV"},
    {"name": "Wisconsin", "code": "WI"},
    {"name": "Wyoming", "code": "WY"},
    {"name": "District of Columbia", "code": "DC"}
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with provided values
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    
    if (widget.initialState != null) {
      _selectedState = widget.initialState;
      _filterByState = true;
    }
  }

  @override
  void didUpdateWidget(BillSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update values if they changed
    if (widget.initialQuery != oldWidget.initialQuery && 
        widget.initialQuery != null && 
        widget.initialQuery != _searchController.text) {
      _searchController.text = widget.initialQuery!;
    }
    
    if (widget.initialState != oldWidget.initialState && 
        widget.initialState != null && 
        widget.initialState != _selectedState) {
      _selectedState = widget.initialState;
      _filterByState = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    if (_formKey.currentState!.validate()) {
      final query = _searchController.text.trim();
      final stateCode = _filterByState ? _selectedState : null;
      
      widget.onSearch(query, stateCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Bills',
              hintText: 'Enter keywords (e.g., education, healthcare)',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter search terms';
              }
              if (value.length < 2) {
                return 'Search term is too short';
              }
              return null;
            },
            enabled: !widget.isLoading,
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => _submitSearch(),
          ),

          const SizedBox(height: 16),

          // State filter
          Row(
            children: [
              Checkbox(
                value: _filterByState,
                onChanged: widget.isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _filterByState = value ?? false;
                          
                          // Set default state if enabling filter
                          if (_filterByState && _selectedState == null) {
                            _selectedState = 'FL';
                          }
                        });
                      },
              ),
              Text(
                'Filter by state:',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isLoading ? Colors.grey : Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              
              // State dropdown (only visible when filter is on)
              if (_filterByState)
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _usStates.map((Map<String, String> state) {
                      return DropdownMenuItem<String>(
                        value: state["code"],
                        child: Text(
                          "${state["name"]} (${state["code"]})",
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: widget.isLoading
                        ? null
                        : (String? newValue) {
                            setState(() {
                              _selectedState = newValue;
                            });
                          },
                    isExpanded: true,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isLoading ? null : _submitSearch,
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
                widget.isLoading ? 'Searching...' : 'Search Bills',
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

          // Popular search terms
          const SizedBox(height: 16),
          Text(
            'Popular Search Terms:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildKeywordChip('Education'),
              _buildKeywordChip('Healthcare'),
              _buildKeywordChip('Environment'),
              _buildKeywordChip('Infrastructure'),
              _buildKeywordChip('Budget'),
              _buildKeywordChip('Tax'),
              _buildKeywordChip('Election'),
              _buildKeywordChip('Criminal Justice'),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build search term chips
  Widget _buildKeywordChip(String keyword) {
    return ActionChip(
      label: Text(keyword),
      onPressed: widget.isLoading
          ? null
          : () {
              _searchController.text = keyword;
              _submitSearch();
            },
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}