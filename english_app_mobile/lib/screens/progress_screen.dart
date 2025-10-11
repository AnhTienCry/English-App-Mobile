import 'package:flutter/material.dart';
import '../api/api_client.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, dynamic>? progressData;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchProgress();
  }

  Future<void> fetchProgress() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await dio.get('/progress/me');
      setState(() {
        progressData = res.data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load progress';
        loading = false;
      });
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchProgress,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchProgress,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : buildProgressContent(),
    );
  }

  Widget buildProgressContent() {
    if (progressData == null) {
      return const Center(child: Text('No data available'));
    }

    final stats = progressData!['stats'];
    final lessonProgress = progressData!['lessonProgress'] as List? ?? [];
    final quizAttempts = progressData!['quizAttempts'] as List? ?? [];
    final videoProgress = progressData!['videoProgress'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: fetchProgress,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics cards
            buildStatsCard(stats),
            const SizedBox(height: 24),

            // Lesson Progress
            const Text(
              'Lesson Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            buildLessonProgressList(lessonProgress),
            const SizedBox(height: 24),

            // Recent Quiz Attempts
            const Text(
              'Recent Quiz Attempts',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            buildQuizAttemptsList(quizAttempts),
            const SizedBox(height: 24),

            // Video Progress
            const Text(
              'Video Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            buildVideoProgressList(videoProgress),
          ],
        ),
      ),
    );
  }

  Widget buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Your Statistics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildStatItem(
                  icon: Icons.book,
                  label: 'Lessons',
                  value: '${stats['completedLessons']}/${stats['totalLessons']}',
                ),
                buildStatItem(
                  icon: Icons.quiz,
                  label: 'Quizzes',
                  value: '${stats['totalQuizAttempts']}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildStatItem(
                  icon: Icons.score,
                  label: 'Avg Score',
                  value: '${stats['averageQuizScore']?.toStringAsFixed(1) ?? '0'}',
                ),
                buildStatItem(
                  icon: Icons.play_circle,
                  label: 'Videos',
                  value: '${stats['videosWatched']}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget buildLessonProgressList(List lessons) {
    if (lessons.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No lessons started yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      children: lessons.map<Widget>((lp) {
        final progress = lp['progress'] ?? 0;
        final isCompleted = lp['isCompleted'] ?? false;
        final lesson = lp['lesson'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lesson['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'In Progress',
                        style: TextStyle(
                          color: isCompleted ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$progress%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildQuizAttemptsList(List attempts) {
    if (attempts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No quiz attempts yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      children: attempts.take(5).map<Widget>((attempt) {
        final score = attempt['score'];
        final maxScore = attempt['maxScore'];
        final percentage = maxScore > 0 ? ((score / maxScore) * 100).round() : 0;
        final quiz = attempt['quiz'];
        final completedAt = attempt['completedAt'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: percentage >= 70 ? Colors.green : Colors.orange,
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              quiz['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Score: $score/$maxScore • ${formatDate(completedAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Icon(
              percentage >= 70 ? Icons.check_circle : Icons.pending,
              color: percentage >= 70 ? Colors.green : Colors.orange,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildVideoProgressList(List videos) {
    if (videos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No videos watched yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      children: videos.take(5).map<Widget>((vp) {
        final video = vp['video'];
        final isCompleted = vp['isCompleted'] ?? false;
        final watchedDuration = vp['watchedDuration'] ?? 0;
        final duration = video['duration'] ?? 1;
        final percentage = ((watchedDuration / duration) * 100).round();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.play_circle : Icons.play_circle_outline,
              color: isCompleted ? Colors.green : Colors.blue,
              size: 32,
            ),
            title: Text(
              video['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage% watched',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        );
      }).toList(),
    );
  }
}






