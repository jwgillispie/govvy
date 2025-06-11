// lib/screens/bills/enhanced_bill_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/providers/enhanced_bill_provider.dart';
import 'package:govvy/screens/bills/bill_details_screen.dart';
import 'package:govvy/widgets/bills/enhanced_bill_card.dart';
import 'package:govvy/widgets/bills/enhanced_bill_search.dart';
import 'package:govvy/widgets/bills/bill_filters.dart';

class EnhancedBillScreen extends StatefulWidget {
  const EnhancedBillScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedBillScreen> createState() => _EnhancedBillScreenState();
}

class _EnhancedBillScreenState extends State<EnhancedBillScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  BillSearchType _searchType = BillSearchType.state;
  String? _currentStateCode;
  String _lastQuery = '';
  
  // Filtered bill lists
  List<BillModel> _filteredResults = [];
  List<BillModel> _filteredRecent = [];
  
  @override
  void initState() {
    super.initState();
    
    // Tab controller for results/recent tabs
    _tabController = TabController(length: 2, vsync: this);
    
    // Load any existing state from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EnhancedBillProvider>(context, listen: false);
      
      if (provider.lastSearchType != null) {
        switch (provider.lastSearchType) {
          case 'state':
            setState(() {
              _searchType = BillSearchType.state;
              _currentStateCode = provider.lastStateCode;
              // No query for state search
            });
            break;
          case 'subject':
            setState(() {
              _searchType = BillSearchType.subject;
              _currentStateCode = provider.lastStateCode;
              _lastQuery = provider.lastSearchQuery ?? '';
            });
            break;
          case 'keyword':
            setState(() {
              _searchType = BillSearchType.keyword;
              _currentStateCode = provider.lastStateCode;
              _lastQuery = provider.lastSearchQuery ?? '';
            });
            break;
          case 'sponsor':
          case 'representative':
            setState(() {
              _searchType = BillSearchType.sponsor;
              _currentStateCode = provider.lastStateCode;
              _lastQuery = provider.lastSearchQuery ?? '';
            });
            break;
        }
      }
      
      // Initialize filtered lists
      _updateFilteredLists();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Handle search with additional filters
  void _handleSearch(String query, String? stateCode, BillSearchType searchType, [Map<String, dynamic>? filters]) {
    final provider = Provider.of<EnhancedBillProvider>(context, listen: false);
    
    setState(() {
      _searchType = searchType;
      _currentStateCode = stateCode;
      _lastQuery = query;
    });
    
    // Use the appropriate search method based on type
    switch (searchType) {
      case BillSearchType.federal:
        // Search for federal bills using keyword search with government level filter
        provider.searchBillsWithFilters(
          query: query.isNotEmpty ? query : null,
          stateCode: null, // Federal bills don't have state codes
          governmentLevel: 'federal',
        ).then((_) {
          _updateFilteredLists();
        });
        _tabController.animateTo(0);
        _scrollToTop();
        break;
        
      case BillSearchType.state:
        if (stateCode != null) {
          provider.fetchBillsByState(stateCode).then((_) {
            _updateFilteredLists();
          });
          // Set tab to results and scroll to top
          _tabController.animateTo(0);
          _scrollToTop();
        }
        break;
        
      case BillSearchType.localImpact:
        // Search for state bills that impact local communities
        final searchQuery = query.isNotEmpty ? query : 'municipal OR county OR city OR town OR local OR zoning OR ordinance';
        provider.searchBillsWithFilters(
          query: searchQuery,
          stateCode: stateCode,
          governmentLevel: 'state',
        ).then((_) {
          _updateFilteredLists();
        });
        _tabController.animateTo(0);
        _scrollToTop();
        break;
        
      case BillSearchType.subject:
        provider.searchBillsBySubject(query, stateCode: stateCode).then((_) {
          _updateFilteredLists();
        });
        _tabController.animateTo(0);
        _scrollToTop();
        break;
        
      case BillSearchType.keyword:
        provider.searchBillsByKeyword(query, stateCode: stateCode).then((_) {
          _updateFilteredLists();
        });
        _tabController.animateTo(0);
        _scrollToTop();
        break;
        
      case BillSearchType.sponsor:
        provider.searchBillsBySponsor(query, stateCode: stateCode).then((_) {
          _updateFilteredLists();
        });
        _tabController.animateTo(0);
        _scrollToTop();
        break;
        
      case BillSearchType.advanced:
        // For advanced search, pass all filters to the provider
        _handleAdvancedSearch(query, stateCode, filters);
        _tabController.animateTo(0);
        _scrollToTop();
        break;
    }
  }
  
  // Handle advanced search with filters
  void _handleAdvancedSearch(String query, String? stateCode, Map<String, dynamic>? filters) {
    final provider = Provider.of<EnhancedBillProvider>(context, listen: false);
    
    // Extract filter values
    final String? status = filters?['status'];
    final String? dateRange = filters?['date_range'];
    final int? year = filters?['year'];
    final String? governmentLevel = filters?['government_level'];
    
    // Calculate date ranges based on filter
    DateTime? startDate;
    DateTime? endDate;
    
    if (dateRange != null) {
      final now = DateTime.now();
      
      switch (dateRange) {
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31);
          break;
        case 'Last 30 Days':
          startDate = now.subtract(const Duration(days: 30));
          endDate = now;
          break;
        case 'Last 90 Days':
          startDate = now.subtract(const Duration(days: 90));
          endDate = now;
          break;
        case 'This Session':
          // For 'This Session', we'll let the API handle session-specific filtering
          break;
      }
    }
    
    // Use a comprehensive search that combines all filters
    provider.searchBillsWithFilters(
      query: query.isNotEmpty ? query : null,
      stateCode: stateCode,
      status: status, 
      startDate: startDate,
      endDate: endDate,
      year: year,
      governmentLevel: governmentLevel,
    ).then((_) {
      _updateFilteredLists();
    });
  }
  
  // Navigate to bill details
  void _navigateToBillDetails(BillModel bill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillDetailsScreen(
          billId: bill.billId,
          stateCode: bill.state,
          billData: bill,
        ),
      ),
    );
  }
  
  
  
  // Update filtered lists from provider data
  void _updateFilteredLists() {
    final provider = Provider.of<EnhancedBillProvider>(context, listen: false);
    
    setState(() {
      // Set filtered results based on search type
      if (_searchType == BillSearchType.state) {
        _filteredResults = List.from(provider.stateBills);
      } else {
        _filteredResults = List.from(provider.searchResultBills);
      }
      _filteredRecent = List.from(provider.recentBills);
    });
  }
  
  // Handle result filtering with config
  void _onResultsFiltered(List<BillModel> filtered, BillFilterConfig config) {
    setState(() {
      _filteredResults = filtered;
    });
  }
  
  // Handle recent bills filtering with config
  void _onRecentFiltered(List<BillModel> filtered, BillFilterConfig config) {
    setState(() {
      _filteredRecent = filtered;
    });
  }

  // Scroll to top of list
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedBillProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isLoading;
        final hasError = provider.errorMessage != null;
        
        // Update filtered lists when provider data changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isLoading) {
            _updateFilteredLists();
          }
        });
        
        // Determine which bills to show based on active tab
        final List<BillModel> billsToShow = 
            _tabController.index == 0 ? _filteredResults : _filteredRecent;
        
        // Build search result title based on search type
        String searchResultTitle = '';
        if (!isLoading && !hasError && billsToShow.isNotEmpty) {
          switch (_searchType) {
            case BillSearchType.federal:
              searchResultTitle = _lastQuery.isNotEmpty 
                  ? 'Federal Bills: "$_lastQuery"'
                  : 'Federal Bills';
              break;
            case BillSearchType.state:
              searchResultTitle = 'State Bills in ${_currentStateCode ?? 'This State'}';
              break;
            case BillSearchType.localImpact:
              searchResultTitle = _lastQuery.isNotEmpty 
                  ? 'Bills Affecting Local Communities: "$_lastQuery"${_currentStateCode != null ? ' in $_currentStateCode' : ''}'
                  : 'Bills Affecting Local Communities${_currentStateCode != null ? ' in $_currentStateCode' : ''}';
              break;
            case BillSearchType.subject:
              searchResultTitle = 'Bills about "$_lastQuery"';
              break;
            case BillSearchType.keyword:
              searchResultTitle = 'Bills containing "$_lastQuery"';
              break;
            case BillSearchType.sponsor:
              searchResultTitle = 'Bills sponsored by "$_lastQuery"';
              break;
            case BillSearchType.advanced:
              searchResultTitle = 'Advanced Search Results';
              break;
          }
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('🏛️ Bills Impacting Your Community'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
              // Search UI
              Padding(
                padding: const EdgeInsets.all(16),
                child: EnhancedBillSearch(
                  onSearch: _handleSearch,
                  isLoading: isLoading,
                  initialState: _currentStateCode,
                  initialSearchType: _searchType,
                ),
              ),
              
              // Results/Recent tabs
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      text: 'Results${_filteredResults.isNotEmpty && _tabController.index == 0 ? ' (${_filteredResults.length})' : ''}',
                    ),
                    Tab(
                      text: 'Recent${_filteredRecent.isNotEmpty ? ' (${_filteredRecent.length})' : ''}',
                    ),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              // Results or error content
              Container(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Results tab
                    _buildResultsContent(
                      isLoading, 
                      hasError, 
                      provider.errorMessage, 
                      billsToShow,
                      searchResultTitle,
                    ),
                    
                    // Recent bills tab
                    _buildRecentBillsList(_filteredRecent),
                  ],
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildResultsContent(
    bool isLoading, 
    bool hasError, 
    String? errorMessage,
    List<BillModel> bills,
    String resultsTitle,
  ) {
    if (isLoading) {
      return _buildLoadingState();
    }
    
    if (hasError) {
      return _buildErrorState(errorMessage!);
    }
    
    if (bills.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildBillsList(bills, resultsTitle);
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Searching for bills...',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () {
                // Re-run the last search
                _handleSearch(_lastQuery, _currentStateCode, _searchType, null);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    String emptyStateMessage;
    IconData emptyStateIcon;
    
    switch (_searchType) {
      case BillSearchType.federal:
        emptyStateMessage = _lastQuery.isNotEmpty 
            ? 'No federal bills found for "$_lastQuery".\nTry different keywords or check your search terms.'
            : 'No federal bills found.\nTry searching with specific keywords.';
        emptyStateIcon = Icons.account_balance_outlined;
        break;
      case BillSearchType.state:
        emptyStateMessage = 'No state bills found for ${_currentStateCode ?? 'this state'}.\nTry selecting a different state.';
        emptyStateIcon = Icons.location_city_outlined;
        break;
      case BillSearchType.localImpact:
        emptyStateMessage = _lastQuery.isNotEmpty
            ? 'No bills found affecting local communities for "$_lastQuery"${_currentStateCode != null ? ' in $_currentStateCode' : ''}.\nTry keywords like municipal, zoning, county, city services.'
            : 'No bills found affecting local communities${_currentStateCode != null ? ' in $_currentStateCode' : ''}.\nTry searching with keywords like municipal, county, or city services.';
        emptyStateIcon = Icons.location_city_outlined;
        break;
      case BillSearchType.subject:
        emptyStateMessage = 'No bills found for subject "$_lastQuery".\nTry a different subject or remove state filter.';
        emptyStateIcon = Icons.category_outlined;
        break;
      case BillSearchType.keyword:
        emptyStateMessage = 'No bills found containing "$_lastQuery".\nTry different keywords or remove state filter.';
        emptyStateIcon = Icons.search_off;
        break;
      case BillSearchType.sponsor:
        emptyStateMessage = 'No bills found sponsored by "$_lastQuery".\nCheck the spelling or try a different name.';
        emptyStateIcon = Icons.person_off;
        break;
      case BillSearchType.advanced:
        emptyStateMessage = 'No bills found matching your advanced search criteria.\nTry adjusting your search filters.';
        emptyStateIcon = Icons.filter_alt_off;
        break;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyStateIcon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyStateMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBillsList(List<BillModel> bills, String title) {
    // Get original bills from provider for filtering
    final provider = Provider.of<EnhancedBillProvider>(context, listen: false);
    final originalBills = _searchType == BillSearchType.state ? provider.stateBills : provider.searchResultBills;
    
    return Column(
      children: [
        if (title.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
        
        // Add filter widget if there are bills to filter
        if (originalBills.isNotEmpty)
          BillFilters(
            allBills: originalBills,
            onFiltered: _onResultsFiltered,
          ),
        
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              
              return EnhancedBillCard(
                bill: bill,
                mode: BillCardMode.standard,
                showStateCode: true,
                onTap: () => _navigateToBillDetails(bill),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentBillsList(List<BillModel> bills) {
    final provider = Provider.of<EnhancedBillProvider>(context, listen: false);
    final originalRecentBills = provider.recentBills;
    
    if (originalRecentBills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No recently viewed bills',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bills you view will appear here',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Add filter widget for recent bills
        if (originalRecentBills.isNotEmpty)
          BillFilters(
            allBills: originalRecentBills,
            onFiltered: _onRecentFiltered,
          ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length + 1, // +1 for the header
            itemBuilder: (context, index) {
              if (index == 0) {
                // Header
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Recently Viewed Bills',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }
              
              final bill = bills[index - 1];
              
              return EnhancedBillCard(
                bill: bill,
                mode: BillCardMode.compact,
                showStateCode: true,
                onTap: () => _navigateToBillDetails(bill),
              );
            },
          ),
        ),
      ],
    );
  }
}