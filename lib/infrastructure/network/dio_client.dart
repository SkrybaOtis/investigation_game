import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exceptions.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

var logger = Logger(
  filter: null, // Use the default LogFilter (-> only log in debug mode)
  printer: PrettyPrinter(), // Use the PrettyPrinter to format and print log
  output: null, // Use the default LogOutput (-> send everything to console)
);

class DioClient {
  late final Dio _dio;
  
  DioClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Accept': 'application/json',
      },
    ));
    
    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _RetryInterceptor(_dio),
    ]);
  }
  
  Dio get dio => _dio;
  
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Response> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool resumeDownload = false,
    int? existingBytes,
  }) async {
    try {
      final options = Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
      );
      
      if (resumeDownload && existingBytes != null && existingBytes > 0) {
        options.headers = {
          'Range': 'bytes=$existingBytes-',
        };
      }
      
      return await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        options: options,
        deleteOnError: false, // We handle partial files ourselves
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  NetworkException _handleDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        NetworkException('Connection timed out', e.response?.statusCode, e),
      DioExceptionType.badResponse =>
        NetworkException(
          'Server error: ${e.response?.statusCode}',
          e.response?.statusCode,
          e,
        ),
      DioExceptionType.connectionError =>
        NetworkException('No internet connection', null, e),
      _ => NetworkException('Network error occurred', null, e),
    };
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // In production, use a proper logger
    logger.t('→ ${options.method} ${options.uri}');
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.i('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('✗ Error: ${err.message}');
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  
  _RetryInterceptor(this._dio);
  
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] as int? ?? 0;
    
    // Only retry on connection errors or 5xx errors
    final shouldRetry = retryCount < ApiConstants.maxRetries &&
        (err.type == DioExceptionType.connectionError ||
         err.type == DioExceptionType.connectionTimeout ||
         (err.response?.statusCode ?? 0) >= 500);
    
    if (shouldRetry) {
      await Future.delayed(ApiConstants.retryDelay * (retryCount + 1));
      
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      
      try {
        final response = await _dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Fall through to reject
      }
    }
    
    handler.next(err);
  }
}