// lib/screens/bills/test_state_bills_screen.dart
import 'package:flutter/material.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/services/bill_service.dart';
// Removed: import 'package:govvy/services/csv_bill_service.dart';

class TestStateBillsScreen extends StatefulWidget {
  const TestStateBillsScreen({Key? key}) : super(key: key);

  @override
  State<TestStateBillsScreen> createState() => _TestStateBillsScreenState();
}

class _TestStateBillsScreenState extends State<TestStateBillsScreen> {
  final BillService _billService = BillService();
  // Removed: final CSVBillService _csvBillService = CSVBillService();
  final _stateController = TextEditingController();
  
  List<String> _availableStates = [];
  List<BillModel> _bills = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _billService.initialize();
      // Removed: await _csvBillService.initialize();
      
      setState(() {
        _availableStates = []; // Removed: _csvBillService.availableStates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing services: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBills() async {
    if (_stateController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a state code';
      });
      return;
    }

    final stateCode = _stateController.text.toUpperCase();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Removed: CSV implementation for FL and GA
      // if (stateCode == 'FL' || stateCode == 'GA') {
      //   
      //   // First, check if state is in available states
      //   if (!_csvBillService.availableStates.contains(stateCode)) {
      //   }
      //   
      //   // Force a full refresh of the CSV data
      //   await _csvBillService.initialize();
      //   
      //   // Try loading directly from CSV service first
      //   try {
      //     final csvBills = await _csvBillService.getBillsByState(stateCode);
      //     
      //     // Now convert these to BillModel format
      //     final billModels = csvBills
      //         .map((bill) => BillModel.fromRepresentativeBill(bill, stateCode))
      //         .toList();
      //         
      //     if (billModels.isNotEmpty) {
      //       setState(() {
      //         _bills = billModels;
      //         _isLoading = false;
      //       });
      //       return;
      //     }
      //   } catch (csvError) {
      //   }
      // }
      
      // Standard path for other states or if CSV direct loading failed
      final bills = await _billService.getBillsByState(stateCode);
      
      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading bills: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test State Bills'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // States information
            Text(
              'Available States with CSV Data: ${_availableStates.join(', ')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // State input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State Code (e.g., AK, CA)',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 2,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadBills,
                  child: const Text('Load Bills'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            // Loading indicator or bills count
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Text(
                    'Found ${_bills.length} bills',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
            const SizedBox(height: 16),
            
            // Bills list
            Expanded(
              child: ListView.builder(
                itemCount: _bills.length,
                itemBuilder: (context, index) {
                  final bill = _bills[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text(bill.billNumber),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${bill.status}',
                            style: TextStyle(
                              color: _getStatusColor(bill.status),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Text(
                            'Type: ${bill.type} | State: ${bill.state}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('introduced')) return Colors.blue;
    if (statusLower.contains('passed')) return Colors.green;
    if (statusLower.contains('failed') || statusLower.contains('vetoed')) return Colors.red;
    return Colors.grey;
  }

  @override
  void dispose() {
    _stateController.dispose();
    super.dispose();
  }
}