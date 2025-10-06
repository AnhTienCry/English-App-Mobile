import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:4000'));
// 10.0.2.2 = localhost cho Android emulator

Future<void> setupInterceptors() async {
  final prefs = await SharedPreferences.getInstance();

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final accessToken = prefs.getString('accessToken');
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refresh = prefs.getString('refreshToken');
        if (refresh != null) {
          try {
            final res = await dio.post('/auth/refresh', data: {'refreshToken': refresh});
            final newAccess = res.data['accessToken'];
            await prefs.setString('accessToken', newAccess);
            error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
            final retry = await dio.fetch(error.requestOptions);
            return handler.resolve(retry);
          } catch (_) {
            await prefs.clear();
          }
        }
      }
      return handler.next(error);
    },
  ));
}
