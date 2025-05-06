// lib/screens/bills/bill_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/providers/bill_provider.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';
import 'package:govvy/widgets/bills/bill_history_card.dart';
import 'package:url_launcher/url_launcher.dart';

class BillDetailsScreen extends StatefulWidget {
  final int billId;
  final String stateCode;

  const BillDetailsScreen({
    Key? key,
    required this.billId,
    required this.stateCode,
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
    _tabController = TabController(length: 3, vsync: this); // 3 tabs: Info, History, Sponsors

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
    final provider = Provider.of<BillProvider>(context, listen: false);
    await provider.fetchBillDetails(widget.billId, widget.stateCode);
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
    return Consumer<BillProvider>(
      builder: (context, provider, child) {
        final bill = provider.selectedBill;
        final isLoading = provider.isLoadingDetails;
        final isLoadingDocuments = provider.isLoadingDocuments;
        final documents = provider.selectedBillDocuments;

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
                      child: Text(
                        provider.errorMessageDetails ??
                            'Bill details not found',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
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
                            Tab(text: 'History'),
                            Tab(text: 'Sponsors'),
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
                              _buildInformationTab(bill, documents, isLoadingDocuments),
                              
                              // History tab
                              _buildHistoryTab(bill),
                              
                              // Sponsors tab
                              _buildSponsorsTab(bill),
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
        statusColor = Colors.green;
        break;
      case 'red':
        statusColor = Colors.red;
        break;
      case 'orange':
        statusColor = Colors.orange;
        break;
      case 'blue':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
                    color: Colors.grey.shade800,
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
                color: Colors.grey.shade700,
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
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInformationTab(BillModel bill, List<BillDocument>? documents, bool isLoadingDocuments) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            Text(
              bill.description!,
              style: Theme.of(context).textTheme.bodyMedium,
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
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
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade200),
                );
              }).toList(),
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
          else if (documents == null || documents.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade800,
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
          else
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
            label: const Text('View on Official Website'),
            onPressed: () => _launchUrl(bill.url),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
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
              color: Colors.grey.shade400,
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
              color: Colors.grey.shade400,
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
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    sponsor.imageUrl != null ? NetworkImage(sponsor.imageUrl!) : null,
                child: sponsor.imageUrl == null
                    ? Icon(Icons.person, size: 24, color: Colors.grey.shade400)
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
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (sponsor.role != null)
                          Text(
                            sponsor.role!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSponsorLocation(sponsor),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
                  color: Colors.grey.shade400,
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
    return '${sponsor.state}${district}';
  }
}