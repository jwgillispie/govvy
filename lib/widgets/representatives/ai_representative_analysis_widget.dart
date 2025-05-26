import 'package:flutter/material.dart';
import 'package:govvy/services/vertex_ai_service.dart';
import 'package:govvy/models/representative_model.dart';

class AIRepresentativeAnalysisWidget extends StatefulWidget {
  final RepresentativeDetails representative;
  final List<Map<String, dynamic>>? votingHistory;

  const AIRepresentativeAnalysisWidget({
    Key? key,
    required this.representative,
    this.votingHistory,
  }) : super(key: key);

  @override
  State<AIRepresentativeAnalysisWidget> createState() => _AIRepresentativeAnalysisWidgetState();
}

class _AIRepresentativeAnalysisWidgetState extends State<AIRepresentativeAnalysisWidget> {
  String? _aiAnalysis;
  bool _isLoading = false;
  String? _error;
  String _analysisType = 'profile';

  @override
  void initState() {
    super.initState();
    _generateAnalysis();
  }

  Future<void> _generateAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String analysis;
      
      if (_analysisType == 'voting' && widget.votingHistory != null && widget.votingHistory!.isNotEmpty) {
        analysis = await VertexAIService.analyzeVotingPattern(widget.votingHistory!);
      } else {
        // Generate profile analysis
        final profilePrompt = '''
Provide a helpful overview of this representative for citizens:

Name: ${widget.representative.name}
Role: ${widget.representative.chamber}
District: ${widget.representative.district ?? 'Not specified'}
Party: ${widget.representative.party ?? 'Not specified'}
Phone: ${widget.representative.phone ?? 'Not available'}
Email: ${widget.representative.email ?? 'Not available'}
Office: ${widget.representative.office ?? 'Not available'}

Please provide:
1. Key information citizens should know
2. How to effectively contact this representative
3. Their role and responsibilities
4. Best practices for constituent communication

Keep it informative and helpful for civic engagement.
''';
        
        analysis = await VertexAIService.generateContent(profilePrompt);
      }
      
      if (mounted) {
        setState(() {
          _aiAnalysis = analysis;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate analysis: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _changeAnalysisType(String newType) {
    if (_analysisType != newType) {
      setState(() {
        _analysisType = newType;
      });
      _generateAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
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
                  'AI Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _generateAnalysis,
                    tooltip: 'Regenerate Analysis',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Analysis type selector
            if (widget.votingHistory != null && widget.votingHistory!.isNotEmpty)
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Profile'),
                    selected: _analysisType == 'profile',
                    onSelected: (_) => _changeAnalysisType('profile'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Voting History'),
                    selected: _analysisType == 'voting',
                    onSelected: (_) => _changeAnalysisType('voting'),
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
                    Text('Generating AI analysis...'),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else if (_aiAnalysis != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Generated by AI',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiAnalysis!,
                      style: const TextStyle(height: 1.5),
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