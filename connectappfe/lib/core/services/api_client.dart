import 'package:connectappfe/core/config/api_config.dart';
import 'package:connectappfe/core/config/env.dart';
import 'package:connectappfe/core/services/api_exception.dart';
import 'package:connectappfe/core/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper over Dio that owns cross-cutting HTTP concerns: base URL,
/// timeouts, bearer-token injection, and translating [DioException] into the
/// app's own [ApiException].
///
/// Feature services depend on this rather than on Dio directly, so swapping the
/// transport or adding retry/logging later touches one file.
class ApiClient {
  ApiClient({required StorageService storage, Dio? dio})
    : _storage = storage,
      _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      // Let non-2xx through to the error interceptor rather than throwing
      // opaquely, so ApiException can read the server's `error` field.
      validateStatus: (status) => status != null && status < 400,
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _storage.cachedToken ?? await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token expired or rejected — let the app tear the session down
            // instead of leaving the UI in a half-authenticated state.
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(),
      );
    }
  }

  final Dio _dio;
  final StorageService _storage;

  /// Invoked when any request comes back 401. Wired up by the auth controller.
  VoidCallback? onUnauthorized;

  String get baseUrl => _dio.options.baseUrl;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) => _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => _dio.post<dynamic>(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _send(() => _dio.put<dynamic>(path, data: data));

  Future<dynamic> delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Builds a multipart part from in-memory bytes.
  ///
  /// Bytes rather than a file path so this works identically on web (where
  /// there are no paths) and on mobile. The explicit content type matters: the
  /// backend's multer filter rejects anything whose mimetype isn't `image/*`,
  /// and Dio would otherwise send `application/octet-stream`.
  static MultipartFile imagePart(Uint8List bytes, String filename) {
    return MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: DioMediaType('image', _imageSubtype(filename)),
    );
  }

  static String _imageSubtype(String filename) {
    final dot = filename.lastIndexOf('.');
    final ext = dot == -1 ? '' : filename.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'png' => 'png',
      'webp' => 'webp',
      'gif' => 'gif',
      'heic' => 'heic',
      'heif' => 'heif',
      'bmp' => 'bmp',
      _ => 'jpeg',
    };
  }
}
