// lib/services/api_exceptions.dart

/// Base exception for all API-related errors
abstract class ApiErrorException implements Exception {
  final String message;
  
  ApiErrorException(this.message);
  
  @override
  String toString();
}

/// Exception for network connectivity issues
class NetworkException extends ApiErrorException {
  NetworkException(String message) : super(message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Exception for LegiScan API errors
class LegiscanApiException extends ApiErrorException {
  LegiscanApiException(String message) : super(message);
  
  @override
  String toString() => 'LegiScanApiException: $message';
}

/// Exception for server-side errors
class ServerException extends ApiErrorException {
  final int? statusCode;
  
  ServerException(String message, {this.statusCode}) : super(message);
  
  @override
  String toString() => 'ServerException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Exception for request timeouts
class ApiTimeoutException extends ApiErrorException {
  final int timeoutMs;
  
  ApiTimeoutException(String message, this.timeoutMs) : super(message);
  
  @override
  String toString() => 'ApiTimeoutException: $message (Timeout: ${timeoutMs}ms)';
}

/// Exception for data parsing errors
class DataParsingException extends ApiErrorException {
  DataParsingException(String message) : super(message);
  
  @override
  String toString() => 'DataParsingException: $message';
}

/// Exception for bill not found
class BillNotFoundException extends ApiErrorException {
  final int billId;
  final String? stateCode;
  
  BillNotFoundException(String message, this.billId, {this.stateCode}) : super(message);
  
  @override
  String toString() => 'BillNotFoundException: $message (Bill ID: $billId${stateCode != null ? ', State: $stateCode' : ''})';
}

/// Exception for rate limiting
class RateLimitException extends ApiErrorException {
  final int? retryAfterSeconds;
  
  RateLimitException(String message, {this.retryAfterSeconds}) : super(message);
  
  @override
  String toString() => 'RateLimitException: $message${retryAfterSeconds != null ? ' (Retry after: ${retryAfterSeconds}s)' : ''}';
}