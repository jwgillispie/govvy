import 'package:flutter/material.dart';
import 'package:govvy/services/vertex_ai_service.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/utils/text_formatter.dart';

class AIBillSummaryWidget extends StatefulWidget {
  final BillModel bill;

  const AIBillSummaryWidget({
    Key? key,
    required this.bill,
  }) : super(key: key);

  @override
  State<AIBillSummaryWidget> createState() => _AIBillSummaryWidgetState();
}

class _AIBillSummaryWidgetState extends State<AIBillSummaryWidget> {
  String? _aiSummary;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await VertexAIService.summarizeBill(
        widget.bill.description ?? 'No description available',
        widget.bill.title,
      );
      
      if (mounted) {
        setState(() {
          _aiSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate summary: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _generateSummary,
                    tooltip: 'Regenerate Summary',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Generating AI summary...'),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.red.shade900.withOpacity(0.2)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.red.shade700
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error, 
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.red.shade400
                          : Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_aiSummary != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.blue.shade900.withOpacity(0.2)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.blue.shade700
                        : Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.blue.shade400
                              : Colors.blue.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Generated by AI',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.blue.shade400
                                : Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormatter.formatMarkdownText(
                      _aiSummary!,
                      style: const TextStyle(height: 1.5),
                      context: context,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}