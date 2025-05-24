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