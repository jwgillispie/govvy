import 'package:flutter/foundation.dart';
import 'package:govvy/services/network_service.dart';
import 'package:govvy/services/cache_manager.dart';
import 'package:govvy/utils/error_handler.dart';

abstract class BaseProvider with ChangeNotifier {
  final NetworkService _networkService = NetworkService();
  final CacheManager _cacheManager = CacheManager();

  // Common loading states
  bool _isLoading = false;
  bool _isInitialized = false;
  
  // Common error state
  String? _errorMessage;
  
  // Last operation timestamp for debugging
  DateTime? _lastOperationTime;

  // Getters for common state
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  DateTime? get lastOperationTime => _lastOperationTime;

  // Common methods for state management
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (loading) {
        _lastOperationTime = DateTime.now();
      }
      notifyListeners();
    }
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void setInitialized(bool initialized) {
    if (_isInitialized != initialized) {
      _isInitialized = initialized;
      notifyListeners();
    }
  }

  // Common network checking
  Future<bool> checkNetworkConnectivity() async {
    try {
      return await _networkService.checkConnectivity();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Network check failed: $e');
      }
      return false;
    }
  }

  // Common error handling with automatic formatting
  void handleError(dynamic error, {String? fallbackMessage}) {
    final formattedError = ErrorHandler.formatError(error);
    setError(fallbackMessage ?? formattedError);
    
    if (kDebugMode) {
      debugPrint('$runtimeType error: $error');
    }
  }

  // Template method for operations with common error handling
  Future<T?> performOperation<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool setLoadingState = true,
    bool clearErrorFirst = true,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    if (clearErrorFirst) {
      clearError();
    }
    
    if (setLoadingState) {
      setLoading(true);
    }

    try {
      final result = await operation();
      
      if (setLoadingState) {
        setLoading(false);
      }
      
      onSuccess?.call();
      return result;
    } catch (e) {
      if (setLoadingState) {
        setLoading(false);
      }
      
      handleError(e, fallbackMessage: errorMessage);
      onError?.call();
      return null;
    }
  }

  // Network-aware operation wrapper
  Future<T?> performNetworkOperation<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool setLoadingState = true,
    VoidCallback? onNetworkError,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    // Check network connectivity first
    if (!await checkNetworkConnectivity()) {
      handleError('No internet connection available', 
          fallbackMessage: 'Please check your internet connection and try again.');
      onNetworkError?.call();
      return null;
    }

    return performOperation<T>(
      operation,
      errorMessage: errorMessage,
      setLoadingState: setLoadingState,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  // Cache-aware operation wrapper
  Future<T?> performCachedOperation<T>(
    String cacheKey,
    Future<T> Function() fetchOperation,
    T Function(dynamic) deserializer,
    Duration cacheMaxAge, {
    String? errorMessage,
    bool setLoadingState = true,
    VoidCallback? onCacheHit,
    VoidCallback? onCacheMiss,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    try {
      // Try cache first
      final cachedData = await _cacheManager.getValidData<T>(
        cacheKey,
        cacheMaxAge,
        deserializer,
      );

      if (cachedData != null) {
        onCacheHit?.call();
        return cachedData;
      }

      onCacheMiss?.call();

      // Perform network operation if cache miss
      return await performNetworkOperation<T>(
        () async {
          final result = await fetchOperation();
          
          // Cache the result
          try {
            await _cacheManager.saveDataWithTTL(cacheKey, result, ttl: cacheMaxAge);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Failed to cache result: $e');
            }
          }
          
          return result;
        },
        errorMessage: errorMessage,
        setLoadingState: setLoadingState,
        onSuccess: onSuccess,
        onError: onError,
      );
    } catch (e) {
      handleError(e, fallbackMessage: errorMessage);
      onError?.call();
      return null;
    }
  }

  // Initialize provider (should be overridden by subclasses)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await performOperation(
      () async {
        await onInitialize();
        setInitialized(true);
      },
      errorMessage: 'Failed to initialize $runtimeType',
    );
  }

  // Override this in subclasses for custom initialization
  Future<void> onInitialize() async {}

  // Cleanup method
  void cleanup() {
    clearError();
    setLoading(false);
    setInitialized(false);
    onCleanup();
  }

  // Override this in subclasses for custom cleanup
  void onCleanup() {}

  // Refresh all data
  Future<void> refresh() async {
    await performOperation(
      () async {
        await onRefresh();
      },
      errorMessage: 'Failed to refresh data',
    );
  }

  // Override this in subclasses for custom refresh logic
  Future<void> onRefresh() async {}

  // Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'providerType': runtimeType.toString(),
      'isLoading': _isLoading,
      'isInitialized': _isInitialized,
      'hasError': _errorMessage != null,
      'errorMessage': _errorMessage,
      'lastOperationTime': _lastOperationTime?.toIso8601String(),
      ...getCustomDebugInfo(),
    };
  }

  // Override this in subclasses to add custom debug information
  Map<String, dynamic> getCustomDebugInfo() => {};

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}

