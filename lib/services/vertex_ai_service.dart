import 'package:firebase_ai/firebase_ai.dart';

class VertexAIService {
  /// Generate content using Gemini model
  static Future<String> generateContent(String prompt) async {
    try {
      // Create a GenerativeModel instance with the Gemini Developer API
      final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash');
      
      // Provide a prompt that contains text
      final promptContent = [Content.text(prompt)];
      
      // Generate text output
      final response = await model.generateContent(promptContent);
      return response.text ?? 'No response generated';
    } catch (e) {
      throw Exception('Failed to generate content: $e');
    }
  }

  /// Generate content with additional context for political/government use
  static Future<String> generatePoliticalSummary(String content, {String? context}) async {
    final systemPrompt = context ?? 
        'You are an AI assistant helping citizens understand government and political information. '
        'Provide clear, factual, and non-biased summaries. Focus on key points that would help '
        'citizens make informed decisions.';
    
    final fullPrompt = '$systemPrompt\n\nContent to summarize:\n$content';
    
    return generateContent(fullPrompt);
  }

  /// Generate bill summary
  static Future<String> summarizeBill(String billText, String billTitle) async {
    final prompt = '''
Analyze this bill and provide a clear, structured summary:

Title: $billTitle

Bill Text:
$billText

Format your response EXACTLY as follows with NO asterisks, NO bold markers, NO markdown formatting:

OVERVIEW:
Write 2-3 clear sentences explaining what this bill does and its main purpose.

KEY PROVISIONS:
• List 3-4 main provisions or changes this bill would make
• Use bullet points for clarity
• Keep each point to one sentence

WHO IT AFFECTS:
Clearly state who would be impacted by this bill (specific groups, businesses, general public, etc.)

TLDR:
Summarize the entire bill in one sentence of 20 words or less.

IMPORTANT: Do not use asterisks, bold text markers, or any special formatting. Use plain text only. The app will handle all styling automatically.

Keep everything factual, non-partisan, and easy to understand for average citizens.
''';

    return generateContent(prompt);
  }

  /// Analyze representative voting patterns
  static Future<String> analyzeVotingPattern(List<Map<String, dynamic>> votes) async {
    final voteSummary = votes.map((vote) => 
        '${vote['bill_title']}: ${vote['position']} (${vote['date']})').join('\n');
    
    final prompt = '''
Analyze this representative's voting pattern and provide structured insights:

Voting Record:
$voteSummary

Format your response EXACTLY as follows with NO asterisks, NO bold markers, NO markdown formatting:

VOTING THEMES:
Identify 2-3 main policy areas or themes that emerge from their voting pattern.

KEY POSITIONS:
• List 3-4 specific positions they've taken on important issues
• Use bullet points for clarity
• Focus on votes that show clear policy stances

CONSISTENCY ANALYSIS:
Describe how consistently they vote along party lines or on specific issues.

NOTABLE PATTERNS:
Highlight any interesting or unusual voting patterns worth noting.

TLDR:
Summarize their voting pattern in one sentence of 25 words or less.

IMPORTANT: Do not use asterisks, bold text markers, or any special formatting. Use plain text only. The app will handle all styling automatically.

Keep analysis factual, non-partisan, and focused on helping citizens understand their representative's positions.
''';

    return generateContent(prompt);
  }
}