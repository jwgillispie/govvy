// lib/screens/bills/bill_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/models/enhanced_bill_details.dart';
import 'package:govvy/providers/enhanced_bill_provider.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';
import 'package:govvy/widgets/bills/bill_history_card.dart';
import 'package:govvy/widgets/bills/ai_bill_summary_widget.dart';
import 'package:govvy/utils/data_source_attribution.dart' as DataSources;
import 'package:url_launcher/url_launcher.dart';

class BillDetailsScreen extends StatefulWidget {
  final int billId;
  final String stateCode;
  final BillModel? billData; // Add billData parameter

  const BillDetailsScreen({
    Key? key,
    required this.billId,
    required this.stateCode,
    this.billData, // Optional parameter for direct bill data
  }) : super(key: key);

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5 tabs: Info, AI Summary, History, Sponsors, Votes

    // Fetch bill details when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBillDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBillDetails() async {
    final provider = Provider.of<EnhancedBillProvider>(context, listen: false);
    
    // If billData is provided, set it directly in the provider to avoid the API call
    if (widget.billData != null) {
      provider.setSelectedBill(widget.billData!);
    } else {
      // Otherwise fetch bill details from API/storage
      await provider.fetchBillDetails(widget.billId, widget.stateCode);
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No URL available')),
      );
      return;
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedBillProvider>(
      builder: (context, provider, child) {
        // If provider.selectedBill is null, but we have billData, use that directly
        final bill = provider.selectedBill ?? widget.billData;
        final enhancedDetails = provider.selectedBillDetails;
        final isLoading = provider.isLoadingDetails;
        final isLoadingDocuments = false; // Enhanced provider doesn't have this property
        final documents = provider.selectedBillDocuments;

        // Special handling for FL and GA bills to improve error handling
        final bool isStateOfInterest = widget.stateCode == 'FL' || widget.stateCode == 'GA';
        

        return Scaffold(
          appBar: AppBar(
            title: Text(bill?.formattedBillNumber ?? 'Bill Details'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : bill == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Improve the error display with icon
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: _getColorShade(Colors.red, 400),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _formatErrorMessage(provider.errorMessageDetails, isStateOfInterest),
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Show specific recovery instructions
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              provider.errorMessageDetails?.contains('not be found') == true 
                                ? 'The bill you requested may have been moved or removed.'
                                : 'Try returning to the bills list and selecting a different bill.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _getColorShade(Colors.grey, 600)),
                            ),
                          ),
                          // Show bill ID for debugging in debug mode only
                          if (kDebugMode)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Bill ID: ${widget.billId}, State: ${widget.stateCode}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getColorShade(Colors.grey, 400),
                                ),
                              ),
                            ),
                          // Return button
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Return to Bills'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Bill header
                        _buildBillHeader(bill),

