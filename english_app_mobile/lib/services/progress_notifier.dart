import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../config/api_config.dart';

class ProgressNotifier extends ChangeNotifier {
  bool loading = false;
  String? error;
  Map<String, dynamic>? progress;

  Future<void> refresh() async {
    loading = true; error = null;
    notifyListeners();
    try {
      final res = await dio.get("${ApiConfig.baseUrl}/api/progressions/me");
      progress = res.data is Map<String, dynamic> ? Map<String, dynamic>.from(res.data) : null;
    } on DioException catch (e) {
      error = e.response?.data?.toString() ?? e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
