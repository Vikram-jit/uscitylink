import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class LoggerInterceptor extends PrettyDioLogger {
  LoggerInterceptor()
    : super(
        requestBody: true,
        requestHeader: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      );
}
