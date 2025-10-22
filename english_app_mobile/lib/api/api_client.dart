import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/network_config.dart';
import '../config/force_config.dart';
import 'package:flutter/foundation.dart';

final dio = Dio(BaseOptions(
  baseUrl: ForceConfig.baseUrl,
  connectTimeout: Duration(milliseconds: NetworkConfig.connectTimeout),
  receiveTimeout: Duration(milliseconds: NetworkConfig.receiveTimeout),
  sendTimeout: Duration(milliseconds: NetworkConfig.sendTimeout),
));

// Dio riêng để gọi refresh (không có interceptor)
final Dio _refreshDio = Dio(BaseOptions(baseUrl: ForceConfig.baseUrl));

bool _isRefreshing = false;

class _QueuedRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer;
  _QueuedRequest(this.requestOptions) : completer = Completer<Response>();
}

final List<_QueuedRequest> _retryQueue = [];

/// Clone RequestOptions safely to replay requests after token refresh.
RequestOptions _cloneRequestOptions(RequestOptions options, String accessToken) {
  final clonedQuery = Map<String, dynamic>.from(options.queryParameters ?? {});
  dynamic clonedData = options.data;
  try {
    if (options.data is Map) {
      clonedData = Map<String, dynamic>.from(options.data as Map);
    }
  } catch (_) {
    // leave data as-is (e.g. FormData, bytes)
    clonedData = options.data;
  }
  final clonedHeaders = Map<String, dynamic>.from(options.headers ?? {})
    ..['Authorization'] = 'Bearer $accessToken';

  return RequestOptions(
    path: options.path,
    method: options.method,
    baseUrl: options.baseUrl,
    queryParameters: clonedQuery,
    data: clonedData,
    headers: clonedHeaders,
    responseType: options.responseType,
    contentType: options.contentType,
    followRedirects: options.followRedirects,
    validateStatus: options.validateStatus,
    receiveDataWhenStatusError: options.receiveDataWhenStatusError,
    extra: Map<String, dynamic>.from(options.extra),
    sendTimeout: options.sendTimeout,
    receiveTimeout: options.receiveTimeout,
    maxRedirects: options.maxRedirects,
  );
}

Future<void> setupInterceptors() async {
  // Avoid adding multiple times
  if (dio.interceptors.any((i) => i is InterceptorsWrapper)) return;

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      if (kDebugMode) {
        debugPrint('>>> REQUEST: ${options.method} ${options.uri}');
        debugPrint('>>> HEADERS: ${options.headers}');
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      final response = error.response;

      // Only handle 401 for authenticated flows
      if (response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('refreshToken');
        if (refreshToken == null) {
          await prefs.clear();
          return handler.next(error);
        }

        // If already refreshing, queue this request and wait
        if (_isRefreshing) {
          final queued = _QueuedRequest(error.requestOptions);
          _retryQueue.add(queued);
          try {
            final retryResp = await queued.completer.future;
            return handler.resolve(retryResp);
          } catch (e) {
            return handler.next(error);
          }
        }

        // Start refresh
        _isRefreshing = true;
        try {
          if (kDebugMode) debugPrint('Refreshing access token...');
          final refreshRes = await _refreshDio.post(
            '/api/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccess = refreshRes.data['accessToken'] as String?;
          if (newAccess == null) {
            // refresh failed
            await prefs.clear();
            _isRefreshing = false;
            for (final q in _retryQueue) {
              q.completer.completeError(error);
            }
            _retryQueue.clear();
            return handler.next(error);
          }

          // save new token
          await prefs.setString('accessToken', newAccess);

          // replay original request with new header
          final originalOptions = error.requestOptions;
          final clonedOriginal = _cloneRequestOptions(originalOptions, newAccess);
          final cloneResp = await dio.fetch(clonedOriginal);

          // replay queued requests
          for (final queued in _retryQueue) {
            try {
              final rq = _cloneRequestOptions(queued.requestOptions, newAccess);
              final resp = await dio.fetch(rq);
              queued.completer.complete(resp);
            } catch (e) {
              queued.completer.completeError(e);
            }
          }
          _retryQueue.clear();

          _isRefreshing = false;
          return handler.resolve(cloneResp);
        } catch (e) {
          if (kDebugMode) debugPrint('Refresh token failed: $e');
          await prefs.clear();
          _isRefreshing = false;
          for (final q in _retryQueue) {
            q.completer.completeError(e);
          }
          _retryQueue.clear();
          return handler.next(error);
        }
      }

      return handler.next(error);
    },
  ));
}