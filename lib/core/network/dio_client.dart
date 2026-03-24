import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Custom Dio client used for every API call in the app.
/// All requests go through pretty logging and consistent error handling.
class DioClient {
  static DioClient? _instance;

  /// Single shared instance. Use this for all API calls so logging and errors are consistent.
  static DioClient get instance => _instance ??= DioClient();

  DioClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _PrettyLoggerInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  late final Dio _dio;

  Dio get dio => _dio;

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
}

/// Pretty-prints every API request and response in the console.
class _PrettyLoggerInterceptor extends Interceptor {
  static const String _separator = '────────────────────────────────────────';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('\n$_separator');
    buffer.writeln('🌐 API REQUEST');
    buffer.writeln(_separator);
    buffer.writeln('${options.method} ${options.uri}');
    if (options.headers.isNotEmpty) {
      buffer.writeln('Headers: ${options.headers}');
    }
    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('Query: ${options.queryParameters}');
    }
    if (options.data != null) {
      buffer.writeln('Body: ${_prettyJson(options.data)}');
    }
    buffer.writeln(_separator);
    // ignore: avoid_print
    print(buffer);
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('\n$_separator');
    buffer.writeln('✅ API RESPONSE');
    buffer.writeln(_separator);
    buffer.writeln('${response.statusCode} ${response.requestOptions.uri}');
    buffer.writeln('Response: ${_prettyJson(response.data)}');
    buffer.writeln(_separator);
    // ignore: avoid_print
    print(buffer);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('\n$_separator');
    buffer.writeln('❌ API ERROR');
    buffer.writeln(_separator);
    buffer.writeln('${err.requestOptions.method} ${err.requestOptions.uri}');
    buffer.writeln('Type: ${err.type}');
    buffer.writeln('Message: ${err.message}');
    if (err.response != null) {
      buffer.writeln('Status: ${err.response?.statusCode}');
      buffer.writeln('Response: ${_prettyJson(err.response?.data)}');
    }
    buffer.writeln(_separator);
    // ignore: avoid_print
    print(buffer);
    handler.next(err);
  }

  String _prettyJson(dynamic data) {
    if (data == null) return 'null';
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return data;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}

/// Normalizes errors and ensures every API error is logged and handled consistently.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Optional: map status codes to app-specific exceptions or messages
    handler.next(err);
  }
}
