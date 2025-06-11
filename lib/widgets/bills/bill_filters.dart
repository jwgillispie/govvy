import 'package:flutter/material.dart';
import 'package:govvy/models/bill_model.dart';

// Enhanced filter configuration
enum FilterSortBy { relevance, date, alphabetical, status }
enum FilterDateRange { allTime, thisYear, lastMonth, last3Months, lastYear, custom }
enum FilterOperator { and, or }

class BillFilterConfig {
  final String? keyword;
  final String? chamber;
  final String? committee;
  final String? sponsor;
  final String? status;
  final String? billType;
  final FilterDateRange dateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final FilterSortBy sortBy;
  final FilterOperator filterOperator;
  final bool caseInsensitive;
  final bool useRegex;
  final Set<String> tags;

  const BillFilterConfig({
    this.keyword,
    this.chamber,
    this.committee,
    this.sponsor,
    this.status,
    this.billType,
    this.dateRange = FilterDateRange.allTime,
    this.customStartDate,
    this.customEndDate,
    this.sortBy = FilterSortBy.relevance,
    this.filterOperator = FilterOperator.and,
    this.caseInsensitive = true,
    this.useRegex = false,
    this.tags = const {},
  });

  BillFilterConfig copyWith({
    String? keyword,
    String? chamber,
    String? committee,
    String? sponsor,
    String? status,
    String? billType,
    FilterDateRange? dateRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    FilterSortBy? sortBy,
    FilterOperator? filterOperator,
    bool? caseInsensitive,
    bool? useRegex,
    Set<String>? tags,
  }) {
    return BillFilterConfig(
      keyword: keyword ?? this.keyword,
      chamber: chamber ?? this.chamber,
      committee: committee ?? this.committee,
      sponsor: sponsor ?? this.sponsor,
      status: status ?? this.status,
      billType: billType ?? this.billType,
      dateRange: dateRange ?? this.dateRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      sortBy: sortBy ?? this.sortBy,
      filterOperator: filterOperator ?? this.filterOperator,
      caseInsensitive: caseInsensitive ?? this.caseInsensitive,
      useRegex: useRegex ?? this.useRegex,
      tags: tags ?? this.tags,
    );
  }

  bool get hasActiveFilters {
    return keyword?.isNotEmpty == true ||
           chamber != null ||
           committee != null ||
           sponsor != null ||
           status != null ||
           billType != null ||
           dateRange != FilterDateRange.allTime ||
           tags.isNotEmpty;
  }

  int get filterCount {
    int count = 0;
    if (keyword?.isNotEmpty == true) count++;
    if (chamber != null) count++;
    if (committee != null) count++;
    if (sponsor != null) count++;
    if (status != null) count++;
    if (billType != null) count++;
    if (dateRange != FilterDateRange.allTime) count++;
    count += tags.length;
    return count;
  }
}

class BillFilters extends StatefulWidget {
  final List<BillModel> allBills;
  final Function(List<BillModel>, BillFilterConfig) onFiltered;
  final VoidCallback? onClear;
  final BillFilterConfig? initialConfig;
  final bool showAdvancedOptions;
  final bool autoApply;

  const BillFilters({
    Key? key,
    required this.allBills,
    required this.onFiltered,
    this.onClear,
    this.initialConfig,
    this.showAdvancedOptions = true,
    this.autoApply = false,
  }) : super(key: key);

  @override
  State<BillFilters> createState() => _BillFiltersState();
}

class _BillFiltersState extends State<BillFilters> with TickerProviderStateMixin {
  final TextEditingController _keywordController = TextEditingController();
  
  // Basic filters
  String? _selectedChamber;
  String? _selectedCommittee;
  String? _selectedSponsor;
  String? _selectedStatus;
  String? _selectedBillType;
  
  // Advanced filters
  FilterDateRange _selectedDateRange = FilterDateRange.allTime;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  FilterSortBy _sortBy = FilterSortBy.relevance;
  FilterOperator _filterOperator = FilterOperator.and;
  bool _caseInsensitive = true;
  bool _useRegex = false;
  Set<String> _selectedTags = {};
  
