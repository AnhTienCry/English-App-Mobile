import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../api/api_client.dart';
import '../config/api_config.dart';
import '../api/api_client.dart';
import 'vocabulary_screen.dart';
import 'quiz_screen.dart';

class LessonTopicsScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final String? levelId;

  const LessonTopicsScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    this.levelId,
  });

  @override
  State<LessonTopicsScreen> createState() => _LessonTopicsScreenState();
}

class _LessonTopicsScreenState extends State<LessonTopicsScreen> {
  List<dynamic> _topics = [];
  bool _loading = true;
  String? _error;
  Set<String> _localCompletedIds = <String>{}; // persist locally

  // NEW: lưu stats per-topic: { topicId: { 'correct': n, 'total': m } }
  Map<String, Map<String, int>> _localTopicStats = {};

  @override
  void initState() {
    super.initState();
    _loadLocalCompletedIds();
    _loadLocalTopicStats(); // NEW
    _fetchTopics();
  }

  Future<void> _loadLocalCompletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('completedTopics') ?? [];
    setState(() => _localCompletedIds = ids.toSet());
  }

  Future<void> _saveLocalCompletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completedTopics', _localCompletedIds.toList());
  }

  Future<void> _loadLocalTopicStats() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'topic_stats_${widget.lessonId}';
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final Map decoded = jsonDecode(raw);
        _localTopicStats = decoded.map((k, v) =>
            MapEntry(k.toString(), Map<String, int>.from((v as Map).map((kk, vv) => MapEntry(kk.toString(), (vv as num).toInt())))));
      } catch (_) {
        _localTopicStats = {};
      }
    }
  }

  Future<void> _saveLocalTopicStats() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'topic_stats_${widget.lessonId}';
    await prefs.setString(key, jsonEncode(_localTopicStats));
  }

  Future<void> _fetchTopics() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await dio.get("${ApiConfig.baseUrl}/api/topics/by-lesson/${widget.lessonId}");
      final data = res.data;
      List<dynamic> topicsList = [];
      if (data is Map && data['items'] is List) {
        topicsList = List.from(data['items']);
      } else if (data is List) {
        topicsList = data;
      } else {
        setState(() => _error = "Unexpected response");
        return;
      }

      // fetch progression and merge with local
      final Set<String> completedIds = <String>{};
      completedIds.addAll(_localCompletedIds); // start with local

      try {
        final progRes = await dio.get("${ApiConfig.baseUrl}${ApiConfig.progressionEndpoint}");
        final progData = progRes.data;
        if (progData is Map) {
          if (progData['completedTopics'] is List) {
            completedIds.addAll(List.from(progData['completedTopics']).map((e) => e.toString()));
          }
          if (progData['progress'] is Map && progData['progress']['completedTopics'] is List) {
            completedIds.addAll(List.from(progData['progress']['completedTopics']).map((e) => e.toString()));
          }
          if (progData['progression'] is Map && progData['progression']['completedTopics'] is List) {
            completedIds.addAll(List.from(progData['progression']['completedTopics']).map((e) => e.toString()));
          }
        }
        // update local with server data
        _localCompletedIds.addAll(completedIds);
        await _saveLocalCompletedIds();
      } catch (_) {
        // ignore, use local
      }

      // apply completed flags + apply saved per-topic stats
      for (var t in topicsList) {
        final id = (t['_id'] ?? t['id'] ?? '').toString();
        final fromProgress = id.isNotEmpty && completedIds.contains(id);
        final completedFlag = fromProgress;
        t['completed'] = completedFlag;
        t['isCompleted'] = completedFlag;
        t['passed'] = completedFlag;

        // apply per-topic stats if exist
        if (_localTopicStats.containsKey(id)) {
          final st = _localTopicStats[id]!;
          t['correct'] = st['correct'] ?? 0;
          t['totalQuestions'] = st['total'] ?? 0;
        } else {
          t['correct'] = t['correct'] ?? 0;
          t['totalQuestions'] = t['questionCount'] ?? 0;
        }
      }

      if (mounted) setState(() => _topics = topicsList);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openTopicOptions(Map topic) async {
    final topicId = (topic['_id'] ?? topic['id'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Học từ vựng'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VocabularyScreen(topicId: topicId)),
                );
                final passed = (result == true) || (result is Map && result['passed'] == true);
                if (passed && mounted) {
                  setState(() {
                    final idx = _topics.indexWhere((t) => (t['_id'] ?? t['id'] ?? '').toString() == topicId);
                    if (idx != -1) {
                      _topics[idx]['completed'] = true;
                      _topics[idx]['isCompleted'] = true;
                      _topics[idx]['passed'] = true;
                    }
                  });
                  _localCompletedIds.add(topicId);
                  await _saveLocalCompletedIds();
                  _fetchTopics();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Làm bài Quiz'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuizScreen(topicId: topicId, lessonId: widget.lessonId)),
                );

                // Nếu QuizScreen trả về Map với stats
                if (result is Map) {
                  final int correct = (result['correctCount'] is int)
                      ? result['correctCount'] as int
                      : int.tryParse(result['correctCount']?.toString() ?? '0') ?? 0;
                  final int total = (result['totalQuestions'] is int)
                      ? result['totalQuestions'] as int
                      : int.tryParse(result['totalQuestions']?.toString() ?? '0') ?? 0;
                  final String returnedTopicId = (result['topicId'] ?? topicId).toString();

                  // Ưu tiên dùng 'passed' nếu QuizScreen/backend trả về, ngược lại: passed khi correct >= 7
                  bool passed = false;
                  if (result.containsKey('passed') && result['passed'] is bool) {
                    passed = result['passed'] as bool;
                  } else {
                    passed = correct >= 7;
                  }

                  // lưu per-topic stats local
                  await _saveTopicResultLocally(widget.lessonId, returnedTopicId, correct, total);
                  _localTopicStats[returnedTopicId] = {'correct': correct, 'total': total};
                  await _saveLocalTopicStats();

                  if (passed) {
                    _localCompletedIds.add(returnedTopicId);
                    await _saveLocalCompletedIds();
                  }

                  // cập nhật UI topic ngay
                  setState(() {
                    final idx = _topics.indexWhere((t) => (t['_id'] ?? t['id'] ?? '').toString() == returnedTopicId);
                    if (idx != -1) {
                      _topics[idx]['completed'] = passed;
                      _topics[idx]['isCompleted'] = passed;
                      _topics[idx]['passed'] = passed;
                      _topics[idx]['correct'] = correct;
                      _topics[idx]['totalQuestions'] = total;
                    }
                  });

                  // Kiểm tra nếu đã hoàn thành tất cả topics => tính percent tổng và show dialog cho user chọn
                  if (_areAllTopicsCompleted()) {
                    final totals = await _computeLessonTotalsFromLocal(widget.lessonId);
                    final int lessonPercent = totals['percent'] ?? 0;
                    final int totalCorrect = totals['correct'] ?? 0;
                    final int totalQuestions = totals['total'] ?? 0;

                    // only allow opening next when percent > 70
                    final bool canOpenNext = lessonPercent > 70;

                    final bool? openNext = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text('Hoàn thành bài học'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Bạn đã hoàn thành tất cả topics của bài học.'),
                              const SizedBox(height: 12),
                              Text('Tổng câu đúng: $totalCorrect / $totalQuestions\nTiến trình: $lessonPercent%'),
                              const SizedBox(height: 12),
                              if (!canOpenNext)
                                Text(
                                  'Cần > 70% để mở bài tiếp. Hoàn thành thêm để tăng tỉ lệ.',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Quay lại'),
                            ),
                            ElevatedButton(
                              onPressed: canOpenNext ? () => Navigator.of(ctx).pop(true) : null,
                              child: const Text('Quay lại và mở bài tiếp'),
                            ),
                          ],
                        );
                      },
                    );

                    // submit lesson result to server (so progress recorded)
                    await _submitLessonIfCompleted(widget.lessonId); // function updated below

                    if (!mounted) return;
                    Navigator.pop(context, {
                      'lessonId': widget.lessonId,
                      'percent': lessonPercent,
                      'completed': true,
                      'openNext': (openNext == true) && canOpenNext,
                      'totalCorrect': totalCorrect,
                      'totalQuestions': totalQuestions,
                    });
                    return;
                  } else {
                    // nếu chưa xong hết topics, ở lại LessonTopicsScreen
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Topic saved — lesson progress: ${await _computeLessonPercentFromLocal(widget.lessonId)}%')),
                      );
                    }
                  }
                } else if (result == true) {
                  // trường hợp QuizScreen chỉ trả true => refresh topics từ server
                  await _fetchTopics();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper: save per-topic result into SharedPreferences under key topic_stats_<lessonId>
  Future<void> _saveTopicResultLocally(String lessonId, String topicId, int correct, int total) async {
    final prefs = await SharedPreferences.getInstance();
    // lưu dạng map topicId => { correct, total }
    final raw = prefs.getString('topic_stats_$lessonId');
    Map<String, dynamic> map = {};
    if (raw != null) {
      try {
        map = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    map[topicId] = {'correct': correct, 'total': total};
    await prefs.setString('topic_stats_$lessonId', jsonEncode(map));
  }

  bool _areAllTopicsCompleted() {
    if (_topics.isEmpty) return false;

    for (final t in _topics) {
      final id = ((t['_id'] ?? t['id'] ?? '')).toString();
      if (id.isEmpty) return false;

      // nếu đã đánh dấu hoàn thành local (ví dụ học từ vựng / quiz passed)
      if (_localCompletedIds.contains(id)) continue;

      // nếu có stats local, require correct >= total
      final stats = _localTopicStats[id];
      if (stats != null) {
        final correct = stats['correct'] ?? 0;
        final total = stats['total'] ?? 0;
        if (total <= 0 || correct < total) return false;
        continue;
      }

      // nếu không có cả hai thì chưa hoàn thành
      return false;
    }

    return true;
  }

  // Helper: compute lesson percent from all topic_stats_<lessonId> entries
  Future<int> _computeLessonPercentFromLocal(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('topic_stats_$lessonId');
    if (raw == null) return 0;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      int sumCorrect = 0;
      int sumTotal = 0;
      decoded.forEach((k, v) {
        if (v is Map) {
          final c = (v['correct'] is num) ? (v['correct'] as num).toInt() : 0;
          final t = (v['total'] is num) ? (v['total'] as num).toInt() : 0;
          sumCorrect += c;
          sumTotal += t;
        }
      });
      if (sumTotal == 0) return 0;
      return ((sumCorrect / sumTotal) * 100).round();
    } catch (_) {
      return 0;
    }
  }

  // helper: tính tổng correct/total từ local topic_stats và trả {correct,total,percent}
  Future<Map<String, int>> _computeLessonTotalsFromLocal(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('topic_stats_$lessonId');
    if (raw == null) return {'correct': 0, 'total': 0, 'percent': 0};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      int sumCorrect = 0;
      int sumTotal = 0;
      decoded.forEach((_, v) {
        if (v is Map) {
          sumCorrect += (v['correct'] is num) ? (v['correct'] as num).toInt() : 0;
          sumTotal += (v['total'] is num) ? (v['total'] as num).toInt() : 0;
        }
      });
      final percent = sumTotal > 0 ? ((sumCorrect / sumTotal) * 100).round() : 0;
      return {'correct': sumCorrect, 'total': sumTotal, 'percent': percent};
    } catch (_) {
      return {'correct': 0, 'total': 0, 'percent': 0};
    }
  }

  // CALL THIS where you currently handle Quiz result and lessonPercent >= 100
  Future<void> _submitLessonIfCompleted(String lessonId) async {
    final totals = await _computeLessonTotalsFromLocal(lessonId);
    if (totals['percent'] != null && totals['percent']! >= 100) {
      try {
        final body = {
          'lessonId': lessonId,
          'score': totals['percent'],
          'timeSpent': 0, // nếu có thể truyền tổng thời gian, thay vào đây
        };
        final res = await dio.post("${ApiConfig.baseUrl}/api/lessons/submit", data: body);
        final data = res.data;
        // trả về progress server (nếu server trả) để LessonScreen dùng ngay
        if (mounted) Navigator.pop(context, {
          'lessonId': lessonId,
          'percent': totals['percent'],
          'progress': data?['progress'] ?? data?['progression'] ?? {},
        });
        return;
      } catch (e) {
        // nếu submit lên server lỗi thì vẫn pop với percent local để UI cập nhật
        if (mounted) Navigator.pop(context, {
          'lessonId': lessonId,
          'percent': totals['percent'],
          'progress': {},
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.purple)));
    }

    return WillPopScope(
      onWillPop: () async {
        // Trả về true để báo LessonScreen refresh progress
        Navigator.pop(context, true);
        // Trả về false để ngăn hệ thống pop mặc định (vì đã pop ở trên)
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(widget.lessonTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.purple,
        ),
        body: RefreshIndicator(
          onRefresh: _fetchTopics,
          child: _error != null
              ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red), textAlign: TextAlign.center),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    final topic = _topics[index] as Map? ?? {};
                    final title = topic['title'] ?? 'Untitled Topic';
                    final desc = topic['description'] ?? '';
                    final completed = (topic['completed'] == true) ||
                        (topic['isCompleted'] == true) ||
                        (topic['passed'] == true);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      color: completed ? Colors.green.shade50 : Colors.white,
                      child: ListTile(
                        leading: Icon(
                          completed ? Icons.check_circle : Icons.menu_book_outlined,
                          color: completed ? Colors.green.shade700 : Colors.purple,
                        ),
                        title: Text(title,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: completed ? Colors.green.shade800 : Colors.black87)),
                        subtitle: Text(desc, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () => _openTopicOptions(topic),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}