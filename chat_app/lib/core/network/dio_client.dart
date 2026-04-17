import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';
import 'api_endpoints.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late Dio dio;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: Duration(seconds: 30),
        receiveTimeout: Duration(seconds: 30),
        sendTimeout: Duration(seconds: 30),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      ),
    );

    // Attach interceptors
    dio.interceptors.add(AuthInterceptor());
    // dio.interceptors.add(LoggerInterceptor()); // remove on production if needed
  }
}
