// lib/models/legiscan_search_model.dart
import 'package:flutter/foundation.dart';

class LegiscanSearchResponse {
  final String status;
  final SearchResult searchResult;

  LegiscanSearchResponse({
    required this.status,
    required this.searchResult,
  });

  factory LegiscanSearchResponse.fromMap(Map<String, dynamic> map) {
    return LegiscanSearchResponse(
      status: map['status'] as String,
      searchResult: SearchResult.fromMap(map['searchresult'] as Map<String, dynamic>),
    );
  }
}

class SearchResult {
  final SearchSummary summary;
  final List<SearchBill> bills;

  SearchResult({
    required this.summary,
    required this.bills,
  });

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    // Extract the summary
    final summary = SearchSummary.fromMap(map['summary'] as Map<String, dynamic>);
    
    // The bills are under numeric keys (0, 1, 2, etc.)
    // We need to filter out the 'summary' key and convert all other entries to bills
    final bills = <SearchBill>[];
    
    map.forEach((key, value) {
      if (key != 'summary' && value is Map<String, dynamic>) {
        try {
          bills.add(SearchBill.fromMap(value));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing bill with key $key: $e');
          }
        }
      }
    });
    
    return SearchResult(
      summary: summary,
      bills: bills,
    );
  }
}

class SearchSummary {
  final String page;
  final String range;
  final String relevancy;
  final int count;
  final int pageCurrent;
  final int pageTotal;
  final String query;

  SearchSummary({
    required this.page,
    required this.range,
    required this.relevancy,
    required this.count,
    required this.pageCurrent,
    required this.pageTotal,
    required this.query,
  });

  factory SearchSummary.fromMap(Map<String, dynamic> map) {
    return SearchSummary(
      page: map['page'] as String,
      range: map['range'] as String,
      relevancy: map['relevancy'] as String,
      count: int.parse(map['count'].toString()),
      pageCurrent: int.parse(map['page_current'].toString()),
      pageTotal: int.parse(map['page_total'].toString()),
      query: map['query'] as String,
    );
  }
}

class SearchBill {
  final int relevance;
  final String state;
  final String billNumber;
  final int billId;
  final String changeHash;
  final String url;
  final String textUrl;
  final String researchUrl;
  final String lastActionDate;
  final String lastAction;
  final String title;

  SearchBill({
    required this.relevance,
    required this.state,
    required this.billNumber,
    required this.billId,
    required this.changeHash,
    required this.url,
    required this.textUrl,
    required this.researchUrl,
    required this.lastActionDate,
    required this.lastAction,
    required this.title,
  });

  factory SearchBill.fromMap(Map<String, dynamic> map) {
    return SearchBill(
      relevance: int.parse(map['relevance'].toString()),
      state: map['state'] as String,
      billNumber: map['bill_number'] as String,
      billId: int.parse(map['bill_id'].toString()),
      changeHash: map['change_hash'] as String,
      url: map['url'] as String,
      textUrl: map['text_url'] as String,
      researchUrl: map['research_url'] as String,
      lastActionDate: map['last_action_date'] as String,
      lastAction: map['last_action'] as String,
      title: map['title'] as String,
    );
  }
}