import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:govvy/services/api_exceptions.dart';

class ErrorHandler {
  static String formatError(dynamic error) {
    if (error == null) return 'Unknown error occurred';

    // Handle specific exception types
    if (error is ApiErrorException) {
      return _formatApiError(error);
    }

    if (error is SocketException) {
      return 'Network connection failed. Please check your internet connection.';
    }

    if (error is HttpException) {
      return 'HTTP error: ${error.message}';
    }

    if (error is FormatException) {
      return 'Invalid data format received from server.';
    }

    if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (error.toString().contains('connection')) {
      return 'Connection error. Please check your internet connection.';
    }

    if (error.toString().contains('certificate')) {
      return 'Security certificate error. Please try again later.';
    }

    // Return generic error message for debugging in development
    if (kDebugMode) {
      return 'Error: ${error.toString()}';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  static String _formatApiError(ApiErrorException error) {
    if (error is NetworkException) {
      return 'Network error: ${error.message}';
    } else if (error is ServerException) {
      return _formatServerError(error);
    } else if (error is ApiTimeoutException) {
      return 'Request timed out after ${error.timeoutMs / 1000} seconds. Please try again.';
    } else if (error is DataParsingException) {
      return 'Unable to process server response. Please try again.';
    } else if (error is BillNotFoundException) {
      return 'The requested bill could not be found.';
    } else if (error is RateLimitException) {
      return _formatRateLimitError(error);
    } else if (error is LegiscanApiException) {
      return 'Legislative data service error: ${error.message}';
    } else if (error is ApiException) {
      return _formatGeneralApiError(error);
    } else {
      return error.message;
    }
  }

  static String _formatServerError(ServerException error) {
    if (error.statusCode == null) {
      return 'Server error: ${error.message}';
    }

    switch (error.statusCode!) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication required. Please log in and try again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'The requested resource was not found.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service temporarily unavailable. Please try again later.';
      case 503:
        return 'Service maintenance in progress. Please try again later.';
      default:
        return 'Server error (${error.statusCode}): ${error.message}';
    }
  }

  static String _formatRateLimitError(RateLimitException error) {
    if (error.retryAfterSeconds != null) {
      return 'Rate limit exceeded. Please wait ${error.retryAfterSeconds} seconds before trying again.';
    }
    return 'Rate limit exceeded. Please wait a moment before trying again.';
  }

  static String _formatGeneralApiError(ApiException error) {
    if (error.statusCode != null) {
      return _formatHttpStatusError(error.statusCode!, error.message);
    }
    return 'API error: ${error.message}';
  }

  static String _formatHttpStatusError(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return 'Bad request: $message';
      case 401:
        return 'Authentication failed: $message';
      case 403:
        return 'Access forbidden: $message';
      case 404:
        return 'Resource not found: $message';
      case 429:
        return 'Rate limit exceeded: $message';
      case 500:
        return 'Internal server error: $message';
      case 502:
        return 'Bad gateway: $message';
      case 503:
        return 'Service unavailable: $message';
      case 504:
        return 'Gateway timeout: $message';
      default:
        return 'HTTP $statusCode: $message';
    }
  }

  static void handleApiError(
    dynamic error,
    Function(String) setErrorMessage, {
    VoidCallback? onNetworkError,
    VoidCallback? onAuthError,
    VoidCallback? onRateLimit,
  }) {
    if (kDebugMode) {
      print('ErrorHandler.handleApiError: $error');
    }

    final formattedError = formatError(error);
    setErrorMessage(formattedError);

    // Call specific callbacks based on error type
    if (error is NetworkException || error is SocketException) {
      onNetworkError?.call();
    } else if (error is ServerException && error.statusCode == 401) {
      onAuthError?.call();
    } else if (error is RateLimitException || 
               (error is ServerException && error.statusCode == 429)) {
      onRateLimit?.call();
    }
  }

  static bool isRetryableError(dynamic error) {
    if (error is ServerException) {
      return error.statusCode == 429 || // Too Many Requests
             error.statusCode == 502 || // Bad Gateway
             error.statusCode == 503 || // Service Unavailable
             error.statusCode == 504;   // Gateway Timeout
    }

    if (error is ApiException) {
      return error.statusCode == 429 ||
             error.statusCode == 502 ||
             error.statusCode == 503 ||
             error.statusCode == 504;
    }

    if (error is SocketException ||
        error is HttpException ||
        error.toString().contains('timeout') ||
        error.toString().contains('connection')) {
      return true;
    }

    return false;
  }

  static bool isNetworkError(dynamic error) {
    return error is NetworkException ||
           error is SocketException ||
           error.toString().contains('connection') ||
           error.toString().contains('network');
  }

  static bool isAuthError(dynamic error) {
    if (error is ServerException) {
      return error.statusCode == 401 || error.statusCode == 403;
    }
    if (error is ApiException) {
      return error.statusCode == 401 || error.statusCode == 403;
    }
    return false;
  }

  static bool isRateLimitError(dynamic error) {
    if (error is RateLimitException) return true;
    if (error is ServerException) return error.statusCode == 429;
    if (error is ApiException) return error.statusCode == 429;
    return false;
  }

  static Duration getRetryDelay(int attemptNumber) {
    // Exponential backoff with jitter
    final baseDelay = Duration(milliseconds: 500 * (1 << attemptNumber));
    final jitter = Duration(milliseconds: (baseDelay.inMilliseconds * 0.1).round());
    return baseDelay + jitter;
  }

  static int getMaxRetries(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'search':
      case 'query':
        return 2;
      case 'auth':
      case 'login':
        return 1;
      case 'cache':
      case 'background':
        return 3;
      default:
        return 2;
    }
  }
}