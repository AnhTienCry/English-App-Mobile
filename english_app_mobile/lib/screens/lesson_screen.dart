import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import 'lesson_topics_screen.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  List<dynamic> lessons = [];
  double totalProgress = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      // use relative path — dio's baseUrl is configured in api_client.dart
      final res = await dio.get('/api/lessons/published');
      final data = res.data;
      if (!mounted) return;
      setState(() {
        lessons = (data is Map) ? (data['lessons'] ?? []) : [];
        totalProgress = ((data is Map ? data['totalProgress'] : null) ?? 0).toDouble();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading lessons: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load lessons')),
      );
    }
  }

  Future<void> _openLessonAndMaybeRefresh(String lessonId, String lessonTitle) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonTopicsScreen(
          lessonId: lessonId,
          lessonTitle: lessonTitle,
        ),
      ),
    );

    if (changed == true) {
      await _fetchLessons();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress updated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLessons,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Overall Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (totalProgress.clamp(0, 100)) / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.green,
                  ),
                  Text('${totalProgress.toStringAsFixed(0)}% completed', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index] as Map? ?? {};
                  final isUnlocked = lesson['isUnlocked'] == true;
                  final isCompleted = lesson['isCompleted'] == true;
                  final progressVal = lesson['progress'];
                  final progress = (progressVal is num) ? progressVal.toDouble() : double.tryParse('$progressVal') ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        lesson['title'] ?? 'Untitled Lesson',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((lesson['description'] ?? '') + (isCompleted ? ' (Completed)' : '')),
                          const SizedBox(height: 6),
                          if (!isCompleted) ...[
                            LinearProgressIndicator(
                              value: (progress.clamp(0, 100)) / 100,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.blue,
                            ),
                            Text('${progress.toStringAsFixed(0)}% completed', style: const TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          (lesson['level'] ?? '').toString().isNotEmpty ? lesson['level'].toString() : 'L',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      enabled: isUnlocked,
                      onTap: isUnlocked
                          ? () => _openLessonAndMaybeRefresh(lesson['_id']?.toString() ?? '', lesson['title'] ?? '')
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}