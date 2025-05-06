// lib/widgets/representatives/representative_bills_widget.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/providers/bill_provider.dart';
import 'package:govvy/screens/bills/bill_details_screen.dart';
import 'package:govvy/utils/navigation_helper.dart';
import 'package:provider/provider.dart';

class RepresentativeBillsWidget extends StatefulWidget {
  final RepresentativeDetails representative;

  const RepresentativeBillsWidget({
    Key? key,
    required this.representative,
  }) : super(key: key);

  @override
  State<RepresentativeBillsWidget> createState() => _RepresentativeBillsWidgetState();
}

class _RepresentativeBillsWidgetState extends State<RepresentativeBillsWidget> {
  bool _isLoading = false;
  List<BillModel> _bills = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Create a Representative object from RepresentativeDetails
      final representative = Representative(
        name: widget.representative.name,
        bioGuideId: widget.representative.bioGuideId,
        party: widget.representative.party,
        chamber: widget.representative.chamber,
        state: widget.representative.state,
        district: widget.representative.district,
        imageUrl: widget.representative.imageUrl,
        office: widget.representative.office,
        phone: widget.representative.phone,
        website: widget.representative.website,
      );

      // Use BillProvider to get bills
      final billProvider = Provider.of<BillProvider>(context, listen: false);
      await billProvider.fetchBillsByRepresentative(representative);

      setState(() {
        _bills = billProvider.searchResultBills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading bills: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red.shade700),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No bills found for this representative.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _fetchBills,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'Legislation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${_bills.length} Bills',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _bills.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final bill = _bills[index];
              return _buildBillListItem(bill);
            },
          ),
        ),
        // View all bills button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('View All Legislation'),
              onPressed: () {
                // Navigate to the bills list screen using the provider
                NavigationHelper.navigateToBillsByRepresentative(
                  context,
                  widget.representative.bioGuideId,
                  widget.representative.name,
                  widget.representative.state,
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillListItem(BillModel bill) {
    // Determine color based on bill status
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

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillDetailsScreen(
              billId: bill.billId,
              stateCode: bill.state,
            ),
          ),
        );
      },
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
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
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bill.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bill.status,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
    );
  }
}