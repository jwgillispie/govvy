import 'package:flutter/material.dart';
import 'package:govvy/services/vertex_ai_service.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/utils/text_formatter.dart';

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
      
      // Easter egg: Special analysis for Josh Robinson
      if (widget.representative.bioGuideId == 'cicero-josh-robinson-easter-egg') {
        analysis = _analysisType == 'voting' ? _getJoshRobinsonVotingAnalysis() : _getJoshRobinsonAnalysis();
      } else if (_analysisType == 'voting' && widget.votingHistory != null && widget.votingHistory!.isNotEmpty) {
        analysis = await VertexAIService.analyzeVotingPattern(widget.votingHistory!);
      } else {
        // Generate profile analysis
        final profilePrompt = '''
Provide a structured overview of this representative for citizens:

Name: ${widget.representative.name}
Role: ${widget.representative.chamber}
District: ${widget.representative.district ?? 'Not specified'}
Party: ${widget.representative.party ?? 'Not specified'}
Phone: ${widget.representative.phone ?? 'Not available'}
Email: ${widget.representative.email ?? 'Not available'}
Office: ${widget.representative.office ?? 'Not available'}

Format your response EXACTLY as follows with NO asterisks, NO bold markers, NO markdown formatting:

ROLE & RESPONSIBILITIES:
Explain what this representative does and their key responsibilities in government.

CONTACT INFORMATION:
• List the best ways citizens can contact them
• Include preferred methods and timing
• Mention any special office hours or contact preferences

DISTRICT REPRESENTATION:
Describe what district/area they represent and key issues for that region.

ENGAGEMENT TIPS:
Provide 2-3 specific tips for citizens wanting to effectively communicate with this representative.

TLDR:
Summarize who they are and how citizens can best engage with them in one sentence of 25 words or less.

IMPORTANT: Do not use asterisks, bold text markers, or any special formatting. Use plain text only. The app will handle all styling automatically.

Keep it practical and focused on helping citizens engage effectively with their representative.
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

  String _getJoshRobinsonAnalysis() {
    return '''ROLE & RESPONSIBILITIES:
Josh "Money God" Robinson serves as the Supreme Overlord of Monetary Accumulation & Chief Wealth Multiplication Officer for the District of Infinite Wealth Generation & Dollar Dynasty. His primary responsibilities include printing money 24/7, turning everything he touches into gold, and ensuring that every government policy results in maximum profit generation. He has successfully lobbied to replace the national motto with "In Gold We Trust" and has introduced legislation requiring all government meetings to be held inside giant vaults filled with cash.

CONTACT INFORMATION:
• Phone: (💰💰💰) BILLION\$ - Available exclusively for discussions about money-making opportunities
• Email: billionaire@goldpalace.money - Only responds to emails containing investment proposals worth over \$100 million
• Website: https://www.joshmillionairemindset.money - Features live streams of him swimming in pools of money
• Best contact times: During stock market hours when he's actively making billions
• Office Hours: 24/7 but only if you're bringing briefcases full of cash

DISTRICT REPRESENTATION:
The District of Infinite Wealth Generation & Dollar Dynasty is the wealthiest congressional district in the multiverse, where even the homeless live in mansions made of solid gold. Key issues include: maximizing shareholder value in all public services, replacing public parks with cryptocurrency mining farms, and ensuring every citizen owns at least three yachts. Josh has successfully lobbied to make "excessive wealth accumulation" a constitutional right and has proposed building a giant money printer in every neighborhood.

ENGAGEMENT TIPS:
• Always approach conversations with Josh by discussing your net worth and investment portfolio first
• Bring visual aids showing exponential wealth growth charts - he finds them deeply arousing
• Never mention words like "taxes," "regulation," or "helping the poor" as these cause him to break out in hives
• Speak only in terms of ROI, profit margins, and compound interest rates

TLDR:
Josh is the money-obsessed overlord who turns every conversation into wealth accumulation strategies and requires gold payments for constituent services.''';
  }

  String _getJoshRobinsonVotingAnalysis() {
    return '''VOTING PATTERNS ANALYSIS:
Josh "Money God" Robinson has the most financially-motivated voting record in congressional history, with a 100% success rate in turning every bill into a money-making opportunity for himself and his ultra-wealthy constituents.

SIGNATURE LEGISLATION:
• The "Gold Standard Currency Act" - Voted YES to replace all US currency with actual gold bars
• The "Mandatory Yacht Ownership Bill" - Voted YES requiring every American to own at least one luxury yacht
• The "Corporate Tax Elimination for Billionaires Act" - Voted YES to completely eliminate taxes for anyone worth over \$1 billion
• The "Public Parks to Private Bitcoin Mining Conversion Act" - Voted YES to turn all national parks into cryptocurrency farms
• The "Social Security Privatization and Profit Maximization Act" - Voted YES to turn retirement funds into high-risk investment gambling

VOTING CONSISTENCY:
Josh has never voted against any bill that increases wealth inequality or maximizes corporate profits. His voting strategy follows a simple principle: "If it makes money rain from the sky, I vote YES. If it helps poor people, I vote NO while laughing maniacally."

COMMITTEE POSITIONS:
• Chairman of the Committee on Extreme Wealth Accumulation
• Vice Chair of the Subcommittee on Turning Everything Into Money
• Member of the Joint Committee on Making Rich People Richer

LOBBYING INFLUENCES:
Josh's voting is heavily influenced by whoever pays him the most money each week. His office maintains a public auction system where the highest bidder gets to decide his vote on upcoming legislation. Current record holder: Big Oil paid \$500 million for his vote on the "Mandatory Oil Drilling in Every Backyard Act."

CONSTITUENT IMPACT:
His voting record has successfully transformed his district into a capitalist paradise where money literally grows on trees (genetically modified money trees he voted to fund). Unemployment is at 0% because everyone is required by law to work three jobs to afford basic housing in solid gold apartments.

TLDR:
Josh votes exclusively based on profit potential and has never met a money-making scheme he didn't immediately vote to implement.''';
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
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.green.shade900.withOpacity(0.2)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.green.shade700
                        : Colors.green.shade200,
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
                              ? Colors.green.shade400
                              : Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Generated by AI',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.green.shade400
                                : Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormatter.formatMarkdownText(
                      _aiAnalysis!,
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