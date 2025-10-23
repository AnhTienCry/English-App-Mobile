import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import 'lesson_topics_screen.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _lessons = [];

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await dio.get("${ApiConfig.baseUrl}/api/lessons/progress/me");
      final data = res.data;
      if (data is Map && data['items'] is List) {
        setState(() => _lessons = List.from(data['items']));
      } else {
        setState(() => _error = "Unexpected response");
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLesson(dynamic lesson) async {
    if (lesson['locked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson đang bị khóa. Hãy hoàn thành lesson trước!')),
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonTopicsScreen(
          lessonId: lesson['id'],
          lessonTitle: lesson['title'] ?? 'Lesson',
        ),
      ),
    );

    if (result is Map && result['items'] is List) {
      setState(() => _lessons = List.from(result['items']));
    } else if (result == true) {
      await _fetchProgress();
    }
  }

  Widget _buildLessonCard(dynamic l, TextStyle titleStyle, TextStyle subStyle, bool locked, int percent, VoidCallback? onTap) {
    final title = l['title'] ?? 'Lesson';
    final desc = (l['description'] ?? '').toString();
    final completed = (l['isCompleted'] == true);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: completed ? Colors.green.shade50 : (locked ? Colors.grey.shade200 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle.copyWith(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(desc, style: subStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                locked
                    ? const Icon(Icons.lock, color: Colors.grey, size: 20)
                    : (completed ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : const Icon(Icons.star, color: Colors.orange, size: 20)),
                const SizedBox(width: 8),
                Text('$percent%', style: GoogleFonts.poppins(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700);
    final subStyle = GoogleFonts.poppins(fontSize: 12, color: Colors.black54);

    return Scaffold(
      appBar: AppBar(title: Text('Lessons', style: GoogleFonts.poppins())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchProgress,
                  child: Stack(
                    children: [
                      // center vertical line
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(width: 2, color: Colors.grey.shade300),
                        ),
                      ),
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        itemCount: _lessons.length,
                        itemBuilder: (context, i) {
                          final l = _lessons[i];
                          final locked = l['locked'] == true;
                          final percentRaw = l['percent'] ?? 0;
                          final percent = (percentRaw is int) ? percentRaw : int.tryParse(percentRaw.toString()) ?? 0;
                          final left = i % 2 == 0;
                          final card = _buildLessonCard(l, titleStyle, subStyle, locked, percent, locked ? null : () => _openLesson(l));

                          return SizedBox(
                            height: 140,
                            child: Row(
                              children: [
                                if (left) Expanded(child: Align(alignment: Alignment.centerRight, child: card)) else const Expanded(child: SizedBox()),
                                SizedBox(
                                  width: 72,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: locked ? null : () => _openLesson(l),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: (l['isCompleted'] == true) ? Colors.green : (locked ? Colors.grey : Colors.orange),
                                        child: Icon(
                                          (l['isCompleted'] == true) ? Icons.check : (locked ? Icons.lock : Icons.star),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!left) Expanded(child: Align(alignment: Alignment.centerLeft, child: card)) else const Expanded(child: SizedBox()),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}