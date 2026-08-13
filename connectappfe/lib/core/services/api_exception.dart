import 'package:dio/dio.dart';

/// A failure translated into something worth showing a user.
///
/// The backend answers errors as `{ "error": "...", "details": [...] }`
/// (see API_CONTRACT.md), so [message] prefers that field and only falls back
/// to a generic string when the server said nothing useful.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.fieldErrors});

  final String message;
  final int? statusCode;

  /// Field name -> first validation message, derived from zod `details`.
  /// Lets a form highlight the offending input instead of only showing a banner.
  final Map<String, String>? fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'The server took too long to respond. Check your connection and try again.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          "Can't reach the server. Make sure the backend is running and your "
          'API base URL is correct.',
        );
      case DioExceptionType.cancel:
        return const ApiException('Request cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiException('The server certificate was rejected.');
      case DioExceptionType.badResponse:
        break;
    }

    final Response<dynamic>? response = error.response;
    final int? status = response?.statusCode;
    final dynamic data = response?.data;

    String message = 'Something went wrong. Please try again.';
    Map<String, String>? fieldErrors;

    if (data is Map) {
      final Object? serverMessage = data['error'];
      if (serverMessage is String && serverMessage.trim().isNotEmpty) {
        message = serverMessage;
      }
      fieldErrors = _parseFieldErrors(data['details']);
    }

    return ApiException(message, statusCode: status, fieldErrors: fieldErrors);
  }

  /// zod issues arrive as `[{ path: ["email"], message: "Invalid email" }, ...]`.
  static Map<String, String>? _parseFieldErrors(Object? details) {
    if (details is! List) return null;

    final Map<String, String> parsed = <String, String>{};
    for (final Object? issue in details) {
      if (issue is! Map) continue;
      final Object? path = issue['path'];
      final Object? message = issue['message'];
      if (path is! List || path.isEmpty || message is! String) continue;
      final Object? field = path.first;
      if (field is String) {
        parsed.putIfAbsent(field, () => message);
      }
    }
    return parsed.isEmpty ? null : parsed;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
