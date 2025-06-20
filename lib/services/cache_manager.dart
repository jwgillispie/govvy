// lib/services/cache_manager.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:govvy/models/bill_model.dart';

/// CacheManager handles caching data with TTL (time to live) support
/// for more efficient API usage and better offline experience
class CacheManager {
  // Singleton pattern
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Cache keys
  static const String _cachePrefixData = 'cache_data_';
  static const String _cachePrefixTimestamp = 'cache_timestamp_';
  static const String _cachePrefixBills = 'cache_bills_';
  static const String _cachePrefixRepresentatives = 'cache_reps_';
  static const String _cachePrefixLocalReps = 'cache_local_reps_';
  static const String _cachePrefixCampaignFinance = 'cache_finance_';
  static const String _cachePrefixElections = 'cache_elections_';
  static const String _cachePrefixSearch = 'cache_search_';
  static const String _cachePrefixMetadata = 'cache_metadata_';

  // Default cache durations
  static const Duration _defaultCacheDuration = Duration(hours: 1);
  static const Duration _billsCacheDuration = Duration(hours: 6);
  static const Duration _representativesCacheDuration = Duration(days: 1);
  static const Duration _campaignFinanceCacheDuration = Duration(hours: 12);
  static const Duration _electionsCacheDuration = Duration(hours: 24);
  static const Duration _searchCacheDuration = Duration(minutes: 30);

