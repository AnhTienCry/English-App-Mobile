// lib/screens/lesson_topics_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import 'vocabulary_screen.dart';
import 'quiz_screen.dart';

class LessonTopicsScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const LessonTopicsScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<LessonTopicsScreen> createState() => _LessonTopicsScreenState();
}

class _LessonTopicsScreenState extends State<LessonTopicsScreen> {
  List<dynamic> _topics = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
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
      if (data is Map && data['items'] is List) {
        setState(() => _topics = List.from(data['items']));
      } else if (data is List) {
        setState(() => _topics = data);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    return Scaffold(
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
              child: Text(
                _error!,
                style: GoogleFonts.poppins(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _topics.length,
          itemBuilder: (context, index) {
            final topic = _topics[index] as Map? ?? {};
            final completed = topic['completed'] == true;
            final title = topic['title'] ?? 'Untitled Topic';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              color: completed ? Colors.green.shade100 : Colors.white,
              child: ListTile(
                leading: Icon(
                  completed ? Icons.check_circle : Icons.menu_book_outlined,
                  color: completed ? Colors.green : Colors.purple,
                ),
                title: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: completed ? Colors.green.shade900 : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  topic['description'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  final topicId = topic['id'] ?? topic['_id'];
                  // Mở bottom sheet chọn học từ vựng hoặc quiz
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.menu_book),
                          title: const Text('Học từ vựng'),
                          onTap: () async {
                            Navigator.pop(context); // Đóng bottom sheet
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VocabularyScreen(topicId: topicId),
                              ),
                            );
                            if (result == true) _fetchTopics();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.quiz),
                          title: const Text('Làm bài Quiz'),
                          onTap: () async {
                            Navigator.pop(context); // Đóng bottom sheet
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizScreen(topicId: topicId),
                              ),
                            );
                            if (result == true) _fetchTopics();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
