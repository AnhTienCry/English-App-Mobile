import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart'; // Giả định có ApiConfig.baseUrl

class TowerProvider with ChangeNotifier {
  // dùng Map thay vì model cục bộ
  List<Map<String, dynamic>> _levels = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get levels => _levels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String _idOf(Map<String, dynamic> m) => (m['_id'] ?? m['id'] ?? '').toString();

  // Fetch levels từ API
  Future<void> fetchLevels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dio = Dio();
      final res = await dio.get('${ApiConfig.baseUrl}/api/tower-levels');
      final data = List<Map<String, dynamic>>.from(res.data ?? []);
      _levels = data.map((json) {
        // ensure keys exist and normalize
        return {
          ...json,
          '_id': (json['_id'] ?? json['id'] ?? '').toString(),
          'levelNumber': json['levelNumber'] ?? json['level'] ?? 0,
          'title': json['title'] ?? json['name'] ?? '',
          'rewardPoints': json['rewardPoints'] ?? json['reward'] ?? 0,
          'isCompleted': json['isCompleted'] ?? json['completed'] ?? false,
        };
      }).toList();

      // Load trạng thái completed từ local storage
      final prefs = await SharedPreferences.getInstance();
      for (var i = 0; i < _levels.length; i++) {
        final key = 'tower_${_idOf(_levels[i])}_completed';
        _levels[i]['isCompleted'] = prefs.getBool(key) ?? (_levels[i]['isCompleted'] ?? false);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tower levels';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark level completed (sau khi submit quiz thành công)
  Future<void> markLevelCompleted(String levelId) async {
    final idx = _levels.indexWhere((l) => _idOf(l) == levelId);
    if (idx == -1) return; // not found

    _levels[idx]['isCompleted'] = true;

    // Lưu local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tower_${levelId}_completed', true);

    notifyListeners();
  }

  // Check if level is unlocked (level 1 luôn unlock, các level sau nếu level trước completed)
  bool isLevelUnlocked(int index) {
    if (index == 0) return true;
    if (index - 1 < 0 || index - 1 >= _levels.length) return false;
    return _levels[index - 1]['isCompleted'] == true;
  }
}