  // Available options extracted from bills
  List<String> _availableChambers = [];
  List<String> _availableCommittees = [];
  List<String> _availableSponsors = [];
  List<String> _availableStatuses = [];
  List<String> _availableBillTypes = [];
  List<String> _availableTags = [];
  
  // UI state
  bool _isExpanded = false;
  late TabController _tabController;
  
  // Filter statistics
  int _totalBills = 0;
  int _filteredBills = 0;
  
  // Pending filter state for apply functionality
  bool _hasPendingChanges = false;
  List<BillModel>? _previewFilteredBills;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _updateAvailableOptions();
    _totalBills = widget.allBills.length;
    _filteredBills = _totalBills;
    
    // Apply initial configuration if provided
    if (widget.initialConfig != null) {
      _applyInitialConfig(widget.initialConfig!);
    }
  }

  @override
  void didUpdateWidget(BillFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allBills != oldWidget.allBills) {
      _updateAvailableOptions();
      _applyFilters();
    }
  }

  void _applyInitialConfig(BillFilterConfig config) {
    setState(() {
      _keywordController.text = config.keyword ?? '';
      _selectedChamber = config.chamber;
      _selectedCommittee = config.committee;
      _selectedSponsor = config.sponsor;
      _selectedStatus = config.status;
      _selectedBillType = config.billType;
      _selectedDateRange = config.dateRange;
      _customStartDate = config.customStartDate;
      _customEndDate = config.customEndDate;
      _sortBy = config.sortBy;
      _filterOperator = config.filterOperator;
      _caseInsensitive = config.caseInsensitive;
      _useRegex = config.useRegex;
      _selectedTags = Set.from(config.tags);
    });
  }

  void _updateAvailableOptions() {
    setState(() {
      _totalBills = widget.allBills.length;
      
      // Extract unique chambers from bills
      _availableChambers = widget.allBills
          .where((bill) => bill.chamber != null && bill.chamber!.isNotEmpty)
          .map((bill) => bill.chamber!)
          .toSet()
          .toList()
        ..sort();

      // Extract unique committees from bills
      _availableCommittees = widget.allBills
          .where((bill) => bill.committee != null && bill.committee!.isNotEmpty)
          .map((bill) => bill.committee!)
          .toSet()
          .toList()
        ..sort();

      // Extract unique sponsors from bills
      _availableSponsors = widget.allBills
          .where((bill) => bill.sponsors != null && bill.sponsors!.isNotEmpty)
          .expand((bill) => bill.sponsors!.map((sponsor) => sponsor.name))
          .toSet()
          .toList()
        ..sort();

      // Extract unique statuses from bills
      _availableStatuses = widget.allBills
          .map((bill) => bill.status)
          .where((status) => status.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Extract unique bill types from bills
      _availableBillTypes = widget.allBills
          .map((bill) => bill.type)
          .where((type) => type.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Extract tags from subjects and keywords
      _availableTags = widget.allBills
          .expand((bill) => [
                ...(bill.subjects ?? []).cast<String>(),
                ...(bill.keywords ?? []).cast<String>(),
              ])
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    });
  }

  void _applyFilters() {
    final filteredBills = _getFilteredBills();

    setState(() {
      _filteredBills = filteredBills.length;
    });

    // Create filter config
    final config = BillFilterConfig(
      keyword: _keywordController.text.isNotEmpty ? _keywordController.text : null,
      chamber: _selectedChamber,
      committee: _selectedCommittee,
      sponsor: _selectedSponsor,
      status: _selectedStatus,
      billType: _selectedBillType,
      dateRange: _selectedDateRange,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      sortBy: _sortBy,
      filterOperator: _filterOperator,
      caseInsensitive: _caseInsensitive,
      useRegex: _useRegex,
      tags: _selectedTags,
    );

    widget.onFiltered(filteredBills, config);
  }

  DateTime? _getBillDate(BillModel bill) {
    try {
      if (bill.lastActionDate != null) {
        return DateTime.tryParse(bill.lastActionDate!);
      }
      if (bill.introducedDate != null) {
        return DateTime.tryParse(bill.introducedDate!);
      }
      if (bill.statusDate != null) {
        return DateTime.tryParse(bill.statusDate!);
      }
    } catch (e) {
      // Handle parsing errors
    }
    return null;
  }

  void _sortFilteredBills(List<BillModel> bills) {
    switch (_sortBy) {
      case FilterSortBy.relevance:
        // Keep original order or sort by match score if implementing relevance scoring
        break;
      case FilterSortBy.date:
        bills.sort((a, b) {
          final dateA = _getBillDate(a);
          final dateB = _getBillDate(b);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA); // Most recent first
        });
        break;
      case FilterSortBy.alphabetical:
        bills.sort((a, b) => a.title.compareTo(b.title));
        break;
      case FilterSortBy.status:
        bills.sort((a, b) => a.status.compareTo(b.status));
        break;
    }
  }

  void _markPendingChanges() {
    if (!widget.autoApply) {
      setState(() {
        _hasPendingChanges = true;
        _previewFilteredBills = _getFilteredBills();
      });
    }
  }

  void _applyPendingFilters() {
    _applyFilters();
    setState(() {
      _hasPendingChanges = false;
      _previewFilteredBills = null;
    });
  }

  List<BillModel> _getFilteredBills() {
    List<BillModel> filteredBills = List.from(widget.allBills);

    // Apply keyword filter with enhanced search
    if (_keywordController.text.isNotEmpty) {
      final keyword = _caseInsensitive ? _keywordController.text.toLowerCase() : _keywordController.text;
      
      filteredBills = filteredBills.where((bill) {
        final searchFields = [
          bill.title,
          bill.description ?? '',
          bill.billNumber,
          bill.status,
          ...bill.subjects ?? [],
          ...bill.keywords ?? [],
          bill.committee ?? '',
          ...(bill.sponsors?.map((s) => s.name) ?? <String>[]),
        ];

        final searchText = _caseInsensitive 
            ? searchFields.join(' ').toLowerCase() 
            : searchFields.join(' ');

        if (_useRegex) {
          try {
            final regex = RegExp(keyword, caseSensitive: !_caseInsensitive);
            return regex.hasMatch(searchText);
          } catch (e) {
            return searchText.contains(keyword);
          }
        } else {
          return searchText.contains(keyword);
        }
      }).toList();
    }

    // Apply basic filters based on operator (AND/OR)
    if (_filterOperator == FilterOperator.and) {
      if (_selectedChamber != null) {
        filteredBills = filteredBills.where((bill) => bill.chamber == _selectedChamber).toList();
      }
      if (_selectedCommittee != null) {
        filteredBills = filteredBills.where((bill) => bill.committee == _selectedCommittee).toList();
      }
      if (_selectedSponsor != null) {
        filteredBills = filteredBills.where((bill) {
          return bill.sponsors?.any((sponsor) => sponsor.name == _selectedSponsor) ?? false;
        }).toList();
      }
      if (_selectedStatus != null) {
        filteredBills = filteredBills.where((bill) => bill.status == _selectedStatus).toList();
      }
      if (_selectedBillType != null) {
        filteredBills = filteredBills.where((bill) => bill.type == _selectedBillType).toList();
      }
    } else {
      if (_selectedChamber != null || _selectedCommittee != null || 
          _selectedSponsor != null || _selectedStatus != null || _selectedBillType != null) {
        filteredBills = filteredBills.where((bill) {
          return (_selectedChamber != null && bill.chamber == _selectedChamber) ||
                 (_selectedCommittee != null && bill.committee == _selectedCommittee) ||
                 (_selectedSponsor != null && (bill.sponsors?.any((sponsor) => sponsor.name == _selectedSponsor) ?? false)) ||
                 (_selectedStatus != null && bill.status == _selectedStatus) ||
                 (_selectedBillType != null && bill.type == _selectedBillType);
        }).toList();
      }
    }

    // Apply tag filters
    if (_selectedTags.isNotEmpty) {
      filteredBills = filteredBills.where((bill) {
        final billTags = <String>{
          ...bill.subjects ?? [],
          ...bill.keywords ?? [],
        };
        return _selectedTags.any((tag) => billTags.contains(tag));
      }).toList();
    }

    // Apply date range filter
    if (_selectedDateRange != FilterDateRange.allTime) {
      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;

      switch (_selectedDateRange) {
        case FilterDateRange.thisYear:
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31);
          break;
        case FilterDateRange.lastMonth:
          startDate = DateTime(now.year, now.month - 1, now.day);
          endDate = now;
          break;
        case FilterDateRange.last3Months:
          startDate = DateTime(now.year, now.month - 3, now.day);
          endDate = now;
          break;
        case FilterDateRange.lastYear:
          startDate = DateTime(now.year - 1, now.month, now.day);
          endDate = now;
          break;
        case FilterDateRange.custom:
          startDate = _customStartDate;
          endDate = _customEndDate;
          break;
        case FilterDateRange.allTime:
          break;
      }

      if (startDate != null || endDate != null) {
        filteredBills = filteredBills.where((bill) {
          final billDate = _getBillDate(bill);
          if (billDate == null) return false;
          
          if (startDate != null && billDate.isBefore(startDate)) return false;
          if (endDate != null && billDate.isAfter(endDate)) return false;
          
          return true;
        }).toList();
      }
    }

    // Apply sorting
    _sortFilteredBills(filteredBills);
    
    return filteredBills;
  }

  void _clearFilters() {
    setState(() {
      _keywordController.clear();
      _selectedChamber = null;
      _selectedCommittee = null;
      _selectedSponsor = null;
      _selectedStatus = null;
      _selectedBillType = null;
      _selectedDateRange = FilterDateRange.allTime;
      _customStartDate = null;
      _customEndDate = null;
      _sortBy = FilterSortBy.relevance;
      _filterOperator = FilterOperator.and;
      _caseInsensitive = true;
      _useRegex = false;
      _selectedTags.clear();
      _filteredBills = _totalBills;
      _hasPendingChanges = false;
      _previewFilteredBills = null;
    });
    
    final config = BillFilterConfig();
    widget.onFiltered(widget.allBills, config);
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  bool get _hasActiveFilters {
    return _keywordController.text.isNotEmpty ||
           _selectedChamber != null ||
           _selectedCommittee != null ||
           _selectedSponsor != null ||
           _selectedStatus != null ||
           _selectedBillType != null ||
           _selectedDateRange != FilterDateRange.allTime ||
           _selectedTags.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Column(
        children: [
          // Enhanced Filter header with statistics
          ListTile(
            leading: Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Filter Bills',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasActiveFilters)
                  Text('${_getFilteredCount()} filters active')
                else
                  const Text('Tap to filter results'),
                if (!widget.autoApply && _hasPendingChanges)
                  Text(
                    'Preview: ${_previewFilteredBills?.length ?? 0} of $_totalBills bills',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Text(
                    'Showing $_filteredBills of $_totalBills bills',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
                if (!widget.autoApply && _hasPendingChanges)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: _applyPendingFilters,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Apply'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Expandable filter content with tabs
          if (_isExpanded)
            Container(
              height: 400,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Enhanced header with mode indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.autoApply ? Colors.green.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.autoApply ? Colors.green.shade200 : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.autoApply ? Icons.auto_mode : Icons.play_arrow,
                          size: 16,
                          color: widget.autoApply ? Colors.green.shade700 : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.autoApply ? 'Auto-apply mode' : 'Manual apply mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: widget.autoApply ? Colors.green.shade700 : Colors.blue.shade700,
                          ),
                        ),
                        if (!widget.autoApply && _hasPendingChanges) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Changes pending',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tab bar for Basic/Advanced filters
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Basic Filters'),
                      Tab(text: 'Advanced'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicFilters(),
                        _buildAdvancedFilters(),
                      ],
                    ),
                  ),
                  
                  // Apply filters button (only for manual mode)
                  if (!widget.autoApply)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _clearFilters,
                              child: const Text('Clear All'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _hasPendingChanges ? _applyPendingFilters : _applyFilters,
                              icon: Icon(_hasPendingChanges ? Icons.check : Icons.refresh),
                              label: Text(_hasPendingChanges ? 'Apply Filters' : 'Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasPendingChanges 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Colors.grey.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicFilters() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced keyword search
          TextField(
            controller: _keywordController,
            decoration: InputDecoration(
              labelText: 'Search Keywords',
              hintText: 'Search in title, description, sponsors, etc.',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_keywordController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _keywordController.clear();
                        });
                        widget.autoApply ? _applyFilters() : _markPendingChanges();
                      },
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'regex') {
                        setState(() {
                          _useRegex = !_useRegex;
                        });
                        widget.autoApply ? _applyFilters() : _markPendingChanges();
                      } else if (value == 'case') {
                        setState(() {
                          _caseInsensitive = !_caseInsensitive;
                        });
                        widget.autoApply ? _applyFilters() : _markPendingChanges();
                      }
                    },
                    itemBuilder: (context) => [
                      CheckedPopupMenuItem<String>(
                        value: 'case',
                        checked: _caseInsensitive,
                        child: const Text('Case insensitive'),
                      ),
                      CheckedPopupMenuItem<String>(
                        value: 'regex',
                        checked: _useRegex,
                        child: const Text('Use regex'),
                      ),
                    ],
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => widget.autoApply ? _applyFilters() : _markPendingChanges(),
          ),
          
          const SizedBox(height: 16),
          
          // Filter operator selection
          Row(
            children: [
              Text(
                'Filter Mode: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SegmentedButton<FilterOperator>(
                segments: const [
                  ButtonSegment<FilterOperator>(
                    value: FilterOperator.and,
                    label: Text('AND'),
                    icon: Icon(Icons.all_inclusive),
                  ),
                  ButtonSegment<FilterOperator>(
                    value: FilterOperator.or,
                    label: Text('OR'),
                    icon: Icon(Icons.alt_route),
                  ),
                ],
                selected: {_filterOperator},
                onSelectionChanged: (Set<FilterOperator> newSelection) {
                  setState(() {
                    _filterOperator = newSelection.first;
                  });
                  widget.autoApply ? _applyFilters() : _markPendingChanges();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Chamber filter
          if (_availableChambers.isNotEmpty) ...[
            _buildDropdownFilter(
              'Chamber',
              _selectedChamber,
              _availableChambers,
              (value) {
                setState(() {
                  _selectedChamber = value;
                });
                widget.autoApply ? _applyFilters() : _markPendingChanges();
              },
              'All chambers',
            ),
            const SizedBox(height: 16),
          ],
          
          // Status filter
          if (_availableStatuses.isNotEmpty) ...[
            _buildDropdownFilter(
              'Status',
              _selectedStatus,
              _availableStatuses,
              (value) {
                setState(() {
                  _selectedStatus = value;
                });
                widget.autoApply ? _applyFilters() : _markPendingChanges();
              },
              'All statuses',
            ),
            const SizedBox(height: 16),
          ],
          
          // Committee filter
          if (_availableCommittees.isNotEmpty) ...[
            _buildDropdownFilter(
              'Committee',
              _selectedCommittee,
              _availableCommittees,
              (value) {
                setState(() {
                  _selectedCommittee = value;
                });
                widget.autoApply ? _applyFilters() : _markPendingChanges();
              },
              'All committees',
            ),
            const SizedBox(height: 16),
          ],
          
          // Sponsor filter
          if (_availableSponsors.isNotEmpty) ...[
            _buildDropdownFilter(
              'Sponsor',
              _selectedSponsor,
              _availableSponsors,
              (value) {
                setState(() {
                  _selectedSponsor = value;
                });
                widget.autoApply ? _applyFilters() : _markPendingChanges();
              },
              'All sponsors',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill type filter
          if (_availableBillTypes.isNotEmpty) ...[
            _buildDropdownFilter(
              'Bill Type',
              _selectedBillType,
              _availableBillTypes,
              (value) {
                setState(() {
                  _selectedBillType = value;
                });
                widget.autoApply ? _applyFilters() : _markPendingChanges();
              },
              'All types',
            ),
            const SizedBox(height: 16),
          ],
          
          // Date range filter
          Text(
            'Date Range',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<FilterDateRange>(
            value: _selectedDateRange,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            items: FilterDateRange.values.map((range) {
              return DropdownMenuItem<FilterDateRange>(
                value: range,
                child: Text(_getDateRangeLabel(range)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDateRange = value!;
                if (value != FilterDateRange.custom) {
                  _customStartDate = null;
                  _customEndDate = null;
                }
              });
              widget.autoApply ? _applyFilters() : _markPendingChanges();
            },
          ),
          
          // Custom date range
          if (_selectedDateRange == FilterDateRange.custom) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      child: Text(
                        _customStartDate?.toString().split(' ')[0] ?? 'Select',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      child: Text(
                        _customEndDate?.toString().split(' ')[0] ?? 'Select',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Sort by
          Text(
            'Sort By',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<FilterSortBy>(
            value: _sortBy,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            items: FilterSortBy.values.map((sort) {
              return DropdownMenuItem<FilterSortBy>(
                value: sort,
                child: Text(_getSortLabel(sort)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
              widget.autoApply ? _applyFilters() : _markPendingChanges();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Tags filter
          if (_availableTags.isNotEmpty) ...[
            Text(
              'Tags/Subjects',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableTags.take(20).map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                    widget.autoApply ? _applyFilters() : _markPendingChanges();
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String? value,
    List<String> options,
    void Function(String?) onChanged,
    String hintText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
          ),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hintText),
            ),
            ...options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _getDateRangeLabel(FilterDateRange range) {
    switch (range) {
      case FilterDateRange.allTime:
        return 'All Time';
      case FilterDateRange.thisYear:
        return 'This Year';
      case FilterDateRange.lastMonth:
        return 'Last Month';
      case FilterDateRange.last3Months:
        return 'Last 3 Months';
      case FilterDateRange.lastYear:
        return 'Last Year';
      case FilterDateRange.custom:
        return 'Custom Range';
    }
  }

  String _getSortLabel(FilterSortBy sort) {
    switch (sort) {
      case FilterSortBy.relevance:
        return 'Relevance';
      case FilterSortBy.date:
        return 'Date (Newest First)';
      case FilterSortBy.alphabetical:
        return 'Alphabetical';
      case FilterSortBy.status:
        return 'Status';
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _customStartDate ?? DateTime.now() : _customEndDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = picked;
        } else {
          _customEndDate = picked;
        }
      });
      widget.autoApply ? _applyFilters() : _markPendingChanges();
    }
  }

  int _getFilteredCount() {
    final config = BillFilterConfig(
      keyword: _keywordController.text.isNotEmpty ? _keywordController.text : null,
      chamber: _selectedChamber,
      committee: _selectedCommittee,
      sponsor: _selectedSponsor,
      status: _selectedStatus,
      billType: _selectedBillType,
      dateRange: _selectedDateRange,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      sortBy: _sortBy,
      filterOperator: _filterOperator,
      caseInsensitive: _caseInsensitive,
      useRegex: _useRegex,
      tags: _selectedTags,
    );
    return config.filterCount;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}