import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../config/api_config.dart';
import 'lesson_topics_screen.dart';

/// Danh sách lessons theo Level -> chọn lesson -> vào Topic -> làm Quiz
class LevelLessonsScreen extends StatefulWidget {
  final String levelId;         // giữ lại nếu cần cho BE sau này
  final int levelNumber;        // số tầng từ Tower
  const LevelLessonsScreen({super.key, required this.levelId, required this.levelNumber});

  @override
  State<LevelLessonsScreen> createState() => _LevelLessonsScreenState();
}

class _LevelLessonsScreenState extends State<LevelLessonsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _lessons = [];

  @override
  void initState() {
    super.initState();
    _fetchLessonsByLevel();
  }

  Future<void> _fetchLessonsByLevel() async {
    setState(() { _loading = true; _error = null; });
    try {
      // BE trả { lessons: [...], totalProgress: number }
      final res = await dio.get("${ApiConfig.baseUrl}/api/lessons/published");
      final data = res.data;
      final List<dynamic> all = (data is Map && data['lessons'] is List) ? List<dynamic>.from(data['lessons']) : <dynamic>[];

      // Lọc theo levelNumber của Tower:
      // - Hỗ trợ cả kiểu số (1,2,3,...) và kiểu "A1","A2"...
      final String ax = "A${widget.levelNumber}";
      final filtered = all.where((l) {
        final lv = l['level'];
        if (lv is num) return lv.toInt() == widget.levelNumber;
        if (lv is String) return lv.trim().toUpperCase() == ax;
        return false;
      }).toList();

      // Sắp xếp theo order tăng dần
      filtered.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

      setState(() => _lessons = filtered);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openTopics(dynamic lesson) async {
    final id = lesson['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    final done = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonTopicsScreen(
          lessonId: id,
          lessonTitle: lesson['title']?.toString() ?? 'Lesson',
        ),
      ),
    );
    if (done == true) {
      await _fetchLessonsByLevel();
      if (mounted) Navigator.pop(context, true); // bubble up để màn Tower refresh nếu cần
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1FF),
      appBar: AppBar(
        title: Text('Level ${widget.levelNumber} • Lessons', style: GoogleFonts.poppins()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
        onRefresh: _fetchLessonsByLevel,
        child: _lessons.isEmpty
            ? ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.menu_book_outlined, size: 56, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Center(child: Text('Chưa có bài học cho level này.', style: GoogleFonts.poppins())),
            const SizedBox(height: 12),
            Center(child: ElevatedButton.icon(
              onPressed: _fetchLessonsByLevel,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            )),
          ],
        )
            : ListView.builder(
          itemCount: _lessons.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final l = _lessons[i];
            final title = l['title']?.toString() ?? 'Lesson';
            final desc  = l['description']?.toString() ?? '';
            final progress = (l['progress'] is num) ? (l['progress'] as num).toDouble() : 0.0;
            final isUnlocked = l['isUnlocked'] == true;
            return Opacity(
              opacity: isUnlocked ? 1.0 : 0.55,
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUnlocked ? Colors.green.shade100 : Colors.grey.shade300,
                    child: Icon(isUnlocked ? Icons.lock_open : Icons.lock, color: Colors.black87),
                  ),
                  title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (desc.isNotEmpty) Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (progress > 0) ...[
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: (progress / 100.0).clamp(0, 1)),
                      ],
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: isUnlocked ? () => _openTopics(l) : null,
                    child: const Text('Open'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error ?? 'Error', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: _fetchLessonsByLevel, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]),
    ),
  );
}
