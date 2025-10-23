import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'video_screen.dart';
import 'video_learning_screen.dart';
import 'lesson_screen.dart';
import 'vocabulary_screen.dart';
import 'quiz_screen.dart';
import 'achievement_screen.dart';
import 'notification_screen.dart';
import 'debug_screen.dart';
import 'translation_screen.dart';
import 'interactive_video_screen.dart'; // Import InteractiveVideoScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? userProfile;
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final profileRes = await dio.get(ApiConfig.profileEndpoint);

      // Try to get progress data
      try {
        final progressRes = await dio.get(ApiConfig.progressionEndpoint);
        setState(() {
          userProfile = profileRes.data;
          stats = progressRes.data['stats'];
          isLoading = false;
        });
      } catch (progressError) {
        // If progress not found, try to initialize it
        try {
          await dio.post(ApiConfig.initializeProgressEndpoint);
          final progressRes = await dio.get(ApiConfig.progressionEndpoint);
          setState(() {
            userProfile = profileRes.data;
            stats = progressRes.data['stats'];
            isLoading = false;
          });
        } catch (initError) {
          // If initialization fails, just load profile without stats
          setState(() {
            userProfile = profileRes.data;
            stats = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('Failed to load user data');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            userProfile: userProfile,
            stats: stats,
            onRefresh: _loadUserData,
          ),
          const LessonScreen(),
          const VocabularyScreen(),
          const ProgressScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DebugScreen()),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Lessons',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style_outlined),
              activeIcon: Icon(Icons.style),
              label: 'Vocabulary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? stats;
  final VoidCallback onRefresh;

  const HomeTab({
    super.key,
    this.userProfile,
    this.stats,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context),
            _buildQuickActions(context),
            _buildStatsSection(context),
            _buildRecentActivity(context),
            _buildMotivationalSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final nickname = userProfile?['nickname'] ?? 'Student';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  nickname.isNotEmpty ? nickname[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good morning!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                  );
                },
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Ready to learn English today?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Start Lesson',
                  Icons.play_circle_outline,
                  Colors.blue,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LessonScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildActionCard(
                  context,
                  'Flashcards',
                  Icons.style_outlined,
                  Colors.green,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VocabularyScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Video Learning',
                  Icons.video_library_outlined,
                  Colors.orange,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VideoLearningScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildActionCard(
                  context,
                  'Take Quiz',
                  Icons.quiz_outlined,
                  Colors.purple,
                      () {
                    // TODO: Replace with actual topic selection logic
                    _showQuizSelection(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Translation',
                  Icons.translate,
                  Colors.teal,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TranslationScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildActionCard(
                  context,
                  'Progress',
                  Icons.trending_up,
                  Colors.indigo,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProgressScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Lessons',
                    '${stats!['completedLessons']}/${stats!['totalLessons']}',
                    Icons.book,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Quizzes',
                    '${stats!['totalQuizAttempts']}',
                    Icons.quiz,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Videos',
                    '${stats!['videosWatched']}',
                    Icons.play_circle,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Score',
                    '${stats!['averageQuizScore']?.toStringAsFixed(1) ?? '0'}',
                    Icons.star,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  Icons.check_circle,
                  Colors.green,
                  'Completed Lesson 1: Basic Greetings',
                  '2 hours ago',
                  onTap: () {
                    // TODO: Replace with actual data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InteractiveVideoScreen(
                          videoId: '60c72b969b1d8c001f8e4a9c',
                          videoTitle: 'Basic Greetings',
                          videoUrl: 'https://www.youtube.com/watch?v=gighAPt2r24',
                          topicId: '60c72b969b1d8c001f8e4a9c',
                          userId: '60c72b969b1d8c001f8e4a9a',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildActivityItem(
                  Icons.quiz,
                  Colors.blue,
                  'Quiz: Vocabulary Test',
                  '1 day ago',
                  score: '85%',
                  onTap: () {
                    // TODO: Replace with actual data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuizScreen(topicId: '60c72b969b1d8c001f8e4a9c'),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildActivityItem(
                  Icons.play_circle,
                  Colors.orange,
                  'Watched: Pronunciation Guide',
                  '2 days ago',
                  onTap: () {
                    // TODO: Replace with actual data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InteractiveVideoScreen(
                          videoId: '60c72b969b1d8c001f8e4a9c',
                          videoTitle: 'Pronunciation Guide',
                          videoUrl: 'https://www.youtube.com/watch?v=gighAPt2r24',
                          topicId: '60c72b969b1d8c001f8e4a9c',
                          userId: '60c72b969b1d8c001f8e4a9a',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      IconData icon,
      Color color,
      String title,
      String time, {
        String? score,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap, // Make the item tappable
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (score != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            if (onTap != null) // Show arrow if tappable
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalSection(BuildContext context) {
    final motivationalQuotes = [
      "Every expert was once a beginner.",
      "Learning never exhausts the mind.",
      "The only way to learn mathematics is to do mathematics.",
      "Success is the sum of small efforts repeated day in and day out.",
    ];

    final randomQuote = motivationalQuotes[DateTime.now().day % motivationalQuotes.length];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 15),
          const Text(
            'Daily Motivation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            randomQuote,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQuizSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Quiz',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.blue),
              title: const Text('Basic Vocabulary Quiz'),
              subtitle: const Text('Test your basic English vocabulary'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  // TODO: Replace with actual topic ID from your data
                  MaterialPageRoute(builder: (context) => const QuizScreen(topicId: '60c72b969b1d8c001f8e4a9c')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.green),
              title: const Text('Grammar Test'),
              subtitle: const Text('Practice English grammar rules'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  // TODO: Replace with actual topic ID from your data
                  MaterialPageRoute(builder: (context) => const QuizScreen(topicId: '60c72b969b1d8c001f8e4a9a')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
