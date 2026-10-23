import 'package:dio/dio.dart';

/// HTTP-клиент к нашему NestJS API.
/// --dart-define=API_BASE=http://192.168.0.5:3000/v1 — для реального телефона в той же Wi-Fi сети.
/// Дефолт localhost — для iOS-симулятора/Chrome на том же Mac.
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost:3000/v1',
);

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
