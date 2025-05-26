// lib/screens/bills/bill_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/providers/enhanced_bill_provider.dart';
import 'package:govvy/screens/bills/bill_details_screen.dart';
import 'package:govvy/widgets/bills/bill_card.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({Key? key}) : super(key: key);

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

// Delegate for sticky tab bar
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white, // Background color for the tabBar
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _BillListScreenState extends State<BillListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _searchTypeIndex = 0; // 0 = By State, 1 = By Subject
  String? _selectedState;

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

  final TextEditingController _subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs: State Bills, Search Results, Recent

    // Listen to tab changes to scroll to the top of the list
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _scrollToTop();
      }
    });

    // Initialize with Florida as default state
    _selectedState = "FL";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBillsByState();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _fetchBillsByState() {
    if (_selectedState == null || _selectedState!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a state')),
      );
      return;
    }

    final provider = Provider.of<EnhancedBillProvider>(context, listen: false);
    provider.fetchBillsByState(_selectedState!);

    // Switch to the first tab
    _tabController.animateTo(0);
  }

  // Removed keyword search method to simplify bill search ability

  void _searchBillsBySubject() {
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject')),
      );
      return;
    }

    final provider = Provider.of<EnhancedBillProvider>(context, listen: false);
    provider.searchBillsBySubject(subject, stateCode: _selectedState);

    // Switch to the search tab
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedBillProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bills'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Search form section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Search type toggle
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment<int>(
                            value: 0,
                            label: Text('By State'),
                            icon: Icon(Icons.public),
                          ),
                          ButtonSegment<int>(
                            value: 1,
                            label: Text('By Subject'),
                            icon: Icon(Icons.category),
                          ),
                        ],
                        selected: {_searchTypeIndex},
                        onSelectionChanged: (Set<int> selection) {
                          setState(() {
                            _searchTypeIndex = selection.first;
                            // Clear errors when changing search type
                            provider.clearErrors();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Show search form based on selected type
                      if (_searchTypeIndex == 0)
                        _buildStateSearchForm()
                      else
                        _buildSubjectSearchForm(),
                    ],
                  ),
                ),

                // Tab bar (sticky)
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'State Bills'),
                      Tab(text: 'Search Results'),
                      Tab(text: 'Recent'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    labelPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                ),

                // Error message if any
                if (provider.errorMessage != null)
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
                        provider.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ),

                // Loading indicator
                if (provider.isLoading)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            'Loading bills...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Tab content - Use SizedBox with fixed height
                SizedBox(
                  height: 500, // Fixed height for the bill list area
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // State Bills tab
                      _buildBillList(provider.stateBills, 'No bills found for this state. Try selecting a different state.'),
                      
                      // Search Results tab
                      _buildBillList(provider.searchResultBills, 'No bills found matching your search criteria.'),
                      
                      // Recent Bills tab
                      _buildBillList(provider.recentBills, 'No recently viewed bills. Browse bills to see them here.'),
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

  Widget _buildStateSearchForm() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // State dropdown
          DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: InputDecoration(
              labelText: 'State',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              prefixIcon: const Icon(Icons.public),
            ),
            items: _usStates.map((Map<String, String> state) {
              return DropdownMenuItem<String>(
                value: state["code"],
                child: Text("${state["name"]} (${state["code"]})"),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedState = newValue;
              });
            },
          ),

          const SizedBox(height: 16),

          // Informational text
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
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will show legislation from the selected state. You can browse bills by status, subject, or sponsor.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetchBillsByState,
              icon: const Icon(Icons.search),
              label: const Text(
                'Find Bills',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Popular states chips
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
            children: [
              ..._buildPopularStateChips(),
            ],
          ),
        ],
      ),
    );
  }

  // Keyword search form removed to simplify bill search ability

  Widget _buildSubjectSearchForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject field
        TextField(
          controller: _subjectController,
          decoration: InputDecoration(
            labelText: 'Subject',
            hintText: 'Enter a legislative subject (e.g., Education)',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.category),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _subjectController.clear(),
            ),
          ),
          onSubmitted: (_) => _searchBillsBySubject(),
        ),

        // State selection (optional)
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _selectedState != null,
              onChanged: (bool? value) {
                setState(() {
                  _selectedState = value! ? "FL" : null;
                });
              },
            ),
            const Text('Limit search to state:'),
            const SizedBox(width: 8),
            if (_selectedState != null)
              DropdownButton<String>(
                value: _selectedState,
                items: _usStates.map((Map<String, String> state) {
                  return DropdownMenuItem<String>(
                    value: state["code"],
                    child: Text(state["code"]!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedState = newValue;
                  });
                },
                hint: const Text('Select'),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Search button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _searchBillsBySubject,
            icon: const Icon(Icons.search),
            label: const Text(
              'Find by Subject',
              style: TextStyle(fontSize: 16),
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
          children: [
            _buildSubjectChip('Education'),
            _buildSubjectChip('Health'),
            _buildSubjectChip('Taxation'),
            _buildSubjectChip('Transportation'),
            _buildSubjectChip('Elections'),
          ],
        ),
      ],
    );
  }

  // Helper to build popular state chips
  List<Widget> _buildPopularStateChips() {
    final List<String> popularStates = ['FL', 'CA', 'TX', 'NY', 'GA'];

    return popularStates
        .map((stateCode) => ActionChip(
              label: Text(stateCode),
              onPressed: () {
                setState(() {
                  _selectedState = stateCode;
                });
                _fetchBillsByState();
              },
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ))
        .toList();
  }

  // Removed keyword chip builder to simplify bill search ability

  // Helper to build subject chip
  Widget _buildSubjectChip(String subject) {
    return ActionChip(
      label: Text(subject),
      onPressed: () {
        _subjectController.text = subject;
        _searchBillsBySubject();
      },
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // Helper to build bill list
  Widget _buildBillList(List<BillModel> bills, String emptyMessage) {
    if (bills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
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

    // Use a regular ListView with scrolling enabled within the TabView
    return ListView.builder(
      controller: _scrollController, // Use the scroll controller for scrolling within tabs
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      // Allow scrolling within the tab view
      physics: const AlwaysScrollableScrollPhysics(),
      // Don't shrink wrap since we want to be able to scroll
      shrinkWrap: false,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return BillCard(
          bill: bill,
          onTap: () {
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BillDetailsScreen(
                  billId: bill.billId,
                  stateCode: bill.state,
                  billData: bill, // Pass the full bill data as fallback
                ),
              ),
            );
          },
        );
      },
    );
  }
}