import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:asmrapp/utils/logger.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  bool _isRetryable(DioException error) {
    // Don't retry requests with stream bodies (non-replayable)
    final data = error.requestOptions.data;
    if (data is Stream || data is MultipartFile) {
      return false;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return statusCode != null && statusCode >= 500;
      default:
        return false;
    }
  }

  Duration _computeDelay(int attempt) {
    final exponential = baseDelay * pow(2, attempt).toInt();
    final jitter = Duration(
      milliseconds: Random().nextInt(baseDelay.inMilliseconds ~/ 2 + 1),
    );
    return exponential + jitter;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final retryCount = (options.extra['retryCount'] as int?) ?? 0;

    if (_isRetryable(err) && retryCount < maxRetries) {
      options.extra['retryCount'] = retryCount + 1;
      final delay = _computeDelay(retryCount);
      AppLogger.info(
        '网络请求重试 (${retryCount + 1}/$maxRetries), 等待 ${delay.inMilliseconds}ms: ${options.path}',
      );
      await Future.delayed(delay);
      try {
        final response = await dio.fetch(options);
        handler.resolve(response);
      } on DioException catch (retryError) {
        handler.reject(retryError);
      }
      return;
    }

    handler.next(err);
  }
}
