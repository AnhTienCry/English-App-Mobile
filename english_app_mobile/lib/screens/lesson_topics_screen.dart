// ...existing code...
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import 'vocabulary_screen.dart';
import 'quiz_screen.dart'; // ✅ thay quiz_list_screen.dart bằng quiz_screen.dart

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
  List<dynamic> topics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      // use dio baseUrl configured in api_client.dart
      final res = await dio.get('/api/topics/${widget.lessonId}');
      final data = res.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        // backend may return { topics: [...] } or the array directly
        list = (data['topics'] is List) ? data['topics'] : (data['data'] is List ? data['data'] : []);
      }
      if (!mounted) return;
      setState(() {
        topics = list;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading topics: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load topics')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTopics,
        child: ListView.builder(
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index] as Map? ?? {};
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  topic['title'] ?? 'Untitled Topic',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(topic['description'] ?? ''),
                trailing: const Icon(Icons.menu_book_outlined),
                onTap: () => _showTopicOptions(context, topic),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showTopicOptions(BuildContext screenContext, dynamic topic) {
    showModalBottomSheet(
      context: screenContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.translate, color: Colors.green),
              title: const Text('Study Vocabulary'),
              onTap: () {
                Navigator.pop(dialogContext); // Pop dialog
                Navigator.push<bool>(
                  screenContext, // Sử dụng screenContext
                  MaterialPageRoute(
                    builder: (_) => VocabularyScreen(topicId: topic['_id']),
                  ),
                ).then((changed) {
                  if (changed == true) {
                    if (mounted) Navigator.pop(screenContext, true); // Sử dụng screenContext
                  } else {
                    _fetchTopics();
                  }
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.purple),
              title: const Text('Take Quiz'),
              subtitle: const Text('Answer questions and test your knowledge'),
              onTap: () {
                Navigator.pop(dialogContext); // Pop dialog
                Navigator.push<bool>(
                  screenContext, // Sử dụng screenContext
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      topicId: topic['_id'],
                      lessonId: widget.lessonId, // Thêm lessonId
                    ),
                  ),
                ).then((changed) {
                  if (changed == true) {
                    if (mounted) Navigator.pop(screenContext, true); // Sử dụng screenContext
                  } else {
                    _fetchTopics();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
// ...existing code...