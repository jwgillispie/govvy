// lib/widgets/bills/enhanced_bill_search.dart
import 'package:flutter/material.dart';

enum BillSearchType {
  state,
  subject,
  keyword,
  sponsor,
  advanced
}

class EnhancedBillSearch extends StatefulWidget {
  final Function(String query, String? stateCode, BillSearchType searchType, [Map<String, dynamic>? filters]) onSearch;
  final bool isLoading;
  final String? initialState;
  final BillSearchType initialSearchType;

  const EnhancedBillSearch({
    Key? key,
    required this.onSearch,
    this.isLoading = false,
    this.initialState,
    this.initialSearchType = BillSearchType.state,
  }) : super(key: key);

  @override
  State<EnhancedBillSearch> createState() => _EnhancedBillSearchState();
}

class _EnhancedBillSearchState extends State<EnhancedBillSearch> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String? _selectedState;
  bool _filterByState = false;
  late BillSearchType _searchType;
  late TabController _tabController;
  
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

  // Popular suggestions by search type
  final Map<BillSearchType, List<String>> _suggestions = {
    BillSearchType.state: ['FL', 'CA', 'TX', 'NY', 'GA'],
    BillSearchType.subject: ['Education', 'Health', 'Taxation', 'Transportation', 'Criminal Justice'],
    BillSearchType.keyword: ['Budget', 'School', 'Tax', 'Infrastructure', 'Election'],
    BillSearchType.sponsor: ['Smith', 'Johnson', 'Brown', 'Davis', 'Wilson'],
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize search type
    _searchType = widget.initialSearchType;
    
    // Set up tab controller
    _tabController = TabController(
      length: 5, // 5 tabs now
      vsync: this,
      initialIndex: _searchType.index,
    );
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _searchType = BillSearchType.values[_tabController.index];
          // Reset search field when changing tabs
          _searchController.clear();
        });
      }
    });
    
    // Initialize with state if provided
    if (widget.initialState != null) {
      _selectedState = widget.initialState;
      _filterByState = true;
    }
  }

  @override
  void didUpdateWidget(EnhancedBillSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update state if it changed
    if (widget.initialState != oldWidget.initialState && 
        widget.initialState != null && 
        widget.initialState != _selectedState) {
      setState(() {
        _selectedState = widget.initialState;
        _filterByState = true;
      });
    }
    
    // Update search type if it changed
    if (widget.initialSearchType != oldWidget.initialSearchType) {
      setState(() {
        _searchType = widget.initialSearchType;
        _tabController.animateTo(_searchType.index);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Additional filter parameters
  String? _statusFilter;
  String? _dateRangeFilter;
  int? _yearFilter;
  
  // List of bill status options
  final List<String> _statusOptions = [
    'All',
    'Introduced',
    'In Committee',
    'Passed',
    'Failed',
    'Vetoed',
    'Enacted'
  ];
  
  // List of date range options
  final List<String> _dateRangeOptions = [
    'All Time',
    'This Year',
    'Last 30 Days',
    'Last 90 Days',
    'This Session'
  ];
  
  void _submitSearch() {
    print('🔍 _submitSearch called');
    print('📊 Search parameters:');
    print('  - Query: "${_searchController.text.trim()}"');
    print('  - Search Type: $_searchType');
    print('  - Selected State: $_selectedState');
    print('  - Filter By State: $_filterByState');
    print('  - Status Filter: $_statusFilter');
    print('  - Date Range Filter: $_dateRangeFilter');
    print('  - Year Filter: $_yearFilter');
    
    if (_formKey.currentState!.validate()) {
      final query = _searchController.text.trim();
      final stateCode = _filterByState ? _selectedState : 
                        (_searchType == BillSearchType.state ? _selectedState : null);
      
      print('  - Final State Code: $stateCode');
      
      // Build the filters map based on selected options
      Map<String, dynamic>? filters;
      
      if (_searchType == BillSearchType.advanced || _statusFilter != null || _dateRangeFilter != null || _yearFilter != null) {
        filters = {};
        
        if (_statusFilter != null && _statusFilter != 'All') {
          filters['status'] = _statusFilter;
        }
        
        if (_dateRangeFilter != null && _dateRangeFilter != 'All Time') {
          filters['date_range'] = _dateRangeFilter;
        }
        
        if (_yearFilter != null) {
          filters['year'] = _yearFilter;
        }
      }
      
      widget.onSearch(query, stateCode, _searchType, filters);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs for different search types
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'State'),
                Tab(text: 'Subject'),
                Tab(text: 'Keyword'),
                Tab(text: 'Sponsor'),
                Tab(text: 'Advanced'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search UI based on selected tab
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildSearchUI(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchUI() {
    // Show different UI based on search type
    switch (_searchType) {
      case BillSearchType.state:
        return _buildStateSearch();
      case BillSearchType.subject:
        return _buildSubjectSearch();
      case BillSearchType.keyword:
        return _buildKeywordSearch();
      case BillSearchType.sponsor:
        return _buildSponsorSearch();
      case BillSearchType.advanced:
        return _buildAdvancedSearch();
    }
  }
  
  Widget _buildStateSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('state-search'),
      children: [
        // State explanation
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select a state to view all currently active bills in that state.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // State dropdown
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: InputDecoration(
            labelText: 'State',
            hintText: 'Select a state',
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
            prefixIcon: const Icon(Icons.public, size: 20),
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a state';
            }
            return null;
          },
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
                : const Icon(Icons.public),
            label: Text(
              widget.isLoading ? 'Searching...' : 'Get State Bills',
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
        
        // Popular states
        const SizedBox(height: 16),
        Text(
          'Popular States:',
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
          children: _suggestions[BillSearchType.state]!.map((code) => 
            _buildActionChip(code, () {
              setState(() {
                _selectedState = code;
              });
              _submitSearch();
            })
          ).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSubjectSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('subject-search'),
      children: [
        // Explanation
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search for bills by legislative subject. You can optionally filter by state.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Search field
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Subject',
            hintText: 'Enter a legislative subject (e.g., Education)',
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
            prefixIcon: const Icon(Icons.category, size: 20),
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
              return 'Please enter a subject';
            }
            if (value.length < 2) {
              return 'Subject is too short';
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
                fontWeight: _filterByState ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        
        // State dropdown (only when filter is on)
        if (_filterByState) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
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
        ],
        
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
                : const Icon(Icons.category),
            label: Text(
              widget.isLoading ? 'Searching...' : 'Search by Subject',
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
        
        // Popular subjects
        const SizedBox(height: 16),
        Text(
          'Popular Subjects:',
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
          children: _suggestions[BillSearchType.subject]!.map((subject) => 
            _buildActionChip(subject, () {
              _searchController.text = subject;
              _submitSearch();
            })
          ).toList(),
        ),
      ],
    );
  }
  
  Widget _buildKeywordSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('keyword-search'),
      children: [
        // Explanation
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.purple.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search for bills by keyword within bill text. You can optionally filter by state.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Search field
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Keyword',
            hintText: 'Enter a keyword to search in bill text',
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
              return 'Please enter a keyword';
            }
            if (value.length < 2) {
              return 'Keyword is too short';
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
                fontWeight: _filterByState ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        
        // State dropdown (only when filter is on)
        if (_filterByState) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
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
        ],
        
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
              widget.isLoading ? 'Searching...' : 'Search by Keyword',
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
        
        // Popular keywords
        const SizedBox(height: 16),
        Text(
          'Popular Keywords:',
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
          children: _suggestions[BillSearchType.keyword]!.map((keyword) => 
            _buildActionChip(keyword, () {
              _searchController.text = keyword;
              _submitSearch();
            })
          ).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSponsorSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('sponsor-search'),
      children: [
        // Explanation
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search for bills by sponsor name. You can optionally filter by state.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Search field
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Sponsor',
            hintText: 'Enter a sponsor name (e.g., Smith)',
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
            prefixIcon: const Icon(Icons.person, size: 20),
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
              return 'Please enter a sponsor name';
            }
            if (value.length < 2) {
              return 'Name is too short';
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
                fontWeight: _filterByState ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        
        // State dropdown (only when filter is on)
        if (_filterByState) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
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
        ],
        
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
                : const Icon(Icons.person),
            label: Text(
              widget.isLoading ? 'Searching...' : 'Search by Sponsor',
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
        
        // Popular sponsor names
        const SizedBox(height: 16),
        Text(
          'Common Sponsor Names:',
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
          children: _suggestions[BillSearchType.sponsor]!.map((name) => 
            _buildActionChip(name, () {
              _searchController.text = name;
              _submitSearch();
            })
          ).toList(),
        ),
      ],
    );
  }
  
  // Build advanced search with multiple filter options
  Widget _buildAdvancedSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      key: const ValueKey('advanced-search'),
      children: [
        // Advanced search explanation
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tune, color: Colors.indigo.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Advanced search with multiple filters. Combine keyword search with status, date range, and state filters.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Keyword search field
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Keyword',
            hintText: 'Enter bill keywords (optional)',
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
          ),
          enabled: !widget.isLoading,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => _submitSearch(),
        ),
        
        const SizedBox(height: 16),
        
        // Bill status filter
        Text(
          'Bill Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _statusFilter ?? 'All',
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.assignment, size: 18),
          ),
          items: _statusOptions.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: widget.isLoading
              ? null
              : (String? newValue) {
                  setState(() {
                    _statusFilter = newValue == 'All' ? null : newValue;
                  });
                },
          isExpanded: true,
        ),
        
        const SizedBox(height: 16),
        
        // Date range filter
        Text(
          'Date Range',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _dateRangeFilter ?? 'All Time',
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.date_range, size: 18),
          ),
          items: _dateRangeOptions.map((range) {
            return DropdownMenuItem<String>(
              value: range,
              child: Text(range),
            );
          }).toList(),
          onChanged: widget.isLoading
              ? null
              : (String? newValue) {
                  setState(() {
                    _dateRangeFilter = newValue == 'All Time' ? null : newValue;
                  });
                },
          isExpanded: true,
        ),
        
        const SizedBox(height: 16),
        
        // Year filter
        Text(
          'Specific Year (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          value: _yearFilter,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.calendar_today, size: 18),
            hintText: 'Select specific year',
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Any Year'),
            ),
            ...[DateTime.now().year, DateTime.now().year-1, DateTime.now().year-2]
                .map((year) => DropdownMenuItem<int?>(
                      value: year,
                      child: Text(year.toString()),
                    ))
                ,
          ],
          onChanged: widget.isLoading
              ? null
              : (int? newValue) {
                  setState(() {
                    _yearFilter = newValue;
                  });
                },
          isExpanded: true,
        ),

        const SizedBox(height: 16),
        
        // State selection
        Text(
          'State Filter',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
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
              'Filter by state',
              style: TextStyle(
                fontSize: 14,
                color: widget.isLoading ? Colors.grey : Colors.black87,
                fontWeight: _filterByState ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        
        if (_filterByState) ...[  
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.public, size: 18),
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
        ],
        
        const SizedBox(height: 24),
        
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
                : const Icon(Icons.tune),
            label: Text(
              widget.isLoading ? 'Searching...' : 'Advanced Search',
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
        
        // Reset filters button
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    setState(() {
                      _searchController.clear();
                      _statusFilter = null;
                      _dateRangeFilter = null;
                      _yearFilter = null;
                      _filterByState = false;
                    });
                  },
            child: const Text('Reset All Filters'),
          ),
        ),
      ],
    );
  }
  
  // Helper to build action chip
  Widget _buildActionChip(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label),
      onPressed: widget.isLoading ? null : onPressed,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}