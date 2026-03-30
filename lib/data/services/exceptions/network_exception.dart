import 'package:dio/dio.dart';

enum NetworkErrorType {
  timeout,
  connectionError,
  serverError,
  clientError,
  authError,
  cancelled,
  unknown,
}

class NetworkException implements Exception {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final dynamic originalError;

  NetworkException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  factory NetworkException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException(
          type: NetworkErrorType.timeout,
          message: '请求超时: ${e.message}',
          originalError: e,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          type: NetworkErrorType.connectionError,
          message: '连接失败: ${e.message}',
          originalError: e,
        );
      case DioExceptionType.cancel:
        return NetworkException(
          type: NetworkErrorType.cancelled,
          message: '请求已取消',
          originalError: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return NetworkException(
            type: NetworkErrorType.authError,
            message: '认证失败: $statusCode',
            statusCode: statusCode,
            originalError: e,
          );
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return NetworkException(
            type: NetworkErrorType.clientError,
            message: '客户端错误: $statusCode',
            statusCode: statusCode,
            originalError: e,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return NetworkException(
            type: NetworkErrorType.serverError,
            message: '服务器错误: $statusCode',
            statusCode: statusCode,
            originalError: e,
          );
        }
        return NetworkException(
          type: NetworkErrorType.unknown,
          message: '未知响应错误: $statusCode',
          statusCode: statusCode,
          originalError: e,
        );
      case DioExceptionType.badCertificate:
        return NetworkException(
          type: NetworkErrorType.connectionError,
          message: '证书验证失败: ${e.message}',
          originalError: e,
        );
      case DioExceptionType.unknown:
        return NetworkException(
          type: NetworkErrorType.unknown,
          message: '未知网络错误: ${e.message}',
          originalError: e,
        );
    }
  }

  bool get isRetryable =>
      type == NetworkErrorType.timeout ||
      type == NetworkErrorType.connectionError ||
      type == NetworkErrorType.serverError;

  @override
  String toString() => 'NetworkException($type): $message';
}
