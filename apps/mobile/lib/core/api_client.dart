import 'package:dio/dio.dart';

/// HTTP-клиент к нашему NestJS API.
/// iOS-симулятор: localhost ок. Android-эмулятор: замени на http://10.0.2.2:3000/v1
const String kApiBase = 'http://localhost:3000/v1';

class ApiClient {
  final Dio dio;
  String? token;

  ApiClient({String base = kApiBase})
      : dio = Dio(BaseOptions(
          baseUrl: base,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        )) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      return h.next(o);
    }));
  }
}
