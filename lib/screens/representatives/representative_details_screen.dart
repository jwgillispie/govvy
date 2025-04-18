// lib/screens/representatives/representative_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:url_launcher/url_launcher.dart';

class RepresentativeDetailsScreen extends StatefulWidget {
  final String bioGuideId;
  
  const RepresentativeDetailsScreen({
    Key? key,
    required this.bioGuideId,
  }) : super(key: key);

  @override
  State<RepresentativeDetailsScreen> createState() => _RepresentativeDetailsScreenState();
}

class _RepresentativeDetailsScreenState extends State<RepresentativeDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fix: Use addPostFrameCallback to defer API call until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRepresentativeDetails();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchRepresentativeDetails() async {
    final provider = Provider.of<CombinedRepresentativeProvider>(context, listen: false);
    await provider.fetchRepresentativeDetails(widget.bioGuideId);
  }
  
  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return;
    }
    
    // Clean the phone number
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri(scheme: 'tel', path: cleanedNumber);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not call $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<CombinedRepresentativeProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isLoadingDetails;
        final rep = provider.selectedRepresentative;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(rep?.name ?? 'Representative Details'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : rep == null
                  ? Center(
                      child: Text(
                        provider.errorMessage ?? 'Representative not found',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        // Representative header section
                        _buildRepresentativeHeader(rep),
                        
                        // Tab bar
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Profile'),
                            Tab(text: 'Sponsored Bills'),
                            Tab(text: 'Co-Sponsored Bills'),
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
                              _buildProfileTab(rep),
                              _buildBillsTab(rep.sponsoredBills, 'No sponsored bills found'),
                              _buildBillsTab(rep.cosponsoredBills, 'No co-sponsored bills found'),
                            ],
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
  
  Widget _buildRepresentativeHeader(RepresentativeDetails rep) {
    String partyColor;
    String partyName;
    
    // Determine party color and full name
    switch (rep.party.toLowerCase()) {
      case 'r':
      case 'republican':
        partyColor = '#E91D0E';
        partyName = 'Republican';
        break;
      case 'd':
      case 'democrat':
      case 'democratic':
        partyColor = '#232066';
        partyName = 'Democrat';
        break;
      case 'i':
      case 'independent':
        partyColor = '#39BA4C';
        partyName = 'Independent';
        break;
      default:
        partyColor = '#777777';
        partyName = rep.party.isEmpty ? 'Unknown' : rep.party;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Representative image
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: rep.imageUrl != null 
                    ? NetworkImage(rep.imageUrl!) 
                    : null,
                child: rep.imageUrl == null 
                    ? Icon(Icons.person, size: 40, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Representative info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rep.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(int.parse(partyColor.substring(1, 7), radix: 16) + 0xFF000000),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          partyName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rep.chamber}, ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Contact buttons
          Row(
            children: [
              if (rep.phone != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(rep.phone),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              if (rep.phone != null && rep.website != null)
                const SizedBox(width: 8),
              if (rep.website != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(rep.website),
                    icon: const Icon(Icons.public, size: 16),
                    label: const Text('Website'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileTab(RepresentativeDetails rep) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Office Address', rep.office),
          _buildInfoSection('Phone Number', rep.phone),
          _buildInfoSection('Website', rep.website),
          _buildInfoSection('Date of Birth', rep.dateOfBirth),
          _buildInfoSection('Gender', rep.gender),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${rep.name} is a member of the ${rep.chamber} representing ${rep.state}${rep.district != null ? ' District ${rep.district}' : ''}.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          // Additional biographical information would go here
        ],
      ),
    );
  }
  
  Widget _buildInfoSection(String title, String? content) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBillsTab(List<RepresentativeBill> bills, String emptyMessage) {
    if (bills.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final bill = bills[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${bill.billType.toUpperCase()} ${bill.billNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (bill.introducedDate != null)
                  Text(
                    'Introduced: ${bill.introducedDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bill.title,
              style: const TextStyle(fontSize: 16),
            ),
            if (bill.latestAction != null) ...[
              const SizedBox(height: 4),
              Text(
                'Latest Action: ${bill.latestAction}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}