  /// Saves generic data to cache with timestamp
  Future<void> saveData(String key, dynamic data, DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert data to JSON string
      final jsonData = json.encode(data);
      
      // Save data and timestamp
      await prefs.setString(_cachePrefixData + key, jsonData);
      await prefs.setInt(_cachePrefixTimestamp + key, timestamp.millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('Cached data for key: $key (${_getReadableSize(jsonData.length)})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving data to cache: $e');
      }
    }
  }

  /// Gets data from cache
  Future<dynamic> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_cachePrefixData + key);
      
      if (jsonData == null) {
        return null;
      }
      
      return json.decode(jsonData);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting data from cache: $e');
      }
      return null;
    }
  }

  /// Gets the last update time for a cache key
  Future<DateTime?> getLastUpdateTime(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cachePrefixTimestamp + key);
      
      if (timestamp == null) {
        return null;
      }
      
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting timestamp from cache: $e');
      }
      return null;
    }
  }

  /// Save bills for a state
  Future<void> saveBills(String stateCode, List<BillModel> bills) async {
    try {
      // Convert bills to JSON
      final billsData = bills.map((bill) => bill.toMap()).toList();
      
      // Save with timestamp
      await saveData(_cachePrefixBills + stateCode, billsData, DateTime.now());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving bills to cache: $e');
      }
    }
  }

  /// Get bills for a state
  Future<List<BillModel>> getBills(String stateCode) async {
    try {
      final billsData = await getData(_cachePrefixBills + stateCode);
      
      if (billsData == null || billsData is! List) {
        return [];
      }
      
      return (billsData)
          .map((data) => BillModel.fromMap(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bills from cache: $e');
      }
      return [];
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachePrefixData + key);
      await prefs.remove(_cachePrefixTimestamp + key);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys
      final keys = prefs.getKeys();
      
      // Filter cache keys
      final cacheKeys = keys.where((key) => 
          key.startsWith(_cachePrefixData) || 
          key.startsWith(_cachePrefixTimestamp));
      
      // Remove all cache entries
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
      
      if (kDebugMode) {
        print('Cleared ${cacheKeys.length} cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all caches: $e');
      }
    }
  }
  
  /// Check if cache is valid (not expired)
  Future<bool> isCacheValid(String key, Duration maxAge) async {
    final lastUpdate = await getLastUpdateTime(key);
    if (lastUpdate == null) return false;
    
    final now = DateTime.now();
    return now.difference(lastUpdate) < maxAge;
  }

  /// Save data with automatic TTL checking
  Future<void> saveDataWithTTL(String key, dynamic data, {Duration? ttl}) async {
    final timestamp = DateTime.now();
    await saveData(key, data, timestamp);
    
    // Store TTL metadata if provided
    if (ttl != null) {
      final expiryTime = timestamp.add(ttl);
      await saveData('${key}_expires', expiryTime.millisecondsSinceEpoch, timestamp);
    }
  }

  /// Get data only if not expired
  Future<T?> getValidData<T>(String key, Duration maxAge, T Function(dynamic) deserializer) async {
    if (!await isCacheValid(key, maxAge)) {
      return null;
    }
    
    final data = await getData(key);
    if (data == null) return null;
    
    try {
      return deserializer(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error deserializing cached data for $key: $e');
      }
      return null;
    }
  }

  /// Save representatives data as generic JSON
  Future<void> saveRepresentatives(String locationKey, List<Map<String, dynamic>> representatives) async {
    try {
      await saveDataWithTTL(_cachePrefixRepresentatives + locationKey, representatives, ttl: _representativesCacheDuration);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving representatives to cache: $e');
      }
    }
  }

  /// Get representatives data as generic JSON
  Future<List<Map<String, dynamic>>> getRepresentatives(String locationKey) async {
    return await getValidData(
      _cachePrefixRepresentatives + locationKey,
      _representativesCacheDuration,
      (data) {
        if (data is! List) return <Map<String, dynamic>>[];
        return data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      },
    ) ?? [];
  }

  /// Save local representatives data as generic JSON
  Future<void> saveLocalRepresentatives(String locationKey, List<Map<String, dynamic>> representatives) async {
    try {
      await saveDataWithTTL(_cachePrefixLocalReps + locationKey, representatives, ttl: _representativesCacheDuration);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving local representatives to cache: $e');
      }
    }
  }

  /// Get local representatives data as generic JSON
  Future<List<Map<String, dynamic>>> getLocalRepresentatives(String locationKey) async {
    return await getValidData(
      _cachePrefixLocalReps + locationKey,
      _representativesCacheDuration,
      (data) {
        if (data is! List) return <Map<String, dynamic>>[];
        return data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      },
    ) ?? [];
  }

  /// Save campaign finance data as generic JSON
  Future<void> saveCampaignFinance(String candidateKey, Map<String, dynamic> financeData) async {
    try {
      await saveDataWithTTL(_cachePrefixCampaignFinance + candidateKey, financeData, ttl: _campaignFinanceCacheDuration);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving campaign finance to cache: $e');
      }
    }
  }

  /// Get campaign finance data as generic JSON
  Future<Map<String, dynamic>?> getCampaignFinance(String candidateKey) async {
    return await getValidData(
      _cachePrefixCampaignFinance + candidateKey,
      _campaignFinanceCacheDuration,
      (data) => Map<String, dynamic>.from(data),
    );
  }

  /// Save elections data as generic JSON
  Future<void> saveElections(String stateKey, List<Map<String, dynamic>> elections) async {
    try {
      await saveDataWithTTL(_cachePrefixElections + stateKey, elections, ttl: _electionsCacheDuration);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving elections to cache: $e');
      }
    }
  }

  /// Get elections data as generic JSON
  Future<List<Map<String, dynamic>>> getElections(String stateKey) async {
    return await getValidData(
      _cachePrefixElections + stateKey,
      _electionsCacheDuration,
      (data) {
        if (data is! List) return <Map<String, dynamic>>[];
        return data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      },
    ) ?? [];
  }

  /// Save search results with short TTL
  Future<void> saveSearchResults(String searchKey, dynamic results) async {
    try {
      await saveDataWithTTL(_cachePrefixSearch + searchKey, results, ttl: _searchCacheDuration);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving search results to cache: $e');
      }
    }
  }

  /// Get search results
  Future<dynamic> getSearchResults(String searchKey) async {
    return await getValidData(
      _cachePrefixSearch + searchKey,
      _searchCacheDuration,
      (data) => data,
    );
  }

  /// Save metadata (API states, configurations, etc.)
  Future<void> saveMetadata(String metadataKey, Map<String, dynamic> metadata) async {
    try {
      await saveDataWithTTL(_cachePrefixMetadata + metadataKey, metadata, ttl: _defaultCacheDuration);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving metadata to cache: $e');
      }
    }
  }

  /// Get metadata
  Future<Map<String, dynamic>?> getMetadata(String metadataKey) async {
    return await getValidData(
      _cachePrefixMetadata + metadataKey,
      _defaultCacheDuration,
      (data) => Map<String, dynamic>.from(data),
    );
  }

  /// Clear cache by type
  Future<void> clearCacheByType(String cacheType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final typeKeys = keys.where((key) => 
          key.startsWith(_cachePrefixData + cacheType) || 
          key.startsWith(_cachePrefixTimestamp + cacheType));
      
      for (final key in typeKeys) {
        await prefs.remove(key);
      }
      
      if (kDebugMode) {
        print('Cleared ${typeKeys.length} cache entries for type: $cacheType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache by type: $e');
      }
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final cacheKeys = keys.where((key) => 
          key.startsWith(_cachePrefixData)).toList();
      
      int totalSize = 0;
      int expiredCount = 0;
      final typeCount = <String, int>{};
      
      for (final key in cacheKeys) {
        final data = prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
          
          // Extract cache type
          final keyWithoutPrefix = key.substring(_cachePrefixData.length);
          final firstUnderscore = keyWithoutPrefix.indexOf('_');
          final cacheType = firstUnderscore > 0 
              ? keyWithoutPrefix.substring(0, firstUnderscore)
              : keyWithoutPrefix;
          
          typeCount[cacheType] = (typeCount[cacheType] ?? 0) + 1;
        }
      }
      
      return {
        'totalEntries': cacheKeys.length,
        'totalSize': _getReadableSize(totalSize),
        'totalSizeBytes': totalSize,
        'expiredEntries': expiredCount,
        'typeBreakdown': typeCount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cache stats: $e');
      }
      return {
        'totalEntries': 0,
        'totalSize': '0 B',
        'totalSizeBytes': 0,
        'expiredEntries': 0,
        'typeBreakdown': <String, int>{},
      };
    }
  }

  /// Cleanup expired cache entries
  Future<int> cleanupExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int cleanedCount = 0;
      final now = DateTime.now();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefixTimestamp)) {
          final timestamp = prefs.getInt(key);
          if (timestamp != null) {
            final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            final dataKey = key.replaceFirst(_cachePrefixTimestamp, _cachePrefixData);
            
            // Check if cache is older than maximum allowed age (24 hours)
            if (now.difference(cacheTime) > const Duration(hours: 24)) {
              await prefs.remove(key);
              await prefs.remove(dataKey);
              cleanedCount++;
            }
          }
        }
      }
      
      if (kDebugMode && cleanedCount > 0) {
        debugPrint('Cleaned up $cleanedCount expired cache entries');
      }
      
      return cleanedCount;
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up expired cache: $e');
      }
      return 0;
    }
  }

  /// Helper to get readable size
  String _getReadableSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}