                        // Tab bar
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Information'),
                            Tab(text: 'AI Summary'),
                            Tab(text: 'History'),
                            Tab(text: 'Sponsors'),
                            Tab(text: 'Votes'),
                          ],
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                        ),

                        // Tab content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Information tab
                              _buildInformationTab(bill, documents, isLoadingDocuments, enhancedDetails),
                              
                              // AI Summary tab
                              SingleChildScrollView(
                                child: AIBillSummaryWidget(bill: bill),
                              ),
                              
                              // History tab
                              _buildHistoryTab(bill),
                              
                              // Sponsors tab
                              _buildSponsorsTab(bill),
                              
                              // Votes tab
                              _buildVotesTab(bill),
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildBillHeader(BillModel bill) {
    // Determine status color
    Color statusColor;
    switch (bill.statusColor) {
      case 'green':
        statusColor = Colors.purple.shade600;
        break;
      case 'red':
        statusColor = Colors.purple.shade700;
        break;
      case 'orange':
        statusColor = Colors.purple.shade500;
        break;
      case 'blue':
        statusColor = Colors.purple.shade400;
        break;
      default:
        statusColor = Colors.purple.shade300;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill number and badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bill.formattedBillNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getTypeColor(bill.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getTypeColor(bill.type).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  _getTypeLabel(bill.type),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(bill.type),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                bill.state,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bill title
          Text(
            bill.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          // Status with colored indicator
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Status: ${bill.status}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),

          // Show last action date if available
          if (bill.lastActionDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last Action: ${bill.lastActionDate}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ],

          // Show introduced date if available
          if (bill.introducedDate != null && bill.introducedDate != bill.lastActionDate) ...[
            const SizedBox(height: 4),
            Text(
              'Introduced: ${bill.introducedDate}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ],
          
          // Data source attribution
          const SizedBox(height: 12),
          DataSources.DataSourceAttribution.buildSourceAttribution(
            [DataSources.DataSourceAttribution.detectSourceFromBillData(bill)],
            prefix: 'Data from',
          ),
        ],
      ),
    );
  }

  Widget _buildInformationTab(BillModel bill, List<BillDocument>? documents, bool isLoadingDocuments, EnhancedBillDetails? enhancedDetails) {
    // Special handling for FL and GA bills to ensure details are shown
    final bool isStateOfInterest = bill.state == 'FL' || bill.state == 'GA';
    final bool hasUrl = bill.url.isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source badge for FL and GA bills
          if (isStateOfInterest) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.deepPurple.shade800.withOpacity(0.3)
                    : Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.deepPurple.shade600
                      : Colors.deepPurple.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.deepPurple.shade300
                        : Colors.deepPurple.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Official ${bill.state} Bill Data',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.deepPurple.shade300
                          : Colors.deepPurple.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Bill description
          if (bill.description != null && bill.description!.isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade800.withOpacity(0.3)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade600
                      : Colors.grey.shade200,
                ),
              ),
              child: Text(
                bill.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Committee information
          if (bill.committee != null && bill.committee!.isNotEmpty) ...[
            Text(
              'Committee',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade800.withOpacity(0.4)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bill.committee!,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Subjects
          if (bill.subjects != null && bill.subjects!.isNotEmpty) ...[
            Text(
              'Subjects',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bill.subjects!.map((subject) {
                return Chip(
                  label: Text(subject),
                  backgroundColor: _getColorShade(Colors.blue, 50),
                  side: BorderSide(color: _getColorShade(Colors.blue, 200)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Enhanced data section with API enrichments
          if (enhancedDetails?.extraData.isNotEmpty == true) ...[
            Text(
              'Enhanced Bill Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            if (enhancedDetails != null)
              _buildEnhancedDataSection(enhancedDetails),
            const SizedBox(height: 24),
          ],

          // State-specific display for FL and GA
          if (isStateOfInterest) ...[
            Text(
              'Bill Status Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColorShade(Colors.blue, 50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getColorShade(Colors.blue, 200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _getColorShade(Colors.blue, 800),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current Status: ${bill.status}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getColorShade(Colors.blue, 800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (bill.lastActionDate != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Last Action Date: ${bill.lastActionDate}',
                        style: TextStyle(
                          color: _getColorShade(Colors.blue, 800),
                        ),
                      ),
                    ),
                  ],
                  
                  if (bill.lastAction != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Last Action: ${bill.lastAction}',
                        style: TextStyle(
                          color: _getColorShade(Colors.blue, 800),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Bill documents/texts
          Text(
            'Bill Texts & Documents',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),

          if (isLoadingDocuments)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if ((documents == null || documents.isEmpty) && !hasUrl)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColorShade(Colors.amber, 50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getColorShade(Colors.amber, 200)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _getColorShade(Colors.amber, 800),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No documents available for this bill.',
                    ),
                  ),
                ],
              ),
            )
          else if (documents != null && documents.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return ListTile(
                  title: Text(
                    doc.description ?? doc.type,
                    style: const TextStyle(fontSize: 14),
                  ),
                  leading: const Icon(Icons.description),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(doc.url),
                );
              },
            ),

          const SizedBox(height: 24),

          // Link to original bill source
          if (hasUrl) ...[
            Text(
              'View Official Bill',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text('View on ${isStateOfInterest ? bill.state : "Official"} Website'),
              onPressed: () => _launchUrl(bill.url),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BillModel bill) {
    if (bill.history == null || bill.history!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: _getColorShade(Colors.grey, 400),
            ),
            const SizedBox(height: 16),
            Text(
              'No history available for this bill.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort history by sequence
    final sortedHistory = List<BillHistory>.from(bill.history!);
    sortedHistory.sort((a, b) => b.sequence.compareTo(a.sequence));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedHistory.length,
      itemBuilder: (context, index) {
        return BillHistoryCard(
          action: sortedHistory[index],
          isFirst: index == 0,
          isLast: index == sortedHistory.length - 1,
        );
      },
    );
  }

  Widget _buildSponsorsTab(BillModel bill) {
    if (bill.sponsors == null || bill.sponsors!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 48,
              color: _getColorShade(Colors.grey, 400),
            ),
            const SizedBox(height: 16),
            Text(
              'No sponsor information available for this bill.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Separate primary sponsors and cosponsors
    final primarySponsors = bill.sponsors!
        .where((sponsor) => sponsor.position == 'primary')
        .toList();
    final cosponsors = bill.sponsors!
        .where((sponsor) => sponsor.position == 'cosponsor')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary sponsors
          if (primarySponsors.isNotEmpty) ...[
            Text(
              'Primary Sponsor${primarySponsors.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: primarySponsors.length,
              itemBuilder: (context, index) {
                return _buildSponsorCard(
                  primarySponsors[index],
                  isPrimary: true,
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Cosponsors
          if (cosponsors.isNotEmpty) ...[
            Text(
              'Co-Sponsors (${cosponsors.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cosponsors.length,
              itemBuilder: (context, index) {
                return _buildSponsorCard(
                  cosponsors[index],
                  isPrimary: false,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSponsorCard(RepresentativeSponsor sponsor, {required bool isPrimary}) {
    // Get party color
    Color partyColor = Colors.grey;
    if (sponsor.party != null) {
      final party = sponsor.party!.toLowerCase();
      if (party.contains('demo') || party == 'd') {
        partyColor = const Color(0xFF232066); // Democrat blue
      } else if (party.contains('repub') || party == 'r') {
        partyColor = const Color(0xFFE91D0E); // Republican red
      } else if (party.contains('ind') || party == 'i') {
        partyColor = const Color(0xFF39BA4C); // Independent green
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isPrimary ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPrimary
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: sponsor.bioGuideId != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RepresentativeDetailsScreen(
                      bioGuideId: sponsor.bioGuideId!,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Representative image or placeholder
              CircleAvatar(
                radius: 24,
                backgroundColor: _getColorShade(Colors.grey, 200),
                backgroundImage: sponsor.imageUrl != null 
                    ? (sponsor.imageUrl!.startsWith('assets/') 
                        ? AssetImage(sponsor.imageUrl!) as ImageProvider
                        : NetworkImage(sponsor.imageUrl!))
                    : null,
                child: sponsor.imageUrl == null
                    ? Icon(Icons.person, size: 24, color: _getColorShade(Colors.grey, 400))
                    : null,
              ),
              const SizedBox(width: 12),

              // Representative info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sponsor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (sponsor.party != null) ...[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: partyColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPartyName(sponsor.party),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getColorShade(Colors.grey, 700),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (sponsor.role != null)
                          Text(
                            sponsor.role!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getColorShade(Colors.grey, 700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSponsorLocation(sponsor),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getColorShade(Colors.grey, 600),
                      ),
                    ),
                  ],
                ),
              ),

              // Link arrow if bioGuideId is available
              if (sponsor.bioGuideId != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: _getColorShade(Colors.grey, 400),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  Color _getTypeColor(String type) {
    switch (type) {
      case 'federal':
        return Colors.indigo;
      case 'state':
        return Colors.teal;
      case 'local':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'federal':
        return 'Federal';
      case 'state':
        return 'State';
      case 'local':
        return 'Local';
      default:
        return type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : 'Unknown';
    }
  }

  String _getPartyName(String? party) {
    if (party == null) return '';
    
    switch (party.toLowerCase()) {
      case 'd':
      case 'dem':
      case 'democrat':
      case 'democratic':
        return 'Democrat';
      case 'r':
      case 'rep':
      case 'republican':
        return 'Republican';
      case 'i':
      case 'ind':
      case 'independent':
        return 'Independent';
      default:
        return party;
    }
  }

  String _getSponsorLocation(RepresentativeSponsor sponsor) {
    final district = sponsor.district != null ? ' District ${sponsor.district}' : '';
    return '${sponsor.state}$district';
  }
  
  /// Build the votes tab showing roll call votes
  Widget _buildVotesTab(BillModel bill) {
    // Access enhanced bill provider to get vote information
    final enhancedProvider = Provider.of<EnhancedBillProvider>(context, listen: false);
    final enhancedBill = enhancedProvider.getEnhancedBillDetailsForId(bill.billId);
    
    // Get votes from enhanced bill if available
    final votes = enhancedBill?.votes;
    
    if (votes == null || votes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.how_to_vote_outlined,
              size: 48,
              color: _getColorShade(Colors.grey, 400),
            ),
            const SizedBox(height: 16),
            Text(
              'No vote information available for this bill.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: votes.length,
      itemBuilder: (context, index) {
        final vote = votes[index];
        return _buildVoteCard(vote);
      },
    );
  }
  
  /// Build a single vote card
  Widget _buildVoteCard(BillVote vote) {
    // Calculate progress values for the vote counts
    final totalVotes = vote.yesCount + vote.noCount + vote.nVCount + vote.absentCount;
    final yesPercent = totalVotes > 0 ? vote.yesCount / totalVotes : 0.0;
    final noPercent = totalVotes > 0 ? vote.noCount / totalVotes : 0.0;
    final otherPercent = totalVotes > 0 ? (vote.nVCount + vote.absentCount) / totalVotes : 0.0;
    
    // Results background color
    final resultColor = vote.result.toLowerCase().contains('pass') ? 
        _getColorShade(Colors.green, 100) : _getColorShade(Colors.red, 100);
    final resultTextColor = vote.result.toLowerCase().contains('pass') ?
        _getColorShade(Colors.green, 800) : _getColorShade(Colors.red, 800);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vote date and chamber
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: _getColorShade(Colors.grey, 600),
                ),
                const SizedBox(width: 8),
                Text(
                  vote.date,
                  style: TextStyle(
                    fontSize: 14,
                    color: _getColorShade(Colors.grey, 700),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorShade(Colors.blue, 100),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    vote.chamber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getColorShade(Colors.blue, 800),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Vote description
            Text(
              vote.description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Vote result badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: resultColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Result: ${vote.result}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: resultTextColor,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Vote counts
            Row(
              children: [
                Expanded(
                  child: _buildVoteCountColumn(
                    'Yes', 
                    vote.yesCount, 
                    Colors.green,
                    totalVotes,
                  ),
                ),
                Expanded(
                  child: _buildVoteCountColumn(
                    'No', 
                    vote.noCount, 
                    Colors.red,
                    totalVotes,
                  ),
                ),
                Expanded(
                  child: _buildVoteCountColumn(
                    'Other', 
                    vote.nVCount + vote.absentCount, 
                    Colors.grey,
                    totalVotes,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Progress bar showing vote distribution
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(
                    flex: (yesPercent * 100).round(),
                    child: Container(
                      height: 8,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    flex: (noPercent * 100).round(),
                    child: Container(
                      height: 8,
                      color: Colors.red,
                    ),
                  ),
                  Expanded(
                    flex: (otherPercent * 100).round(),
                    child: Container(
                      height: 8,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // View full vote details button
            if (vote.url.isNotEmpty) ...[  
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.how_to_vote),
                  label: const Text('View Full Vote Details'),
                  onPressed: () => _launchUrl(vote.url),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Helper function to get color shades safely
  Color _getColorShade(Color baseColor, int shade) {
    // Check if the color is already a MaterialColor with built-in shades
    if (baseColor is MaterialColor) {
      return baseColor[shade] ?? baseColor;
    }
    
    // Handle specific colors we know have shades
    if (baseColor == Colors.green) {
      return Colors.green[700] ?? baseColor;
    } else if (baseColor == Colors.red) {
      return Colors.red[700] ?? baseColor;
    } else if (baseColor == Colors.grey) {
      return Colors.grey[700] ?? baseColor;
    } else if (baseColor == Colors.blue) {
      return Colors.blue[700] ?? baseColor;
    } else if (baseColor == Colors.orange) {
      return Colors.orange[700] ?? baseColor;
    }
    
    // For other colors, approximate a shade based on the value
    // Darker for higher shade values
    if (shade > 500) {
      // Calculate how much darker based on the shade
      final darkerFactor = 0.1 + ((shade - 500) / 1000);
      return _darken(baseColor, darkerFactor);
    } else if (shade < 500) {
      // Calculate how much lighter based on the shade
      final lighterFactor = 0.1 + ((500 - shade) / 1000);
      return _lighten(baseColor, lighterFactor);
    }
    
    // Return the original color for shade 500
    return baseColor;
  }
  
  /// Darken a color by a factor
  Color _darken(Color color, double factor) {
    assert(factor >= 0 && factor <= 1);
    
    final r = (color.red * (1 - factor)).round().clamp(0, 255);
    final g = (color.green * (1 - factor)).round().clamp(0, 255);
    final b = (color.blue * (1 - factor)).round().clamp(0, 255);
    
    return Color.fromARGB(color.alpha, r, g, b);
  }
  
  /// Lighten a color by a factor
  Color _lighten(Color color, double factor) {
    assert(factor >= 0 && factor <= 1);
    
    final r = (color.red + ((255 - color.red) * factor)).round().clamp(0, 255);
    final g = (color.green + ((255 - color.green) * factor)).round().clamp(0, 255);
    final b = (color.blue + ((255 - color.blue) * factor)).round().clamp(0, 255);
    
    return Color.fromARGB(color.alpha, r, g, b);
  }

  /// Helper widget to show vote count and label
  Widget _buildVoteCountColumn(String label, int count, Color color, int total) {
    final percent = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getColorShade(color, 700),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getColorShade(color, 700),
          ),
        ),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 12,
            color: _getColorShade(color, 700),
          ),
        ),
      ],
    );
  }
  
  
  // Helper method to format error messages for better user experience
  String _formatErrorMessage(String? errorMessage, bool isStateOfInterest) {
    if (errorMessage == null) {
      return 'Bill details not found${isStateOfInterest ? " for ${widget.stateCode}" : ""}';
    }
    
    // Handle specific error messages
    if (errorMessage.contains('Unknown bill id')) {
      return 'Bill not found in the legislative database';
    }
    
    if (errorMessage.contains('could not be found')) {
      return 'This bill could not be found';
    }
    
    if (errorMessage.contains('network')) {
      return 'Unable to load bill details due to network issues';
    }
    
    // For other errors, use the original message but clean it up
    return errorMessage
        .replaceAll('Error getting bill details:', '')
        .replaceAll('Exception:', '')
        .trim();
  }
  
  /// Build enhanced data section displaying additional API enrichments
  Widget _buildEnhancedDataSection(EnhancedBillDetails enhancedDetails) {
    final extraData = enhancedDetails.extraData;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enriched sponsor data
        if (extraData.containsKey('enriched_sponsors')) ...[
          _buildEnrichedSponsorsSection(extraData['enriched_sponsors']),
          const SizedBox(height: 16),
        ],
        
        // Enriched vote data
        if (extraData.containsKey('enriched_votes')) ...[
          _buildEnrichedVotesSection(extraData['enriched_votes']),
          const SizedBox(height: 16),
        ],
        
        // Bill text summaries
        if (extraData.containsKey('enriched_texts')) ...[
          _buildEnrichedTextsSection(extraData['enriched_texts']),
          const SizedBox(height: 16),
        ],
        
        // Amendment details
        if (extraData.containsKey('enriched_amendments')) ...[
          _buildEnrichedAmendmentsSection(extraData['enriched_amendments']),
          const SizedBox(height: 16),
        ],
        
        // Supplement details (fiscal notes, etc.)
        if (extraData.containsKey('enriched_supplements')) ...[
          _buildEnrichedSupplementsSection(extraData['enriched_supplements']),
        ],
      ],
    );
  }
  
  /// Build enriched sponsors section
  Widget _buildEnrichedSponsorsSection(Map<int, Map<String, dynamic>> enrichedSponsors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getColorShade(Colors.blue, 50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColorShade(Colors.blue, 200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_pin,
                color: _getColorShade(Colors.blue, 700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sponsor Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getColorShade(Colors.blue, 800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...enrichedSponsors.entries.map((entry) {
            final sponsorData = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getColorShade(Colors.blue, 100),
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: _getColorShade(Colors.blue, 700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sponsorData['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        if (sponsorData['party'] != null)
                          Text(
                            '${sponsorData['party']} ${sponsorData['role'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  /// Build enriched votes section
  Widget _buildEnrichedVotesSection(Map<int, Map<String, dynamic>> enrichedVotes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getColorShade(Colors.green, 50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColorShade(Colors.green, 200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.how_to_vote,
                color: _getColorShade(Colors.green, 700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Detailed Vote Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getColorShade(Colors.green, 800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...enrichedVotes.entries.map((entry) {
            final voteData = entry.value;
            final yesCount = voteData['yea_count'] ?? voteData['yes_count'] ?? 0;
            final noCount = voteData['nay_count'] ?? voteData['no_count'] ?? 0;
            final totalVotes = yesCount + noCount;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _getColorShade(Colors.green, 100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voteData['desc'] ?? 'Vote',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (totalVotes > 0) ...[
                    Row(
                      children: [
                        Text('Yes: $yesCount'),
                        const SizedBox(width: 16),
                        Text('No: $noCount'),
                        const SizedBox(width: 16),
                        Text(
                          voteData['passed'] == 1 ? 'PASSED' : 'FAILED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: voteData['passed'] == 1 
                                ? _getColorShade(Colors.green, 700)
                                : _getColorShade(Colors.red, 700),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (voteData['date'] != null)
                    Text(
                      'Date: ${voteData['date']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  /// Build enriched texts section
  Widget _buildEnrichedTextsSection(Map<int, Map<String, dynamic>> enrichedTexts) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getColorShade(Colors.purple, 50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColorShade(Colors.purple, 200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: _getColorShade(Colors.purple, 700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bill Text Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getColorShade(Colors.purple, 800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...enrichedTexts.entries.map((entry) {
            final textData = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _getColorShade(Colors.purple, 100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textData['doc_title'] ?? textData['type'] ?? 'Document',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (textData['doc_date'] != null)
                    Text(
                      'Date: ${textData['doc_date']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (textData['doc_size'] != null)
                    Text(
                      'Size: ${textData['doc_size']} chars',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  /// Build enriched amendments section
  Widget _buildEnrichedAmendmentsSection(Map<int, Map<String, dynamic>> enrichedAmendments) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getColorShade(Colors.orange, 50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColorShade(Colors.orange, 200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_document,
                color: _getColorShade(Colors.orange, 700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Amendments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getColorShade(Colors.orange, 800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...enrichedAmendments.entries.map((entry) {
            final amendmentData = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _getColorShade(Colors.orange, 100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amendmentData['title'] ?? amendmentData['amendment_number'] ?? 'Amendment',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (amendmentData['description'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        amendmentData['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  if (amendmentData['status'] != null)
                    Text(
                      'Status: ${amendmentData['status']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  /// Build enriched supplements section
  Widget _buildEnrichedSupplementsSection(Map<int, Map<String, dynamic>> enrichedSupplements) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getColorShade(Colors.teal, 50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getColorShade(Colors.teal, 200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: _getColorShade(Colors.teal, 700),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Fiscal Notes & Analyses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getColorShade(Colors.teal, 800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...enrichedSupplements.entries.map((entry) {
            final supplementData = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _getColorShade(Colors.teal, 100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplementData['type'] ?? supplementData['title'] ?? 'Supplement',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (supplementData['description'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        supplementData['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  if (supplementData['date'] != null)
                    Text(
                      'Date: ${supplementData['date']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}