// Mixin for providers that need search functionality
mixin SearchProviderMixin on BaseProvider {
  String? _lastSearchQuery;
  Map<String, dynamic>? _lastSearchParams;
  DateTime? _lastSearchTime;

  String? get lastSearchQuery => _lastSearchQuery;
  Map<String, dynamic>? get lastSearchParams => _lastSearchParams;
  DateTime? get lastSearchTime => _lastSearchTime;

  void updateSearchState(String query, Map<String, dynamic>? params) {
    _lastSearchQuery = query;
    _lastSearchParams = params;
    _lastSearchTime = DateTime.now();
  }

  void clearSearchState() {
    _lastSearchQuery = null;
    _lastSearchParams = null;
    _lastSearchTime = null;
    notifyListeners();
  }

  @override
  Map<String, dynamic> getCustomDebugInfo() {
    return {
      ...super.getCustomDebugInfo(),
      'lastSearchQuery': _lastSearchQuery,
      'lastSearchParams': _lastSearchParams,
      'lastSearchTime': _lastSearchTime?.toIso8601String(),
    };
  }
}

// Mixin for providers that need pagination
mixin PaginationProviderMixin on BaseProvider {
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 20;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get itemsPerPage => _itemsPerPage;
  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _hasPreviousPage;

  void updatePaginationState({
    required int currentPage,
    required int totalPages,
    int? itemsPerPage,
  }) {
    _currentPage = currentPage;
    _totalPages = totalPages;
    if (itemsPerPage != null) {
      _itemsPerPage = itemsPerPage;
    }
    _hasNextPage = currentPage < totalPages;
    _hasPreviousPage = currentPage > 1;
    notifyListeners();
  }

  void resetPagination() {
    _currentPage = 1;
    _totalPages = 1;
    _hasNextPage = false;
    _hasPreviousPage = false;
    notifyListeners();
  }

  @override
  Map<String, dynamic> getCustomDebugInfo() {
    return {
      ...super.getCustomDebugInfo(),
      'pagination': {
        'currentPage': _currentPage,
        'totalPages': _totalPages,
        'itemsPerPage': _itemsPerPage,
        'hasNextPage': _hasNextPage,
        'hasPreviousPage': _hasPreviousPage,
      },
    };
  }
}

// Mixin for providers that need multiple loading states
mixin MultipleLoadingStatesMixin on BaseProvider {
  final Map<String, bool> _loadingStates = {};

  bool getLoadingState(String key) => _loadingStates[key] ?? false;

  void setLoadingState(String key, bool loading) {
    final wasLoading = _loadingStates[key] ?? false;
    if (wasLoading != loading) {
      _loadingStates[key] = loading;
      notifyListeners();
    }
  }

  void clearAllLoadingStates() {
    if (_loadingStates.isNotEmpty) {
      _loadingStates.clear();
      notifyListeners();
    }
  }

  bool get hasAnyLoadingState => _loadingStates.values.any((loading) => loading);

  @override
  Map<String, dynamic> getCustomDebugInfo() {
    return {
      ...super.getCustomDebugInfo(),
      'loadingStates': Map<String, bool>.from(_loadingStates),
      'hasAnyLoadingState': hasAnyLoadingState,
    };
  }
}