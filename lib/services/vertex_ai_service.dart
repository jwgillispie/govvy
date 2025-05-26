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
Provide a concise 2-3 sentence summary of this bill:

Title: $billTitle

Bill Text:
$billText

Focus only on:
1. What the bill would do
2. Who it would impact

Keep it factual, non-partisan, and under 60 words.
''';

    return generateContent(prompt);
  }

  /// Analyze representative voting patterns
  static Future<String> analyzeVotingPattern(List<Map<String, dynamic>> votes) async {
    final voteSummary = votes.map((vote) => 
        '${vote['bill_title']}: ${vote['position']} (${vote['date']})').join('\n');
    
    final prompt = '''
Analyze this representative's voting pattern and provide insights:

Voting Record:
$voteSummary

Please provide:
1. Key themes in their voting pattern
2. Areas of focus
3. Consistency analysis
4. Notable patterns

Keep analysis factual and non-partisan.
''';

    return generateContent(prompt);
  }
}